"""Estimate a shared gyro prior using only the six AI TRAIN parents."""
import numpy as np
from .io import verify_parent


def estimate_train_prior(root, parents):
    records, estimates = [], []
    for p in parents:
        if p["ai_split"] != "train": continue
        t, x, hz = verify_parent(root / p["relative_path"], p)
        accepted = []
        for start in np.arange(0.5, 5.0, 0.5):
            q = x[(t >= start) & (t < start + 0.5)]
            if len(q) < 0.99 * 0.5 * hz: continue
            a, g = q[:, :3], q[:, 3:]
            if (np.max(np.std(g, axis=0, ddof=1)) <= 0.6
                and np.max(np.abs(g.mean(axis=0))) <= 5
                and np.max(np.std(a, axis=0, ddof=1)) <= 0.3
                and abs(np.linalg.norm(a.mean(axis=0)) - 9.81) <= 1.5):
                accepted.append(g.mean(axis=0))
        if accepted: estimates.append(np.median(accepted, axis=0))
        records.append({"parent": p["key"], "accepted_windows": len(accepted),
                        "accepted_gyro_means_deg_s": [v.tolist() for v in accepted]})
    if len(estimates) < 2:
        raise ValueError("At least two TRAIN parents need qualifying quiet prefixes")
    return {"gyro_bias_deg_s": np.median(estimates, axis=0).tolist(),
            "train_parent_keys": [p["key"] for p in parents if p["ai_split"] == "train"],
            "records": records, "validation_or_test_used": False,
            "acc_bias_prior_m_s2": [0, 0, 0],
            "scope": "conditional quiet-prefix gyro prior, not independently verified calibration"}


def rebase_position_effect(x, definition, frozen, new_bias):
    """Remove the generator's seven-BUILD gyro-prior contribution analytically.

    For fixed translation dr: a_shift = alpha x dr + w x (w x dr).
    A constant gyro-prior change leaves alpha unchanged. Correct only the
    centripetal term; nominal sensor signals and added bias remain unchanged.
    This is a sensor-augmentation rebase, not a new 3D trajectory solution.
    """
    r = np.asarray(definition["position_delta_body_m"], dtype=float)
    if r.shape != (3,) or not np.isfinite(r).all(): raise ValueError("Invalid lever arm")
    if np.linalg.norm(r) > 0.5 + 1e-8: raise ValueError("Position shift exceeds 0.5 m")
    old_bias = np.asarray(frozen["K"]["bias"], dtype=float)
    rotation = np.asarray(frozen["K"]["sensor_to_body"], dtype=float)
    delta = np.asarray(definition["bias_delta"], dtype=float)
    total = np.asarray(definition["bias_total"], dtype=float)
    if old_bias.shape != (6,) or delta.shape != (6,) or rotation.shape != (3, 3):
        raise ValueError("Unexpected frozen calibration layout")
    if not np.allclose(total, old_bias + delta, atol=1e-8):
        raise ValueError("Variant bias metadata does not match frozen calibration")
    if not np.allclose(rotation @ rotation.T, np.eye(3), atol=1e-8):
        raise ValueError("Invalid mounting rotation")
    # Published export gyro = nominal conditioned gyro + the added gyro delta.
    w_old = np.deg2rad(x[:, 3:] - total[3:]) @ rotation.T
    offset = np.deg2rad(old_bias[3:] - np.asarray(new_bias)) @ rotation.T
    w_new = w_old + offset
    correction = (np.cross(w_new, np.cross(w_new, r))
                  - np.cross(w_old, np.cross(w_old, r))) @ rotation
    y = x.copy(); y[:, :3] += correction
    return y, float(np.max(np.abs(correction)))
