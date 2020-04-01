#!/usr/bin/env ash

# Variables
BITS=${BITS:-'2048'}
CERT_DIR=${CERT_DIR:-'/etc/ssl/certs'}
DAYS=${DAYS:-'365'}
FQDN=${FQDN:-"example.churchoffoxx.net"}

# Functions

## Create the PEM format file
create_pem()
{
  cat ${CERT_DIR}/${FQDN}.crt ${CERT_DIR}/${FQDN}.key | tee ${CERT_DIR}/${FQDN}.pem
}

## Create the certificate
generate_cert()
{
  # Create the key and CSR
  openssl req -nodes \
    -newkey rsa:${BITS} \
    -keyout ${CERT_DIR}/${FQDN}.key \
    -out ${CERT_DIR}/${FQDN}.csr \
    -subj "/C=US/ST=State/L=Town/O=Church of Foxx/OU=Example/CN=${FQDN}"

  # Sign the CSR
  openssl x509 -req \
    -days ${DAYS} \
    -in ${CERT_DIR}/${FQDN}.csr \
    -signkey ${CERT_DIR}/${FQDN}.key \
    -out ${CERT_DIR}/${FQDN}.crt
}

## Check if the cert directory exists
make_cert_dir()
{
  # Create the directory if it doesn't exist yet
  if [[ -n ${CERT_DIR} ]]; then
    mkdir -p ${CERT_DIR}
  fi
}

## Display usage information
usage()
{
  echo "Usage: [Environment Variables] generate_ssl_cert.ash [options]"
  echo "  Environment Variables:"
  echo "    FQDN                fully qualified domain name of the server (default: example.churchoffoxx.net)"
}

# Logic

## Argument parsing
while [[ "$1" != "" ]]; do
  case $1 in
    -h | --help ) usage
                  exit 0
                  ;;
    * )           usage
                  exit 1
  esac
  shift
done

make_cert_dir
generate_cert
create_pem
