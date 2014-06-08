#!/bin/sh

# nQWTFsv Installer Script v1.0 (for Linux)
# by Empezar & dimman

defaultdir="~/nqwtfsv"
eval defaultdir=$defaultdir

error() {
    printf "ERROR: %s\n" "$*"
    [ -n "$created" ] || {
        cd
        echo "The directory $directory is about to be removed, press ENTER to confirm or CTRL+C to exit." 
        read dummy
        rm -rf $directory
    }
    exit 1
}

# Check if unzip is installed
which unzip >/dev/null || error "The package 'unzip' is not installed. Please install it and run the installation again."

# Check if curl is installed
which curl >/dev/null || error "The package 'curl' is not installed. Please install it and run the installation again."

echo
echo "Welcome to the nQWTFsv v1.0 installation"
echo "========================================"
echo
echo "Press ENTER to use [default] option."
echo

# Create the nQWTFsv folder
printf "Where do you want to install nQWTFsv? [$defaultdir]: " 
read directory

eval directory=$directory

[ ! -z "$directory" ] || eval directory=$defaultdir

if [ -d "$directory" ]; then
	if [ -w "$directory" ]; then
		created=0
	else
		error "You do not have write access to '$directory'. Exiting."
	fi
else
	if [ -e "$directory" ]; then
		error "'$directory' already exists but is a file, not a directory. Exiting."
		exit
	else
		mkdir -p $directory 2>/dev/null || error "Failed to create install dir: '$directory'"
		created=1
	fi
fi
if [ -w "$directory" ]
then
	cd $directory
	directory=$(pwd)
else
	error "You do not have write access to $directory. Exiting."
fi

# Hostname
defaulthostname="nQWTF Team Fortress"
printf "Enter a descriptive hostname [$defaulthostname]: " 
read hostname
[ ! -z "$hostname" ] || hostname=$defaulthostname

# IP/dns
printf "Enter your server's DNS. [use external IP]: " 
read hostdns

# Port number
defaultport=27500
printf "What port do you want to use for your Team Fortress server? [27500]: " 
read port
[ ! -z "$port" ] || port=$defaultport

# Run qtv?
printf "Do you wish to run a qtv proxy? (y/n) [y]: " 
read qtv
[ ! -z "$qtv" ] || qtv="y"

# Run qwfwd?
printf "Do you wish to run a qwfwd proxy? (y/n) [y]: " 
read qwfwd
[ ! -z "$qwfwd" ] || qwfwd="y"

# Admin name
defaultadmin=$USER

printf "Who is the admin of this server? [$defaultadmin]: " 
read admin
[ ! -z "$admin" ] || admin=$defaultadmin

# Admin email
defaultemail="$admin@example.com"
printf "What is the admin's e-mail? [$defaultemail]: " 
read email
[ ! -z "$email" ] || email=$defaultemail

# Rcon
defaultrcon="changeme"
printf "What should the rcon password be? [$defaultrcon]: " 
read rcon
[ ! -z "$rcon" ] || {
	echo
	echo "Your rcon has been set to $defaultrcon. This is an enormous security risk."
	echo "To change this, edit $directory/fortress/pwd.cfg"
	echo
        rcon=$defaultrcon
}

if [ "$qtv" = "y" ]
then
	# Qtv password
	defaultqtvpass="changeme"
	printf "What should the qtv admin password be? [$defaultqtvpass]: " 
	read qtvpass
	[ ! -z "$qtvpass" ] || {
	        echo
	        echo "Your qtv password has been set to $defaultqtvpass. This is not recommended."
	        echo "To change this, edit $directory/qtv/qtv.cfg"
	        echo
	        qtvpass=$defaultqtvpass
	}
fi

# Download nqwtf.ini
wget --inet4-only -q -O nqwtf.ini http://nqwtf.sourceforge.net/nqwtf.ini || error "Failed to download nqwtf.ini"
[ -s "nqwtf.ini" ] || error "Downloaded nqwtf.ini but file is empty?! Exiting."

