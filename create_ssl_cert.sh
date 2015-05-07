#!/bin/bash
openssl req -config openssl_req.conf -new -out csr.pem -passin asdqwe123! && openssl x509 -req -in csr.pem -signkey key.pem -out cert.pem && echo "success!"
