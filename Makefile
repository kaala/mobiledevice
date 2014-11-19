CC = clang
PREFIX = /usr/local

.PHONY: all install clean

all: mobiledevice

mobiledevice: main.m
	$(CC) -Wall -fobjc-arc -o mobiledevice -framework CoreFoundation -framework Cocoa -framework MobileDevice -F/System/Library/PrivateFrameworks main.m

install: mobiledevice
	install -d ${PREFIX}/bin
	install mobiledevice ${PREFIX}/bin

clean:
	rm -rf mobiledevice
