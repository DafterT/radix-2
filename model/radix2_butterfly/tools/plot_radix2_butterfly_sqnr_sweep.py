from __future__ import annotations

import argparse
import csv
import os
import re
import shlex
import subprocess
from pathlib import Path

try:
    import matplotlib.pyplot as plt
    from matplotlib.ticker import MultipleLocator
except ImportError as exc:  # pragma: no cover
    raise SystemExit("matplotlib is required to build the plot") from exc

try:
    from tqdm import tqdm
except ImportError as exc:  # pragma: no cover
    raise SystemExit("tqdm is required to display the sweep progress") from exc


SQNR_PATTERN = re.compile(
    r"Average SQNR\s+=\s+([+-]?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?) dB"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Sweep WHITE_NOISE_BACKOFF_DB and plot radix2_butterfly SQNR."
    )
    parser.add_argument("--start", type=int, default=1, help="Sweep start backoff in dB.")
    parser.add_argument("--stop", type=int, default=70, help="Sweep stop backoff in dB.")
    parser.add_argument("--step", type=int, default=1, help="Sweep step in dB.")
    parser.add_argument(
        "--runs",
        type=int,
        default=1000,
        help="STAGE_COMPARE_RUNS value passed into radix2_butterfly_compare.c.",
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
        f"-DSTAGE_COMPARE_RUNS={runs} "
        f"-DWHITE_NOISE_BACKOFF_DB={backoff_db}.0 "
        "-DSTAGE_COMPARE_PRINT_RUNS=0"
    )

    if os.name == "nt":
        shell_root = windows_path_to_wsl(root)
        bash_command = (
            f"cd {shlex.quote(shell_root)} && "
            f"make -s -C model CFLAGS={shlex.quote(cflags)} run-radix2_butterfly_compare"
        )
        return ["wsl.exe", "bash", "-lc", bash_command]

    bash_command = (
        f"cd {shlex.quote(str(root))} && "
        f"make -s -C model CFLAGS={shlex.quote(cflags)} run-radix2_butterfly_compare"
    )
    return ["bash", "-lc", bash_command]


def parse_compare_output(output: str) -> float:
    match = SQNR_PATTERN.search(output)
    if match is None:
        raise ValueError(f"Failed to parse Average SQNR.\n{output}")
    return float(match.group(1))


def run_single_compare(root: Path, runs: int, backoff_db: int) -> float:
    completed = subprocess.run(
        build_compare_command(root, runs, backoff_db),
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
            f"radix2_butterfly_compare failed for WHITE_NOISE_BACKOFF_DB={backoff_db}.\n{output}"
        )

    return parse_compare_output(output)


def collect_results(root: Path, runs: int, backoffs: list[int]) -> list[dict[str, float]]:
    rows: list[dict[str, float]] = []

    for backoff_db in tqdm(backoffs, desc="Backoff sweep", unit="dB"):
        rows.append(
            {
                "backoff_db": float(backoff_db),
                "avg_sqnr": run_single_compare(root, runs, backoff_db),
            }
        )

    return rows


def write_csv(rows: list[dict[str, float]], output_path: Path) -> None:
    with output_path.open("w", newline="", encoding="utf-8") as csv_file:
        writer = csv.DictWriter(csv_file, fieldnames=["backoff_db", "avg_sqnr"])
        writer.writeheader()
        writer.writerows(rows)


def plot_rows(rows: list[dict[str, float]], output_path: Path, title: str) -> None:
    fig, axis = plt.subplots(1, 1, figsize=(12, 6))
    backoffs = [row["backoff_db"] for row in rows]
    sqnr_values = [row["avg_sqnr"] for row in rows]

    axis.plot(backoffs, sqnr_values, marker="o", markersize=3, linewidth=1.5)
    axis.set_xlabel("WHITE_NOISE_BACKOFF_DB, dB")
    axis.set_ylabel("Average SQNR, dB")
    axis.xaxis.set_major_locator(MultipleLocator(5))
    axis.grid(True, alpha=0.3)
    fig.suptitle(title)
    fig.tight_layout()
    fig.savefig(output_path, dpi=180)
    plt.close(fig)


def main() -> int:
    args = parse_args()
    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    if args.step <= 0:
        raise SystemExit("--step must be positive")
    if args.stop < args.start:
        raise SystemExit("--stop must be greater than or equal to --start")
    if args.runs <= 0:
        raise SystemExit("--runs must be positive")

    rows = collect_results(repo_root(), args.runs, list(range(args.start, args.stop + 1, args.step)))
    write_csv(rows, output_dir / "radix2_butterfly_sqnr_sweep.csv")
    plot_rows(
        rows,
        output_dir / "radix2_butterfly_sqnr_sweep.png",
        f"radix2_butterfly SQNR Sweep: {args.start}..{args.stop} dB",
    )

    print(f"Saved outputs to {output_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
