#!/bin/sh

sudo apt install automake autoconf build-essential git texinfo libtool libftdi-dev libusb-1.0-0-dev
git clone https://github.com/raspberrypi/openocd.git --branch rp2040 --recursive --depth=1
cd openocd
./bootstrap
./configure --enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio
make -j1
sudo make install