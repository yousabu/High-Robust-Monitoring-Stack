#!/bin/bash

# Update and install necessary packages
sudo apt update
sudo apt install -y openjdk-11-jdk wget

# Add kafka user and add to sudo group
sudo adduser --disabled-password --gecos "" kafka
sudo usermod -aG sudo kafka

# Switch to kafka user
su -l kafka

# Create a downloads directory and download Kafka
mkdir ~/downloads
cd ~/downloads
wget https://archive.apache.org/dist/kafka/3.4.0/kafka_2.12-3.4.0.tgz

# Extract Kafka and move to home directory
cd ~
tar -xvzf ~/downloads/kafka_2.12-3.4.0.tgz
mv kafka_2.12-3.4.0 kafka

# Create Zookeeper systemd service
sudo tee /etc/systemd/system/zookeeper.service > /dev/null << EOF
[Unit]
Description=Apache Zookeeper Service
Requires=network.target
After=network.target

[Service]
Type=simple
User=kafka
ExecStart=/home/kafka/kafka/bin/zookeeper-server-start.sh /home/kafka/kafka/config/zookeeper.properties
ExecStop=/home/kafka/kafka/bin/zookeeper-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Create Kafka systemd service
sudo tee /etc/systemd/system/kafka.service > /dev/null << EOF
[Unit]
Description=Apache Kafka Service that requires zookeeper service
Requires=zookeeper.service
After=zookeeper.service

[Service]
Type=simple
User=kafka
ExecStart=/home/kafka/kafka/bin/kafka-server-start.sh /home/kafka/kafka/config/server.properties
ExecStop=/home/kafka/kafka/bin/kafka-server-stop.sh
Restart=on-abnormal

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to apply new services
sudo systemctl daemon-reload

# Start Zookeeper and Kafka services
sudo systemctl start zookeeper
sudo systemctl start kafka

# Enable the services to start on boot
sudo systemctl enable zookeeper
sudo systemctl enable kafka

# Check Kafka status and connectivity
sudo systemctl status kafka
nc -vz localhost 9092
cat ~/kafka/logs/server.log

# Create a Kafka topic
~/kafka/bin/kafka-topics.sh --bootstrap-server localhost:9092 --create --topic firstTopic

# List all Kafka topics
~/kafka/bin/kafka-topics.sh --list --bootstrap-server localhost:9092

# Produce messages to the topic
echo "Type your messages and press Ctrl+C to exit"
~/kafka/bin/kafka-console-producer.sh --bootstrap-server localhost:9092 --topic firstTopic

# Consume messages from the topic
~/kafka/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic firstTopic --from-beginning
