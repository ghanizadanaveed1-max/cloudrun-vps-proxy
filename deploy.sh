#!/usr/bin/env bash
# One-click deploy to Google Cloud Run (SSH-WS + V2Ray/VLESS/VMess/Trojan WS)
# Usage: bash deploy.sh
# Override: SERVICE=name REGION=europe-west1 SSH_WS_PORT=8880 V2RAY_PORT=10000 bash deploy.sh
set -euo pipefail

SERVICE="${SERVICE:-vps-proxy}"
REGION="${REGION:-us-central1}"
VPS_HOST="${VPS_HOST:-217.60.6.102}"
SSH_WS_PORT="${SSH_WS_PORT:-80}"
V2RAY_PORT="${V2RAY_PORT:-8080}"
VLESS_PORT="${VLESS_PORT:-8081}"
VMESS_PORT="${VMESS_PORT:-8082}"
TROJAN_PORT="${TROJAN_PORT:-8083}"
MAX_INSTANCES="${MAX_INSTANCES:-3}"

command -v gcloud >/dev/null 2>&1 || { echo "gcloud not found. Use Google Cloud Shell: https://shell.cloud.google.com"; exit 1; }

if [ -z "$(gcloud auth list --filter=status:ACTIVE --format='value(account)')" ]; then
  gcloud auth login
fi

PROJECT="$(gcloud config get-value project 2>/dev/null || true)"
if [ -z "$PROJECT" ] || [ "$PROJECT" = "(unset)" ]; then
  read -rp "Enter your GCP Project ID: " PROJECT
  gcloud config set project "$PROJECT"
fi
echo "Project: $PROJECT | Region: $REGION | Service: $SERVICE | VPS: $VPS_HOST"

gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com

gcloud run deploy "$SERVICE" \
  --source . \
  --region "$REGION" \
  --platform managed \
  --allow-unauthenticated \
  --port 8080 \
  --cpu 1 \
  --memory 256Mi \
  --concurrency 1000 \
  --min-instances 0 \
  --max-instances "$MAX_INSTANCES" \
  --timeout 3600 \
  --cpu-boost \
  --session-affinity \
  --set-env-vars "VPS_HOST=$VPS_HOST,SSH_WS_PORT=$SSH_WS_PORT,V2RAY_PORT=$V2RAY_PORT,VLESS_PORT=$VLESS_PORT,VMESS_PORT=$VMESS_PORT,TROJAN_PORT=$TROJAN_PORT"

URL="$(gcloud run services describe "$SERVICE" --region "$REGION" --format='value(status.url)')"
HOST="${URL#https://}"

cat <<INFO

=========================================
 Deployed: $URL
=========================================
 Host / SNI : $HOST
 Port       : 443 (TLS on)

 SSH-WS     : path /        -> VPS :$SSH_WS_PORT
 V2Ray (ws) : path /vray    -> VPS :$V2RAY_PORT
 VLESS (ws) : path /vless   -> VPS :$VLESS_PORT
 VMess (ws) : path /vmess   -> VPS :$VMESS_PORT
 Trojan (ws): path /trojan  -> VPS :$TROJAN_PORT

 Health     : $URL/health
 Test       : bash check.sh $HOST
=========================================
INFO
