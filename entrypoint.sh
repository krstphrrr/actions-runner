#!/bin/sh

# Create necessary directories
mkdir -p /certs/server
mkdir -p /certs/client

# Generate CA, server and client keys
openssl genrsa -aes256 -out /certs/ca-key.pem -passout pass:unsecure 4096
openssl req -new -x509 -days 365 -key /certs/ca-key.pem -sha256 -out /certs/ca.pem -passin pass:unsecure -subj "/CN=docker-ca"

# Create server cert
openssl genrsa -out /certs/server/server-key.pem 4096
openssl req -subj "/CN=docker-server" -sha256 -new -key /certs/server/server-key.pem -out /certs/server/server.csr
echo "subjectAltName = DNS:sidecar,IP:0.0.0.0" >> /certs/server/extfile.cnf
openssl x509 -req -days 365 -sha256 -in /certs/server/server.csr -CA /certs/ca.pem -CAkey /certs/ca-key.pem -CAcreateserial -out /certs/server/server-cert.pem -extfile /certs/server/extfile.cnf -passin pass:unsecure

# Create client cert
openssl genrsa -out /certs/client/key.pem 4096
openssl req -subj "/CN=docker-client" -new -key /certs/client/key.pem -out /certs/client/client.csr
echo "extendedKeyUsage = clientAuth" > /certs/client/extfile.cnf
openssl x509 -req -days 365 -sha256 -in /certs/client/client.csr -CA /certs/ca.pem -CAkey /certs/ca-key.pem -CAcreateserial -out /certs/client/cert.pem -extfile /certs/client/extfile.cnf -passin pass:unsecure

# Set proper permissions
chmod 0444 /certs/ca.pem
chmod -R 0400 /certs/server/server-key.pem
chmod -R 0444 /certs/server/server-cert.pem
chmod -R 0400 /certs/client/key.pem
chmod -R 0444 /certs/client/cert.pem

# Start dockerd with TLS verification
exec dockerd \
  --tlsverify \
  --tlscacert=/certs/ca.pem \
  --tlscert=/certs/server/server-cert.pem \
  --tlskey=/certs/server/server-key.pem \
  --host=tcp://0.0.0.0:2376 \
  --host=unix:///var/run/docker.sock