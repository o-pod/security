#!/bin/bash
#
# Script:       ssl-check-matching.sh
# Source:       https://github.com/o-pod/security
#
# Description:  Checking public and private keys for valid and matching
# Version:      0.2.0
# Date:         Aug 2018
# Depends:      OpenSSL
#
# Author:       Oleg Podgaisky (o-pod)
# E-mail:       oleg-podgaisky@yandex.ru
#
# Usage:        ssl-check-matching.sh <certificate> <private key> [-v]
# Output:       0 - certificate and private key are match
#               1 - certificate and private key are NOT match
#               2 - error
#======================================================================

params=$(echo "${*}" | sed 's/[\t ]\{1,\}/ /g' | sed 's/^[ ]\{1,\}//' | sed 's/[ ]\{1,\}$//')
verbose=$(echo " "${params}" " | grep -o " \-v ")


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


### Test parameters of the commandline
#
files=$(echo " "${params}" " | sed ' s/-[a-z] / /gi' | sed 's/[\t ]\{1,\}/ /g')
file1=$(echo ${files} | cut -d" " -f1)
file2=$(echo ${files} | cut -d" " -f2)
if [ "${file1}" == "${file2}" ]; then
    myExit 2 "ERROR: You should specify 2 not same files as parameters"
fi


### Test the files for exist
#
if [ ! -f "${file1}" ]; then
    myExit 2 "ERROR: File ${file1} is not exist or access denied"
fi
if [ ! -f "${file2}" ]; then
    myExit 2 "ERROR: File ${file2} is not exist or access denied"
fi


### Validate the certificate and the private key
#
cert_from_file=$(openssl x509 -noout -modulus -in ${file1} 2>&1)
cert_from_file_test=$(echo ${cert_from_file} | grep "unable to load certificate")
if [ -n "${cert_from_file_test}" ]; then
    cert_from_file=$(openssl x509 -noout -modulus -in ${file2} 2>&1)
    cert_from_file_test=$(echo ${cert_from_file} | grep "unable to load certificate")
    if [ -n "${cert_from_file_test}" ]; then
        myExit 2 "ERROR: Not the ${file1} nor the ${file2} are valid certificate"
    fi
fi

key_from_file=$(openssl rsa -noout -modulus -in ${file1} 2>&1)
key_from_file_test=$(echo ${key_from_file} | grep "unable to load Private Key")
if [ -n "${key_from_file_test}" ]; then
    key_from_file=$(openssl rsa -noout -modulus -in ${file2} 2>&1)
    key_from_file_test=$(echo ${key_from_file} | grep "unable to load Private Key")
    if [ -n "${key_from_file_test}" ]; then
        myExit 2 "ERROR: Not the ${file1} nor the ${file2} are valid private key"
    fi
fi


### Test matching certificate and private key
#
cert_md5=$(echo ${cert_from_file} | openssl md5)
key_md5=$(echo ${key_from_file} | openssl md5)
if [ "${cert_md5}" != "${key_md5}" ]; then
    myExit 1 "PROBLEM: The certificate and the private key are NOT matching"
else
    myExit 0 "SUCCESS: The certificate and the private key are matching"
fi

