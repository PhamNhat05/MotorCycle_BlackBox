"""Readable English HTML, vector figures and explicit file/window counts."""
from pathlib import Path
from html import escape
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from .features import FEATURE_NAMES
from .io import read_imu

plt.rcParams.update({"font.size": 12, "axes.labelsize": 12, "axes.titlesize": 14,
                     "figure.facecolor": "white", "axes.facecolor": "white",
                     "text.color": "#14263b", "axes.labelcolor": "#14263b",
                     "svg.fonttype": "none"})


def save_figure(fig, path):
    fig.savefig(path.with_suffix(".svg"), bbox_inches="tight")
    fig.savefig(path.with_suffix(".png"), dpi=180, bbox_inches="tight")
    plt.close(fig)


def confusion_figure(metrics, title, path):
    matrix = np.array([[metrics["TN"], metrics["FP"]], [metrics["FN"], metrics["TP"]]])
    fig, ax = plt.subplots(figsize=(6.2, 5))
    ax.imshow(matrix, cmap="Blues")
    for i in range(2):
        for j in range(2):
            ax.text(j, i, str(matrix[i, j]), ha="center", va="center", fontsize=22,
                    color="white" if matrix[i, j] > matrix.max()/2 else "#102030")
    ax.set(xticks=[0, 1], yticks=[0, 1], xticklabels=["Normal", "Fall"],
           yticklabels=["Normal", "Fall"], xlabel="Predicted label", ylabel="True label", title=title)
    save_figure(fig, path)


def timeline_figure(record, root, threshold, settings, path):
    parent = record["parent"]
    t, x, _ = read_imu(root / parent["relative_path"])
    idx = np.unique(np.linspace(0, len(t)-1, min(len(t), 6000)).astype(int))
    fig, axes = plt.subplots(3, 1, figsize=(13, 8), sharex=True)
    for c, label in enumerate(["X", "Y", "Z"]):
        axes[0].plot(t[idx], x[idx, c], label=label, linewidth=0.8)
        axes[1].plot(t[idx], x[idx, c+3], label=label, linewidth=0.8)
    axes[0].set_ylabel("Acceleration (m/s²)"); axes[1].set_ylabel("Gyro (deg/s)")
    for ax in axes[:2]: ax.legend(loc="upper right", ncol=3); ax.grid(alpha=0.2)
    td, p = record["t"], record["probability"]
    axes[2].plot(td, p, color="#075bb8", label="RF fall score", linewidth=1.6)
    axes[2].axhline(threshold, color="#b84600", linestyle="--", label=f"Threshold {threshold:.2f}")
    alerts = record["alarm"].astype(bool)
    axes[2].scatter(td[alerts], p[alerts], color="#ad001b", marker="x", s=65, label="Alarm")
    if parent["record_contains_fall"]:
        contact, hip = parent["reference_contact_start_s"], parent["reference_contact_end_s"]
        for ax in axes:
            ax.axvspan(contact-settings["pre_contact_guard_s"], contact, color="#f1bc42", alpha=0.3)
            ax.axvspan(contact, hip+settings["positive_after_hip_s"], color="#ec7e8a", alpha=0.23)
            ax.axvspan(hip+settings["positive_after_hip_s"], t[-1], color="#9aa6b2", alpha=0.16)
            ax.axvline(contact, color="#9c1527", linestyle=":")
    axes[2].set(xlabel="Source time (s)", ylabel="Fall score", ylim=(-0.04, 1.08))
    axes[2].legend(loc="upper right", ncol=3, fontsize=10); axes[2].grid(alpha=0.2)
    axes[0].set_title(f"{parent['key']} | {parent['ai_split'].upper()} | full measured recording")
    fig.tight_layout(); save_figure(fig, path)


def html_table(frame):
    return '<div class="scroll">'+frame.to_html(index=False, border=0, escape=True, float_format=lambda x: f"{x:.4f}")+"</div>"


