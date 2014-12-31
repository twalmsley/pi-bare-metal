
C_FLAGS = -O2 -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s -nostartfiles
FLAGS = -Wall $(C_FLAGS)

FILES = heap.S \
	gert.S \
	util.S \
	video.S \
	conio.S \
	gfx.S \
	interrupt_handler.S \
	uart.S

OBJ = $(FILES:.S=.o)
OUT = ../lib/libaosd_asm.a

TOOLCHAIN=/opt/local/bin/arm-none-eabi-

CC = $(TOOLCHAIN)gcc
LINKER = $(TOOLCHAIN)ar

.S.o:
	$(CC) $(FLAGS) -c $< -o $@

$(OUT): $(OBJ)
	rm -f $(OUT)
	$(LINKER) -rcs $(OUT) *.o
	cp constants.h ../lib

clean:
	rm -f $(OUT) *.o ../lib/constants.h
