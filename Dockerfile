FROM nginx:1.27-alpine
COPY ws-proxy.conf /etc/nginx/ws-proxy.conf
COPY nginx.conf.template /etc/nginx/templates/default.conf.template
ENV PORT=8080 \
    VPS_HOST=217.60.6.102 \
    SSH_WS_PORT=80 \
    V2RAY_PORT=8080 \
    VLESS_PORT=8081 \
    VMESS_PORT=8082 \
    TROJAN_PORT=8083
EXPOSE 8080
