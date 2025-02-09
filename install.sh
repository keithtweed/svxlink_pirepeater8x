#!/bin/bash

############################################
# Script to install SVXLink from source on
# a fresh Raspbian install.
############################################

# Reset variables
VERBOSE=1
INTERACTIVE=1
CONFIGURE=0

# Helpers
redir() {
  if [ $VERBOSE == 1 ]; then
    $@ > /dev/null 2>&1
  else
    $@ >
  fi
}

pause() {
  if [ $INTERACTIVE == 0 ]; then
    read -p "Press [Enter] to continue..."
  fi
}

# Get options
while getopts "hvin" opt; do
  case $opt in
    h|\? )
      echo "Usage: install.sh"
      echo "  -h  Display help"
      echo "  -v  Verbose output"
      echo "  -i  Interactive mode (pause after each step)"
      echo "  -n  Do not load included configuration"
      exit 0
      ;;
    v)
      VERBOSE=0
      ;;
    i)
      INTERACTIVE=0
      ;;
    n)
      CONFIGURE=1
      ;;
  esac
done

# Check if the user is root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

# Update the system
echo "Updating the system..."
redir apt-get update
redir apt-get upgrade -y
echo "Updates complete."
pause

# Install dependencies
echo "Installing dependencies..."
redir apt-get install -y gcc g++ make cmake groff gzip doxygen tar git \
  libsigc++-2.0-dev libpopt-dev tcl tcllib tcl-dev libgcrypt20-dev \
  libasound2-dev libgsm1-dev libjsoncpp-dev libspeex-dev librtlsdr-dev \
  libgpiod-dev qtbase5-dev qt5-qmake libqt5widgets5 qttools5-dev libssl-dev \
  alsa-utils libvorbis-dev libopus-dev opus-tools libcurl4-openssl-dev
# Optional, for QoL and debugging
redir apt-get install tmux i2c-tools -y
echo "Dependencies installed."
pause

# Create the svxlink user
echo "Creating the svxlink user..."

redir useradd -rG audio,plugdev,gpio,dialout,daemon svxlink
redir groupadd svxlink
redir usermod -a -G svxlink svxlink

echo "User created."
pause

# Install SVXLink
echo "Compiling SVXLink..."
redir rm -r /usr/local/src/svxlink
redir mkdir /usr/local/src/svxlink 
redir chown svxlink:daemon /usr/local/src/svxlink
sudo -u svxlink -- bash -c \
'cd /usr/local/src/ && \
git clone https://github.com/sm0svx/svxlink.git && \
mkdir svxlink/src/build && \
cd svxlink/src/build && \
cmake -DUSE_QT=OFF -DCMAKE_INSTALL_PREFIX=/usr -DSYSCONF_INSTALL_DIR=/etc -DLOCAL_STATE_DIR=/var -DWITH_SYSTEMD=ON .. && \
make && \
make doc'
echo "SVXLink compiled."
pause

echo "Installing SVXLink..."
redir (cd /usr/local/src/svxlink/src/build && make install && ldconfig)
echo "SVXLink installed."
pause

# Download the voice files
echo "Downloading voice files..."
(cd /usr/share/svxlink/sounds/ && \
curl -LO https://github.com/sm0svx/svxlink-sounds-en_US-heather/releases/download/24.02/svxlink-sounds-en_US-heather-16k-24.02.tar.bz2 && \
tar xvjf svxlink-sounds-en_US-heather-16k-24.02.tar.bz2 && \
ln -s en_US-heather-16k en_US)
echo "Voice files downloaded."
pause

if [ $CONFIGURE == 0 ]; then
  # Copy the configuration files
  echo "Copying configuration files..."
  cp -r $SCRIPT_DIR/svxlink/* /etc/svxlink/
  cp -r $SCRIPT_DIR/events/* /usr/share/svxlink/events.d/
  echo "Configuration files copied."
  pause
fi

# Update config.txt
echo "Updating boot configuration..."
cp /boot/firmware/config.txt /boot/firmware/config.txt.bak
sed -i 's/dtparam=audio=on/#dtparam=audio=on/' /boot/firmware/config.txt
sed -i 's/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-kms-v3d,noaudio/' /boot/firmware/config.txt
sed -i /boot/firmware/config.txt -e "s#\#dtparam=i2c_arm=on#dtparam=i2c_arm=on#"
tee -a /boot/firmware/confit.txt << EOF
##### Pi-Repeater 8x Configs #####
dtparam=i2c1=on

# MAIN BOARD
dtoverlay=mcp23017,addr=0x27,gpiopin=23
dtoverlay=mcp23017,addr=0x26,gpiopin=24
dtoverlay=mcp23017,addr=0x25,gpiopin=25
# RELAY BOARD
dtoverlay=mcp23017,addr=0x24,gpiopin=13
EOF

tee -a /etc/modules << EOF
i2c-dev
EOF

ln -s /dev/null /etc/udev/rules.d/60-gpiochip4.rules

echo "Boot configuration updated."


echo "Installation complete!"
echo "Please restart the system to apply changes."