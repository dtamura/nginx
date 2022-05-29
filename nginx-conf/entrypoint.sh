#!/bin/sh

envsubst '$DATADOG_TRACE_AGENT_HOSTNAME' < /etc/nginx/dd-config.json.in > /etc/nginx/dd-config.json

find /usr/share/nginx/html -type f | xargs gzip -k

nginx -g "daemon off;"
