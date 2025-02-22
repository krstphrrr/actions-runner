#!/bin/sh


# Add nameservers to /etc/resolv.conf
cat > /etc/resolv.conf << EOF
nameserver 192.168.177.52
nameserver 192.168.177.1
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOF

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

# Copy CA cert to client directory
cp /certs/ca.pem /certs/client/ca.pem

# Set proper permissions and ownership
chmod -R 755 /certs
chmod 444 /certs/ca.pem
chmod 444 /certs/client/ca.pem
chmod 400 /certs/server/server-key.pem
chmod 444 /certs/server/server-cert.pem
chmod 400 /certs/client/key.pem
chmod 444 /certs/client/cert.pem

# Ensure proper ownership (github user has UID 1001)
chown -R 1001:1001 /certs/client
chmod -R g+r /certs/client  # Add group read permissions
chown -R root:root /certs/server
chown root:root /certs/ca.pem

# Start dockerd with TLS verification
exec dockerd \
  --tlsverify \
  --tlscacert=/certs/ca.pem \
  --tlscert=/certs/server/server-cert.pem \
  --tlskey=/certs/server/server-key.pem \
  --host=tcp://0.0.0.0:2376 \
  --host=unix:///var/run/docker.sock