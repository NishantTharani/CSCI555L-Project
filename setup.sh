#!/bin/bash

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

# Read /tmp/hwtype.txt and save the string to the variable HWTYPE, without a newline
HWTYPE=$(cat /tmp/hwtype.txt)
NAME=$(cat /tmp/name.txt)

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

# Try to ping every IP address in the cluster and exit with an error if any fail
for IP in $MASTER_IP $WORKER1_IP $WORKER2_IP $WORKER3_IP $CLIENT_IP; do
  ping -c 1 -W 1 $IP > /dev/null
  if [[ $? -ne 0 ]]; then
    echo "Error: Could not ping $IP"
    exit 1
  fi
done

# Set our role based on the IP address
if [[ $OUR_IP == $MASTER_IP ]]; then
  ROLE="master"
elif [[ $OUR_IP == $WORKER1_IP ]]; then
  ROLE="worker1"
elif [[ $OUR_IP == $WORKER2_IP ]]; then
  ROLE="worker2"
elif [[ $OUR_IP == $WORKER3_IP ]]; then
  ROLE="worker3"
elif [[ $OUR_IP == $CLIENT_IP ]]; then
  ROLE="client"
else
  echo "Error: IP address $OUR_IP is not recognized"
  exit 1
fi


# if [[ $ROLE != "client" ]]; then
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
sudo tar zxf hadoop-3.3.6.tar.gz
sudo rm hadoop-3.3.6.tar.gz
sudo mv hadoop-3.3.6 hadoop

# Update hadoop configuration
# Define the file path to core-site.xml
file_path="/$DIRNAME/hadoop/etc/hadoop/core-site.xml"

# Backup the original file
sudo cp "$file_path" "$file_path.backup"

# Write the new configuration
# If this doesn't work then try using <name>fs.default.name</name> instead?
sudo echo '<?xml version="1.0" encoding="UTF-8"?>
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

# Write hdfs-site.xml
file_path="/$DIRNAME/hadoop/etc/hadoop/hdfs-site.xml"
sudo mkdir -p /$DIRNAME/hadoop/data/namenode/
sudo mkdir -p /$DIRNAME/hadoop/data/datanode/
sudo echo '<configuration>
<property>
<name>dfs.namenode.name.dir</name>
<value>/'$DIRNAME'/hadoop/data/namenode/</value>
</property>
<property>
<name>dfs.datanode.data.dir</name>
<value>/'$DIRNAME'/hadoop/data/datanode/</value>
</property>
</configuration>' > "$file_path"

# Set JAVA_HOME
java_path=$(update-alternatives --display java | grep 'link currently points to' | awk '{print $5}')
JAVA_HOME=$(dirname $(dirname $java_path))

if [[ -z "$JAVA_HOME" ]]; then
    echo "JAVA_HOME could not be determined."
    exit 1
fi

hadoop_env_file="/$DIRNAME/hadoop/etc/hadoop/hadoop-env.sh"
sudo cp "$hadoop_env_file" "$hadoop_env_file.backup"
sudo sed -i "/^# export JAVA_HOME=/c\export JAVA_HOME=$JAVA_HOME" "$hadoop_env_file"

# Set all the users to root
sudo sed -i "/^# export HDFS_NAMENODE_USER=hdfs/c\export HDFS_NAMENODE_USER=\"root\"\nexport HDFS_DATANODE_USER=\"root\"\nexport HDFS_SECONDARYNAMENODE_USER=\"root\"\nexport YARN_RESOURCEMANAGER_USER=\"root\"\nexport YARN_NODEMANAGER_USER=\"root\"" "$hadoop_env_file"


# Set worker IP addresses
hadoop_workers_file="/$DIRNAME/hadoop/etc/hadoop/workers"
sudo cp "$hadoop_workers_file" "$hadoop_workers_file.backup"
echo "$WORKER1_IP" | sudo tee "$hadoop_workers_file"
echo "$WORKER2_IP" | sudo tee -a "$hadoop_workers_file"
echo "$WORKER3_IP" | sudo tee -a "$hadoop_workers_file"

# Shortcut to the hadoop bin and sbin directories
HBIN=/$DIRNAME/hadoop/bin
HSBIN=/$DIRNAME/hadoop/sbin
# fi

