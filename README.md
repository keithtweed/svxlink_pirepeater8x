# svxlink_pirepeater8x
Updated configurations and support scripts for SVXLink to support the PI-REPEATER-8X from ICS

SVXLink was updated since the last commit to [OpenRepeater/svxlink-sample-configs](https://github.com/OpenRepeater/svxlink-sample-configs) in December of 2023, and the previous GPIO configuration was deprecated in favor of GPIOd. These configuration files are updated from svxlink-sample-configs to use GPIOd and for use at [The Northern Alberta Radio Club](https://tnarc.ca). 

## /boot/firmware/config.txt changes
```
# Comment out
#dtparam=audio=on

...

# add noaudio
dtoverlay=vc4-kms-v3d,noaudio

[all]
# Pi-Repeater-8X
dtparam=i2c_arm=on
dtparam=i2c1=on

##### MAIN BOARD #####
dtoverlay=mcp23017,addr=0x27,gpiopin=23
dtoverlay=mcp23017,addr=0x26,gpiopin=24
dtoverlay=mcp23017,addr=0x25,gpiopin=25
##### RELAY BOARD #####
dtoverlay=mcp23017,addr=0x24,gpiopin=13