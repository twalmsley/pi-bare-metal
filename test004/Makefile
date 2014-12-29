
C_FLAGS = -O2 -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s -nostartfiles
FLAGS = -Wall -Wl,-T,rpi.x $(C_FLAGS)

FILES = cstartup.c \
    start.S \
    gert.S \
    util.S \
    interrupt_handler.S

CC = /opt/local/bin/arm-none-eabi-gcc

all : compile kernel

compile : $(FILES)
	$(CC) $(FLAGS) -o test004 $(FILES)

kernel:
	/opt/local/bin/arm-none-eabi-objcopy -O binary test004 kernel.img

clean:
	rm test004 kernel.img
