#! /bin/bash

# install dependencies
apt update
apt install -y ssh rsync

# configure and run ssh
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/id_rsa
chmod 700 /root/.ssh/authorized_keys
mkdir /var/run/sshd
echo 'root:screencast' | chpasswd
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/Port 22/Port 3022/' /etc/ssh/sshd_config
sed -i 's/#   Port 22/  Port 3022/' /etc/ssh/ssh_config
sed -i 's/#   StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config

# SSH login fix. Otherwise user is kicked off after login
sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

/usr/sbin/sshd

# install and configure hadoop
mkdir /home/hadoop-2.8.2
curl http://apache.claz.org/hadoop/common/hadoop-2.8.2/hadoop-2.8.2.tar.gz | tar -xz -C /home

export HADOOP_HOME=/home/hadoop-2.8.2
echo 'export HADOOP_HOME=/home/hadoop-2.8.2' >> ~/.bashrc

export HADOOP_CONF_DIR=/home/hadoop-2.8.2/etc/hadoop
echo 'export HADOOP_CONF_DIR=/home/hadoop-2.8.2/etc/hadoop' >> ~/.bashrc

export PATH=$PATH:$HADOOP_HOME/bin
echo 'export PATH=$PATH:$HADOOP_HOME/bin' >> ~/.bashrc

echo '<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://'$MASTER_IP':8020</value>
    </property>
</configuration>' > $HADOOP_HOME/etc/hadoop/core-site.xml

echo '<?xml version="1.0" encoding="UTF-8"?>
    <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
    <configuration>
        <property>
            <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
            <value>false</value>
        </property>
    </configuration>' > $HADOOP_HOME/etc/hadoop/hdfs-site.xml

# run HDFS
if [ $IS_MASTER -eq "1" ]; then
    echo 'starting namenode and datanode'
    hdfs namenode -format
    $HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start namenode
    $HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
else
    echo 'starting datanode'
    echo '<?xml version="1.0" encoding="UTF-8"?>
    <?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
    <configuration>
        <property>
            <name>dfs.namenode.datanode.registration.ip-hostname-check</name>
            <value>false</value>
        </property>
    </configuration>' > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
    $HADOOP_HOME/sbin/hadoop-daemon.sh --config $HADOOP_CONF_DIR --script hdfs start datanode
fi