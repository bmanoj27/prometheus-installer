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

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl start prometheus
systemctl enable prometheus 





