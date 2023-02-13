# Awesome NGINX 
## Introduction
Please refer to 
- https://medium.com/tech-it-out/proxy-vs-reverse-proxy-vs-load-balancer-3937915631c8
- https://www.nginx.com/products/nginx/
- https://levelup.gitconnected.com/multiplex-tls-traffic-with-sni-routing-ece1e4e43e56


## Prerequisites 
### Clone this repo via
```
git clone https://github.com/Alliedium/awesome-nginx.git
```

### Configure IP subnet for Docker containers
Let us make it so IPs start with `172.32`?

```
❯ cat /etc/docker/daemon.json
{
  "debug" : true,
  "default-address-pools" : [
    {
      "base" : "172.32.0.0/16",
      "size" : 24
    }
  ]
}
```
Refer to https://serverfault.com/questions/916941/configuring-docker-to-not-use-the-172-17-0-0-range
### Install w3m text-based web browser

install w3m 
```
sudo pacman -S w3m
```
and then

### Install NGINX

#### Manjaro/Arch Linux
```
sudo pacman -S nginx
```

### Disclaimer
All examples below assume the host name is "mkde0". Please make sure to
adjust all commands for your host by replacing "mkde0" with your host
name (use "hostname -s" to see your hostname).

### Modify `/etc/hosts`:
```
sudo sh -c 'echo "127.0.0.1 nginx1.mkde0.intranet" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 nginx2.mkde0.intranet" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 nginx3.mkde0.intranet" >> /etc/hosts'
```
### Run Docker Hoster
to automatically map container names to their IPs:
```
./nginx-in-docker/docker-run-docker-hoster.sh
```


## 1. Single static page

Study NGINX config:
```
cat ./1-static-page.nginx.conf
```
And then use it to configure NGINX
```
sudo cp ./1-static-page.nginx.conf /etc/nginx/nginx.conf
sudo nginx -s reload
```
Then make sure it works as expected
```
w3m http://127.0.0.1:8080 -dump
w3m http://nginx1.mkde0.intranet:8080 -dump
```

## 2. Virtual hosting with static pages

Study NGINX configuration:

```
cat ./2-vitual-hosting-static.nginx.conf
```
and then configure NGINX:

```
sudo cp ./2-virtual-hosting-static.nginx.conf /etc/nginx/nginx.conf
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index2.html
sudo sed -i "s/nginx/nginx2/g" /usr/share/nginx/html/index2.html
sudo nginx -s reload

w3m http://127.0.0.1:8080 -dump
w3m http://nginx1.mkde0.intranet:8080 -dump
w3m http://nginx2.mkde0.intranet:8080 -dump
```

## 3. HTTP load balancing
### Let us see how Nginx servers are configured.
Let us have a look at NGINX-Demos/nginx-hello docker image and study how
it configures NGINX by looking at

https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello
https://github.com/nginxinc/NGINX-Demos/blob/master/nginx-hello/hello.conf

Also let us refer to 

https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/
http://nginx.org/en/docs/http/ngx_http_sub_module.html#example

### Study helper scripts for running NGINX in Docker 
All the scripts are in `./nginx-in-docker` folder, pay attention to 
scripts for running/stopping NGINX in Docker in HTTP mode 

### Run nginx demos web servers
```
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-0
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-1
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-2
```
and sure that Docker Hoster is registered DNS names for newly launched
containers:

```
docker ps
cat /etc/hosts
```

### Show mapping between docker networks, IP addresses of the containers
  and veths

Let us refer to
https://docs.docker.com/engine/tutorials/networkingcontainers/ and
verify

Docker networks:
```
docker network ls
```
Linux bridges and links:
```
ip link
```
Mapping between containers, IP addresses and bridges
```
docker inspect -f '{{.Name}} - {{.NetworkSettings.IPAddress }} - {{.NetworkSettings.Networks}}' $(docker ps -aq)
```

Download the script for mapping between veths and containers
```
wget https://raw.githubusercontent.com/samos123/docker-veth/master/docker-veth.sh
```
Show the mapping between veths and containers

```
sudo ./docker-veth.sh
```

### Access webservers running inside containers via a text based web

```
w3m http://hello-http-0 -dump
w3m http://hello-http-1 -dump
```
### Confgure Nginx as a Load Balancer combined with Virtual Hosting

Study the new NGINX configuration:

```
cat ./3-virtual-hosting-n-load-balancing.nginx.conf
```

And then apply the new nginx configuration
```
sudo cp ./3-virtual-hosting-n-load-balancing.nginx.conf /etc/nginx/nginx.conf
sudo nginx -s reload
```

The web page at "http://127.0.0.1:8080" is empty:
```
w3m http://127.0.0.1:8080 -dump
```

