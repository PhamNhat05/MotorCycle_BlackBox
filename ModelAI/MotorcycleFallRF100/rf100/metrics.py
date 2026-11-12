"""Separate window classification, contact-associated events and raw alerts."""
import numpy as np
from sklearn.metrics import confusion_matrix, average_precision_score


def labels(t, parent, settings):
    y = np.zeros(len(t), dtype=np.int8)
    if parent["record_contains_fall"]:
        contact, hip = parent["reference_contact_start_s"], parent["reference_contact_end_s"]
        y[t >= contact-settings["pre_contact_guard_s"]] = -1
        y[(t >= contact) & (t <= hip+settings["positive_after_hip_s"])] = 1
    return y


def alarms(t, decision, cooldown):
    """Rising-edge alarm, with a refractory time, using no ground-truth labels."""
    result = np.zeros(len(t), bool); previous = False; last = -np.inf
    for i, (now, high) in enumerate(zip(t, decision)):
        if high and not previous and now-last >= cooldown:
            result[i] = True; last = now
        previous = high
    return result


def window_metrics(y, probability, threshold):
    use = y >= 0; yt = y[use]; yp = probability[use] >= threshold
    tn, fp, fn, tp = confusion_matrix(yt, yp, labels=[0, 1]).ravel()
    precision = tp/(tp+fp) if tp+fp else 0.0
    recall = tp/(tp+fn) if tp+fn else None
    return {"scored_windows": int(len(yt)), "ignored_windows": int((~use).sum()),
            "TN": int(tn), "FP": int(fp), "FN": int(fn), "TP": int(tp),
            "accuracy": (tn+tp)/len(yt) if len(yt) else None,
            "precision_fall": precision, "recall_fall": recall,
            "balanced_accuracy": ((tn/(tn+fp)+recall)/2 if tn+fp and recall is not None else None),
            "f1_fall": 2*tp/(2*tp+fp+fn) if 2*tp+fp+fn else 0.0,
            "f2_fall": 5*tp/(5*tp+4*fn+fp) if 5*tp+4*fn+fp else 0.0,
            "average_precision": float(average_precision_score(yt, probability[use]))
                 if len(np.unique(yt)) == 2 else None}


def event_metrics(t, probability, parent, threshold, settings):
    y = labels(t, parent, settings)
    alert = alarms(t, probability >= threshold, settings["alarm_cooldown_s"])
    times = t[alert]; falls = int(parent["record_contains_fall"])
    if falls:
        contact = parent["reference_contact_start_s"]
        lo = contact-settings["pre_contact_guard_s"]
        hi = parent["reference_contact_end_s"]+settings["positive_after_hip_s"]
        matched = times[(times >= lo) & (times <= hi)]
        false = int((times < lo).sum()); ignored = int((times > hi).sum())
        delay = float(matched[0]-contact) if len(matched) else None
    else:
        matched = []; false = len(times); ignored = 0; delay = None
    return {"fall_events": falls, "detected_fall_events": int(bool(len(matched))),
            "false_alarm_events": false, "unscored_post_event_alarms": ignored,
            "contact_delay_s": delay, "early_guard_match": bool(delay is not None and delay < 0),
            "positive_window_detected": bool(np.any((y == 1) & (probability >= threshold)))}


def summarize(records, threshold, settings):
    y = np.concatenate([r["y"] for r in records])
    p = np.concatenate([r["probability"] for r in records])
    out = window_metrics(y, p, threshold)
    events = [event_metrics(r["t"], r["probability"], r["parent"], threshold, settings) for r in records]
    for key in ["fall_events", "detected_fall_events", "false_alarm_events", "unscored_post_event_alarms"]:
        out[key] = sum(e[key] for e in events)
    out["event_recall"] = (out["detected_fall_events"]/out["fall_events"]
                           if out["fall_events"] else None)
    delays = [e["contact_delay_s"] for e in events if e["contact_delay_s"] is not None]
    out["median_contact_delay_s"] = float(np.median(delays)) if delays else None
    out["independent_parent_count"] = len(set(r["parent"]["key"] for r in records))
    out["recordings"] = len(records)
    return out
