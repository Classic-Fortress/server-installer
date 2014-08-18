Classic Fortress Server Installer for Linux
===========================================

How to install:

    wget https://raw.githubusercontent.com/Classic-Fortress/server-installer-linux/master/install_cfortsv.sh
    chmod +x install_cfortsv.sh
    ./install_cfortsv.sh

During the installation you will get to select a program directory (default *~/cfortsv/*) and a download mirror where the installation files will be downloaded from.

Before starting your servers, you **need** to edit the files [server.conf](https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/fortress/config.cfg), [qtv.conf](https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qtv/config.cfg) and [qwfwd.conf](https://raw.githubusercontent.com/Classic-Fortress/server-scripts/master/config/qwfwd/config.cfg) located in *~/.cfortsv/* (note the leading dot) or the servers will not start. Pay special attention to the last few lines of the config, as you need to remove/comment out one or two lines there to make the servers start. This is to prevent users from trying to launch servers that have not been configured properly.

If you wish to change the way *mvdsv*, *qtv* and *qwfwd* starts, edit the respective startup scripts in *~/.cfortsv/run/* (again, note the leading dot).
