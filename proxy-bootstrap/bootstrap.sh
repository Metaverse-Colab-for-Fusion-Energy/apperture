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
