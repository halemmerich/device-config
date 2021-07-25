#!/bin/sh

openssl genrsa -out ca.key 4096
openssl req -new -x509 -days 3650 -key ca.key -out ca.pem -subj "/C=FK/ST=FAKE/L=FAKE/O=FAKE/OU=CA/CN=CA"
