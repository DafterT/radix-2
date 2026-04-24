# radix2_butterfly

Запуск:

```bash
make -C model run-radix2_butterfly_compare
```

Compare-цель собирает fixed и reference модели radix-2 butterfly и прогоняет рандомизированное сравнение по SQNR.

Основные файлы:

- `fixed/radix2_butterfly_fixed_model.[ch]`
- `reference/radix2_butterfly_reference_model.[ch]`
- `tools/radix2_butterfly_compare.c`
