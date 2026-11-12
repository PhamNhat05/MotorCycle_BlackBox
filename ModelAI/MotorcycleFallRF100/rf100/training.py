"""Fixed RF100 fitting, parent-aware weights and real-validation selection."""
import numpy as np
from sklearn.ensemble import RandomForestClassifier
from .metrics import summarize


def training_arrays(records):
    """Equal class mass, then parent mass, then original/augmented mass.

    Within a parent/category/class, each recording has equal mass and its
    windows share that mass. A long recording or 100 descendants cannot
    silently dominate a short measured parent.
    """
    x = np.concatenate([r["X"][r["y"]>=0] for r in records])
    y = np.concatenate([r["y"][r["y"]>=0] for r in records])
    weights = [np.zeros((r["y"]>=0).sum(), float) for r in records]
    for cls in [0, 1]:
        parents = sorted({r["parent"]["key"] for r in records if np.any(r["y"] == cls)})
        if not parents: raise ValueError("TRAIN must contain both classes")
        for parent in parents:
            indices = [i for i, r in enumerate(records) if r["parent"]["key"] == parent and np.any(r["y"] == cls)]
            kinds = sorted({records[i]["kind"] for i in indices})
            for kind in kinds:
                selected = [i for i in indices if records[i]["kind"] == kind]
                mass = 0.5/len(parents)/len(kinds)/len(selected)
                for i in selected:
                    yr = records[i]["y"]; ys = yr[yr>=0]; use = ys == cls
                    weights[i][use] = mass/use.sum()
    w = np.concatenate(weights); w *= len(w)/w.sum()
    return x, y, w


def fit(records, settings):
    x, y, weights = training_arrays(records)
    rf = RandomForestClassifier(**settings["rf"], random_state=settings["seed"])
    rf.fit(x, y, sample_weight=weights)
    return rf, {"fit_windows": len(y), "class_counts": np.bincount(y, minlength=2).tolist(),
                "class_weight_mass": [float(weights[y==c].sum()/weights.sum()) for c in [0, 1]],
                "actual_trees": len(rf.estimators_), "total_nodes": sum(t.tree_.node_count for t in rf.estimators_),
                "maximum_actual_depth": max(t.tree_.max_depth for t in rf.estimators_)}


def score_records(model, records):
    for r in records:
        r["probability"] = model.predict_proba(r["X"])[:, list(model.classes_).index(1)]
    return records


def selection_key(metrics):
    delay = metrics.get("median_contact_delay_s")
    return (metrics.get("event_recall") or 0, metrics["f2_fall"],
            -metrics["false_alarm_events"], -max(delay if delay is not None else 1e9, 0))


def select_threshold(model, validation, settings):
    score_records(model, validation)
    rows = [{"threshold": threshold, **summarize(validation, threshold, settings)}
            for threshold in settings["threshold_grid"]]
    # A fixed final tie-break chooses the higher threshold on identical metrics.
    best = max(rows, key=lambda r: (*selection_key(r), r["threshold"]))
    return best, rows
