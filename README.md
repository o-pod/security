# Security scripts for Linux
Scripts for checking security settings of Linux servers

## About
* ssl-check-matching.sh - checks SSL-certificate for matching Private key
* ssl-check-revoc.sh - checks SSL-certificate for revocation using CRL

## Installing
### In Debian/Ubuntu
```
sudo apt update
sudo apt install openssl wget
wget https://raw.githubusercontent.com/o-pod/security/master/ssl-check-matching.sh
wget https://raw.githubusercontent.com/o-pod/security/master/ssl-check-revoc.sh
chmod a+x ssl-check-revoc.sh
chmod a+x ssl-check-matching.sh
```

## Usage
```
ssl-check-revoc.sh [<domain> | -f <file>] [-v]
```
Output:
* 0 - the certificate is not revoked
* 1 - the certificate is revoked
* 2 - error

```
ssl-check-matching.sh <certificate> <private key> [-v]
```
Output:
* 0 - certificate and private key are match
* 1 - certificate and private key are NOT match
* 2 - error

## Examples
```
ssl-check-revoc.sh github.com -v
ssl-check-revoc.sh -f certificate.crt -v
ssl-check-matching.sh certificate.crt privatekey.key -v
```
