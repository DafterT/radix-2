TESTS = [
    ("t1", 3 + 2j, 1.5 - 0.25j),
    ("t2", -7 + 4j, -1.0 + 0.5j),
    ("t3", 32767 - 32768j, 0.5 + 0.5j),
]


def to_fixed(value, frac_bits):
    return int(round(value * (1 << frac_bits)))


rows = []
for name, a, b in TESTS:
    y = a * b

    # a: Q16.0 (integer)
    a_re = to_fixed(a.real, 0)
    a_im = to_fixed(a.imag, 0)

    # b: Q2.14
    b_re = to_fixed(b.real, 14)
    b_im = to_fixed(b.imag, 14)

    # y: Q18.14
    y_re = to_fixed(y.real, 14)
    y_im = to_fixed(y.imag, 14)

    rows.append(
        {
            "name": name,
            "a_vals": f"{{{a_re}, {a_im}}},",
            "b_vals": f"{{{b_re}, {b_im}}},",
            "y_vals": f"{{{y_re}, {y_im}}}",
            "a_comment": f"({a.real:g}, {a.imag:g}) in Q16.0",
            "b_comment": f"({b.real:g}, {b.imag:g}) in Q2.14",
            "y_comment": f"({y.real:g}, {y.imag:g}) in Q18.14",
        }
    )


col_width = max(
    max(len(r["a_vals"]), len(r["b_vals"]), len(r["y_vals"])) for r in rows
)

print("const test_vec_t tests[] = {")
for r in rows:
    print("    {")
    print(f'        "{r["name"]}",')
    print(f'        {r["a_vals"].ljust(col_width)} // {r["a_comment"]}')
    print(f'        {r["b_vals"].ljust(col_width)} // {r["b_comment"]}')
    print(f'        {r["y_vals"].ljust(col_width)} // {r["y_comment"]}')
    print("    },")
print("};")
