from __future__ import annotations

import argparse
import csv
import os
import re
import shlex
import subprocess
import sys
from pathlib import Path

try:
    import matplotlib.pyplot as plt
except ImportError as exc:  # pragma: no cover
    raise SystemExit("matplotlib is required to build the plots") from exc

try:
    from tqdm import tqdm
except ImportError as exc:  # pragma: no cover
    raise SystemExit("tqdm is required to display the sweep progress") from exc


METHODS = ("sqrt2", "div2", "collect")
METHOD_COLORS = {
    "sqrt2": "#1f77b4",
    "div2": "#ff7f0e",
    "collect": "#2ca02c",
}
METRICS = (
    ("avg_error", "Average Error"),
    ("max_error", "Maximum Error"),
    ("avg_sqnr", "Average SQNR, dB"),
)
SUMMARY_PATTERNS = {
    "avg_error": r"\[{method}\]\s+Average error = ([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
    "max_error": r"\[{method}\]\s+Maximum error = ([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)",
    "avg_sqnr": r"\[{method}\]\s+Average SQNR\s+= ([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?) dB",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sweep WHITE_NOISE_BACKOFF_DB and plot fixed fft64_core comparison metrics."
    )
    parser.add_argument("--start", type=int, default=1, help="Sweep start backoff in dB.")
    parser.add_argument("--stop", type=int, default=70, help="Sweep stop backoff in dB.")
    parser.add_argument("--step", type=int, default=1, help="Sweep step in dB.")
    parser.add_argument("--zoom-start", type=int, default=8, help="Zoom plot start backoff in dB.")
    parser.add_argument("--zoom-stop", type=int, default=16, help="Zoom plot stop backoff in dB.")
    parser.add_argument(
        "--runs",
        type=int,
        default=1000,
        help="FFT64_COMPARE_RUNS value passed into fft64_core_fixed_compare.c.",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).resolve().parent / "pic",
        help="Directory for PNG and CSV outputs.",
    )
    return parser.parse_args()


def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def windows_path_to_wsl(path: Path) -> str:
    drive = path.drive.rstrip(":").lower()
    tail = path.as_posix().split(":", 1)[1]
    return f"/mnt/{drive}{tail}"


def build_compare_command(root: Path, runs: int, backoff_db: int) -> list[str]:
    cflags = (
        "-std=c11 -Wall -Wextra -O3 "
        f"-DFFT64_COMPARE_RUNS={runs} "
        f"-DWHITE_NOISE_BACKOFF_DB={backoff_db}.0 "
        "-DFFT64_COMPARE_PRINT_RUNS=0"
    )

    if os.name == "nt":
        shell_root = windows_path_to_wsl(root)
        bash_command = (
            f"cd {shlex.quote(shell_root)} && "
            f"make -s -C model CFLAGS={shlex.quote(cflags)} run-fft64_core_fixed_compare"
        )
        return ["wsl.exe", "bash", "-lc", bash_command]

    bash_command = (
        f"cd {shlex.quote(str(root))} && "
        f"make -s -C model CFLAGS={shlex.quote(cflags)} run-fft64_core_fixed_compare"
    )
    return ["bash", "-lc", bash_command]


def parse_compare_output(output: str) -> dict[str, dict[str, float]]:
    parsed: dict[str, dict[str, float]] = {}

    for method in METHODS:
        parsed[method] = {}
        for metric_key, pattern in SUMMARY_PATTERNS.items():
            match = re.search(pattern.format(method=re.escape(method)), output)
            if match is None:
                raise ValueError(f"Failed to parse {metric_key} for {method}.\n{output}")
            parsed[method][metric_key] = float(match.group(1))

    return parsed


def run_single_compare(root: Path, runs: int, backoff_db: int) -> dict[str, dict[str, float]]:
    command = build_compare_command(root, runs, backoff_db)
    completed = subprocess.run(
        command,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    output = completed.stdout
    if completed.stderr:
        output = f"{output}\n{completed.stderr}"

    if completed.returncode != 0:
        raise RuntimeError(
            f"compare_fixed failed for WHITE_NOISE_BACKOFF_DB={backoff_db}.\n{output}"
        )

    return parse_compare_output(output)


def collect_results(root: Path, runs: int, backoffs: list[int]) -> list[dict[str, float]]:
    rows: list[dict[str, float]] = []

    for backoff_db in tqdm(backoffs, desc="Backoff sweep", unit="dB"):
        parsed = run_single_compare(root, runs, backoff_db)
        row: dict[str, float] = {"backoff_db": float(backoff_db)}
        for method in METHODS:
            for metric_key, _ in METRICS:
                row[f"{method}_{metric_key}"] = parsed[method][metric_key]
        rows.append(row)

    return rows


def write_csv(rows: list[dict[str, float]], output_path: Path) -> None:
    fieldnames = ["backoff_db"]
    for method in METHODS:
        for metric_key, _ in METRICS:
            fieldnames.append(f"{method}_{metric_key}")

    with output_path.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def plot_metric(
    rows: list[dict[str, float]],
    metric_key: str,
    metric_label: str,
    output_path: Path,
    title: str,
) -> None:
    fig, axis = plt.subplots(figsize=(12, 5))
    backoffs = [row["backoff_db"] for row in rows]

    for method in METHODS:
        values = [row[f"{method}_{metric_key}"] for row in rows]
        axis.plot(
            backoffs,
            values,
            marker="o",
            markersize=3,
            linewidth=1.5,
            label=method,
            color=METHOD_COLORS[method],
        )
    axis.set_xlabel("WHITE_NOISE_BACKOFF_DB, dB")
    axis.set_ylabel(metric_label)
    axis.grid(True, alpha=0.3)
    axis.legend(loc="best")
    fig.suptitle(title)
    fig.tight_layout()
    fig.savefig(output_path, dpi=180)
    plt.close(fig)


def plot_rows(rows: list[dict[str, float]], output_prefix: Path, title: str) -> None:
    for metric_key, metric_label in METRICS:
        plot_metric(
            rows,
            metric_key,
            metric_label,
            output_prefix.with_name(f"{output_prefix.name}_{metric_key}.png"),
            f"{title}: {metric_label}",
        )


def main() -> int:
    args = parse_args()
    root = repo_root()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.step <= 0:
        raise SystemExit("--step must be positive")
    if args.stop < args.start:
        raise SystemExit("--stop must be greater than or equal to --start")
    if args.zoom_stop < args.zoom_start:
        raise SystemExit("--zoom-stop must be greater than or equal to --zoom-start")
    if args.runs <= 0:
        raise SystemExit("--runs must be positive")

    backoffs = list(range(args.start, args.stop + 1, args.step))
    rows = collect_results(root, args.runs, backoffs)
    write_csv(rows, output_dir / "fft64_core_backoff_sweep.csv")
    plot_rows(
        rows,
        output_dir / "fft64_core_backoff_sweep_full",
        f"fft64_core Fixed Compare Sweep: {args.start}..{args.stop} dB",
    )

    zoom_rows = [
        row
        for row in rows
        if args.zoom_start <= row["backoff_db"] <= args.zoom_stop
    ]
    if zoom_rows:
        plot_rows(
            zoom_rows,
            output_dir / "fft64_core_backoff_sweep_zoom_8_20",
            f"fft64_core Fixed Compare Sweep: {args.zoom_start}..{args.zoom_stop} dB",
        )

    print(f"Saved outputs to {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
