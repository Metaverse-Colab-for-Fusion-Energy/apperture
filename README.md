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
docker compose up -d && docker compose logs -f
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

To upload the certificate to the proxy, go to the proxy interface at `localhost:81` and login with the credentials you generated earlier.
- Click on the `SSL Certificates` tab, click on "Add SSL Certificate", and select "Custom".
- Choose a name for the certificate, and  upload the key and certificate.
- Save, and go to Hosts -> Proxy Hosts.
- Click on the three vertical dots of the route you want to add the certificate to, and click on "Edit".
- Click on the `SSL` tab, and select the certificate you just uploaded.
- Make sure the "Force SSL" toggle is **not** enabled, and save.

You should now be able to access the route using https.







<!-- ------------------------------------- Tutorials ------------------------------------- -->

## Tutorial - Setting up a secure web portal wit localtest.me

If you do not have a domain, for local development you can use the domain `localtest.me` which resolves to your local machine.

This tutorial will guide you through the getting started section using the `localtest.me` domain.

### First steps - Setup the environment

- Clone the repository
  ```shell
  git clone git@github.com:UoMResearchIT/apperture.git
  cd apperture
  ```
- Copy the template env file
  ```shell
  cp env.template .env
  nano .env
  ```
- Edit the URL to `localtest.me` for local development.
  ```diff
  - URL=foobar.org
  + URL=localtest.me
```
- Set the `PROXY_USER` to your email address.
- Now, run the script to generate passwords.
  ```shell
  ./generate_passwords.sh
```
- Make a note of the admin credentials printed by the script, as you will need them later.

### Launch apperture

With the configuration in place, we can now launch apperture.
To launch the apperture, run:
```shell
docker compose up -d && docker compose logs -f
```
and wait for the services to start.
Make sure no errors were raised, and exit the logs with `Ctrl+C`.

### View the proxy interface

Go to [localtest.me:81](localtest.me:81) and login with the credentials printed by the script.

Here you can see the routes which come pre-configured with Apperture and navigate to them if you wish.

However, there is a significant problem with the current setup. The proxy is not set up to use SSL and therefore (secure) connections are impossible.

#### Add SSL certificates to the proxy

When you speified `localtest.me` as the URL, the script generated a self-signed certificate for you. You can find it in the project directory.

To add the certificate to the proxy, you need to navigate to the `SSL Certificates` tab in the proxy interface and upload the certificate and key.

Add `localtest.me+3-key.pem` to the key box and `localtest.me+3.pem` to the certificate box.

#### Update the routes

Now you can apply the SSL certificates to the routes. On the `Hosts` tab, click on the three vertical dots of the `whoami` route and click on `Edit`.

Here you can select the `SSL` tab and select the certificate you uploaded earlier.

Now do this for the `authelia` and `users` routes.

#### Access the routes

Now we can access the routes! Got to [whoami.localtest.me](whoami.localtest.me) and you should be challenged with a login screen.

Here you can use the `admin` credentials generated by the script to login.

Once you have logged in, you can see the details of the request that was made to the `whoami` service.

You now have a secure web portal running on your local machine!

#### Add a user

You will want more than just the admin user to be able to access the portal. To add a user, go to [users.localtest.me](users.localtest.me) and login with the LDAP admin credentials generated by the script.

Once logged in, you can add a user with the `Create a user` button.








<!-- ------------------------------------- How to ---------------------------------------- -->

## How to

### Configure the proxy

#### Setup your first route
Go to [localhost:81](localhost:81) and login with the default credentials: 
- admin@example.com
- changeme
  
Update the credentials to some that suit you.

Click on the menu "Hosts" and then "Proxy Hosts". Add a Proxy Host:
- Add a full domain name (subdomain and domain) to the Domain Name box:
  ```
  whoami.mylovelydomain.org
  ```
- set the Forward Hostname to
  ```
  apperture-whoami
  ```
- Use the port
  ```
  80
  ```

#### Setup Authelia
Add another proxy host:
- Add a subdomain:
  ```
  authelia.mylovelydomain.org
  ```
- Set the Forward Hostname to
  ```
  apperture-authelia
  ```
- Use the port
  ```9091```
- In the "Advanced" tab, paste:
    ```
    location / {
        include /snippets/proxy.conf;
        proxy_pass $forward_scheme://$server:$port;
    }
    ```
    
#### Protect the route
Click on the three vertical dots of the `whoami` route and click on "Edit".
In the "Advanced" tab, paste:
```
include /snippets/authelia-location.conf;
location / {
    include /snippets/proxy.conf;
    include /snippets/authelia-authrequest.conf;
    proxy_pass $forward_scheme://$server:$port;
}
```

#### Setup the user-admin site
Add another proxy host:
- Add a subdomain, for example
  ```
  users.mylovelydomain.org
  ```
- Set the Forward Hostname to
  ```
  apperture-ldap
  ```
- Use the port
  ```
  17170
  ```
- In the "Advanced" tab, paste:
    ```
    include /snippets/authelia-location.conf;
    location / {
        include /snippets/proxy.conf;
        include /snippets/authelia-authrequest.conf;
        proxy_pass $forward_scheme://$server:$port;
    }
    ```
Go to `users.mylovelydomain.org` and login with the LLDAP admin credentials.
Add a non-admin user.

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
