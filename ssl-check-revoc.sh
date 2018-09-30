#!/bin/bash
#
# Script:       ssl-check-revoc.sh
# Source:       https://github.com/o-pod/security
#
# Description:  Checking SSL certificates for revocation using CRL
# Version:      0.2.1
# Date:         Oct 2018
# Depends:      OpenSSL, Wget
#
# Author:       Oleg Podgaisky (o-pod)
# E-mail:       oleg-podgaisky@yandex.ru
#
# Usage:        ssl-check-revoc.sh [<domain> | -f <file>] [-v]
# Output:       0 - the certificate is not revoked
#               1 - the certificate is revoked
#               2 - error
#=================================================================

path="/tmp"
verbose=$(echo " "${*}" " | grep -o " \-v ")
file=$(echo " "${*}" " | grep -o " \-f ")


### Exit processing
#
function myExit {
    if [ -n "${verbose}" ]; then
        echo "${2}"    ### Exit message
    else
        echo "${1}"    ### Exit code:    0 - True,    1 - False,    2 - Error
    fi
    exit ${1}
}


### Get a certificate
#
# from FILE:
if [ -n "${file}" ]; then
    crt_file=$(echo ${*} | sed 's/\-[a-z]//gi' | sed 's/ //g')
    if [ ! -f "${crt_file}" ]; then
        myExit 2 "ERROR: File ${crt_file} is not exist"
    fi
# from DOMAIN:
else
    domain=$(echo ${*} | sed 's/\-[a-z]//gi' | sed 's/ //g')
    if [ -z "${domain}" ]; then
        myExit 2 "ERROR: Domain is not defined"
    fi
    domain_ping=$(ping -c1 ${domain} 2>&1 | grep -v "unknown host")
    if [ -z "${domain_ping}" ]; then
        myExit 2 "ERROR: Unknown domain ${domain}"
    fi
    crt_file="${path}/${domain}.crt"
    echo -n | openssl s_client -connect ${domain}:443 -servername ${domain} 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${crt_file}
    crt_file_size=$(wc -c < "${crt_file}")
    if [ $crt_file_size -lt 100 ]; then
        myExit 2 "ERROR: Failed to get certificate from domain ${domain}"
    fi
fi


### Validate the certificate
#
crt_file_data=$(openssl x509 -noout -modulus -in ${crt_file} 2>&1)
crt_file_data_test=$(echo ${crt_file_data} | grep "unable to load certificate")
if [ -n "${crt_file_data_test}" ]; then
    if [ -n "${domain}" ]; then
        rm ${crt_file} 2>/dev/null
    fi
    myExit 2 "ERROR: The certificate is NOT valid"
fi


### Get a Issuer, Serial, OCSP and other information of the certificate
#
crt_serial=$(openssl x509 -in ${crt_file} -noout -serial | cut -d"=" -f2)
if [ -n "${verbose}" ]; then
    echo "=== Certificate details ==="
    crt_subject=$(openssl x509 -in ${crt_file} -noout -subject | sed 's/^subject=//')
    echo "Subject: ${crt_subject}"
    crt_issuer=$(openssl x509 -in ${crt_file} -noout -issuer | sed 's/^issuer=//')
    echo "Issuer: ${crt_issuer}"
    echo "Serial: ${crt_serial}"
    crt_startdate=$(openssl x509 -in ${crt_file} -noout -startdate | sed 's/^notBefore=//')
    echo "Start date: ${crt_startdate}"
    crt_enddate=$(openssl x509 -in ${crt_file} -noout -enddate | sed 's/^notAfter=//')
    echo "End date: ${crt_enddate}"
    ocsp_url=$(openssl x509 -in ${crt_file} -noout -ocsp_uri)
    echo "OCSP server: ${ocsp_url}"
fi


### Download CRL
#
if [ -n "${verbose}" ]; then
    echo "=== CRL ==="
fi
crl_url=$(openssl x509 -noout -text -in ${crt_file} | grep -o 'http://.\{1,\}\.crl$')
if [ -z "${crl_url}" ]; then
    if [ -n "${domain}" ]; then
        rm ${crt_file} 2>/dev/null
    fi
    myExit 2 "ERROR: CRL is not present"
fi
if [ -n "${verbose}" ]; then
    echo "CRL from: ${crl_url}"
fi
crl_file=$(echo ${crl_url} | grep -o '[^\/]\{1,\}$')
wget --quiet ${crl_url} -O ${path}/${crl_file}
if [ -n "${verbose}" ]; then
    echo "CRL was saved to: ${path}/${crl_file}"
fi


### Look for serial of the certificate in the CRL
#
if [ -n "${verbose}" ]; then
    echo "=== REVOCATION STATUS ==="
fi
result=$(openssl crl -inform DER -text -in ${path}/${crl_file} | grep "${crt_serial}")
rm ${path}/${crl_file} 2>/dev/null
if [ -n "${domain}" ]; then
    rm ${crt_file} 2>/dev/null
fi
if [ -z "${result}" ]; then
    myExit 0 "SUCCESS: The certificate is not in revocation list"
else
    myExit 1 "PROBLEM: The certificate is in revocation list"
fi

