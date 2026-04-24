# complex_mul_3dsp

Запуск:

```bash
make -C model run-complex_mul_3dsp
```

Модель собирает `complex_mul_3dsp_model.c` вместе с локальным smoke test `complex_mul_3dsp_test.c` и сверяет несколько фиксированных комплексных векторов.

Генератор тестовых векторов для RTL/DPI лежит в `tools/`:

```bash
make -C model/complex_mul_3dsp/tools file
```
