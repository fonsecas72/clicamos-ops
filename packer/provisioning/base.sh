#!/usr/bin/env bash
set -xe

# update packages
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# install base packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y vim curl python3-pip  # Added python3-pip for ec2metadata

# Install ec2metadata
sudo pip3 install ec2metadata

# hostname scripts
sudo bash -c 'cat << "EOF" > /opt/update_hostname.sh
#!/bin/bash
name="$(ec2metadata --instance-id 2>/dev/null)"
if [ "$name" != "" ]; then
  echo "writing hostname $name"
  echo -n $name > /etc/hostname
  echo "127.0.0.1 $name localhost" > /etc/hosts
else
  echo "ec2metadata not found"
fi

hostname -b -F /etc/hostname
EOF'

# The following Upstart configuration is legacy and not needed for Ubuntu 22.04+
# It has been removed.
# sudo bash -c 'cat << "EOF" > /etc/init/hostname.conf
# description     "set system hostname"
#
# start on startup
#
# pre-start script
#   bash /opt/update_hostname.sh
# end script
# EOF'

# For Ubuntu 22.04 and 24.04, Upstart is replaced by systemd.
# We'll create a systemd service for hostname update.
sudo bash -c 'cat << "EOF" > /etc/systemd/system/hostname-update.service
[Unit]
Description=Set system hostname from EC2 metadata
After=network.target

[Service]
Type=oneshot
ExecStart=/opt/update_hostname.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF'

sudo chmod 0755 /opt/update_hostname.sh
sudo chmod 0644 /etc/systemd/system/hostname-update.service

# Run the script immediately to set hostname
sudo /opt/update_hostname.sh

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable hostname-update.service
sudo systemctl start hostname-update.service
