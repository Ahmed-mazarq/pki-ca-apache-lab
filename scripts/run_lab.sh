#!/usr/bin/env bash
set -euo pipefail

echo "==[1] Prepare directories =="
mkdir -p myCA/{certs,private} server

echo "==[2] Create Root CA key & certificate =="
openssl genrsa -out myCA/private/ca.key.pem 4096

openssl req -x509 -new -nodes \
  -key myCA/private/ca.key.pem \
  -sha256 -days 3650 \
  -subj "/C=SA/O=GraduationProject/OU=PKI-Lab/CN=Root-CA" \
  -out myCA/certs/ca.cert.pem

echo "==[3] Create Server key & CSR =="
DOMAIN="${1:-localhost}"
openssl genrsa -out server/server.key.pem 2048

openssl req -new \
  -key server/server.key.pem \
  -subj "/C=SA/O=DonationsProject/OU=Web/CN=${DOMAIN}" \
  -out server/server.csr.pem

echo "==[4] Sign Server certificate using our CA =="
openssl x509 -req \
  -in server/server.csr.pem \
  -CA myCA/certs/ca.cert.pem \
  -CAkey myCA/private/ca.key.pem \
  -CAcreateserial \
  -out server/server.crt.pem \
  -days 825 -sha256

echo "==[5] Show certificate summary =="
openssl x509 -in server/server.crt.pem -noout -subject -issuer -dates

echo "==[6] Create Apache SSL config template =="
cat > server/default-ssl.conf <<EOF
<IfModule mod_ssl.c>
  <VirtualHost _default_:443>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    SSLEngine on
    SSLCertificateFile      /etc/ssl/certs/server.crt
    SSLCertificateKeyFile   /etc/ssl/private/server.key
    SSLCACertificateFile    /etc/ssl/certs/CA.crt
  </VirtualHost>
</IfModule>
EOF

echo "PKI LAB DONE"
