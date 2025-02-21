#!/bin/sh

# Add nameservers to /etc/resolv.conf
cat <<EOL > /etc/resolv.conf
nameserver 192.168.177.52
nameserver 192.168.177.1
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 1.1.1.1
EOL

# Execute the Docker daemon with specified parameters
# exec dockerd --tls=true --tlscert=/certs/ca/cert.pem --tlskey=/certs/ca/key.pem --tlscacert=/certs/client/ca.pem  --host=tcp://0.0.0.0:2375
# exec dockerd --tlscert=/certs/ca/cert.pem --tlskey=/certs/ca/key.pem --tlscacert=/certs/client/ca.pem  --host=tcp://0.0.0.0:2375
# exec dockerd --tls=true --tlsverify=true --tlscert="" --tlskey="" --tlscacert=""  --host=tcp://0.0.0.0:2375

exec dockerd --tls=false --host=tcp://0.0.0.0:2375