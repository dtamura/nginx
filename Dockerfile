# build opentracing
# An nginx container that includes the module and plugin required for Datadog tracing.
FROM nginx:1.19.6 as build-opentracing-module

RUN apt-get update && \
  apt-get install -y wget tar

# Install nginx-opentracing
RUN \
  NGINX_VERSION=`nginx -v 2>&1 > /dev/null | sed -E "s/^.*nginx\/(.*)/\\1/"`&& \
  OPENTRACING_NGINX_VERSION="v0.24.0" && \
  DD_OPENTRACING_CPP_VERSION="v1.3.2" && \
  \
  wget https://github.com/opentracing-contrib/nginx-opentracing/releases/download/${OPENTRACING_NGINX_VERSION}/linux-amd64-nginx-${NGINX_VERSION}-ot16-ngx_http_module.so.tgz && \
  NGINX_MODULES=$(nginx -V 2>&1 | grep "configure arguments" | sed -n 's/.*--modules-path=\([^ ]*\).*/\1/p') && \
  tar zxvf linux-amd64-nginx-${NGINX_VERSION}-ot16-ngx_http_module.so.tgz -C "${NGINX_MODULES}" && \
  # Install Datadog module
  wget -O - https://github.com/DataDog/dd-opentracing-cpp/releases/download/${DD_OPENTRACING_CPP_VERSION}/linux-amd64-libdd_opentracing_plugin.so.gz | gunzip -c > /usr/local/lib/libdd_opentracing_plugin.so


# Production
FROM nginx:1.19.6 as production-stage

# モジュールのコピー
COPY --from=build-opentracing-module --chown=nginx:nginx /usr/lib/nginx/modules/ngx_http_opentracing_module.so /usr/lib/nginx/modules/ngx_http_opentracing_module.so
COPY --from=build-opentracing-module --chown=nginx:nginx /usr/local/lib/libdd_opentracing_plugin.so /usr/local/lib/libdd_opentracing_plugin.so

COPY --chown=nginx:nginx nginx-conf/entrypoint.sh /entrypoint.sh


# COPY --from=build-stage /app/build /usr/share/nginx/html

RUN chown -R nginx:nginx /var/cache/nginx /var/log/nginx /etc/nginx/ /usr/share/nginx/html &&\
    chmod +x /entrypoint.sh
EXPOSE 8080

USER nginx


# CMD ["nginx", "-g", "daemon off;"]

ENTRYPOINT ["sh", "-c", "/entrypoint.sh"]
