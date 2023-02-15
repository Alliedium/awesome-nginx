# Awesome NGINX 
## Introduction
Please refer to 
- https://medium.com/tech-it-out/proxy-vs-reverse-proxy-vs-load-balancer-3937915631c8
- https://www.nginx.com/products/nginx/
- https://levelup.gitconnected.com/multiplex-tls-traffic-with-sni-routing-ece1e4e43e56


## Prerequisites 
### Clone this repo via
```
git clone https://github.com/Alliedium/awesome-nginx.git ~/awesome-nginx
cd ~/awesome-nginx
```

In all the examples below assume that current folder is
"~/awesome-nginx".

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

install w3m (see https://github.com/tats/w3m):
```
sudo pacman -S w3m
```
and then

### Install NGINX

#### Manjaro/Arch Linux
```
sudo pacman -S nginx
sudo systemctl enable nginx --now
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
#    this is the same as 
# sudo systemctl reload nginx
```
We can also check NGINX configuration via 
```
sudo nginx -t
```
or 
```
sudo nginx -T
```

Then let us make sure it works as expected:
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
All the scripts are in `./nginx-in-docker` folder. Here is what
each of the script does:

- `docker-run-nginx-hello-http.sh "hello-http-0"` launches HTTP
  sever with DNS name "hello-http-0" in Docker container named
  "hello-http-0" on port 80

- `docker-run-nginx-hello-https.sh "hello-https-0"` launches HTTPS 
  sever with DNS name "hello-https-0" and self-signed certificate issued
  for "hello-https-0.mkde0.intranet" in Docker container named
  "hello-https-0" on port 443

- `docker-run-docker-hoster.sh` runs "Docker hoster" in Docker

- `docker-stop-rm-docker-hoster.sh` stops "Docker hoster" and removes
  its stopped container
- `docker-stop-rm-nginx-hello-http.sh` stops all Docker containers with
  HTTP servers and removes the stopped containers.
- `docker-stop-rm-nginx-hello-https.sh` stops all Docker containers with
  HTTPS servers and removes the stopped containers.


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

while Round Robin algorithm works as expected:
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
cat ./4-virtual-hosting-sni-no-tls-termination.nginx.conf
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

## 5. Virtual Hosting with TLS termination and no HTTP routing

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

./nginx-in-docker/main-gen-certs.sh nginx2.mkde0.intranet
sudo cp ./public.crt /etc/nginx/public-1.crt
sudo cp ./private.key /etc/nginx/private-1.key
```

### Study the new NGINX configuration
In the previous example we used `$ssl_preread_server_name` and it was ok
because this variable was available at the time we used it to forward
our requests to corresponding backend server. However, in case of TLS
termination we cannot use this variable in `map` block to map server
names to certificates used by NGINX (assuming we want different
certificate for each server name). This is because
`$ssl_preread_server_name` is not available at the time we read our
certification. To work around that we need to use `$ssl_server_name`
variable of NGINX to make it so NGINX extracts server_name from
certificates and compares that server than with client certification.
`ssl_preread on` is no longer necessary as well (because it just makes
`$ssl_preread_server_name` variable available).
We do not make routing decisions based on HTTP protocol which is why we
still use `stream` blocok (as in the previous example).
```
cat ./5-virtual-hosting--tls-termination.nginx.conf
```

### Apply the new configuration 
```
sudo cp ./5-virtual-hosting--tls-termination.nginx.conf /etc/nginx/
sudo nginx -s reload
```

### Make sure reverse proxy works as expected

Running
```
sudo nginx -t
``` 
to verify NGINX configuration shows that it is. However, when try to
access our HTTP serves via

```
w3m https://nginx1.mkde0.intranet:8443 -dump -insecure
w3m https://nginx2.mkde0.intranet:8443 -dump -insecure
```

we see that NGINX doesn't work as expected:
```
SSL error: error:0A000438:SSL routines::tlsv1 alert internal error, a workaround might be: w3m -insecure
w3m: Can't load https://nginx1.mkde0.intranet:8443.
```

Checking logs via
```
sudo journalctl -u nginx|less 
```
shows that NGINX can't read private keys. Maybe the reason is that
NGINX doesn't run as root? Let us check that:
```
systemctl show -pUser,UID,ControlGroup nginx
```
shows
```
UID=[not set]
ControlGroup=/system.slice/nginx.service
User=
```
while
```
sudo cat /usr/lib/systemd/system/nginx.service
```
shows
```
[Unit]
Description=A high performance web server and a reverse proxy server
After=network.target network-online.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
PrivateDevices=yes
SyslogLevel=err

ExecStart=/usr/bin/nginx -g 'pid /run/nginx.pid; error_log stderr;'
ExecReload=/usr/bin/nginx -s reload
KillMode=mixed

[Install]
WantedBy=multi-user.target
```
This clearly indicates that NGINX runs under "root" user. If so - how
can it be that NGINX cannot read private keys?
The answer is tricky - NGINX starts as root but then it launches child
processes from under "http" user which doesn't have root permissions.
Since we use "map" block in our "nginx.conf" configuration NGINX cannot
read private keys when the master process starts (while NGINX still has
root permissions). So reading private keys is postponed till later and
done by the child process which doesn't have root permissions to read
private keys.

Let us make sure that this is the case by running
```
sudo lsof -nP -i | grep 'LISTEN'|grep 'nginx'
```
which shows

```
nginx     17606    root    5u  IPv4 162506      0t0  TCP *:8443 (LISTEN)
nginx     38902    http    5u  IPv4 162506      0t0  TCP *:8443 (LISTEN)
```
confirming that there are two NGINX processes - the master and the child
one and the child process runs from under "http" user.

Let us now fix permissions for NGINX private keys by making "http" user
the owner of private keys:

```
sudo chown http /etc/nginx/private-*
```
Permissions for public keys can remain unchanged as they are "644" by
default (set by openssl).

Now NGINX should work as expected, we can check that by running

```
w3m https://nginx1.mkde0.intranet:8443 -dump -insecure
w3m https://nginx2.mkde0.intranet:8443 -dump -insecure
```

## 6. Virtual Hosting with TLS termination and HTTP routing

In the previous example we used TLS termination and SNI routing but we
did not make any routing decisions based on content of HTTP requestion.
Let us consider a new example that adds HTTP routing on top of what we
had in the previous example:

```
cat ./6-virtual-hosting-tls-termination-http-routing.nginx.conf
```

As you can see now we use `http` block instead of `stream`, this is
because `http` block allows NGINX to look inside content of HTTP
request. We also introduce multiple upstream backends and path rewriting
done using different methods.

This time we require 6 HTTP servers:
```
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-0
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-1
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-2
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-3
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-4
./nginx-in-docker/docker-run-nginx-hello-http.sh hello-http-5
```

Let us generate 3 certificates;
for the default server:
``` 
./nginx-in-docker/main-gen-certs.sh "*"
sudo cp ./private.key /etc/nginx/private-default.key 
sudo cp ./public.crt /etc/nginx/public-default.crt
```
for `nginx1.mkde0.intranet`
```
./nginx-in-docker/main-gen-certs.sh "nginx1.mkde0.intranet"
sudo cp ./private.key /etc/nginx/private-0.key 
sudo cp ./public.crt /etc/nginx/public-0.crt
```
and for `nginx2.mkde0.intranet`
```
./nginx-in-docker/main-gen-certs.sh "nginx2.mkde0.intranet"
sudo cp ./private.key /etc/nginx/private-1.key 
sudo cp ./public.crt /etc/nginx/public-1.crt
```

Let us apply the new configuration

```
sudo cp /6-virtual-hosting-tls-termination-http-routing.nginx.conf /etc/nginx/nginx.conf
sudo nginx -s reload
```

Finally, let us check that everything works as expected, starting with 
```
w3m https://nginx1.mkde0.intranet:8443 -dump
w3m https://nginx1.mkde0.intranet:8443 -dump
```
to make sure that Round Robin load balancing is used for "/" path for 
`nginx1.mkde0.intranet`.

Accessing "/alpha" and "beta" paths lead to "/" path on different backs
as expected:

```
w3m https://nginx1.mkde0.intranet:8443/alpha -dump
w3m https://nginx1.mkde0.intranet:8443/beta -dump
```
while accessing "/gamma" path leads to "/delta" path and also features
Round Robin load balancing:
```
w3m https://nginx1.mkde0.intranet:8443/gamma -dump
w3m https://nginx1.mkde0.intranet:8443/gamma -dump
```
The static content is available as well, this time via HTTPS:
```
w3m https://nginx1.mkde0.intranet:8443/static-legacy -dump
w3m https://nginx2.mkde0.intranet:8443 -dump
```
As we can see in this particular example, when we specify certificates
exmplicitly (instead of using `map` block) via `ssl_certificate` and 
`ssl_certificate_key` directives we do not need to make `http` user an
owner of private keys as in example 5 above. This is because in this
case certificates are read by the master process that runs from under
"root" account.

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
