# Securing Node Exporter with Basic Authentication and TLS

This guide explains how to enable **Basic Authentication** and **TLS encryption** for `node_exporter`, and how to configure Prometheus to scrape it securely.

---

# 🧩 1. Enable Basic Authentication for Node Exporter

### Step 1: Generate a bcrypt password hash

**Ubuntu/Debian:**
```bash
apt install apache2-utils
```

Generate a bcrypt hash:
```bash
htpasswd -nBC 12 ""
```

Example output:
```
$2y$12$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### Step 2: Update `/etc/node_exporter/config.yml`

```yaml
basic_auth_users:
  prometheus: "$2y$12$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  # user2: "$2y$12$hashhere"
```

### Step 3: Restart Node Exporter

```bash
systemctl restart node_exporter
```

---

# 🧩 2. Update Prometheus to Use Basic Authentication

Add this to `prometheus.yml`:

```yaml
- job_name: "node_exporter"
  basic_auth:
    username: "prometheus"
    password: "P@ssw0rd"
  static_configs:
    - targets: ["localhost:9100"]
      labels:
        app: "node_scrape"
```

Restart Prometheus afterward.

---

# 🔐 3. Enable TLS for Node Exporter

### Step 1: Generate TLS certificate

```bash
openssl req \
  -new -newkey rsa:2048 -days 3650 -nodes -x509 \
  -keyout node_exporter.key \
  -out node_exporter.crt \
  -addext "subjectAltName = DNS:localhost"
```

Fix permissions if needed:

```bash
chown node_exporter:node_exporter node_exporter.crt node_exporter.key
chmod 600 node_exporter.key
```

### Step 2: Update `/etc/node_exporter/config.yml`

```yaml
tls_server_config:
  cert_file: /etc/node_exporter/node_exporter.crt
  key_file: /etc/node_exporter/node_exporter.key
```

Restart Node Exporter:

```bash
systemctl restart node_exporter
```

---

# 🔐 4. Update Prometheus to Scrape via HTTPS

Copy certificate to Prometheus server:

```bash
cp node_exporter.crt /etc/prometheus/node_exporter.crt
chown prometheus:prometheus /etc/prometheus/node_exporter.crt
```

Update Prometheus job:

```yaml
- job_name: "node_exporter"
  scheme: "https"
  tls_config:
    ca_file: /etc/prometheus/node_exporter.crt
    insecure_skip_verify: true
  basic_auth:
    username: "prometheus"
    password: "P@ssw0rd"
  static_configs:
    - targets: ["localhost:9100"]
```

Restart Prometheus.

---

# ✅ Summary

| Feature | Node Exporter Config | Prometheus Config |
|---------|----------------------|-------------------|
| Basic Auth | `basic_auth_users` | `basic_auth` |
| TLS | `tls_server_config` | `scheme: https` + `tls_config` |

With Basic Auth + TLS:
- Node Exporter is secured against unauthorized access  
- Prometheus-to-node_exporter traffic is encrypted  
- Credentials and metrics are protected  

---

# ✔ Troubleshooting Tips

- Ensure your node_exporter version supports `--web.config.file` (v1.5.0+)
- Key file must have restrictive permissions (`chmod 600`)
- Test manually:

```bash
curl -k https://localhost:9100/metrics
```