def create_report(output, root, bundle, originals, summary, split_summary, candidates, per_file, audit):
    charts = output / "charts"; charts.mkdir(exist_ok=True)
    for row in summary:
        confusion_figure(row, row["evaluation"].replace("_", " "), charts / f"confusion_{row['evaluation']}")
    links = []
    for r in originals:
        key = r["parent"]["key"]
        timeline_figure(r, root, bundle["threshold"], bundle["settings"], charts / key)
        links.append(f'<details><summary>{escape(key)} — {r["parent"]["ai_split"].upper()}</summary>'
                     f'<a href="predictions/original/{key}.csv">Prediction CSV</a> · '
                     f'<a href="charts/{key}.svg">Open full-size vector chart</a>'
                     f'<img src="charts/{key}.svg" alt="{escape(key)} timeline"></details>')
    importance = pd.DataFrame({"feature": FEATURE_NAMES, "importance": bundle["model"].feature_importances_}).sort_values("importance", ascending=False)
    importance.to_csv(output / "FEATURE_IMPORTANCE.csv", index=False)
    fig, ax = plt.subplots(figsize=(10, 8))
    show = importance.iloc[::-1]
    ax.barh(show.feature, show.importance, color="#075bb8")
    ax.set(xlabel="Impurity-based feature importance", title="RF100 feature ranking (not causal attribution)")
    fig.tight_layout(); save_figure(fig, charts / "feature_importance")
    frame = pd.DataFrame(summary)
    cols = ["evaluation", "recordings", "independent_parent_count", "scored_windows", "accuracy",
            "precision_fall", "recall_fall", "f1_fall", "balanced_accuracy", "fall_events",
            "detected_fall_events", "false_alarm_events", "median_contact_delay_s"]
    pd.DataFrame(summary).to_csv(output / "EVALUATION_SUMMARY.csv", index=False)
    pd.DataFrame(per_file).to_csv(output / "PER_RECORD_METRICS.csv", index=False)
    pd.DataFrame(audit).to_csv(output / "DATASET_AUDIT.csv", index=False)
    class_rows = []
    for row in summary:
        tn, fp, fn, tp = [row[k] for k in ["TN", "FP", "FN", "TP"]]
        for label, correct, false_positive, missed in [("normal", tn, fn, fp), ("fall", tp, fp, fn)]:
            class_rows.append({"evaluation": row["evaluation"], "class": label,
                "precision": correct/(correct+false_positive) if correct+false_positive else 0,
                "recall": correct/(correct+missed) if correct+missed else None,
                "f1": 2*correct/(2*correct+false_positive+missed) if 2*correct+false_positive+missed else 0,
                "support": correct+missed})
    pd.DataFrame(class_rows).to_csv(output / "CLASS_METRICS.csv", index=False)
    matrix_sections = []
    for row in summary:
        name = row["evaluation"]
        matrix_sections.append(f'<section><h3>{name.replace("_", " ")}</h3>'
                               f'<img class="matrix" src="charts/confusion_{name}.svg" alt="Confusion matrix"></section>')
    page = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Motorcycle RF100 report</title><style>
