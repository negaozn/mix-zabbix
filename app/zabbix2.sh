#!/bin/bash

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Define variables
ZABBIX_VERSION="5.4"
MYSQL_ROOT_PASSWORD="admin"
ZABBIX_DB_USER="zabbix"
ZABBIX_DB_PASSWORD="your_zabbix_db_password"
ZABBIX_SERVER_NAME="zabbix_server"

# Update and install prerequisites
apt update
apt install -y software-properties-common
add-apt-repository universe
apt update

# Install MySQL server and set root password
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $MYSQL_ROOT_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $MYSQL_ROOT_PASSWORD"
apt install -y mysql-server

# Install Zabbix Server and frontend
wget https://repo.zabbix.com/zabbix/$ZABBIX_VERSION/ubuntu/pool/main/z/zabbix-release/zabbix-release_$ZABBIX_VERSION-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_$ZABBIX_VERSION-1+ubuntu20.04_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-agent

# Create Zabbix database
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "create database zabbix character set utf8 collate utf8_bin;"
mysql -uroot -p$MYSQL_ROOT_PASSWORD -e "grant all privileges on zabbix.* to $ZABBIX_DB_USER@localhost identified by '$ZABBIX_DB_PASSWORD';"
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u $ZABBIX_DB_USER -p$ZABBIX_DB_PASSWORD zabbix

# Configure Zabbix Server
sed -i 's/# DBPassword=/DBPassword='$ZABBIX_DB_PASSWORD'/' /etc/zabbix/zabbix_server.conf

# Configure PHP for Zabbix frontend
sed -i 's/max_execution_time = 30/max_execution_time = 300/' /etc/php/7.4/apache2/php.ini
sed -i 's/max_input_time = 60/max_input_time = 300/' /etc/php/7.4/apache2/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 16M/' /etc/php/7.4/apache2/php.ini
sed -i 's/max_input_vars = 1000/max_input_vars = 3000/' /etc/php/7.4/apache2/php.ini
systemctl restart apache2

# Start Zabbix Server and Agent
systemctl restart zabbix-server
systemctl restart zabbix-agent

# Enable Zabbix Server and Agent to start on boot
systemctl enable zabbix-server
systemctl enable zabbix-agent

# Display information
echo "Zabbix Server is installed and configured."
echo "Web Interface: http://your_server_ip/zabbix"
echo "Default Username: Admin"
echo "Default Password: zabbix"

# Clean up
rm -f zabbix-release_$ZABBIX_VERSION-1+ubuntu20.04_all.deb
