generate_random_data() {
  rm -f temp_file
  BS=$((1048576*$1))
  dd if=/dev/urandom of=temp_file bs=$BS count=1
}

# Read parameters from user input
read -p "Enter the size of each file that you set up the read experiment with in MB: " READ_SETUP_SIZE
read -p "Enter the number of files that you set up the read experiment with: " READ_SETUP_COUNT
read -p "Enter the number of times to randomly read a file: " READ_COUNT

# Read the name of this node from /tmp/name.txt
node_name=$(cat /tmp/name.txt)

# This should match from read_setup.sh
file_path="/read/read_file"

# Read a randomly selected file from the ones we setup
start_time=$(date +%s%3N)
for ((i=0; i<$READ_COUNT; i++)); do
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Read $i out of $READ_COUNT"
  fi
  sudo hdfs dfs -cat $file_path"_"$((RANDOM % $READ_SETUP_COUNT)) > /dev/null
done
end_time=$(date +%s%3N)
read_time=$((end_time - start_time))
echo "===== Read time (ms): $read_time"

# Log the timing information to a file
log_file="/tmp/log_benchmark_read.txt"
echo "Read time (ms): $read_time" >> $log_file
echo "Read total amount (MB): $(($READ_COUNT * $READ_SETUP_SIZE))" >> $log_file
echo "Read throughput (MB/s): $(($READ_COUNT * $READ_SETUP_SIZE * 1000 / $read_time))" >> $log_file