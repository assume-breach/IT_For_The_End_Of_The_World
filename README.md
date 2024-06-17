# IT_For_The_End_Of_The_World
A server for the end of the world.

This repo's purpose is to provide scripts/configurations for a server that will assist with file hosting and chatting if the grid goes down. While this will be configured on a Ubuntu server, the configurations and packages should work on any Debian based distro and Rapsberry Pi.

**Features**

File hosting via Apache<br>
Simple Chat server <br>
Captive Portal via HostAPD<br>
SMB Fileshare for local clients

**USAGE**
1.) Clone The Repo

cd /opt/ && git clone https://github.com/assume-breach/IT_For_The_End_Of_The_World.git

2.) Run this oneliner 

bash Captive.sh; bash Web.sh; bash FileShare; bash Music.sh; bash Cron.sh

3.) Reboot

reboot now
