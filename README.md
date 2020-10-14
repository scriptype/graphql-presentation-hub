# GraphQL Presentation Hub

This repo is used for deploying the 2 parts of the GraphQL presentation app. For
local development environment, this repo can be ignored.

The workflow is designed with the idea of using a DigitalOcean droplet that has
docker pre-installed in it.

Currently there's no CI/CD pipeline to automate the deployment process.

## How to deploy for the first time

`ssh` into your server, and then do the following:

```sh
# Let's create the app folder
mkdir app

# Go to the folder
cd app

# Run this executable to quickly clone the necessary repositories into
# appropriate folders
./clone

# Create necessary .env files
echo "REACT_APP_GRAPHQL_API_URL=<API_URL>" > ./react-apollo/.env.production
echo "API_BASE_URL=<CHARGING_STATIONS_REST_API_URL>" > ./node-graphql/.env

# Get the system up and running
# Docker should start in detached mode, so you can use the session for other things.
# App should be accessible through http on the IP once the system is up and running.
docker-compose up -d
```

## How to deploy the next iterations

Once the initial setup is done, deploying future changes is simpler.

Again, `ssh` into your server, and then do the following:

```sh
# Go to app folder
cd app

# Pull the latest changes in all parts of the project
./pull

# Build docker images, recreate containers and run the project setup
# When it finishes building, new version of the app should be ready & accessible.
docker-compose up -d --build --force-recreate
```

## Nice to know docker commands

These commands helped me to understand better what's happening inside containers:

```sh
# Check logs of a container:
docker logs <container-id> --follow

# Run a command within a container:
docker exec <container-id> <command>

# When you want to remove everything unused, to open up some disk space
docker system prune -af
```

## Configuring domains and obtaining SSL certificates

By default, the project is configured to deploy a non-secure http/1.1 nginx.
When you decide to switch to a secure connection (with a domain name), make sure
you have these:
- A domain
- DNS lookups pointed on the registrar side to cloud provider's name servers.
- Necessary A and CNAME records added on the cloud provider side.

Firstly, you would need to replace occurences of `chargin.cf` and `www.chargin.cf`
in nginx configs and docker-compose.yml with your own domain name.

Once you're good to go, ssh into the server and do the following:

```sh
# Change to app directory
cd app

# Switch to using nginx config for SSL connection.
# It should print: "Now using nginx for https/2".
./toggle-nginx-ssl

# Comment-in the certbot part in the docker-compose.yml
# (Remove `#` characters before the certbot block, and adjust the indentation)
vim docker-compose.yml

# Create folder for storing Diffie-Hellman parameters (used for obtaining SSL certificates)
mkdir dhparam

# Generate key
sudo openssl dhparam -out /root/app/dhparam/dhparam-2048.pem 2048

# Get the whole setup up and running
docker-compose up -d --build

# Check if certbot successfully obtained the certificates
docker logs <certbot-container-id>

# If so, we don't need to run certbot from now on (until renewal time)
# So, again comment-out the certbot-related parts in docker-compose
# (Put # character before lines in certbot block)
vim docker-compose.yml

# That's it! If everything went as planned, our service now should be accessible
# via https/2. We reverted our docker-compose to avoid running certbot on every deploy.
# That's because of API rate-limits of letsencrypt.
```
