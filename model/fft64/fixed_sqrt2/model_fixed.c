#include "model_fixed.h"
#include "butterfly_fixed.h"

#define FFT64_FIXED_BANK_COUNT 2U
#define FFT64_FIXED_BANK_DEPTH (FFT64_FIXED_SIZE / FFT64_FIXED_BANK_COUNT)

typedef struct {
    unsigned bank;
    unsigned address;
} fft64_fixed_bank_addr_t;

typedef struct {
    fft64_fixed_cpx_q16_0_t banks[FFT64_FIXED_BANK_COUNT][FFT64_FIXED_BANK_DEPTH];
} fft64_fixed_memory_t;

static unsigned reverse_bits_6(unsigned value) {
    unsigned reversed = 0;

    for (int bit = 0; bit < 6; ++bit) {
        reversed = (reversed << 1U) | ((value >> bit) & 1U);
    }

    return reversed;
}

static fft64_fixed_bank_addr_t fft64_fixed_resolve_bank_addr(unsigned logical_index) {
    unsigned bank = 0;

    for (unsigned value = logical_index; value != 0U; value >>= 1U) {
        bank ^= value & 1U;
    }

    return (fft64_fixed_bank_addr_t){
        .bank = bank,
        .address = logical_index & (FFT64_FIXED_BANK_DEPTH - 1U)
    };
}

static fft64_fixed_cpx_q16_0_t fft64_fixed_memory_read(
    const fft64_fixed_memory_t *memory,
    unsigned logical_index
) {
    fft64_fixed_bank_addr_t bank_addr = fft64_fixed_resolve_bank_addr(logical_index);

    return memory->banks[bank_addr.bank][bank_addr.address];
}

static void fft64_fixed_memory_write(
    fft64_fixed_memory_t *memory,
    unsigned logical_index,
    fft64_fixed_cpx_q16_0_t value
) {
    fft64_fixed_bank_addr_t bank_addr = fft64_fixed_resolve_bank_addr(logical_index);

    memory->banks[bank_addr.bank][bank_addr.address] = value;
}

static void fft64_fixed_bit_reverse_copy(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE],
    fft64_fixed_memory_t *memory
) {
    for (unsigned i = 0; i < FFT64_FIXED_SIZE; ++i) {
        fft64_fixed_memory_write(memory, reverse_bits_6(i), input[i]);
    }
}

static void fft64_fixed_execute_stage(
    fft64_fixed_memory_t *memory,
    int stage_size
) {
    int half_stage = stage_size / 2;
    int twiddle_step = FFT64_FIXED_SIZE / stage_size;

    for (int block_start = 0; block_start < FFT64_FIXED_SIZE; block_start += stage_size) {
        for (int j = 0; j < half_stage; ++j) {
            int top_index = block_start + j;
            int bottom_index = top_index + half_stage;
            int twiddle_index = j * twiddle_step;
            fft64_fixed_cpx_q16_0_t top = fft64_fixed_memory_read(memory, (unsigned)top_index);
            fft64_fixed_cpx_q16_0_t bottom = fft64_fixed_memory_read(memory, (unsigned)bottom_index);

            fft64_fixed_butterfly(
                &top,
                &bottom,
                twiddle_index
            );

            fft64_fixed_memory_write(memory, (unsigned)top_index, top);
            fft64_fixed_memory_write(memory, (unsigned)bottom_index, bottom);
        }
    }
}

static void fft64_fixed_execute_all_stages(
    fft64_fixed_memory_t *memory
) {
    for (int stage_size = 2; stage_size <= FFT64_FIXED_SIZE; stage_size *= 2) {
        fft64_fixed_execute_stage(memory, stage_size);
    }
}

static void fft64_fixed_collect_result(
    const fft64_fixed_memory_t *memory,
    fft64_fixed_result_t *result
) {
    for (unsigned i = 0; i < FFT64_FIXED_SIZE; ++i) {
        result->bins[i] = fft64_fixed_memory_read(memory, i);
    }
}

fft64_fixed_result_t fft64_radix2_fixed(
    const fft64_fixed_cpx_q16_0_t input[FFT64_FIXED_SIZE]
) {
    fft64_fixed_memory_t memory = {0};
    fft64_fixed_result_t result;

    fft64_fixed_bit_reverse_copy(input, &memory);
    fft64_fixed_execute_all_stages(&memory);
    fft64_fixed_collect_result(&memory, &result);

    return result;
}
