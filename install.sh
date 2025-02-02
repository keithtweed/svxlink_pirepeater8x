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
  if [ $VERBOSE ]; then
    $@ > /dev/null 2>&1
  else
    $@ 
  fi
}

pause() {
  if [ $INTERACTIVE ]; then
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
redir apt-get install gcc g++ make cmake -y
redir apt-get install groff -y 
redir apt-get install gzip -y
redir apt-get install doxygen -y
redir apt-get install tar -y 
redir apt-get install git -y 
redir apt-get install libsigc++-2.0-dev -y
redir apt-get install libpopt-dev -y
redir apt-get install tcl tcllib tcl-dev -y
redir apt-get install libgcrypt20-dev -y
redir apt-get install libasound2-dev -y
redir apt-get install libgsm1-dev -y
redir apt-get install libjsoncpp-dev -y
redir apt-get install libspeex-dev -y
redir apt-get install librtlsdr-dev -y
redir apt-get install libgpiod-dev -y
redir apt-get install qtbase5-dev qt5-qmake libqt5widgets5 qttools5-dev -y
redir apt-get install libssl-dev -y
redir apt-get install alsa-utils -y
redir apt-get install libvorbis-dev -y 
redir apt-get install libopus-dev opus-tools -y 
redir apt-get install libcurl4-openssl-dev -y
# QoL because I like tmux
redir apt-get install tmux -y
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
redir sudo -u svxlink -- bash -c \
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
+
echo "Voice files downloaded."
pause

if [ $CONFIGURE ]; then
  # Copy the configuration files
  echo "Copying configuration files..."
  cp -r $SCRIPT_DIR/svxlink/* /etc/svxlink/
  cp -r $SCRIPT_DIR/events/* /usr/share/svxlink/events.d/
  echo "Configuration files copied."
  pause
fi

# Update config.txt
echo "Updating boot configuration..."
sed -i 's/dtparam=audio=on/#dtparam=audio=on/' /boot/firmware/config.txt
sed -i 's/dtoverlay=vc4-kms-v3d/dtoverlay=vc4-kms-v3d,noaudio/' /boot/firmware/config.txt

echo "Installation complete!"
echo "Please restart the system to apply changes."