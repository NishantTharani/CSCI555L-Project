# Variables
# Directory name that we will use
DIRNAME=data

# IP Addresses should be hardcoded by the profile
MASTER_IP=10.10.1.100
WORKER1_IP=10.10.1.101
WORKER2_IP=10.10.1.102
WORKER3_IP=10.10.1.103
CLIENT_IP=10.10.1.104

# Hostname cannot reliably be used to identify cluster since it only seems to include the cluster for the master node

# Get HWTYPE from user input
read -p "Enter HWTYPE: " HWTYPE

# Exit with an error if HWTYPE is not defined
if [[ -z $HWTYPE ]]; then
  echo "Error: HWTYPE is not defined"
  exit 1
fi

# Set cluster name based on HWTYPE
if [[ $HWTYPE == "m400" ]]; then
  CLUSTER="UTAH"
else 
  # Exit with error if HWTYPE is not recognized
  echo "Error: HWTYPE $HWTYPE is not recognized"
  exit 1
fi

# Try to get the IP address of the interface named enp1s0d1
OUR_IP=$(ifconfig enp1s0d1 | grep 'inet ' | awk '{print $2}')

# Check if the OUR_IP variable is empty
if [[ -z $OUR_IP ]]; then
  echo "Error: Interface enp1s0d1 does not have an IP address or does not exist"
  exit 1
fi

# If the script reaches this point, the ip_address variable
# should contain the IP address of the interface enp1s0d1
echo "IP Address of enp1s0d1: $OUR_IP"


sudo mkdir -p /$DIRNAME
cd /$DIRNAME

# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
# Create a new filesystem using the remaining space on the system (boot) disk, at /DIRNAME
# The below seems unnecessary for now as we seem to be getting 68G anyway even though the docs say we should only be getting 16G?
# sudo /usr/local/etc/emulab/mkextrafs.pl /$DIRNAME

# Install java
sudo apt-get update
# Sleep for a bit to let apt-get get its act together
sleep 2
sudo apt-get install openjdk-8-jdk -y

# Download hadoop
sudo wget https://dlcdn.apache.org/hadoop/common/hadoop-3.3.6/hadoop-3.3.6.tar.gz
sudo tar zvxf hadoop-3.3.6.tar.gz
sudo rm hadoop-3.3.6.tar.gz

# Update hadoop configuration
# Define the file path to core-site.xml
file_path="/data/hadoop-3.3.6/etc/hadoop/core-site.xml"

# Backup the original file
cp "$file_path" "$file_path.backup"

# Write the new configuration
# If this doesn't work then try using <name>fs.default.name</name> instead?
echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
<name>fs.defaultFS</name>
<value>hdfs://'$MASTER_IP':9000</value>
</property>
</configuration>' > "$file_path"