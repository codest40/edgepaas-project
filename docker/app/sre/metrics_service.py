from prometheus_client import Counter, Histogram

# Counters
weather_requests_total = Counter(
    "weather_requests_total", "Total number of weather requests"
)

preferences_saved_total = Counter(
    "preferences_saved_total", "Total number of preferences saved"
)

# Optional: measure request latency
request_latency_seconds = Histogram(
    "request_latency_seconds", "Time spent processing requests"
)

