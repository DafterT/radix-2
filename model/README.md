# model

Каталог `model/` хранит программные модели и утилиты сравнения, организованные по назначению.

- `build/`: исполняемые файлы и временные артефакты сборки из `model/Makefile`.
- `complex_mul_3dsp/`: отдельная модель комплексного умножителя на 3 DSP и связанные с ней генераторы тестовых данных.
- `fft64/`: полная 64-точечная radix-2 FFT.
- `fft64/fixed_sqrt2/`: fixed-point FFT64 в `model_fixed.[ch]`; fixed butterfly и twiddle-логика вынесены в `butterfly_fixed.[ch]`.
- `fft64/reference/`: double reference FFT64 в `model_double.[ch]` и standalone-прогон `double_main.c`.
- `fft64/tools/compare_fftw.c`: сравнение double FFT64 с FFTW3.
- `fft64/tools/compare_fixed.c`: сравнение fixed FFT64 с double FFT64, включая backoff, среднюю/максимальную ошибку и SQNR.
- `tools/`: прочие вспомогательные скрипты, например вывод данных twiddle ROM.

Именование в `fft64/` и связанных helper-файлах единообразное:

- `model_fixed.[ch]`: fixed-point модель.
- `model_double.[ch]`: double/reference модель.
- `fixed_main.c` и `double_main.c`: standalone entry points для ручного прогона.
- `compare*.c`: утилиты сравнения.

Основные цели `model/Makefile`:

- `make -C model mul`
- `make -C model fft`
- `make -C model fft_compare`
- `make -C model fft_fixed_compare`
- `make -C model print_twiddle`
