CC = clang
PREFIX = /usr/local

SRC = $(wildcard *.m *.c)
OUT = bin/mobiledevice

all: bin $(OUT)

bin:
	mkdir bin/

$(OUT): $(SRC)
	$(CC) -Wall -fobjc-arc -o $(OUT) -framework MobileDevice -F/System/Library/PrivateFrameworks $(SRC)

.PHONY: clean
clean:
	rm -r $(OUT)
	rm -r bin/
	