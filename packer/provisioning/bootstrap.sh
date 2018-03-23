#!/usr/bin/env bash
set -xe

sudo apt-get install -y git nodejs npm

sudo mkdir -p /srv/projectX/current

sudo chown $USER /srv/projectX/current

git clone https://github.com/fonsecas72/clicamos-project.git /srv/projectX/current

npm install --prefix /srv/projectX/current /srv/projectX/current

sudo cat > node_server.service <<EOF
[Unit]
Description=Node.js server

[Service]
Environment= PORT=80
WorkingDirectory=/srv/projectX/current
ExecStart=/usr/bin/nodejs /srv/projectX/current/iosocket.js
Restart=always

[Install]
WantedBy=multi-user.target

EOF

sudo cp $(pwd)/node_server.service /etc/systemd/system/node_server.service
sudo chown root:root /etc/systemd/system/node_server.service

sudo systemctl daemon-reload
sudo systemctl enable node_server.service
sudo systemctl start node_server.service

echo "END"
