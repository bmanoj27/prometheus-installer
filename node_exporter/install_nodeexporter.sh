#!/bin/bash

mkdir /tmp/node_exporter && cd /tmp/node_exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.10.2/node_exporter-1.10.2.linux-amd64.tar.gz

tar -xzf node_exporter-*.linux-amd64.tar.gz
cd node_exporter-*linux-amd64/

useradd --no-create-home --shell /bin/false node_exporter

cp node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

mkdir /etc/node_exporter
touch /etc/node_exporter/config.yml
chown -R node_exporter:node_exporter /etc/node_exporter/

cat << EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter --web.config.file=/etc/node_exporter/config.yml

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now node_exporter

echo -e "\nNode Exporter installation completed."
