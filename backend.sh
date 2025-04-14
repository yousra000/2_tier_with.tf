!/bin/bash
# Install Python and simple HTTP server
dnf install -y python3
python3 -m http.server 8080 --directory /tmp &
mkdir -p /tmp
echo "OK" > /tmp/health