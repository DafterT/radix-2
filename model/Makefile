CC ?= gcc
CFLAGS ?= -std=c11 -Wall -Wextra -O3
TARGET ?= dpi_complex_fixed_test
SRC := dpi_complex_fixed_test.c

.PHONY: all build run clean

all: build

build: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $< -o $@

run: build
	./$(TARGET)

clean:
	$(RM) $(TARGET) $(TARGET).exe a.out
