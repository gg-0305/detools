# Base image with Ubuntu 18.04
FROM ubuntu:18.04

# Update the package list and install necessary dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    openjdk-8-jdk \
    python3 \
    python3-pip \
    ssh \
    python3-setuptools \
    rsync \
    vim \
    gcc \
    python3-dev \
    openssh-server \
    jupyter-notebook \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
RUN echo "detools ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/detools
ENV HOME=/home/detools
RUN useradd -rm -d $HOME -s /bin/bash -g root -G sudo -u 1001 detools
USER detools
WORKDIR /home/detools
RUN mkdir -p $HOME/installations

ENV JAVA_HOME=/usr
ENV INSTALLATION_DIR=$HOME/installations
ENV HADOOP_VERSION=2.8.5
ENV SPARK_VERSION=2.4.5
ENV HIVE_VERSION=2.3.6
ENV SQOOP_VERSION=1.4.7
ENV HADOOP_HOME=$INSTALLATION_DIR/hadoop
ENV SPARK_HOME=$INSTALLATION_DIR/spark
ENV HIVE_HOME=$INSTALLATION_DIR/hive
ENV SQOOP_HOME=$INSTALLATION_DIR/sqoop
ENV PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$HIVE_HOME/bin:$SQOOP_HOME/bin
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop

# Install Hadoop

RUN wget https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/hadoop-$HADOOP_VERSION.tar.gz -P $INSTALLATION_DIR && \
    tar -xzf $INSTALLATION_DIR/hadoop-$HADOOP_VERSION.tar.gz -C $INSTALLATION_DIR/ && \
    rm $INSTALLATION_DIR/hadoop-$HADOOP_VERSION.tar.gz && \
    ln -s $INSTALLATION_DIR/hadoop-$HADOOP_VERSION $HADOOP_HOME

# Install Spark
RUN wget https://archive.apache.org/dist/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop2.7.tgz -P $INSTALLATION_DIR && \
    tar -xzf $INSTALLATION_DIR/spark-$SPARK_VERSION-bin-hadoop2.7.tgz -C $INSTALLATION_DIR/ && \
    rm $INSTALLATION_DIR/spark-$SPARK_VERSION-bin-hadoop2.7.tgz && \
    ln -s $INSTALLATION_DIR/spark-$SPARK_VERSION-bin-hadoop2.7 $SPARK_HOME

# Install Hive
RUN wget https://archive.apache.org/dist/hive/hive-$HIVE_VERSION/apache-hive-$HIVE_VERSION-bin.tar.gz -P $INSTALLATION_DIR && \
    tar -xzf $INSTALLATION_DIR/apache-hive-$HIVE_VERSION-bin.tar.gz -C $INSTALLATION_DIR/ && \
    rm $INSTALLATION_DIR/apache-hive-$HIVE_VERSION-bin.tar.gz && \
    ln -s $INSTALLATION_DIR/apache-hive-$HIVE_VERSION-bin $HIVE_HOME

# Install Sqoop
RUN wget https://archive.apache.org/dist/sqoop/$SQOOP_VERSION/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz -P $INSTALLATION_DIR && \
    tar -xzf $INSTALLATION_DIR/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz -C $INSTALLATION_DIR/ && \
    rm $INSTALLATION_DIR/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0.tar.gz && \
    ln -s $INSTALLATION_DIR/sqoop-$SQOOP_VERSION.bin__hadoop-2.6.0 $SQOOP_HOME

# Install Mysql Jar
RUN wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-8.1.0.tar.gz -P $INSTALLATION_DIR && \
    tar -xzf $INSTALLATION_DIR/mysql-connector-j-8.1.0.tar.gz -C $INSTALLATION_DIR/ && \
    rm $INSTALLATION_DIR/mysql-connector-j-8.1.0.tar.gz && \
    ln -s $INSTALLATION_DIR/mysql-connector-j-8.1.0/mysql-connector-j-8.1.0.jar ${SQOOP_HOME}/lib/
# COPY --chown=detools:detools  configs


COPY conf/ipython_kernel_config.py /root/.ipython/profile_default/ipython_kernel_config.py
COPY --chown=detools:detools  conf/core-site.xml $HADOOP_HOME/etc/hadoop/core-site.xml
COPY --chown=detools:detools  conf/hdfs-site.xml $HADOOP_HOME/etc/hadoop/hdfs-site.xml
COPY --chown=detools:detools  conf/yarn-site.xml $HADOOP_HOME/etc/hadoop/yarn-site.xml 
COPY --chown=detools:detools  conf/mapred-site.xml $HADOOP_HOME/etc/hadoop/mapred-site.xml 
COPY --chown=detools:detools  conf/hadoop-env.sh $HADOOP_HOME/etc/hadoop/hadoop-env.sh
COPY --chown=detools:detools  conf/hive-env.sh ${HIVE_HOME}/conf
COPY --chown=detools:detools  conf/hive-site.xml ${HIVE_HOME}/conf
COPY --chown=detools:detools  conf/spark-defaults.conf ${SPARK_HOME}/conf
COPY --chown=detools:detools  start-services.sh $INSTALLATION_DIR/start-services.sh
RUN mkdir -p ${HOME}/notebooks/
COPY --chown=detools:detools  sample_notebook.ipynb $INSTALLATION_DIR/sample_notebook.ipynb

RUN chmod 755 $INSTALLATION_DIR/start-services.sh 

USER root
RUN ln -s /usr/bin/python3 /usr/bin/python
USER detools

RUN ssh-keygen -t rsa -P '' -f $HOME/.ssh/id_rsa
RUN cat ~/.ssh/id_rsa.pub >> $HOME/.ssh/authorized_keys
RUN chmod 0600 $HOME/.ssh/authorized_keys


RUN python3 -m pip install findspark
# Expose ports for Hadoop and Spark (optional)
EXPOSE 8888 50070 7077 10000 9000 22 9083 1527 4040 8080 8042

WORKDIR /home/detools
ENTRYPOINT [ "sh", "/home/detools/installations/start-services.sh" ]
