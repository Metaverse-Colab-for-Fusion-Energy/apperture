FROM alpine:3.12

WORKDIR /app

RUN apk add --no-cache bash curl jq
COPY ./nginx_proxy_manager_cli.sh /app/nginx_proxy_manager_cli.sh
RUN chmod +x /app/nginx_proxy_manager_cli.sh

COPY ./bootstrap.sh /app/bootstrap.sh
COPY ./config.json /app/config.json
ENTRYPOINT ["bash", "/app/bootstrap.sh"]
