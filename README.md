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
# Install NodeJS 20.x
sudo apt update
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node --version
## v20.18.2
npm --version
## 10.8.2
```



## Create a simple Angular website

Install `Angular` for the web service:

```shell
# Update npm
sudo npm install -g npm@11.1.0
# Install Angular
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

Install `mkcert` package:

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
## For Linux
mkdir linux
cd linux
mkcert -install
mkcert localhost 127.0.0.1 ::1
cd ..

## for macOS
mkdir -p macbook
cd macbook
mkcert localhost 127.0.0.1 ::1
cd ..

## for Windows
mkdir windows
cd windows
mkcert localhost 127.0.0.1 ::1
cd ..

## Created a new certificate valid for the following names 📜
## - "localhost"
## - "127.0.0.1"
## - "::1"
##  The certificate is at "./localhost+2.pem" and the key at "./localhost+2-key.pem" ✅
##  It will expire on 1 June 2027 🗓
```



Then re-launch the website by adding the `RootCA`:

For Linux

```shell
ng serve --ssl --ssl-cert "./linux/localhost+2.pem" --ssl-key "./linux/localhost+2-key.pem" --no-hmr
```
For macOS
```shell
ng serve --ssl --ssl-cert "./macos/localhost+2.pem" --ssl-key "./macos/localhost+2-key.pem" --no-hmr
```

For Windows

```shell
ng serve --ssl --ssl-cert "windows\localhost+2.pem" --ssl-key "windows\localhost+2-key.pem" --no-hmr
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



## End

