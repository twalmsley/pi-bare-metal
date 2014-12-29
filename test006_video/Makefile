CC = /opt/local/bin/arm-none-eabi-gcc
LIBS = aosd_asm

C_FLAGS = -O2 -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s -nostartfiles -L ../lib
FLAGS = -Wall -Wl,-T,rpi.x $(C_FLAGS)

FILES = cstartup.c \
    start.S


all : compile kernel

compile : $(FILES)
	$(CC) $(FLAGS) -o test006 $(FILES) -l $(LIBS)

kernel:
	/opt/local/bin/arm-none-eabi-objcopy -O binary test006 kernel.img

clean:
	rm -f test006 kernel.img
