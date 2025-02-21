FROM docker:dind-rootless
USER root

# Install OpenSSL for certificate generation
RUN apk add --no-cache openssl

# Create certs directory
RUN mkdir -p /certs/client /certs/server && \
    chmod -R 700 /certs
RUN adduser -D -g '' -u 1001 github 

RUN adduser github docker 

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
# USER rootless

CMD []
