mkdir certs
openssl genrsa -out certs/mydomain.key 2048
openssl req -new -key certs/mydomain.key -out certs/mydomain.csr
openssl x509 -req -days 365 -in certs/mydomain.csr -signkey certs/mydomain.key -out certs/mydomain.crt
cat certs/mydomain.key certs/mydomain.crt >> certs/mydomain.pem
