"""Check scientific boundaries and exact causal inference, not just syntax."""
from pathlib import Path
import json
import tempfile
import unittest
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from rf100.io import read_imu, verify_parent
from rf100.features import extract, window_features, FEATURE_NAMES
from rf100.calibration import rebase_position_effect
from rf100.metrics import labels, alarms, event_metrics
from rf100.training import training_arrays
from rf100.stream import StreamingPredictor

ROOT = Path(__file__).resolve().parents[1]
SETTINGS = json.loads((ROOT / "config/settings.json").read_text())
PARENTS = json.loads((ROOT / "config/parents.json").read_text())


class CoreChecks(unittest.TestCase):
    def test_original_integrity_and_parent_split(self):
        counts = [sum(p["ai_split"] == s for p in PARENTS) for s in ["train", "validation", "test"]]
        self.assertEqual(counts, [6, 2, 2])
        for p in PARENTS:
            t, x, hz = verify_parent(ROOT / p["relative_path"], p)
            self.assertEqual(hz, 1000); self.assertEqual(x.shape, (p["samples"], 6))

    def test_named_column_order_and_units_contract(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / "example.csv"
            p.write_text("Gz,Ay,time,Ax,Gx,Az,Gy\n6,2,0,1,4,3,5\n6,2,0.01,1,4,3,5\n")
            t, x, hz = read_imu(p)
            np.testing.assert_equal(x[0], [1, 2, 3, 4, 5, 6]); self.assertEqual(hz, 100)

    def test_label_boundaries_and_no_record_level_positive_label(self):
        parent = dict(record_contains_fall=True, reference_contact_start_s=10, reference_contact_end_s=10.2)
        t = np.array([1, 9.49, 9.5, 9.99, 10, 12.2, 12.21])
        np.testing.assert_equal(labels(t, parent, SETTINGS), [0, 0, -1, -1, 1, 1, -1])

    def test_uncertain_early_alarm_is_distinct_from_positive_windows(self):
        parent = dict(record_contains_fall=True, reference_contact_start_s=10, reference_contact_end_s=10.2)
        t = np.round(np.arange(8, 14, 0.1), 6); p = np.where(t >= 9.8, 0.9, 0.0)
        m = event_metrics(t, p, parent, 0.5, SETTINGS)
        self.assertEqual(m["detected_fall_events"], 1)
        self.assertTrue(m["early_guard_match"]); self.assertAlmostEqual(m["contact_delay_s"], -0.2)
        self.assertEqual(int(alarms(t, p>=0.5, 5).sum()), 1)

    def test_gyro_prior_rebase_matches_fresh_lever_arm_equation(self):
        rng = np.random.default_rng(4)
        w = rng.normal(size=(40, 3)); alpha = rng.normal(size=(40, 3))
        r = np.array([0.2, -0.1, 0.3]); rotation = np.array([[0., -1, 0], [1, 0, 0], [0, 0, 1]])
        old = np.array([0, 0, 0, 0.8, -0.2, 0.4]); new = np.array([0.1, 0.3, -0.1])
        delta = np.array([1, -2, 3, 0.1, -0.1, 0.2]); base_acc = rng.normal(size=(40, 3))
        old_shift = (np.cross(alpha, r)+np.cross(w, np.cross(w, r))) @ rotation
        gyro = np.rad2deg(w @ rotation)+old[3:]+delta[3:]
        exported = np.column_stack([base_acc+old_shift+delta[:3], gyro])
        result, _ = rebase_position_effect(exported, {"position_delta_body_m": r,
            "bias_delta": delta, "bias_total": old+delta},
            {"K": {"bias": old, "sensor_to_body": rotation}}, new)
        wn = w + np.deg2rad(old[3:]-new) @ rotation.T
        expected = base_acc+(np.cross(alpha, r)+np.cross(wn, np.cross(wn, r))) @ rotation+delta[:3]
        np.testing.assert_allclose(result[:, :3], expected, atol=2e-13)
        np.testing.assert_array_equal(result[:, 3:], gyro)

    def test_weight_mass_is_balanced_despite_many_descendants(self):
        def record(parent, kind, y):
            return {"parent": {"key": parent}, "kind": kind, "y": np.array(y), "X": np.ones((len(y), 24))}
        records = [record("a", "original", [0, 0, 1]), record("b", "original", [0]*10)]
        records += [record("a", "augmented", [0, 1, 1, 1]) for _ in range(20)]
        _, y, weights = training_arrays(records)
        self.assertAlmostEqual(weights[y==0].sum(), weights[y==1].sum())
        self.assertTrue(np.all(weights > 0))

    def test_batch_and_stream_are_equivalent_and_past_only(self):
        fs = 1000; t = np.arange(6500)/fs+0.001
        x = np.column_stack([0.2*np.sin(2*np.pi*t), 0*t, -9.81+0*t,
                             0*t, 20*np.sin(t), 0*t])
        bias = [0.1, -0.2, 0.05]
        ends, features = extract(t, x, fs, SETTINGS, bias)
        rf = RandomForestClassifier(n_estimators=100, max_depth=3, random_state=42, n_jobs=1)
        rf.fit(np.vstack([features, features+0.5]), [0]*len(features)+[1]*len(features))
        bundle = {"model": rf, "threshold": 0.5, "settings": SETTINGS,
                  "calibration": {"gyro_bias_deg_s": bias}}
        output = StreamingPredictor(bundle, fs).push_block(t, x)
        np.testing.assert_allclose([r["time_s"] for r in output], ends, atol=1e-12)
        np.testing.assert_allclose([r["probability_fall"] for r in output], rf.predict_proba(features)[:, 1], atol=1e-12)
        changed = x.copy(); changed[4000:] = 1e4
        ends2, f2 = extract(t, changed, fs, SETTINGS, bias)
        np.testing.assert_array_equal(features[ends < t[4000]], f2[ends2 < t[4000]])
        stream = StreamingPredictor(bundle, fs); stream.push(t[0], x[0])
        with self.assertRaises(ValueError): stream.push(t[1]+1, x[1])
        with self.assertRaises(ValueError): stream.push_block(t[:3], x[:2])

    def test_stationary_and_frequency_feature_definitions(self):
        fs = 100; t = np.arange(200)/fs
        w = np.zeros((1, 200, 6)); w[0, :, 2] = -9.81
        f = window_features(w, fs)[0]
        self.assertEqual(len(f), len(FEATURE_NAMES)); self.assertAlmostEqual(f[3], 9.81, places=5)
        self.assertEqual(f[12], 1); self.assertEqual(f[13], 1); self.assertEqual(f[14], 0)
        np.testing.assert_allclose(f[-3:], 0, atol=1e-20)
        w[0, :, 2] = -(9.81+np.sin(2*np.pi*10*t))
        f = window_features(w, fs)[0]
        self.assertAlmostEqual(f[-2], 0.5, places=5)


if __name__ == "__main__": unittest.main()
