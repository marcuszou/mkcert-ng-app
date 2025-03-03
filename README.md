# Local SSL with `mkcert`

by Marcus Zou | 1 March 2025 | 3 minutes reading | 15 minutes practice

![mkcert-logo](./assets/mkcert-logo.png)

## Why mkcert?

TLS and SSL are vital for web security, but they're useless unless you have a trusted *root certificates* list. Root certificates identify who you trust unconditionally as well as who you trust to authenticate the legitimate owners of a website.

Modern browsers are making it easier to evaluate your list of trusted root certificate authorities. `mkcert.org` is one of the open source site handling this RootCA thing, but it turns out https://mkcert.dev or https://github.com/FiloSottile/mkcert has a better and easy-to-deploy approach for such purpose.



## Pre-requisites

Make some pre-requisites ready:

```shell
# Install common tools - Do Not install NodeJS/npm here as it's very low version.
sudo apt update && sudo apt upgrade -y
sudo apt install curl git htop nano net-tools wget tar unrar unzip zip tree -y
# Install NodeJS 22.x (LTS)
sudo apt update
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt install -y nodejs
node --version
## v22.14.0
npm --version
## 10.9.2
# Update npm
sudo npm install -g npm@latest
```



## Create a simple Angular website

Install `Angular` engine for the web service:

```shell
## For Linux
sudo npm install -g @angular/cli@latest
```
```shell
## For macOS
brew install @angular/cli@latest
```

```shell
## For Windows
winget install nodejs-lts
winget install @angular/cli@latest
```

Create a Angular website:

```shell
ng new mkcert-ng-app
## Press: Y, N, Enter, N keys to create a simple Angular website
cd mkcert-ng-app
ng serve
## -> Local:  http://lolcahost:4200
## press h + enter to show help
```

Open the website: http://localhost:4200 as below:

![http-conn](./assets/ng-site-http.png)



## Install `mkcert` and Create the local CA

Install `mkcert` tool:

```shell
## For Linux - if you use Firefox browser
sudo apt install libnss3-tools 
## Install mkcert
sudo apt install mkcert

## for macOS - if you use Firefox browser
brew install nss
## Install mkcert
brew install mkcert

## For Windows
winget install mkcert
```



Then create the certificate and key:

```shell
## Create local RootCA at `mkcert-ng-app` folder
## For Linux/macOS/Windows
mkcert -install
## Where is the RootCA?
mkcert -CAROOT
## /home/zenusr/.local/share/mkcert

## create a simple certificate in subfolder: devcerts
mkdir devcerts
cd devcerts
mkcert localhost 127.0.0.1 ::1
cd ..
## Advanced method: run from the main folder and save the cert/key in the subfolder:
mkcert -cert-file devcerts/cert.pem -key-file devcerts/key.pem localhost 127.0.0.1 ::1

## The output be like:
## Created a new certificate valid for the following names 📜
## - "localhost"
## - "127.0.0.1"
## - "::1"
##  The certificate is at "devcerts/cert.pem" and the key at "devcerts/key.pem" ✅
##  It will expire on 1 June 2027 🗓
```



Then re-launch the website by adding the `RootCA`:

For Linux/macOS

```shell
ng serve --ssl --ssl-cert "devcerts/cert.pem" --ssl-key "devcerts/key.pem" --no-hmr
```
For Windows

```shell
ng serve --ssl --ssl-cert "devcerts\cert.pem" --ssl-key "devcerts\key.pem" --no-hmr
```



Here is the SSL connection: https://localhost:4200

![ssl-conn](./assets/ng-site-http-ssl.png)



## Advanced options

```shell
	-cert-file FILE, -key-file FILE, -p12-file FILE
	    Customize the output paths.

	-client
	    Generate a certificate for client authentication.

	-ecdsa
	    Generate a certificate with an ECDSA key.

	-pkcs12
	    Generate a ".p12" PKCS #12 file, also know as a ".pfx" file,
	    containing certificate and key for legacy applications.

	-csr CSR
	    Generate a certificate based on the supplied CSR. Conflicts with
	    all other flags and arguments except -install and -cert-file.
```

Example:

```shell
mkcert -keyfile key.pem -cert-file cert.pem mydomain.com *.mydomain.com localhost 127.0.0.1 ::1
```

More: `mkcert` automatically generates an S/MIME certificate if one of the supplied names is an email address.

```shell
mkcert user@example.com
```



#### Using the root with Node.js

Node does not use the system root store, so it won't accept mkcert certificates automatically. Instead, you will have to set the [`NODE_EXTRA_CA_CERTS`](https://nodejs.org/api/cli.html#cli_node_extra_ca_certs_file) environment variable.

```
export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
```



#### Changing the location of the CA files

The CA certificate and its key are stored in an application data folder in the user home. You usually don't have to worry about it, as installation is automated, but the location is printed by `mkcert -CAROOT`.

If you want to manage separate CAs, you can use the environment variable `$CAROOT` to set the folder where mkcert will place and look for the local CA files.



#### Installing the CA on other systems

Installing in the trust store does not require the CA key, so you can export the CA certificate and use mkcert to install it in other machines.

- Look for the `rootCA.pem` file in `mkcert -CAROOT`
- copy it to a different machine
- set `$CAROOT` to its directory
- run `mkcert -install`

Remember that `mkcert` is meant for development purposes, not production, so it should not be used on end users' machines, and that you should *not* export or share `rootCA-key.pem`.



## localhost TLS through Nginx Docker

1- Build the custom image: Angular + Nginx with a `Dockerfile`:

```
# Stage 1
FROM node:alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2
FROM nginx:alpine
COPY --from=builder /app/dist/my-ng-app/browser /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
COPY ./devcerts /etc/nginx/certs
EXPOSE 80
```

2- Create directories and generate new cert/key files:

```
mkdir devcerts
mkcert -certofile ./devcerts/cert.pem -key-file ./devcerts/key.pem localhost 127.0.0.1 ::1

mkdir logs
```

3- Add `nginx.conf` for future.

```shell
events{}

http {
  
  include /etc/nginx/mime.types;
  
  server {
    listen 80;
    server_name localhost;
    #return 301 https://$host$request_uri;

    location / {
      try_files $uri $uri/ /index.html =404;
    }

    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location / {
        #proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
  }

  server {
    listen 443 ssl;
    server_name localhost;

    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    location = /favicon.ico {
      access_log off; 
      log_not_found off;
    }

    location / {
      #proxy_pass http://localhost:8000;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
    }
  }
}

```

4- Run commands as below:

```shell
docker build -t ang-cert .
docker run -d -p 80:80 ang-cert
```

This will start your application on port 80, then access your service from `http://localhost` and `https://localhost`.




## End

