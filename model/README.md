# model

This directory is organized by purpose rather than by historical file order.

- `build/`: generated executables and temporary build outputs from the top-level `model/Makefile`.
- `complex_mul_3dsp/`: standalone model and self-test for the 3-DSP complex multiplier used in RTL.
- `stage/fixed/`: fixed-point functional model for a radix-2 FFT stage.
- `stage/reference/`: double-precision reference model for the same stage behavior.
- `stage/tools/`: comparison utilities built on top of the stage models, such as SQNR checks.
- `fft64/`: standalone 64-point radix-2 FFT reference model.
- `complex_mul_3dsp/tools/`: generators for complex multiplier test vectors and related helper scripts.
- `tools/`: miscellaneous standalone helpers, such as scripts for inspecting twiddle ROM data.

The top-level `model/Makefile` still provides the main entry points:

- `make -C model run`
- `make -C model run-fft64`
- `make -C model run-stage`
- `make -C model run-stage-double`
- `make -C model run-stage-compare`
