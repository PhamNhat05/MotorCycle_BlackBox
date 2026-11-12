"""Causal preprocessing and 24 explicitly defined window features."""
import numpy as np
from scipy.signal import butter, sosfilt, sosfilt_zi

FEATURE_NAMES = [
    "A_max", "A_mean", "A_std", "A_rms", "G_max", "G_mean", "G_std",
    "jerk_max", "tilt_proxy_end_deg", "tilt_proxy_max_deg", "tilt_proxy_change_deg",
    "Az_second_half_mean", "still_A", "still_G", "freefall_fraction",
    "Ax_absmax", "Ay_absmax", "Az_absmax", "Gx_absmax", "Gy_absmax", "Gz_absmax",
    "fft_energy_0_5", "fft_energy_5_15", "fft_energy_15_40",
]


def design_filter(source_hz, settings):
    target = settings["sampling_hz"]
    if source_hz < target or source_hz % target:
        raise ValueError(f"Source rate must be an integer multiple of {target} Hz")
    return butter(settings["filter_order"], settings["lowpass_hz"],
                  fs=source_hz, output="sos"), source_hz // target


def preprocess(t, x, hz, settings, gyro_bias):
    sos, factor = design_filter(hz, settings)
    corrected = x.copy(); corrected[:, 3:] -= np.asarray(gyro_bias)
    zi = sosfilt_zi(sos)[:, :, None] * corrected[0][None, None, :]
    y, _ = sosfilt(sos, corrected, axis=0, zi=zi)
    return t[::factor], y[::factor]


def window_features(w, fs):
    """Input [batch, samples, 6]; output [batch, 24] float32.

    A/G statistics use Euclidean magnitudes. Tilt is a gravity proxy from
    acceleration, not an estimated true attitude during dynamic motion.
    """
    a = np.linalg.norm(w[:, :, :3], axis=2)
    g = np.linalg.norm(w[:, :, 3:], axis=2)
    tilt = np.rad2deg(np.arctan2(np.linalg.norm(w[:, :, :2], axis=2),
                               np.abs(w[:, :, 2]) + 1e-12))
    jerk = np.linalg.norm(np.diff(w[:, :, :3], axis=1) * fs, axis=2)
    f = [a.max(1), a.mean(1), a.std(1), np.sqrt((a*a).mean(1)),
         g.max(1), g.mean(1), g.std(1), jerk.max(1), tilt[:, -1],
         tilt.max(1), tilt[:, -1] - tilt[:, 0], w[:, w.shape[1]//2:, 2].mean(1),
         (np.abs(a - 9.81) < 1.5).mean(1), (g < 5).mean(1), (a < 0.5*9.81).mean(1)]
    f.extend(np.abs(w).max(1).T)
    n = w.shape[1]
    spec = np.fft.rfft(a - a.mean(1, keepdims=True), axis=1)
    power = np.abs(spec)**2 / n**2
    weights = np.full(power.shape[1], 2.0); weights[0] = 1
    if n % 2 == 0: weights[-1] = 1
    power *= weights
    freq = np.fft.rfftfreq(n, 1/fs)
    for lo, hi in [(0, 5), (5, 15), (15, 40)]:
        f.append(power[:, (freq >= lo) & (freq < hi)].sum(1))
    out = np.column_stack(f).astype(np.float32)
    if out.shape[1] != 24 or not np.isfinite(out).all():
        raise ValueError("Invalid feature matrix")
    return out


def extract(t, x, hz, settings, gyro_bias):
    td, y = preprocess(t, x, hz, settings, gyro_bias)
    fs = settings["sampling_hz"]
    n, step = round(settings["window_s"]*fs), round(settings["stride_s"]*fs)
    ends = np.arange(n-1, len(y), step)
    batches = []
    for start in range(0, len(ends), 128):
        e = ends[start:start+128]
        idx = e[:, None] - np.arange(n-1, -1, -1)[None, :]
        batches.append(window_features(y[idx], fs))
    return td[ends], np.concatenate(batches) if batches else np.empty((0, 24), np.float32)