body{margin:0;background:#eef3f8;color:#14263b;font:18px/1.6 Arial,sans-serif}main{max-width:1450px;margin:auto;padding:28px}
h1{font-size:34px}h2{font-size:25px}section,details{background:white;border:1px solid #bccbda;border-radius:12px;padding:22px;margin:20px 0}
table{border-collapse:collapse;width:100%;font-size:16px}th,td{padding:11px;border:1px solid #b9c9d8;text-align:left;white-space:nowrap}
th{background:#173a61;color:white}tr:nth-child(even){background:#eff5fb}.scroll{overflow:auto}a{color:#064da0;font-weight:bold}
img{display:block;width:100%;height:auto;margin-top:16px}.matrix{max-width:630px}.notice{border-left:6px solid #b84600;padding:12px 18px;background:#fff4df}
summary{cursor:pointer;font-weight:bold}code{background:#e8eff6;padding:2px 5px} .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(320px,1fr));gap:15px}
</style><main><h1>Motorcycle fall classification — RF100</h1>'''
    page += f'<section><p><strong>Selected model:</strong> {escape(bundle["candidate_id"])} · '
    page += f'<strong>Trees:</strong> {len(bundle["model"].estimators_)} · <strong>Features:</strong> 24 · '
    page += f'<strong>Threshold:</strong> {bundle["threshold"]:.2f}</p>'
    page += '<p>Measured IMU → causal low-pass filter → 100 Hz → past-only 2 s window, 0.5 s stride → 24 features → 100-tree Random Forest → fall score → threshold → alarm.</p></section>'
    page += '<section><h2>File split and actual augmentation availability</h2>'+html_table(split_summary)
    page += '<p>AI split: six TRAIN, two VALIDATION, two TEST original parents. The generator\'s seven BUILD / three TEST split is separate. Every descendant follows its AI parent. Only TRAIN descendants enter fitting. Real VALIDATION selects thresholds/model; augmented VALIDATION/TEST are evaluated afterward as separate stress checks.</p></section>'
    page += '<section><h2>Real-validation candidate comparison</h2>'+html_table(candidates)+ '</section>'
    page += '<section><h2>Selected-model results</h2>'+html_table(frame[cols])+'</section>'
    page += '<div class="notice"><strong>Interpretation:</strong> TRAIN results and the all-data diagnostic include fitted windows. They are not unseen-test accuracy. Descendants are sensor variants of the same events, not independent new crashes. Real TEST contains one recorded fall; all ten recordings have been inspected in earlier project work. Publisher-corrected Ay byte identity is unresolved.</div>'
    if not (split_summary.augmented_available.sum()):
        page += '<p class="notice"><strong>Measured-only run:</strong> no generated CSV dataset was supplied. Expected augmentation counts are plans, not files used in this run. Run MATLAB RUN_AUGMENT, then rerun training with its result directory.</p>'
    page += '<section><h2>Label and alarm definitions</h2><p>Fall is scored from protector contact T1 through hip contact T2 + 2 s. The final 0.5 s before T1 and later post-event handling are unscored. Other earlier windows are normal. Nonfall files are normal throughout. The file-level fall label is never assigned to the whole recording.</p>'
    page += '<p>An alarm matches a contact-associated event in [T1 − 0.5 s, T2 + 2 s]. A negative delay means a match inside the uncertain pre-contact guard; it is not a validated instability-onset measurement. Rising-edge alarms use a causal 5 s cooldown. Raw window decisions and emitted alarms are both exported. No timestamps are hidden from prediction.</p></section>'
    page += '<h2>Confusion matrices</h2><div class="grid">'+''.join(matrix_sections)+'</div>'
    page += '<section><h2>Feature importance</h2><img src="charts/feature_importance.svg" alt="Feature ranking"></section>'
    page += '<h2>Full original-file inference</h2><p>Yellow: uncertain pre-contact guard. Red: scored fall interval. Gray: unscored post-event handling. Display traces are reduced for plotting only; preprocessing and feature extraction use every source sample.</p>'+''.join(links)
    page += '<section><h2>Output files</h2><p><a href="DATA_SPLIT.csv">Parent split</a> · <a href="SPLIT_SUMMARY.csv">File counts</a> · <a href="DATASET_AUDIT.csv">Dataset audit</a> · <a href="EVALUATION_SUMMARY.csv">Evaluation summary</a> · <a href="CLASS_METRICS.csv">Per-class scores</a> · <a href="PER_RECORD_METRICS.csv">Per-record results</a> · <a href="BEST_MODEL_INFO.json">Selected model information</a> · <a href="MODEL_SELECTION_FROZEN.json">Frozen validation choice</a></p></section></main></html>'
    (output / "REPORT.html").write_text(page, encoding="utf-8")