# List all the available mirrors
echo "From what mirror would you like to download nQuakesv?"
grep "[0-9]\{1,2\}=\".*" nqwtf.ini | cut -d "\"" -f2 | nl
printf "Enter mirror number [random]: " 
read mirror
mirror=$(grep "^$mirror=[fhtp]\{3,4\}://[^ ]*$" nqwtf.ini | cut -d "=" -f2)
[ -n "$mirror" ] || {
        echo;echo -n "* Using mirror: "
        range=$(expr$(grep "[0-9]\{1,2\}=\".*" nqwtf.ini | cut -d "\"" -f2 | nl | tail -n1 | cut -f1) + 1)
        while [ -z "$mirror" ]
        do
                number=$RANDOM
                let "number %= $range"
                mirror=$(grep "^$number=[fhtp]\{3,4\}://[^ ]*$" nqwtf.ini | cut -d "=" -f2)
		mirrorname=$(grep "^$number=\".*" nqwtf.ini | cut -d "\"" -f2)
        done
        echo "$mirrorname"
}
mkdir -p id1
echo;echo

# Download all the packages
echo "=== Downloading ==="
wget --inet4-only -O qsw106.zip $mirror/qsw106.zip || error "Failed to download $mirror/qsw106.zip"
wget --inet4-only -O qwtf-sv-gpl.zip $mirror/qwtf-sv-gpl.zip || error "Failed to download $mirror/qwtf-sv-gpl.zip"
wget --inet4-only -O qwtf-sv-non-gpl.zip $mirror/qwtf-sv-non-gpl.zip || error "Failed to download $mirror/qwtf-sv-non-gpl.zip"
wget --inet4-only -O qwtf-sv-configs.zip $mirror/qwtf-sv-configs.zip || error "Failed to download $mirror/qwtf-sv-configs.zip"
wget --inet4-only -O qwtf-sv-maps.zip $mirror/qwtf-sv-maps.zip || error "Failed to download $mirror/qwtf-sv-maps.zip"
wget --inet4-only -O qwtf-sv-bin-x86.zip $mirror/qwtf-sv-bin-x86.zip || error "Failed to download $mirror/qwtf-sv-bin-x86.zip"

[ -s "qsw106.zip" ] || error "Downloaded qwsv106.zip but file is empty?!"
[ -s "qwtf-sv-gpl.zip" ] || error "Downloaded qwtf-sv-gpl.zip but file is empty?!"
[ -s "qwtf-sv-non-gpl.zip" ] || error "Downloaded qwtf-sv-non-gpl.zip but file is empty?!"
[ -s "qwtf-sv-configs.zip" ] || error "Downloaded qwtf-sv-configs.zip but file is empty?!"
[ -s "qwtf-sv-maps.zip" ] || error "Downloaded qwtf-sv-maps.zip but file is empty?!"


