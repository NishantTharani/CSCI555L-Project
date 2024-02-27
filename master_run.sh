DIRNAME=data
HBIN=/$DIRNAME/hadoop/bin
HSBIN=/$DIRNAME/hadoop/sbin

# Format the namenode
sudo $HBIN/hdfs namenode -format

# Start the master node and all data nodes
sudo $HSBIN/start-dfs.sh