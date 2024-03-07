generate_random_data() {
#   SIZE=$1
    # SIZE of 1MB
    SIZE=1048576
    dd if=/dev/urandom of=temp_file bs=$SIZE count=1
}

# Create a new file in HDFS
file_path="/write_read_append/test_file"
sudo hdfs dfs -mkdir -p /write_read_append
sudo hdfs dfs -touchz $file_path

# Write 100 MB to the file in distinct 1 MB writes
# We're appending here - is that right? 
start_time=$(date +%s%3N)
for ((i=1; i<=100; i++)); do
  # If i is a multiple of 10, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Write $i out of 100"
  fi
  generate_random_data 1M
  sudo hdfs dfs -appendToFile temp_file $file_path
done
end_time=$(date +%s%3N)
write_time=$((end_time - start_time))
echo "===== Write time (ms): $write_time"

# Read a randomly selected 2 MB region from the file, 25 times
file_size=$(sudo hdfs dfs -du -h $file_path | cut -f1)
start_time=$(date +%s%3N)
for ((i=1; i<=25; i++)); do
  # If i is a multiple of 5, print progress
  if [[ $((i % 5)) == 0 ]]; then
    echo "===== Read $i out of 25"
  fi
  offset=$((RANDOM % (file_size - 2)))
  sudo hdfs dfs -cat $file_path | dd bs=1M skip=$offset count=2 > /dev/null
done
end_time=$(date +%s%3N)
read_time=$((end_time - start_time))
echo "===== Read time (ms): $read_time"

# Record append 1 MB to the file, 50 times
start_time=$(date +%s%3N)
for ((i=1; i<=50; i++)); do
  # If i is a multiple of 10, print progress
  if [[ $((i % 10)) == 0 ]]; then
    echo "===== Append $i out of 50"
  fi
  generate_random_data 1M
  sudo hdfs dfs -appendToFile temp_file $file_path
done
end_time=$(date +%s%3N)
append_time=$((end_time - start_time))
echo "===== Append time (ms): $append_time"

# Clean up the temporary file
rm temp_file

# Log the timing information to a file
log_file="/tmp/log_benchmark_read_write_append.txt"
rm -f $log_file
echo "Write time (ms): $write_time" >> $log_file
echo "Read time (ms): $read_time" >> $log_file
echo "Append time (ms): $append_time" >> $log_file