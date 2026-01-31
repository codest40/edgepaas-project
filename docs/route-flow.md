# ----------------------------
# EdgePaaS Blue-Green Traffic Flow
# ----------------------------

```bash
Internet (browser)
       |
       v
+-------------------+
|       Nginx        |  <-- listens on EC2 host port 80
+-------------------+
       |
       |  proxy_pass http://127.0.0.1:<active_host_port>
       |
+-------------------+           +-------------------+
| Blue Container    |           | Green Container   |
| Host Port 8080    |           | Host Port 8081    |
| Container Port 80 |           | Container Port 80 |
+-------------------+           +-------------------+
       ^                           ^
       | Docker port mapping       | Docker port mapping
       | 8080:80                   | 8081:80
       |                           |
       +---------------------------+


# Explanation of flow:

##  Browser → Nginx

All requests from the internet hit port 80 on the EC2 host where Nginx is listening.

Nginx → Active Container

Nginx forwards requests to the active host port (8080 for blue, 8081 for green) based on our blue-green routing rules.

Host Port → Container Port

Docker maps the host port to the container’s internal port 80, where our FastAPI serves the app.


##  Response → Browser

Container responds → Docker → Nginx → Internet → Browser.

```

