"""Causal sample/block inference with persistent filtering and a ring buffer."""
from collections import deque
import numpy as np
from scipy.signal import sosfilt, sosfilt_zi
from .features import design_filter, window_features


class StreamingPredictor:
    """Feed successive samples from ONE continuous acquisition session.

    Output begins after a full two-second window, then every half second.
    Reset the object at a genuinely independent file/session boundary.
    """
    def __init__(self, bundle, source_hz=1000):
        self.bundle = bundle; self.settings = bundle["settings"]
        self.sos, self.factor = design_filter(source_hz, self.settings)
        self.source_hz = source_hz; self.count = 0; self.previous_time = None
        self.zi = None; self.last_alarm = -np.inf; self.previous_high = False
        self.n = round(self.settings["window_s"]*self.settings["sampling_hz"])
        self.step = round(self.settings["stride_s"]*self.settings["sampling_hz"])
        self.buffer = deque(maxlen=self.n); self.decimated_count = 0

    def push(self, time_s, imu):
        x = np.asarray(imu, float).copy()
        if x.shape != (6,) or not np.isfinite(x).all() or not np.isfinite(time_s):
            raise ValueError("Expected a finite six-axis sample")
        if self.previous_time is not None and not np.isclose(time_s-self.previous_time, 1/self.source_hz, atol=1e-7, rtol=1e-5):
            raise ValueError("Stream timestamp discontinuity: explicitly start a new session")
        self.previous_time = time_s
        x[3:] -= np.asarray(self.bundle["calibration"]["gyro_bias_deg_s"])
        if self.zi is None: self.zi = sosfilt_zi(self.sos)[:, :, None]*x[None, None, :]
        y, self.zi = sosfilt(self.sos, x[None, :], axis=0, zi=self.zi)
        take = self.count % self.factor == 0; self.count += 1
        if not take: return None
        self.buffer.append(y[0]); self.decimated_count += 1
        if len(self.buffer) < self.n or (self.decimated_count-self.n) % self.step: return None
        features = window_features(np.asarray(self.buffer)[None, :, :], self.settings["sampling_hz"])
        model = self.bundle["model"]
        probability = float(model.predict_proba(features)[0, list(model.classes_).index(1)])
        high = probability >= self.bundle["threshold"]
        alert = high and not self.previous_high and time_s-self.last_alarm >= self.settings["alarm_cooldown_s"]
        if alert: self.last_alarm = time_s
        self.previous_high = high
        return {"time_s": time_s, "probability_fall": probability, "predicted_fall": int(high), "alarm": int(alert)}

    def push_block(self, time_s, imu):
        time_s = np.asarray(time_s)
        imu = np.asarray(imu)
        if time_s.ndim != 1 or imu.ndim != 2 or imu.shape != (len(time_s), 6):
            raise ValueError("A block must contain matching timestamps and six-axis rows")
        output = []
        for t, x in zip(time_s, imu):
            result = self.push(float(t), x)
            if result is not None: output.append(result)
        return output
