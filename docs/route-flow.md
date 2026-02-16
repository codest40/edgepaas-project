```text

EdgePaaS Blue-Green Traffic Flow
----------------------------
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
       | 8080:80                   | 8001:80
       |                           |
       +---------------------------+


EdgePaaS Request Flow Explanation

1. Browser → Nginx
- All requests from the internet hit port 80 on the EC2 host.
- Nginx is the traffic authority, always running, and managed by Ansible.
- No container ever exposes port 80 publicly.

2. Nginx → Active Container
- Nginx forwards traffic to the active host port (blue=8080, green=8081).
- The active port is determined by Ansible during deploy.
- nginx configuration template uses:
  ```nginx
  proxy_pass http://127.0.0.1:{{ active_port }};
  ```
```
3. Docker Host Port → Container Port
- Docker maps host port to container internal port 80.
- The FastAPI app inside the container only knows its internal port — it does not care about blue/green.

4. Health Checks Before Switch
- Ansible runs HTTP and port checks before switching active traffic.
- If health checks fail, nginx is not updated and the old container keeps serving requests.

5. Traffic Switch (Zero-Downtime)
- After success:
  - Ansible updates nginx config with new active port.
  - nginx reloads gracefully.
- Traffic instantly flows to the new version.

6. Old Container as Rollback
- The inactive container stays alive as a rollback target.
- Switching back is instant if the new version fails.

7. Response → Browser
- Container → Docker → Nginx → Internet → Browser.

Key Notes

- Nginx is essential for blue-green deployment and zero-downtime.
- Ansible controls which port is active.
- Docker containers are stateless and only serve the app.
- CI/CD pipelines never mutate nginx directly — only Ansible does.
```
