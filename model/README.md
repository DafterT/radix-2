# model

Этот каталог организован по назначению, а не по истории появления файлов.

- `build/`: сгенерированные исполняемые файлы и временные артефакты сборки из верхнеуровневого `model/Makefile`.
- `complex_mul_3dsp/`: отдельная модель и self-test для комплексного умножителя на 3 DSP, который используется в RTL.
- `complex_mul_3dsp/tools/`: генераторы тестовых векторов и вспомогательные утилиты для модели комплексного умножителя.
- `stage/fixed/`: функциональная модель одного radix-2 FFT stage в fixed-point формате.
- `stage/reference/`: reference-модель того же stage на `double`.
- `stage/tools/`: утилиты сравнения поверх stage-моделей, например для оценки SQNR.
- `fft64/reference/`: reference-модель 64-точечного radix-2 FFT и отдельный self-test для нее.
- `fft64/tools/`: утилиты сравнения FFT64, включая сопоставление с библиотечной реализацией FFTW3.
- `tools/`: прочие вспомогательные скрипты, например для просмотра данных twiddle ROM.

Основные точки входа из верхнего `model/Makefile`:

- `make -C model mul`
- `make -C model fft`
- `make -C model fft_compare`
- `make -C model stage_fixed`
- `make -C model stage_double`
- `make -C model stage_compare`
- `make -C model print_twiddle`
