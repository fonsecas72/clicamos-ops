#!/usr/bin/env bash
set -xe

# Install Node.js and npm (using NodeSource repository for a specific version if needed, but default should be fine for 22.04)
# curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
# sudo apt-get install -y nodejs

# For Ubuntu 22.04, nodejs and npm are available in default repositories.
# nodejs package might install /usr/bin/nodejs, some scripts might expect /usr/bin/node.
# Let's ensure both are available or use the correct one.
sudo apt-get update
sudo apt-get install -y git nodejs npm

# Create a symbolic link if `node` is not found but `nodejs` is.
# This is often needed for older scripts.
if ! command -v node &> /dev/null && command -v nodejs &> /dev/null; then
  sudo ln -s /usr/bin/nodejs /usr/bin/node
fi


sudo mkdir -p /srv/projectX/current

# It's better to use a non-root user for application files if possible,
# but for this script, we'll keep it as is, assuming $USER is 'ubuntu' or similar.
# If $USER is root, this chown is not strictly necessary here but doesn't harm.
sudo chown $USER:$USER /srv/projectX/current

# Clone the project as the $USER
sudo -u $USER git clone https://github.com/fonsecas72/clicamos-project.git /srv/projectX/current

# Install npm packages as $USER in the project directory
sudo -u $USER npm install --prefix /srv/projectX/current

# Ensure the ExecStart path for nodejs is correct.
# On Ubuntu 22.04, `nodejs` is typically at `/usr/bin/nodejs`.
# If `node` symlink was created, `/usr/bin/node` would also work.
# Let's use /usr/bin/nodejs to be explicit.
sudo bash -c 'cat > /etc/systemd/system/node_server.service <<EOF
[Unit]
Description=Node.js server

[Service]
Environment= PORT=80
WorkingDirectory=/srv/projectX/current
ExecStart=/usr/bin/nodejs /srv/projectX/current/iosocket.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF'

# The previous step wrote directly to /etc/systemd/system/node_server.service
# No need to cp and chown if written directly by root.
# sudo cp $(pwd)/node_server.service /etc/systemd/system/node_server.service
# sudo chown root:root /etc/systemd/system/node_server.service

sudo systemctl daemon-reload
sudo systemctl enable node_server.service
sudo systemctl start node_server.service

echo "END"
