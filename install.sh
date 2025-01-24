#!/bin/bash

############################################
# Script to install SVXLink from source on
# a fresh Raspbian install.
############################################

# Check if the user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Update the system
echo "Updating the system..."
apt-get update
apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
apt-get install gcc g++ make cmake -y
apt-get install groff -y 
apt-get install gzip -y
apt-get install doxygen -y
apt-get install tar -y 
apt-get install git -y 
apt-get install libsigc++-2.0-dev -y
apt-get install libpopt-dev -y
apt-get install tcl tcllib tcl-dev -y
apt-get install libgcrypt20-dev -y
apt-get install libasound2-dev -y
apt-get install libgsm1-dev -y
apt-get install libjsoncpp-dev -y
apt-get install libspeex-dev -y
apt-get install librtlsdr-dev -y
apt-get install libgpiod-dev -y
apt-get install qtbase5-dev qt5-qmake libqt5widgets5 qttools5-dev -y
apt-get install libssl-dev -y
apt-get install alsa-utils -y
apt-get install libvorbis-dev -y 
apt-get install libopus-dev opus-tools -y 
apt-get install libcurl4-openssl-dev -y
# QoL because I like tmux
apt-get install tmux -y

# Create the svxlink user
echo "Creating the svxlink user..."


sudo useradd -rG audio,plugdev,gpio,dialout,daemon svxlink

groupadd svxlink
usermod -a -G svxlink svxlink

# Install SVXLink
echo "Installing SVXLink..."
rm -r /usr/local/src/svxlink
mkdir /usr/local/src/svxlink 
chown svxlink:daemon /usr/local/src/svxlink
sudo -u svxlink -- bash -c \
'cd /usr/local/src/ && \
git clone https://github.com/sm0svx/svxlink.git && \
mkdir svxlink/src/build && \
cd svxlink/src/build && \
cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DWITH_SYSTEMD=ON .. && \
make && \
make doc'

(cd /usr/local/src/svxlink/src/build && make install && ldconfig)

# Download the voice files
echo "Downloading voice files..."
(cd /usr/share/svxlink/sounds/ && \
curl -LO https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/24.02/svxlink-sounds-en_US-heather-16k-24.02.tar.bz2 && \
tar xvjf svxlink-sounds-en_US-heather-16k-24.02.tar.bz2 && \
ln -s en_US-heather-16k en_US)

