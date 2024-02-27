# Variables
# Directory name for the new filesystem to be at
DIRNAME=mydata

# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
cd /
sudo mkdir $DIRNAME
sudo /usr/local/etc/emulab/mkextrafs.pl /$DIRNAME
