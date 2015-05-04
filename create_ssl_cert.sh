#!/bin/bash
CERT_NAME="ca"
echo $CERT_NAME
if [ -n "$1" ]
then
    CERT_NAME=$1
fi
echo "cert="$CERT_NAME
openssl genrsa -out $CERT_NAME-key.pem 1024
openssl req -new -key $CERT_NAME-key.pem -out $CERT_NAME-csr.pem
openssl x509 -req -in $CERT_NAME-csr.pem -signkey $CERT_NAME-key.pem -out $CERT_NAME-cert.pem
