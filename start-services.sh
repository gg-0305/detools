#!/bin/bash
sudo /etc/init.d/ssh start
ssh-keygen -R localhost
ssh-keygen -R 0.0.0.0
ssh-keygen -R localhost,0.0.0.0
ssh-keyscan -H localhost,0.0.0.0 >> ~/.ssh/known_hosts
ssh-keyscan -H 0.0.0.0 >> ~/.ssh/known_hosts
ssh-keyscan -H localhost >> ~/.ssh/known_hosts
hdfs namenode -format -nonInteractive
start-dfs.sh
start-yarn.sh

hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -mkdir -p /user/detools
hdfs dfs -chmod g+w /tmp
hdfs dfs -chmod g+w /user/hive/warehouse
hdfs dfs -chmod g+w /user/detools

schematool -dbType derby -initSchema
# Start Spark

$SPARK_HOME/sbin/start-all.sh
jupyter notebook --ip 0.0.0.0 --port 8888 --no-browser

# while true; do sleep 1; done