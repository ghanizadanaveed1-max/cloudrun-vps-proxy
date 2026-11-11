# Cloud Run -> VPS Proxy (SSH-WS + V2Ray / VLESS / VMess / Trojan)

Nginx reverse proxy on Cloud Run that forwards WebSocket traffic to your VPS (217.60.6.102).

| Path      | Protocol                | VPS port (default) |
|-----------|-------------------------|--------------------|
| `/`       | SSH over WebSocket      | 80                 |
| `/vray`   | V2Ray/Xray (any proto)  | 8080               |
| `/vless`  | VLESS WS                | 8081               |
| `/vmess`  | VMess WS                | 8082               |
| `/trojan` | Trojan WS               | 8083               |
| `/health` | Health check            | -                  |

## Quick copy
Replace `REPO` with your GitHub repo name, then paste in Cloud Shell:

```bash

rm -rf cloudrun-vps-proxy && \
git clone https://github.com/ghanizadanaveed1-max/cloudrun-vps-proxy.git && \
cd cloudrun-vps-proxy && \
gcloud services enable \
  run.googleapis.com \
  cloudbuild.googleapis.com \
  artifactregistry.googleapis.com && \
gcloud run deploy vps-proxy \
  --source . \
  --region us-east1 \
  --platform managed \
  --allow-unauthenticated \
  --port 8080 \
  --cpu 1 \
  --memory 256Mi \
  --concurrency 1000 \
  --min-instances 0 \
  --max-instances 3 \
  --timeout 3600 \
  --cpu-boost \
  --session-affinity \
  --set-env-vars="VPS_HOST=217.60.6.102,SSH_WS_PORT=80,V2RAY_PORT=8080,VLESS_PORT=8081,VMESS_PORT=8082,TROJAN_PORT=8083"
8083
```

## One-click script (prints client settings at the end)
```bash
bash deploy.sh
```
Override: `SERVICE=ghanizada3 REGION=europe-west1 SSH_WS_PORT=8880 V2RAY_PORT=10000 bash deploy.sh`

## Test after deploy
```bash
bash check.sh your-service-xxxx.a.run.app
```
`101` = tunnel works, `502/504` = VPS port closed or wrong.

## Client settings
- Address/SNI/Host: `your-service-xxxx.a.run.app`, Port `443`, TLS on
- V2Ray family: network `ws`, path `/vray` (or `/vless`, `/vmess`, `/trojan`)
- VPS inbound: listen on the matching port, transport `ws`, same path, **TLS off**
- SSH-WS payload example:
  `GET / HTTP/1.1[crlf]Host: your-service-xxxx.a.run.app[crlf]Upgrade: websocket[crlf][crlf]`

## GitHub Actions (optional)
Secrets: `GCP_SA_KEY`, `GCP_REGION`. Optional: `VPS_HOST`, `SSH_WS_PORT`, `V2RAY_PORT`, `VLESS_PORT`, `VMESS_PORT`, `TROJAN_PORT`.
Roles: Cloud Run Admin, Service Account User, Cloud Build Editor, Artifact Registry Writer, Storage Admin.

## Notes
- Cloud Run supports HTTP/WebSocket/gRPC only (no raw TCP/UDP, no Reality/XTLS).
- Open the VPS ports in the firewall.
- Connections are cut after 60 minutes; clients must reconnect.
- `--min-instances 0` saves cost; set `1` to avoid cold starts.