# Get remote IP address
echo "Resolving external IP address..."
echo
remote_ip=$(curl http://myip.dnsomatic.com)
[ -n "$hostdns" ] || hostdns=$remote_ip

echo

# Extract all the packages
echo "=== Installing ==="
printf "* Extracting Quake Shareware..."
(unzip -qqo qsw106.zip ID1/PAK0.PAK 2>/dev/null && echo done) || echo fail
printf "* Extracting nQWTF setup files (1 of 2)..."
(unzip -qqo qwtf-sv-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting nQWTF setup files (2 of 2)..."
(unzip -qqo qwtf-sv-non-gpl.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting nQWTF binaries..."
(unzip -qqo qwtf-sv-bin-x86.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting nQWTF configuration files..."
(unzip -qqo qwtf-sv-configs.zip 2>/dev/null && echo done) || echo fail
printf "* Extracting nQWTF maps..."
(unzip -qqo qwtf-sv-maps.zip 2>/dev/null && echo done) || echo fail
echo

# Rename files
echo "=== Cleaning up ==="
printf "* Renaming files..."
(mv $directory/ID1/PAK0.PAK $directory/id1/pak0.pak 2>/dev/null && rm -rf $directory/ID1 && echo done) || echo fail

# Remove distribution files
printf "* Removing distribution files..."
(rm -rf $directory/qsw106.zip $directory/qwtf-sv-gpl.zip $directory/qwtf-sv-non-gpl.zip $directory/qwtf-sv-configs.zip $directory/qwtf-sv-maps.zip $directory/qwtf-sv-bin-x86.zip $directory/nqwtf.ini && echo done) || echo fail

# Convert DOS files to UNIX
printf "* Converting DOS files to UNIX..."
for file in $(find $directory -iname "*.cfg" -or -iname "*.txt" -or -iname "*.sh" -or -iname "README")
do
	[ ! -f "$file" ] || cat $file|tr -d '\015' > tmpfile
	rm $file
	mv tmpfile $file
done
echo "done"

# Set the correct permissions
printf "* Setting permissions..."
find $directory -type f -exec chmod -f 644 {} \;
find $directory -type d -exec chmod -f 755 {} \;
chmod -f +x $directory/mvdsv 2>/dev/null
chmod -f +x $directory/fortress/mvdfinish.qws 2>/dev/null
chmod -f +x $directory/qtv/qtv.bin 2>/dev/null
chmod -f +x $directory/qwfwd/qwfwd.bin 2>/dev/null
chmod -f +x $directory/*.sh 2>/dev/null
chmod -f +x $directory/run/*.sh 2>/dev/null
echo "done"

# Update configuration files
printf "* Updating configuration files..."
mkdir -p ~/.nqwtfsv
echo $directory > ~/.nqwtfsv/install_dir
echo $hostname > ~/.nqwtfsv/hostname
echo $hostdns > ~/.nqwtfsv/hostdns
echo $remote_ip > ~/.nqwtfsv/ip
echo "$admin <$email>" > ~/.nqwtfsv/admin
#/start_servers.sh
safe_pattern=$(printf "%s\n" "$directory" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_PATH/${safe_pattern}/g" $directory/start_servers.sh
#/ktx/pwd.cfg
safe_pattern=$(printf "%s\n" "$rcon" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_RCON/${safe_pattern}/g" $directory/fortress/pwd.cfg
#/qtv/qtv.cfg
if [ "$qtv" = "y" ]
then
	safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQWTFSV_HOSTNAME/${safe_pattern}/g" $directory/qtv/qtv.cfg
	safe_pattern=$(printf "%s\n" "$qtvpass" | sed 's/[][\.*^$/]/\\&/g')
	sed -i "s/NQWTFSV_QTVPASS/${safe_pattern}/g" $directory/qtv/qtv.cfg
	cd qtv
	ln -s ../fortress/demos demos
fi
#/qwfwd/qwfwd.cfg
if [ "$qwfwd" = "y" ]
then
        safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
        sed -i "s/NQWTFSV_HOSTNAME/${safe_pattern}/g" $directory/qwfwd/qwfwd.cfg
fi
echo "done"

printf "* Setting up shell scripts..."
# Fix shell scripts
safe_pattern=$(printf "%s\n" "./mvdsv -port $port -game fortress" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_RUN_MVDSV/${safe_pattern}/g" $directory/run/fortress.sh
# Fix /fortress/port1.cfg
safe_pattern=$(printf "%s\n" "$hostname" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_HOSTNAME/${safe_pattern}/g" $directory/fortress/port1.cfg
safe_pattern=$(printf "%s\n" "$admin <$email>" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_ADMIN/${safe_pattern}/g" $directory/fortress/port1.cfg
safe_pattern=$(printf "%s\n" "$remote_ip:$port" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_IP/${safe_pattern}/g" $directory/fortress/port1.cfg
safe_pattern=$(printf "%s\n" "$port" | sed 's/[][\.*^$/]/\\&/g')
sed -i "s/NQWTFSV_PORT/${safe_pattern}/g" $directory/fortress/port1.cfg
# Fix /qtv/qtv.cfg
echo "qtv $hostdns:$port" >> $directory/qtv/qtv.cfg
# Fix start_servers.sh script
echo >> $directory/start_servers.sh
echo "printf \"* Starting Team Fortress server (port $port)...\"" >> $directory/start_servers.sh
echo "if ps ax | grep -v grep | grep \"mvdsv -port $port\" > /dev/null" >> $directory/start_servers.sh
echo "then" >> $directory/start_servers.sh
echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
echo "else" >> $directory/start_servers.sh
echo "./run/fortress.sh > /dev/null &" >> $directory/start_servers.sh
echo "echo \"[OK]\"" >> $directory/start_servers.sh
echo "fi" >> $directory/start_servers.sh
# Fix stop_servers.sh script
echo >> $directory/stop_servers.sh
echo "# Kill $port" >> $directory/stop_servers.sh
echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/fortress.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
echo "pid=\`ps ax | grep -v grep | grep \"mvdsv -port $port\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
i=$((i+1))
echo "done"

# Add QTV
if [ "$qtv" = "y" ]
then
	printf "* Adding qtv to start/stop scripts..."
	# start_servers.sh
	echo >> $directory/start_servers.sh
	echo "printf \"* Starting qtv (port 28000)...\"" >> $directory/start_servers.sh
	echo "if ps ax | grep -v grep | grep \"qtv.bin +exec qtv.cfg\" > /dev/null" >> $directory/start_servers.sh
	echo "then" >> $directory/start_servers.sh
	echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
	echo "else" >> $directory/start_servers.sh
	echo "./run/qtv.sh > /dev/null &" >> $directory/start_servers.sh
	echo "echo \"[OK]\"" >> $directory/start_servers.sh
	echo "fi" >> $directory/start_servers.sh
	# stop_servers.sh
	echo >> $directory/stop_servers.sh
	echo "# Kill QTV" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/qtv.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"qtv.bin +exec qtv.cfg\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "done"
else
	printf "* Removing qtv files..."
	(rm -rf $directory/qtv $directory/run/qtv.sh && echo done) || echo fail
fi

# Add/remove qwfwd
if [ "$qwfwd" = "y" ]
then
	# start_servers.sh
        echo -n "* Adding qwfwd to start/stop scripts..."
        echo >> $directory/start_servers.sh
    	echo "echo -n \"* Starting qwfwd (port 30000)...\"" >> $directory/start_servers.sh
        echo "if ps ax | grep -v grep | grep \"qwfwd.bin\" > /dev/null" >> $directory/start_servers.sh
        echo "then" >> $directory/start_servers.sh
        echo "echo \"[ALREADY RUNNING]\"" >> $directory/start_servers.sh
        echo "else" >> $directory/start_servers.sh
        echo "./run/qwfwd.sh > /dev/null &" >> $directory/start_servers.sh
    	echo "echo \"[OK]\"" >> $directory/start_servers.sh
        echo "fi" >> $directory/start_servers.sh
        # stop_servers.sh
	echo >> $directory/stop_servers.sh
	echo "# Kill QWFWD" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"/bin/sh ./run/qwfwd.sh\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
	echo "pid=\`ps ax | grep -v grep | grep \"qwfwd.bin\" | awk '{print \$1}'\`" >> $directory/stop_servers.sh
	echo "if [ \"\$pid\" != \"\" ]; then kill -9 \$pid; fi;" >> $directory/stop_servers.sh
        echo "done"
else
	printf "* Removing qwfwd files..."
        (rm -rf $directory/qwfwd $directory/run/qwfwd.sh && echo done) || echo fail
fi

echo;echo "To make sure your servers are always running, type \"crontab -e\" and add the following:"
echo;echo "*/10 * * * * $directory/start_servers.sh >/dev/null 2>&1"
echo;echo "Installation complete. Please read the README in $directory."
echo
