#!/usr/bin/env bash

pass_files=("config/lldap/secrets/LLDAP_JWT_SECRET" \
            "config/lldap/secrets/LLDAP_PASSWORD" \
            "config/lldap/secrets/LLDAP_STORAGE_PASSWORD" \
            "config/authelia/secrets/AUTHELIA_JWT_SECRET" \
            "config/authelia/secrets/AUTHELIA_SESSION_SECRET" \
            "config/authelia/secrets/AUTHELIA_STORAGE_ENCRYPTION_KEY" \
            "config/authelia/secrets/AUTHELIA_STORAGE_PASSWORD" 
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
  Pass: $(cat config/lldap/secrets/LLDAP_PASSWORD)
"

# replace $URL in config/authelia/snippets/authelia-authrequest.conf with the URL stored in the .env file
sed "s|\$URL|$(grep URL .env | cut -d '=' -f2)|g" \
    config/authelia/snippets/authelia-authrequest.conf.template \
    > config/authelia/snippets/authelia-authrequest.conf

# if URL is localtest.me, generate certificates using mkcert
DOMAIN=$(cat .env | grep URL | cut -d '=' -f2)
if [ "$DOMAIN" == "localtest.me" ]; then
    # Check if mkcert is installed
    if ! command -v mkcert &> /dev/null; then
        echo "mkcert could not be found. Please install it and run this script again."
        exit 1
    fi
    
    mkcert -install
    mkcert -cert-file cert.pem -key-file key.pem "$DOMAIN" "*.$DOMAIN" "127.0.0.1" "::1" 
fi
