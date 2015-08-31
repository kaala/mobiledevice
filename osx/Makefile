CC = clang
PREFIX = /usr/local

SRC = $(wildcard *.m *.c)
OUT = mobiledevice

all: $(OUT)

$(OUT): $(SRC)
	$(CC) -Wall -fobjc-arc -o $(OUT) -framework MobileDevice -F/System/Library/PrivateFrameworks $(SRC)

.PHONY: clean
clean:
	rm -r $(OUT)
