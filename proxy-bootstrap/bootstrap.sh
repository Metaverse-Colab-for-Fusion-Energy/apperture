# Description: Bootstrap script for Nginx Proxy Manager CLI

#!/bin/bash
echo "Running Nginx Proxy Manager Bootstrap"

# Set environment variables
CONFIG_FILE="/app/config.json"
echo "Reading config from: $CONFIG_FILE"

# Get password from docker secret caled PROXY_PASS
API_PASS=$(cat /run/secrets/PROXY_PASS)

# Create script config file
function set_config () {
    cat <<EOF > "/app/nginx_proxy_manager_cli.conf"
NGINX_IP="$NGINX_IP"
API_USER="$1"
API_PASS="$2"
BASE_DIR="/app"
EOF
    /app/nginx_proxy_manager_cli.sh --info
}

set_config "$API_USER" "$API_PASS"

# Check if the user profile exists, if not log in with default credentials and create it
/app/nginx_proxy_manager_cli.sh --check-token

if [ $? -ne 0 ]; then  
    echo "Token is not valid - logging in with default credentials"

    # Create script config file with default credentials
    set_config "admin@example.com" "changeme"

    # Validate default credentials login
    /app/nginx_proxy_manager_cli.sh --check-token
    if [ $? -ne 0 ]; then
        echo "Failed to log in with default credentials"
        exit 1
    fi

    # Add user profile
    /app/nginx_proxy_manager_cli.sh --create-user "$API_USER" "$API_PASS" "$API_USER"
    if [ $? -ne 0 ]; then
        echo "Failed to create user profile"
        exit 1
    fi
    
    # Log in with user profile
    set_config "$API_USER" "$API_PASS"

    # Validate user profile login
    /app/nginx_proxy_manager_cli.sh --check-token
    if [ $? -ne 0 ]; then
        echo "Failed to log in with user profile"
        exit 1
    fi
else
    echo "Credentials valid"
fi

# Check if the config file exists and is correct JSON
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi
if ! jq empty "$CONFIG_FILE" > /dev/null 2>&1; then
    echo "ERROR: Config file is not valid JSON: $CONFIG_FILE"
    exit 1
fi
# Validate required fields in the config file
ERR=0
PH_i=0
while read -r host; do
    PH_i=$((PH_i + 1))
    FORWARD_HOST=$(echo "$host" | jq -r '.forward_host')
    FORWARD_PORT=$(echo "$host" | jq -r '.forward_port')
    FQDN=$(echo "$host" | jq -r '.fqdn')
    SUBDOMAIN=$(echo "$host" | jq -r '.subdomain')
    if { [ -z "$FORWARD_HOST" ] || [ "$FORWARD_HOST" == "null" ]; }; then
        echo "ERROR: Proxy host $PH_i has no forward_host. The forward_host must be defined for each proxy host."
        ERR=1
    fi
    if { [ -z "$FORWARD_PORT" ] || [ "$FORWARD_PORT" == "null" ]; }; then
        echo "ERROR: Proxy host $PH_i has no forward_port. The forward_port must be defined for each proxy host"
        ERR=1
    fi
    if { [ -z "$FQDN" ] || [ "$FQDN" == "null" ]; } && { [ -z "$SUBDOMAIN" ] || [ "$SUBDOMAIN" == "null" ]; }; then
        echo "ERROR: Proxy host $PH_i has no subdomain and no fqdn. One of the two must be defined for each proxy host"
        ERR=1
    fi
done < <(jq -c '.proxy_hosts[]' "$CONFIG_FILE")
if [ $ERR -ne 0 ]; then
    echo "ERROR: Invalid config file: $CONFIG_FILE"
    exit 1
fi

# Read config file and add proxy hosts
jq -c '.proxy_hosts[]' "$CONFIG_FILE" | while read -r host; do
    FULL_DOMAIN=$(echo "$host" | jq -r '.fqdn')
    if { [ -z "$FULL_DOMAIN" ] || [ "$FULL_DOMAIN" == "null" ]; }; then
        SUBDOMAIN=$(echo "$host" | jq -r '.subdomain')
        FULL_DOMAIN=$SUBDOMAIN.$DOMAIN
    fi
    FORWARD_HOST=$(echo "$host" | jq -r '.forward_host')
    FORWARD_PORT=$(echo "$host" | jq -r '.forward_port')
    ADVANCED_CONFIG=$(echo "$host" | jq -r '.advanced_config')
    if [ "$ADVANCED_CONFIG" == "null" ]; then
        ADVANCED_CONFIG=""
    fi

    echo "Configuring: $FULL_DOMAIN -> $FORWARD_HOST:$FORWARD_PORT"

    # Run Nginx Proxy Manager CLI
    /app/nginx_proxy_manager_cli.sh -y -d $FULL_DOMAIN -i $FORWARD_HOST -p $FORWARD_PORT -a "$ADVANCED_CONFIG"

    # check if the command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to add $DOMAIN"
        continue
    else
        echo "Added $DOMAIN"
    fi
done
