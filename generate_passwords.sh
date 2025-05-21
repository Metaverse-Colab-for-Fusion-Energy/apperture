#!/usr/bin/env bash

pass_files=("${HOME}/.config/apperture/lldap/secrets/LLDAP_JWT_SECRET" \
            "${HOME}/.config/apperture/lldap/secrets/LLDAP_PASSWORD" \
            "${HOME}/.config/apperture/lldap/secrets/LLDAP_STORAGE_PASSWORD" \
            "${HOME}/.config/apperture/authelia/secrets/AUTHELIA_JWT_SECRET" \
            "${HOME}/.config/apperture/authelia/secrets/AUTHELIA_SESSION_SECRET" \
            "${HOME}/.config/apperture/authelia/secrets/AUTHELIA_STORAGE_ENCRYPTION_KEY" \
            "${HOME}/.config/apperture/authelia/secrets/AUTHELIA_STORAGE_PASSWORD" \
            "${HOME}/.config/apperture/casbin/secrets/CASBIN_STORAGE_PASSWORD" \
            "${HOME}/.config/apperture/proxy/secrets/PROXY_PASSWORD" \
           )

for file in ${pass_files[@]}
do
    # only generate passwords if the files do not exist
    if [ ! -f $file ]; then
        mkdir -p $(dirname $file)
        echo Generating $file
        docker run authelia/authelia:latest authelia crypto rand --length 64 --charset alphanumeric | awk '{print $3}' > $file
    else
        echo Skipping $file - it already exists
    fi
done

# Echo the lldap password to the console
echo "
 LLDAP admin credentials:
  User: admin
  Pass: $(cat ${HOME}/.config/apperture/lldap/secrets/LLDAP_PASSWORD)
"

# Echo the proxy password to the console
echo "
 Proxy credentials:
  User: $(cat .env | grep PROXY_USER | cut -d '=' -f2)
  Pass: $(cat ${HOME}/.config/apperture/proxy/secrets/PROXY_PASSWORD)
"

# replace $URL in config/apperture/authelia/snippets/authelia-authrequest.conf with the URL stored in the .env file
sed "s|\$URL|$(grep URL .env | cut -d '=' -f2)|g" \
    config/apperture/authelia/snippets/authelia-authrequest.conf.template \
    > config/apperture/authelia/snippets/authelia-authrequest.conf

# if URL is localtest.me, generate certificates using mkcert
DOMAIN=$(cat .env | grep URL | cut -d '=' -f2)
if [ "$DOMAIN" == "localtest.me" ]; then
    # Check if mkcert is installed
    if ! command -v mkcert &> /dev/null; then
        echo "mkcert could not be found. Please install it and run this script again."
        exit 1
    fi
    
    mkcert -install
    mkcert "$DOMAIN" "*.$DOMAIN" "127.0.0.1" "::1" -cert-file ${HOME}/.config/apperture/certs/cert.pem -key-file ${HOME}/.config/apperture/certs/key.pem
fi
