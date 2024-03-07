# CSCI555L-Project

Instantiate the Cloudlab profile based on this repo

Run `sudo master_run.sh` on the master

- Or if that doesn't work, run these two on the master
  - `sudo /data/hadoop/bin/hdfs namenode -format`
  - `sudo /data/hadoop/sbin/start-dfs.sh`

Then HDFS will be running. Go to the master's hostname checkhealth page eg http://master.ntharani-195400.advancedosproj-pg0.utah.cloudlab.us:9870/dfshealth.html#tab-overview , replacing the hostname with the URL output by `hostname` on the master.

Maybe need to `source ~/.bashrc` on the client

You can then run commands on the client eg `sudo hdfs dfs -mkdir /hadoop`

Copy a benchmark from `client_benchmarks` to the home folder on the client, and run it.
