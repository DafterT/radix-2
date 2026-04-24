# Тесты

Запускать из WSL:

```bash
make -C testbenchs build-all
make -C testbenchs run-all
make -C testbenchs wave-all
```

Единый шаблон для любого теста:

```bash
make -C testbenchs build-<test>
make -C testbenchs run-<test>
make -C testbenchs wave-<test>
```

Доступные тесты:

- `dsp48e2_slice_model` — сравнивает RTL DSP48E2-like с C-моделью через DPI.
- `complex_mul_3dsp` — проверяет комплексный умножитель через DPI-модель.
- `fft64_core` — гоняет FFT64 core на случайных кадрах и сверяет с fixed C-моделью.
- `convergent_rounding` — проверяет округление на фиксированных значениях.
- `symmetric_saturate` — проверяет симметричное насыщение перебором входов.
- `twiddle_rom` — читает таблицу twiddle ROM.
- `radix2_butterfly` — прогоняет несколько векторов через butterfly.
