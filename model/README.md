# model

Каталог `model/` хранит C-модели и вспомогательные утилиты. Имена верхнеуровневых папок совпадают с RTL/testbench naming там, где модель соответствует конкретному RTL-модулю.

- `complex_mul_3dsp/`: модель `rtl/complex_mul_3dsp.sv`.
- `dsp48e2_slice_model/`: модель `rtl/dsp48e2_slice_model.sv`.
- `radix2_butterfly/`: fixed/reference модели `rtl/radix2_butterfly.sv` и compare-утилита.
- `fft64_core/`: reference/fixed модели `rtl/fft64_core.sv`, compare-утилиты и генераторы входов.
- `rules/`: общие make-правила для всех моделей.
- `tools/`: общие helper scripts, например вывод данных `twiddle_rom`.
- `build/`: локальные артефакты сборки `model/Makefile`.

## Запуск

Все цели запускаются из верхнего `model/Makefile`:

```bash
make -C model list-models
make -C model run-<model-name>
make -C model run-all
make -C model clean
```

Из Windows запускай через WSL:

```bash
wsl.exe bash -lc "cd /mnt/c/Users/Dafte/OneDrive/Documents/GitHub/radix-2 && make -C model run-fft64_core_fixed_compare"
```

Текущие основные цели:

- `make -C model run-complex_mul_3dsp`
- `make -C model run-dsp48e2_slice_model`
- `make -C model run-radix2_butterfly_compare`
- `make -C model run-fft64_core_reference`
- `make -C model run-fft64_core_fixed_compare`
- `make -C model run-twiddle_rom_data`

Опциональная цель, если установлен `libfftw3-dev`:

- `make -C model run-fft64_core_reference_compare_fftw`
