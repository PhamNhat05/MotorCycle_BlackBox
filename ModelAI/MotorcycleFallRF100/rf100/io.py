"""Strict CSV parsing and provenance utilities; no MATLAB runtime is needed."""
from pathlib import Path
import hashlib
import json
import numpy as np


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def write_json(path, value):
    """Write portable JSON: unavailable numeric metrics become null."""
    def clean(v):
        if isinstance(v, dict):
            return {str(k): clean(x) for k, x in v.items()}
        if isinstance(v, (list, tuple, np.ndarray)):
            return [clean(x) for x in v]
        if isinstance(v, (np.integer,)): return int(v)
        if isinstance(v, (float, np.floating)):
            return float(v) if np.isfinite(v) else None
        if isinstance(v, np.bool_): return bool(v)
        if isinstance(v, Path): return str(v)
        return v
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(clean(value), indent=2, allow_nan=False), encoding="utf-8")


def read_imu(path):
    """Accept measured tab-separated CSVs, generated CSVs or named live CSVs.

    Return time [s], IMU [m/s^2, deg/s], source frequency [Hz]. Columns and
    timestamps are checked rather than inferred from the .csv extension.
    """
    path = Path(path)
    with path.open(encoding="utf-8-sig", errors="replace") as f:
        header = f.readline()
    delimiter = "\t" if "\t" in header else ","
    names = [s.strip().lower() for s in header.rstrip().split(delimiter)]
    if delimiter == "\t" and names[0].startswith("time(s)"):
        columns = list(range(7))  # Legacy source headers contain Latin-1 units.
    else:
        aliases = [
            ("time_s", "time", "time(s)"),
            ("ax_m_s2", "ax"), ("ay_m_s2", "ay"), ("az_m_s2", "az"),
            ("gx_deg_s", "gx", "rx"), ("gy_deg_s", "gy", "ry"),
            ("gz_deg_s", "gz", "rz"),
        ]
        columns = []
        for choices in aliases:
            found = [names.index(a) for a in choices if a in names]
            if not found: raise ValueError(f"Missing IMU column {choices}: {path}")
            columns.append(found[0])
    a = np.loadtxt(path, delimiter=delimiter, skiprows=1, usecols=columns,
                   encoding="latin-1", ndmin=2)
    if len(a) < 2 or not np.isfinite(a).all():
        raise ValueError(f"Nonfinite or insufficient data: {path}")
    dt = np.diff(a[:, 0]); median = np.median(dt)
    if median <= 0 or not np.allclose(dt, median, atol=1e-7, rtol=1e-5):
        raise ValueError(f"Timestamps must be uniform and strictly increasing: {path}")
    hz = int(round(1 / median))
    if not np.isclose(1 / median, hz, atol=1e-3):
        raise ValueError("Source frequency must be an integer Hz value")
    return a[:, 0], a[:, 1:7], hz


def verify_parent(path, item):
    if sha256(path) != item["sha256"]:
        raise ValueError(f"Measured input checksum changed: {item['key']}")
    t, x, hz = read_imu(path)
    if len(t) != item["samples"] or not np.allclose(
            [t[0], t[-1]], [item["first_time_s"], item["last_time_s"]], atol=1e-7):
        raise ValueError(f"Measured input timing changed: {item['key']}")
    return t, x, hz
