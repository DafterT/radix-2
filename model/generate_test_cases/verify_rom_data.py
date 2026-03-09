import cmath

def print_twiddles(n: int) -> None:
    if n < 2:
        raise ValueError("N должно быть >= 2")
    if n & (n - 1):
        raise ValueError("N должно быть степенью двойки")

    for k in range(n // 2):
        w = cmath.exp(-2j * cmath.pi * k / n)
        print(f"k={k:2d}: Re={w.real:.16f}, Im={w.imag:.16f}")

if __name__ == "__main__":
    n = int(input("Введите N: "))
    print_twiddles(n)