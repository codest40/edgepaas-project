==============================================================
EDGEPaaS MONITORING SYSTEM – FULL DOCUMENTATION
==============================================================


1️⃣ OVERVIEW
--------------------------------------------------------------

The EdgePaaS monitoring stack is built using:

• Prometheus       → Metrics collection & storage
• Grafana          → Dashboards & visualization
• Node Exporter    → Host-level metrics
• FastAPI metrics  → Application-level observability


Provides:

• Infrastructure monitoring (CPU, memory, disk)
• Application monitoring (requests, latency, business metrics)
• Dynamic service discovery (file-based targets)



--------------------------------------------------------------
2️⃣ ARCHITECTURE
--------------------------------------------------------------

                ┌────────────────────┐
                │   FastAPI App      │
                │  /metrics endpoint │
                └─────────┬──────────┘
                          │
                ┌─────────▼──────────┐
                │    Prometheus      │
                │  (scrapes metrics) │
                └─────────┬──────────┘
                          │
        ┌─────────────────┴─────────────────┐
        │                                   │
┌───────▼────────┐                 ┌────────▼────────┐
│ Node Exporter  │                 │ File SD Targets │
│ (host metrics) │                 │ dynamic configs │
└────────────────┘                 └─────────────────┘
                          │
                ┌─────────▼──────────┐
                │      Grafana       │
                │   Dashboards UI    │
                └────────────────────┘



--------------------------------------------------------------
3️⃣ PROMETHEUS CONFIGURATION
--------------------------------------------------------------

File:

monitoring/prometheus/prometheus.yml


CORE CONFIGURATION
--------------------------------------------------------------

global:
  scrape_interval: 15s



--------------------------------------------------------------
DYNAMIC APP DISCOVERY
--------------------------------------------------------------

- job_name: "edgepaas_apps"
  metrics_path: /metrics
  file_sd_configs:
    - files:
        - /etc/prometheus/targets/*.json


Example target:

[
  {
    "targets": ["fastapi:8090"],
    "labels": {
      "service": "fastapi"
    }
  }
]



--------------------------------------------------------------
NODE EXPORTER INTEGRATION
--------------------------------------------------------------

- job_name: "node_exporter"
  file_sd_configs:
    - files:
        - /etc/prometheus/targets/node.yml



--------------------------------------------------------------
4️⃣ GRAFANA PROVISIONING
--------------------------------------------------------------

DATASOURCE CONFIGURATION
--------------------------------------------------------------

File:

grafana/provisioning/datasources/datasources.yml

- name: Prometheus
  url: http://prometheus:9090
  isDefault: true



DASHBOARD AUTO-LOADING
--------------------------------------------------------------

File:

grafana/provisioning/dashboards/dashboards.yml

providers:
  - name: EdgePaaS
    options:
      path: /var/lib/grafana/dashboards



--------------------------------------------------------------
5️⃣ DASHBOARDS
--------------------------------------------------------------


FASTAPI DASHBOARD
--------------------------------------------------------------

File:

fastapi.json


Tracks:

SYSTEM METRICS
• CPU usage          → cpu_percent
• Memory usage       → memory_percent
• Disk usage         → disk_percent


APPLICATION METRICS
• Active users                → active_users
• Total requests             → weather_requests_total
• Failed requests            → failed_weather_requests_total
• Business actions           → preferences_saved_total


LATENCY METRICS
--------------------------------------------------------------

request_latency_seconds_sum
/
request_latency_seconds_count



--------------------------------------------------------------
NODE EXPORTER DASHBOARD
--------------------------------------------------------------

File:

node_exporter.json


Tracks:

• CPU usage
• Memory usage
• Disk I/O
• Network traffic



--------------------------------------------------------------
6️⃣ SUMMARY
--------------------------------------------------------------

• Prometheus collects and stores metrics
• Node Exporter provides host-level metrics
• FastAPI exposes application metrics
• File-based service discovery enables dynamic targets
• Grafana provides visualization and dashboards


==============================================================
END OF MONITORING DOCUMENTATION
==============================================================
