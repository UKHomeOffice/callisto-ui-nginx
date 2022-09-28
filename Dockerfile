FROM ghcr.io/nginxinc/nginx-s3-gateway/nginx-oss-s3-gateway:latest-20220916

RUN addgroup --system --gid 1001 s3gateway && \
    adduser --system --disabled-login --no-create-home --ingroup s3gateway -uid 1001 gatewayuser && \
    chown -R gatewayuser /etc/nginx/conf.d && \
    chown -R gatewayuser /var/cache/nginx && \
    chown -R gatewayuser /var/log/nginx

RUN touch /var/run/nginx.pid && \
    chown -R gatewayuser /var/run/nginx.pid

USER 1001
