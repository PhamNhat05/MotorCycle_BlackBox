"""Train RF100 from the bundled originals and optional MATLAB augmentation."""
from pathlib import Path
from datetime import datetime
import argparse
from rf100.pipeline import run


def main():
    root = Path(__file__).resolve().parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--augmentation-dir", help="MotorcycleIMULab root or AUGMENTED/results/RUN_...")
    parser.add_argument("--original-run", help="Original result directory if it was moved away from the MATLAB project")
    parser.add_argument("--allow-partial", action="store_true", help="Explicitly allow incomplete augmentation; actual counts remain visible")
    parser.add_argument("--out", type=Path, help="Result directory")
    parser.add_argument("--resume", action="store_true", help="Reuse validated features in --out; unfinished model fitting restarts")
    args = parser.parse_args()
    if args.resume and not args.out: parser.error("--resume requires --out")
    output = args.out or root / "results" / datetime.now().strftime("RUN_%Y%m%d_%H%M%S_%f")
    run(root, output, args.augmentation_dir, args.original_run, args.allow_partial, args.resume)


if __name__ == "__main__": main()
