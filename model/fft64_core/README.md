# fft64_core

Запуск reference-модели:

```bash
make -C model run-fft64_core_reference
```

Запуск fixed/reference сравнения:

```bash
make -C model run-fft64_core_fixed_compare
```

Опциональное сравнение reference-модели с FFTW3:

```bash
make -C model run-fft64_core_reference_compare_fftw
```

Для FFTW3 нужен пакет `libfftw3-dev` в WSL.

Основные файлы:

- `fft64_core_model_types.h`: общие публичные типы fixed/reference моделей.
- `reference/fft64_core_reference_model.[ch]`: double reference FFT64.
- `fixed_sqrt2/fft64_core_fixed_sqrt2_model.[ch]`: fixed FFT64 с масштабированием `1/sqrt(2)` на каждом stage.
- `fixed_div2/fft64_core_fixed_div2_model.[ch]`: fixed FFT64 с периодическим делением на 2.
- `fixed_collect/fft64_core_fixed_collect_model.[ch]`: fixed FFT64 с накоплением и финальным масштабированием.
- `tools/fft64_core_fixed_compare.c`: сравнение fixed-вариантов с reference-моделью.
- `tools/fft64_core_white_noise.[ch]`: генератор входных кадров для DPI-тестов.