while Round Robing algorithm works as expected:
```
w3m http://nginx1.mkde0.intranet:8080 -dump
w3m http://nginx1.mkde0.intranet:8080 -dump
w3m http://nginx1.mkde0.intranet:8080 -dump
```

The static content is available as well:
```
w3m http://nginx1.mkde0.intranet:8080/static-legacy -dump
w3m http://nginx2.mkde0.intranet:8080 -dump
```

## 4. Nginx HTTPS Virtual Hosting with SNI without TLS termination

### Refer to 
https://levelup.gitconnected.com/multiplex-tls-traffic-with-sni-routing-ece1e4e43e56

to understand the network topology we are going to build

### Make sure that SNI is enabled 
```
nginx -V
```
### Study how "docker-run-nginx-hello-https.sh" script works
by looking at its source code and the correspodning Dockerfile

### Run NGINX HTTPS backend servers

Build the Docker image for NGINX Hello HTTPS server first via
```
./nginx-in-docker/docker-build-nginx-hello-https.sh
```

and then run 3 containers

```
./nginx-in-docker/docker-run-nginx-hello-https.sh hello-https-0
./nginx-in-docker/docker-run-nginx-hello-https.sh hello-https-1
./nginx-in-docker/docker-run-nginx-hello-https.sh hello-https-2
``` 
Then make sure that their DNS names are registered in "/etc/hosts"
```
cat /etc/hosts
```

### See what happens if you try to access these web servers directly

```
w3m https://hello-https-0 -dump
w3m https://hello-https-0 -insecure -dump
```

### Configure NGINX for SNI

Study the new config
```
cat ./4-virtual-hosting-sni-no-tls-termination.nginx.conf /etc/nginx/nginx.conf
```

and then apply it

```
sudo cp ./4-virtual-hosting-sni-no-tls-termination.nginx.conf /etc/nginx/nginx.conf
sudo nginx -s reload
```

### Add 2 external FQDNs for NGINX to hosts file:

```
sudo sh -c 'echo "127.0.0.1 hello-https-0.mkde0.intranet" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 hello-https-1.mkde0.intranet" >> /etc/hosts'
```

### Let us check how SNI works

```
w3m https://hello-https-0.mkde0.intranet:8443 -insecure -dump
w3m https://hello-https-1.mkde0.intranet:8443 -insecure -dump
```

## 5. Virtual Hosting with TLS termination

### Run HTTP backend severs
```
./nginx-in-docker/docker-run-nginx-hello-http.sh "hello-http-0"
./nginx-in-docker/docker-run-nginx-hello-http.sh "hello-http-1"
```

and make sure they are visible in "/etc/host"
```
cat /etc/hosts
```

### Let us generate two self-signed certificates
```
./nginx-in-docker/main-gen-certs.sh nginx1.mkde0.intranet
sudo cp ./public.crt /etc/nginx/public-0.crt
sudo cp ./private.key /etc/nginx/private-0.key
sudo chmod a+r /etc/nginx/private-0.key

./nginx-in-docker/main-gen-certs.sh nginx2.mkde0.intranet
sudo cp ./public.crt /etc/nginx/public-1.crt
sudo cp ./private.key /etc/nginx/private-1.key
sudo chmod a+r /etc/nginx/private-1.key
```
### Study the new NGINX configuration
```
cat ./5-virtual-hosting--tls-termination.nginx.conf
```

### Apply the new configuration 
```
sudo cp ./5-virtual-hosting--tls-termination.nginx.conf /etc/nginx/
sudo nginx -s reload
```

### Make sure reverse proxy works as expected

```
w3m https://nginx1.mkde0.intranet:8443 -dump -insecure
w3m https://nginx2.mkde0.intranet:8443 -dump -insecure
```


## References
### Docker
- https://docs.docker.com/engine/tutorials/networkingcontainers/
- https://github.com/samos123/docker-veth/blob/master/docker-veth.sh

### Nginx

- http://nginx.org/en/docs/
- http://nginx.org/en/docs/beginners_guide.html
- https://docs.nginx.com/nginx/admin-guide/load-balancer/http-load-balancer/ 
- https://docs.nginx.com/nginx/admin-guide/load-balancer/tcp-udp-load-balancer/
- https://www.baeldung.com/linux/nginx-docker-container
- https://github.com/digitalocean/nginxconfig.io
- https://www.digitalocean.com/community/tools/nginx
- https://github.com/trimstray/nginx-admins-handbook
- https://github.com/h5bp/server-configs-nginx
- https://artifacthub.io/packages/helm/bitnami/nginx
- https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello
- https://hub.docker.com/r/nginxdemos/hello/
- https://www.youtube.com/watch?v=7VAI73roXaY
- https://levelup.gitconnected.com/multiplex-tls-traffic-with-sni-routing-ece1e4e43e56
