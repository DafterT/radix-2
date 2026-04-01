from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


MODEL_ROW_RE = re.compile(
    r"^\s*(?P<input_idx>\d+)\s*\|"
    r"\s*(?P<valid>[01])\s*\|"
    r"\s*(?P<last_in>[01])\s*\|"
    r"\s*(?P<a_re>-?\d+)\s*\|"
    r"\s*(?P<a_im>-?\d+)\s*\|"
    r"\s*(?P<b_re>-?\d+)\s*\|"
    r"\s*(?P<b_im>-?\d+)\s*\|"
    r"\s*(?P<status>RUN|SKIP)\s*\|"
    r"\s*(?P<last_out>-|[01])\s*\|"
    r"\s*(?P<ao_re>-|-?\d+)\s*\|"
    r"\s*(?P<ao_im>-|-?\d+)\s*\|"
    r"\s*(?P<bo_re>-|-?\d+)\s*\|"
    r"\s*(?P<bo_im>-|-?\d+)\s*$",
    re.MULTILINE,
)

TB_OUT_RE = re.compile(
    r"OUT\s+idx=(?P<out_idx>\d+)\s+valid=(?P<valid>[01])\s+last=(?P<last_out>[01])\n"
    r"\s+a_o = 0x[0-9A-Fa-f]{8}\s+=>\s+(?P<ao_re>-?\d+)\s+\+\s+j(?P<ao_im>-?\d+)\s+\(Q16\.0\)\n"
    r"\s+b_o = 0x[0-9A-Fa-f]{8}\s+=>\s+(?P<bo_re>-?\d+)\s+\+\s+j(?P<bo_im>-?\d+)\s+\(Q16\.0\)",
    re.MULTILINE,
)


@dataclass
class StageRow:
    input_idx: int
    valid: int
    last_in: int
    a_re: int
    a_im: int
    b_re: int
    b_im: int
    status: str
    last_out: int | None
    ao_re: int | None
    ao_im: int | None
    bo_re: int | None
    bo_im: int | None


@dataclass
class StageResult:
    order_idx: int
    last_out: int
    ao_re: int
    ao_im: int
    bo_re: int
    bo_im: int
    input_idx: int | None = None


def parse_optional_int(value: str) -> int | None:
    if value == "-":
        return None

    return int(value)


def parse_model_rows(model_log: str) -> list[StageRow]:
    rows: list[StageRow] = []

    for match in MODEL_ROW_RE.finditer(model_log):
        rows.append(
            StageRow(
                input_idx=int(match.group("input_idx")),
                valid=int(match.group("valid")),
                last_in=int(match.group("last_in")),
                a_re=int(match.group("a_re")),
                a_im=int(match.group("a_im")),
                b_re=int(match.group("b_re")),
                b_im=int(match.group("b_im")),
                status=match.group("status"),
                last_out=parse_optional_int(match.group("last_out")),
                ao_re=parse_optional_int(match.group("ao_re")),
                ao_im=parse_optional_int(match.group("ao_im")),
                bo_re=parse_optional_int(match.group("bo_re")),
                bo_im=parse_optional_int(match.group("bo_im")),
            )
        )

    return rows


def collect_model_results(model_rows: list[StageRow]) -> list[StageResult]:
    results: list[StageResult] = []

    for row in model_rows:
        if row.status != "RUN":
            continue

        results.append(
            StageResult(
                order_idx=len(results) + 1,
                input_idx=row.input_idx,
                last_out=row.last_out if row.last_out is not None else 0,
                ao_re=row.ao_re if row.ao_re is not None else 0,
                ao_im=row.ao_im if row.ao_im is not None else 0,
                bo_re=row.bo_re if row.bo_re is not None else 0,
                bo_im=row.bo_im if row.bo_im is not None else 0,
            )
        )

    return results


def parse_tb_results(tb_log: str) -> list[StageResult]:
    results: list[StageResult] = []

    for match in TB_OUT_RE.finditer(tb_log):
        results.append(
            StageResult(
                order_idx=int(match.group("out_idx")),
                input_idx=None,
                last_out=int(match.group("last_out")),
                ao_re=int(match.group("ao_re")),
                ao_im=int(match.group("ao_im")),
                bo_re=int(match.group("bo_re")),
                bo_im=int(match.group("bo_im")),
            )
        )

    return results


def format_result(result: StageResult) -> str:
    if result.input_idx is None:
        return (
            f"order={result.order_idx} "
            f"last={result.last_out} "
            f"a_o=({result.ao_re}, {result.ao_im}) "
            f"b_o=({result.bo_re}, {result.bo_im})"
        )

    return (
        f"order={result.order_idx} "
        f"input_idx={result.input_idx} "
        f"last={result.last_out} "
        f"a_o=({result.ao_re}, {result.ao_im}) "
        f"b_o=({result.bo_re}, {result.bo_im})"
    )


def print_model_table(model_rows: list[StageRow]) -> None:
    print()
    print(
        " idx | last |   a.re |   a.im |   b.re |   b.im | out.last | a_o.re | a_o.im | b_o.re | b_o.im"
    )
    print(
        "-----+------+--------+--------+--------+--------+----------+--------+--------+--------+--------"
    )

    for row in model_rows:
        if row.status != "RUN":
            continue

        print(
            f"{row.input_idx:4d} |"
            f" {row.last_in:4d} |"
            f" {row.a_re:6d} |"
            f" {row.a_im:6d} |"
            f" {row.b_re:6d} |"
            f" {row.b_im:6d} |"
            f" {row.last_out:8d} |"
            f" {row.ao_re:6d} |"
            f" {row.ao_im:6d} |"
            f" {row.bo_re:6d} |"
            f" {row.bo_im:6d}"
        )


def compare_results(model_rows: list[StageRow], model_results: list[StageResult], tb_results: list[StageResult]) -> int:
    if len(model_results) != len(tb_results):
        print(
            f"Count mismatch: model has {len(model_results)} valid outputs, "
            f"tb has {len(tb_results)} valid outputs."
        )
        return 1

    mismatches = 0

    for position, (model_result, tb_result) in enumerate(zip(model_results, tb_results), start=1):
        if (
            model_result.last_out != tb_result.last_out
            or model_result.ao_re != tb_result.ao_re
            or model_result.ao_im != tb_result.ao_im
            or model_result.bo_re != tb_result.bo_re
            or model_result.bo_im != tb_result.bo_im
        ):
            mismatches += 1
            print(f"Mismatch at valid output #{position}:")
            print(f"  model: {format_result(model_result)}")
            print(f"  tb:    {format_result(tb_result)}")

    if mismatches == 0:
        print(f"No differences found. Compared {len(model_results)} valid outputs.")
        print_model_table(model_rows)
        return 0

    print(f"Found {mismatches} mismatched outputs out of {len(model_results)}.")
    return 1


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: compare_fixed_stage_outputs.py <model_log> <tb_log>")
        return 2

    model_log_path = Path(sys.argv[1])
    tb_log_path = Path(sys.argv[2])

    model_rows = parse_model_rows(model_log_path.read_text(encoding="utf-8", errors="replace"))
    model_results = collect_model_results(model_rows)
    tb_results = parse_tb_results(tb_log_path.read_text(encoding="utf-8", errors="replace"))

    if not model_rows:
        print(f"No model outputs parsed from {model_log_path}")
        return 1

    if not tb_results:
        print(f"No tb outputs parsed from {tb_log_path}")
        return 1

    return compare_results(model_rows, model_results, tb_results)


if __name__ == "__main__":
    raise SystemExit(main())
