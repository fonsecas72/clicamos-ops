#!/usr/bin/env bash
set -xe

# Install Node.js and npm.
# For Ubuntu 22.04/24.04 LTS, nodejs and npm are available in default repositories.
# Using default repositories is generally preferred for simplicity unless a very specific Node version is required.
# If a specific version like Node.js 18.x, 20.x or 22.x were needed, you might use NodeSource:
# curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
# sudo apt-get install -y nodejs

# The `nodejs` package might install the binary as `/usr/bin/nodejs`.
# Some scripts or tools might expect `/usr/bin/node`.
# The following lines ensure that `npm` and `git` are installed,
# and later, a symlink is created if `node` is not found but `nodejs` is.
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
# On Ubuntu 22.04/24.04, `nodejs` (if installed from default repos) is typically at `/usr/bin/nodejs`.
# The `node` symlink created earlier would make `/usr/bin/node` also work.
# Using `/usr/bin/nodejs` in the service file is explicit and reliable.
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
