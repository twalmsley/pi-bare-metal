CC = /opt/local/bin/arm-none-eabi-gcc
LIBS = aosd_asm

C_FLAGS = -O2 -mfpu=vfp -mfloat-abi=hard -march=armv6zk -mtune=arm1176jzf-s -nostartfiles -L ../lib
FLAGS = -Wall -Wl,-T,rpi.x $(C_FLAGS)

FILES = cstartup.c \
    start.S

TARGET=test007.exe

all : compile kernel

compile : $(FILES)
	$(CC) $(FLAGS) -o $(TARGET) $(FILES) -l $(LIBS)

kernel:
	/opt/local/bin/arm-none-eabi-objcopy -O binary $(TARGET) kernel.img

clean:
	rm -f $(TARGET) kernel.img
