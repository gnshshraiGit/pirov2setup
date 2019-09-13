#!/bin/bash
#Script to setup environment for pirov2 and make Rpi ready to run pirov2 server
homedir=`pwd`
crntuser=`whoami`
#Enable Camera and I2C interface to disable red camera led manually append disable_camera_led=1 to /boot/config.txt
raspi-config

#install update to base raspbian image.
echo "Installing updates"
sudo apt-get update
sudo apt-get upgrade -y

#Optional : Install rmate to remotely work with visual studio code, 
#ref: https://medium.com/@prtdomingo/editing-files-in-your-linux-virtual-machine-made-a-lot-easier-with-remote-vscode-6bb98d0639a4

echo "Installing rmate client"
wget -O /usr/local/bin/rmate https://raw.github.com/aurora/rmate/master/rmate
chmod a+x /usr/local/bin/rmate

#install v4l2, main driver to capture images from camera module
echo "Installing v4l2 modules"
apt-get install libv4l-dev v4l-utils -y

#install git client only needed if you haven't installed git
echo "Installing Git"
apt-get install git -y

#install alsa sound drivers
echo "Installing alsa sound"
sudo apt-get install alsa-utils mpg321 lame -y

#install Nodejs 11
echo "Installing Nodejs 11"
curl -sL https://deb.nodesource.com/setup_11.x | bash -
apt-get install nodejs build-essential npm node-semver -y

#install pigpio to control onboard GPIO pins and setup demon, pigpio modules uses BCM pin maps
echo "Installing pigpio"
apt-get install pigpio -y
sudo systemctl disable pigpiod
sudo systemctl stop pigpiod

#install ffmpeg with ffserver , version 3.4.6
echo "Installing ffmpeg@3.4.6 with ffserver"
apt-get install libasound2-dev libmp3lame-dev libx264-dev -y
cd /usr/local/bin
wget -O ./ffmpeg-3.4.6.tar.bz2 https://ffmpeg.org/releases/ffmpeg-3.4.6.tar.bz2
tar -xvf ffmpeg-3.4.6.tar.bz2
cd ffmpeg-3.4.6
./configure --arch=armel --target-os=linux --enable-gpl --enable-libx264 --enable-nonfree --enable-indev=alsa --enable-outdev=alsa --enable-omx --enable-omx-rpi --enable-mmal --enable-libmp3lame --enable-decoder=h264_mmal --enable-decoder=mpeg2_mmal --enable-encoder=h264_omx
#For RPi = v3
make -j4
#For RPi < v3
#make
make install
cd $homedir

#Go back to home directory and install pirov2 server
echo "Installing pirov2 at $homedir"
git clone https://github.com/gnshshraiGit/pirov2.git
cd pirov2
sudo npm install 
mkdir recordings
cd $homedir

#Demonize pirov2 server, if user is other than pi please change user name in pirov2.service line 10 
echo "Demonizing pirov2"

sed "/Service/a\Environment="""pirov2dir=$homedir"""\nUser=$crntuser" pirov2.service.conf > pirov2.service
sudo cp pirov2.service /etc/systemd/system/pirov2.service
sudo systemctl enable pirov2.service
sudo systemctl start pirov2.service

#copy preconfigured ffserver config
echo "Configuring ffserver"
sudo cp ffserver.conf /etc/ffserver.conf

# Cleanup and Reboot
echo "All done now clean and restarting"
sudo reboot
