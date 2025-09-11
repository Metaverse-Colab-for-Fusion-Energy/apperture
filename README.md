# Apperture #

Apperture is a secure web portal for protecting web applications. It takes the form of a docker-compose configuration and is merely the combination of several excellent open source containers.

## Preqrequisites 

To deploy this project, you will need a domain name. 
We suggest cloudflare for registering domains but many other services are available.

To run Apperture, you will need:
- Git
- Docker
- Docker-compose

## Getting started

### Clone the repository

To get started, get the code from github:

```shell
git clone git@github.com:UoMResearchIT/apperture.git
cd apperture
```

### Create env file

Copy the template file to the correct name (note leading .)

```shell
cp env.template .env
nano .env
```

Edit the URL to your domain, the name of your organisation and a tile for your site.

```diff
- URL=foobar.org
- ORGANISATION=Uni of Foo
- TITLE=FooBar
+ URL=mylovelydomain.org
+ ORGANISATION=Uni of Foo
+ TITLE=My lovley site
```

### Generate admin credentials

Run the script to generate secure, random passwords and configure your apperture environment.
```shell
./generate_passwords.sh
```

The script will print admin credentials, that you will need to access the proxy manager.
The output should look like this:
```shell
Generating ...
Generating ...
Generating ...

## Save these for later!! (or rerun the script to view them again) ##

# Account for the portal and to add users:
LLDAP admin credentials:
  User: admin
  Pass: kGb6eX8M4oVjd2WeKzGaK3NYTyz29eLmqUvX78JqfTnev9cEQNG9yWsV2w4QfWs88yLxnvj9
```

**Securly save these credientials for later** 
We suggest using a password manger. 

### Configure your subdomains

The subdomains configured in the `config.json` file are added to your site when apperture is launched.

You can add your own hosts to the config.json file.
Make sure to use the same format as the existing hosts, that is:
* *name*: title of subdomain, headline on home page
* *subdomain*: address users will visit `subdomain.mylovleydomain.org`
* *icon*: font-awesome icon to represent subdomain on home page
* *group*: home page group to add endpoint to (default: "Apps")
* *description*: long form text to describe subdomain on home page
* *forward_host*: container name or IP address of target service
* *port*: port to access on target service
* *auth*: boolean to enable / disable requring authelia logon for access
* *ssl*: whether or not to apply https routing to the subdomain

For example, if in the `.env` file you used `URL=mylovelydomain.org`, adding this:
```json
    {
      "name": "My App",
      "icon": "fa-solid fa-cog",
      "group": "Apps",
      "description": "The my app service for testing",
      "subdomain": "myapp",
      "forward_host": "apperture-myapp",
      "forward_port": 80,
      "auth": true,
      "ssl": true
    },
```
will add `myapp.mylovelydomain.org` to the proxy your site, with https enabled and protected by authelia. The homepage will have a tile added with a cog symbol called "My App" which connects to the container `apperture-myapp` on port 80.

### Launch apperture

You are now ready to launch apperture. Do so with:

```shell
docker compose up --build -d && docker compose logs -f
```

and make sure no errors are thrown. you can exit the logs with `Ctrl+C`.

### Load ssl certificates

By default apperture requires ssl certificates for the protected routes.

At the moment, these are not automatically generated nor loaded into the proxy. You will need to do this manually.

You can generate a self-signed certificate using:
```shell
sudo apt install mkcert
mkcert -install
mkcert "<your_domain_here>" "*.your_domain_here" "127.0.0.1" "::1"
```
This will generate a certificate and key in the current directory. 
You should now be able to access the route using https.

<!-- ------------------------------------- How to ---------------------------------------- -->

## How to
 
### Use with cloudflare tunnels

#### Remove exposed ports 

Comment the exposed ports in the docker-compose file:
```diff
- - '80:80' # Public HTTP Port
- - '443:443' # Public HTTPS Port
+ # - '80:80' # Public HTTP Port
+ # - '443:443' # Public HTTPS Port
```

Now restart apperture:

```shell
docker compose down
docker compuse up
```

#### Set up tunnels on Cloudflare

- Login to cloudflare.
- On the side menu, select "Zero Trust".
- Create a team name and subscribe to the free plan
- Click on "Networks" and then "Tunnels".
- Click on "Add a Tunnel".
- Select cloudflared as the connector.
- Choose a name for the tunnel, and save it.
- Click on your tunnel.
- Click on "Configure".
- In "Choose your environment", select "Docker".
- Copy the code in the "Install and run a connector" box. It includes the token after the flag `--token`.

Now save the token into a file `config/cloudflared/.secret_token` in your project.:

```shell
mkdir -p config/cloudflared/
echo "TUNNEL_TOKEN=<your_token_here>" config/cloudflared/.secret_token
```

The file should look like this:
```
TUNNEL_TOKEN=your_token
```

Add the cloudflared service to your docker-compose file.
A standard configuration would look like this:
```
services:

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: mylovelyproject-cloudflared
    restart: unless-stopped
    env_file:
      - ./config/cloudflared/.secret_token
    command:
      tunnel --no-autoupdate run
    networks:
      apperture:
```

You can now launch the cloudflared service with `docker-compose up -d cloudflared`.

**Note**: Each domain you add to cloudflare also needs to be added in the proxy, and protected in the "Advanced" tab (See the [Protect the Route](#protect-the-route) section).

#### Add wildcard hostname to cloudflare
For testing purposes, you may want to add a wildcard hostname to cloudflare.
This will allow you to access any subdomain of your domain without having to add each one individually.
If you prefer to restrict access to specific subdomains, you can instead look at the [Add individual hostnames to cloudflare](#add-individual-hostnames-to-cloudflare) section.

To add a wildcard hostname:
 - Go to Tunnels.
 - Make a note of the tunnel id.
 - Select your tunnel, and click on "Edit"
 - Go to the "Public Hostname" tab, and click on "Add a public hostname".
   - **Subdomain:** *
   - **Domain:** mylovelydomain.org
   - **Service Type:** HTTP
   - **URL:** apperture-proxy
 - From the cloudflare dashboard, select your domain.
 - On the left hand side nav-bar, go to the "DNS" tab.
 - In the DNS management box, select "add record":
   - **Type:** CNAME
   - **Name:** *
   - **Target:** `<your_tunnel_id>.cfargotunnel.com`
   - **TTL:** Auto
   - **Proxy status:** Proxied
You can now access any subdomain of your domain, for example `foo.mylovelydomain.org`.

#### Add individual hostnames to cloudflare

You will now be able to add Public Hostnames.

- Go to Tunnels, select your tunnel, and click on "Edit".
- Go to the "Public Hostname" tab, and click on "Add a public hostname".
  - **Subdomain:** whoami
  - **Domain:** mylovelydomain.org
  - **Service Type:** HTTP
  - **URL:** apperture-proxy

Using your domain (`mylovelydomain.org`), add the subdomains necessary for apperture (see the [Configure the proxy](#configure-the-proxy) section):
- `whoami`
- `authelia`
- `users`
In all three cases, make sure you select `http` for the type, and `apperture-proxy` for the url. You may leave the path empty.

## Troubleshooting

### Authelia doesn't start due to NTP failures

In the docker compose config for the Authelia service, add two environment variables:

```yaml
AUTHELIA_NTP_DISABLE_STARTUP_CHECK: True
AUTHELIA_NTP_DISABLE_FAILURE: True
```

## Explaination

## Reference
