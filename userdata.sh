#!/bin/bash
# Install web server (nginx for Fedora)
dnf install -y nginx
systemctl start nginx
systemctl enable nginx

# Simple health check endpoint
echo "OK" > /usr/share/nginx/html/health
chmod 644 /usr/share/nginx/html/health