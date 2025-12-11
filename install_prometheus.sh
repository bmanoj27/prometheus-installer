#!/bin/bash
# This script installs Prometheus on a Linux system with node_exporter metrics.

mkdir -p /tmp/prometheus && cd /tmp/prometheus

URL=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest \
      | grep browser_download_url \
      | grep linux-amd64.tar.gz \
      | cut -d '"' -f 4)

echo "Latest Prometheus URL: $URL"

wget -q $URL

if [[ $? != 0 ]] || [ -z "$URL" ]; then
    echo "Failed to fetch the latest Prometheus release URL. Falling back to version 3.8.0."
    wget -q https://github.com/prometheus/prometheus/releases/download/v3.8.0/prometheus-3.8.0.linux-amd64.tar.gz
fi

tar -xzf prometheus-*.linux-amd64.tar.gz
cd prometheus-*linux-amd64/

useradd --no-create-home --shell /bin/false prometheus
mkdir /etc/prometheus
mkdir /var/lib/prometheus
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus

cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool

cp prometheus.yml /etc/prometheus/
chown prometheus:prometheus /etc/prometheus/prometheus.yml

cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/
# --web.console.templates=/etc/prometheus/consoles \
# --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF

# Creating sample rules
mkdir /etc/prometheus/rules
cat << EOF > /etc/prometheus/rules/first_rule.yml
#Rules have to separated by job, specific job rules go into their own files
#This file contains example rules for node exporter metrics
#update prometheus.yml to include this file under 'rule_files' section
groups:
  - name: example
    interval: 30s
    rules:
      - record: node_memory_memFree_percent
        expr: round(100 - (100 * node_memory_MemFree_bytes / node_memory_MemTotal_bytes ), 0.01)
      - record: node_filesystem_free_percent
        expr: round(100 * node_filesystem_free_bytes / node_filesystem_size_bytes, 0.01)
      - record: node_filesystem_free_percent_avg
        expr: avg by(instance) (node_filesystem_free_percent) #using the second record here,since it is sequential
EOF

chown -R prometheus:prometheus /etc/prometheus/rules

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus 

#Installing Alert Manager
cd /tmp
wget https://github.com/prometheus/alertmanager/releases/download/v0.29.0/alertmanager-0.29.0.linux-amd64.tar.gz
# Note: You might encounter an SSL certificate issue:
tar xzf alertmanager-0.29.0.linux-amd64.tar.gz
cd alertmanager-0.29.0.linux-amd64

sudo useradd --no-create-home --shell /bin/false alertmanager

sudo mkdir /etc/alertmanager
sudo mv alertmanager.yml /etc/alertmanager
sudo chown -R alertmanager:alertmanager /etc/alertmanager

sudo mkdir /var/lib/alertmanager
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager

sudo cp alertmanager /usr/local/bin
sudo chown alertmanager:alertmanager /usr/local/bin/alertmanager
sudo chown alertmanager:alertmanager /usr/local/bin/amtool

cat << EOF > /etc/systemd/system/alertmanager.service
[Unit]
Description=Alert Manager
Wants=network-online.target
After=network-online.target


[Service]
Type=simple
User=alertmanager
Group=alertmanager
ExecStart=/usr/local/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start alertmanager
sudo systemctl enable alertmanager

#Update the Prometheus configuration located at /etc/prometheus/prometheus.yml to point to the new AlertManager endpoint at localhost:9093