"""Ideal reference model for the radix2_top datapath.

This script mirrors the functional flow of rtl/radix2_top.sv, but intentionally
removes all implementation artifacts:
- no pipeline latency
- no fixed-point quantization of twiddles
- no convergent rounding
- no output clipping

Input stimuli are defined at the top of the file. For each valid input sample,
the model applies the current twiddle factor selected by the same address
sequence as rtl/radix2_cu.sv and prints the ideal complex result immediately.
"""

from __future__ import annotations

from dataclasses import dataclass
from math import cos, pi, sin
from typing import Iterable, List, Optional, Sequence, Tuple


FFT_N = 64
COMPLEX_PRECISION = 9
TRACE_HEADERS: Tuple[str, ...] = (
    "cyc",
    "name",
    "v",
    "l",
    "addr",
    "input_iq",
    "twiddle",
    "output",
)
TRACE_ALIGN_RIGHT: Tuple[bool, ...] = (True, False, True, True, True, False, False, False)
EMPTY_ADDR = "--"
EMPTY_VALUE = "-"


@dataclass(frozen=True)
class Stimulus:
    name: str
    iq: complex
    valid: bool = True
    last: bool = False


@dataclass(frozen=True)
class TraceRow:
    cycle: int
    name: str
    valid: bool
    last: bool
    addr: Optional[int]
    input_iq: Optional[complex]
    twiddle: Optional[complex]
    output: Optional[complex]

    def as_cells(self) -> Tuple[str, ...]:
        return (
            str(self.cycle),
            self.name,
            str(int(self.valid)),
            str(int(self.last)),
            EMPTY_ADDR if self.addr is None else str(self.addr),
            format_optional_complex(self.input_iq),
            format_optional_complex(self.twiddle),
            format_optional_complex(self.output),
        )


# Top-of-file stimuli, as requested.
# These default samples mirror tb/radix2_top_tb.sv.
STIMULI: Tuple[Stimulus, ...] = (
    Stimulus("s0", complex(10.0, 10.0), valid=True, last=False),
    Stimulus("s1", complex(10.0, 10.0), valid=True, last=False),
    Stimulus("s2", complex(10.0, 10.0), valid=True, last=False),
    Stimulus("s3", complex(10.0, 10.0), valid=True, last=True),
    Stimulus("s4", complex(10.0, 10.0), valid=True, last=False),
    Stimulus("s5", complex(10.0, 10.0), valid=True, last=True),
)


def validate_fft_n(fft_n: int) -> None:
    if fft_n < 4:
        raise ValueError("FFT_N must be >= 4")
    if fft_n & (fft_n - 1):
        raise ValueError("FFT_N must be a power of two")


def build_twiddle_table(fft_n: int) -> List[complex]:
    validate_fft_n(fft_n)
    depth = fft_n // 2
    return [complex(cos(2.0 * pi * k / fft_n), -sin(2.0 * pi * k / fft_n)) for k in range(depth)]


def format_complex(value: complex, precision: int = COMPLEX_PRECISION) -> str:
    real_part = f"{value.real:+.{precision}f}"
    imag_part = f"{value.imag:+.{precision}f}"
    return f"{real_part} {imag_part}j"


def format_optional_complex(value: Optional[complex]) -> str:
    if value is None:
        return EMPTY_VALUE
    return format_complex(value)


def next_twiddle_addr(current_addr: int, last: bool, depth: int) -> int:
    if last or current_addr == depth - 1:
        return 0
    return current_addr + 1


def print_text_table(
    headers: Sequence[str],
    rows: Sequence[Sequence[str]],
    align_right: Sequence[bool],
) -> None:
    if len(headers) != len(align_right):
        raise ValueError("headers and align_right must have the same length")

    widths = [len(header) for header in headers]
    for row in rows:
        if len(row) != len(headers):
            raise ValueError("row width does not match header width")
        for idx, cell in enumerate(row):
            widths[idx] = max(widths[idx], len(cell))

    def format_row(row: Sequence[str]) -> str:
        cells = []
        for idx, cell in enumerate(row):
            if align_right[idx]:
                cells.append(f"{cell:>{widths[idx]}}")
            else:
                cells.append(f"{cell:<{widths[idx]}}")
        return " | ".join(cells)

    print(format_row(headers))
    print("-+-".join("-" * width for width in widths))
    for row in rows:
        print(format_row(row))


def build_trace_rows(stimuli: Iterable[Stimulus], twiddles: Sequence[complex]) -> List[TraceRow]:
    depth = len(twiddles)
    addr = 0
    rows: List[TraceRow] = []

    for cycle, stimulus in enumerate(stimuli):
        if not stimulus.valid:
            rows.append(
                TraceRow(
                    cycle=cycle,
                    name=stimulus.name,
                    valid=False,
                    last=stimulus.last,
                    addr=None,
                    input_iq=None,
                    twiddle=None,
                    output=None,
                )
            )
            continue

        twiddle = twiddles[addr]
        result = stimulus.iq * twiddle

        rows.append(
            TraceRow(
                cycle=cycle,
                name=stimulus.name,
                valid=True,
                last=stimulus.last,
                addr=addr,
                input_iq=stimulus.iq,
                twiddle=twiddle,
                output=result,
            )
        )

        addr = next_twiddle_addr(addr, stimulus.last, depth)

    return rows


def print_trace_table(rows: Sequence[TraceRow]) -> None:
    print_text_table(
        headers=TRACE_HEADERS,
        rows=[row.as_cells() for row in rows],
        align_right=TRACE_ALIGN_RIGHT,
    )


def run_ideal_model(stimuli: Iterable[Stimulus], fft_n: int) -> None:
    twiddles = build_twiddle_table(fft_n)
    rows = build_trace_rows(stimuli, twiddles)

    print_trace_table(rows)


def main() -> None:
    run_ideal_model(STIMULI, FFT_N)


if __name__ == "__main__":
    main()
