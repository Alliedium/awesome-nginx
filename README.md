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

### Modify `/etc/hosts`:
```
sudo sh -c 'echo "127.0.0.1 nginx1.devops-host.intranet" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 nginx2.devops-host.intranet" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 nginx3.devops-host.intranet" >> /etc/hosts'
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
w3m http://nginx1.devops-host.intranet:8080 -dump
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
w3m http://nginx1.devops-host.intranet:8080 -dump
w3m http://nginx2.devops-host.intranet:8080 -dump
```

## 3. HTTP load balancing
### Let us see how Nginx servers are configured.
Let us have a look at NGINX-Demos/nginx-hello docker image and study how
it configures NGINX by looking at

- https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello
- https://github.com/nginxinc/NGINX-Demos/blob/master/nginx-hello/hello.conf

Also let us refer to 

- https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/
- http://nginx.org/en/docs/http/ngx_http_sub_module.html#example

### Study helper scripts for running NGINX in Docker 
All the scripts are in `./nginx-in-docker` folder. Here is what
each of the script does:

- `docker-run-nginx-hello-http.sh "hello-http-0"` launches HTTP
  sever with DNS name "hello-http-0" in Docker container named
  "hello-http-0" on port 80

- `docker-run-nginx-hello-https.sh "hello-https-0"` launches HTTPS 
  sever with DNS name "hello-https-0" and self-signed certificate issued
  for "hello-https-0.devops-host.intranet" in Docker container named
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
w3m http://nginx1.devops-host.intranet:8080 -dump
w3m http://nginx1.devops-host.intranet:8080 -dump
w3m http://nginx1.devops-host.intranet:8080 -dump
```

The static content is available as well:
```
w3m http://nginx1.devops-host.intranet:8080/static-legacy -dump
w3m http://nginx2.devops-host.intranet:8080 -dump
```

## 4. Nginx HTTPS Virtual Hosting with SNI without TLS termination and with TCP forwarding

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
sudo sh -c 'echo "127.0.0.1 hello-https-0.devops-host.intranet" >> /etc/hosts'
sudo sh -c 'echo "127.0.0.1 hello-https-1.devops-host.intranet" >> /etc/hosts'
```

### Let us check how SNI works

```
w3m https://hello-https-0.devops-host.intranet:8443 -insecure -dump
w3m https://hello-https-1.devops-host.intranet:8443 -insecure -dump
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
./nginx-in-docker/main-gen-certs.sh nginx1.devops-host.intranet
sudo cp ./nginx-in-docker/public.crt /etc/nginx/public-0.crt
sudo cp ./nginx-in-docker/private.key /etc/nginx/private-0.key

./nginx-in-docker/main-gen-certs.sh nginx2.devops-host.intranet
sudo cp ./nginx-in-docker/public.crt /etc/nginx/public-1.crt
sudo cp ./nginx-in-docker/private.key /etc/nginx/private-1.key
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
cat ./5-virtual-hosting-tls-termination.nginx.conf
```

### Apply the new configuration 
```
sudo cp ./5-virtual-hosting-tls-termination.nginx.conf /etc/nginx/nginx.conf
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
w3m https://nginx1.devops-host.intranet:8443 -dump -insecure
w3m https://nginx2.devops-host.intranet:8443 -dump -insecure
```

we see that NGINX doesn't work as expected:
```
SSL error: error:0A000438:SSL routines::tlsv1 alert internal error, a workaround might be: w3m -insecure
w3m: Can't load https://nginx1.devops-host.intranet:8443.
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
w3m https://nginx1.devops-host.intranet:8443 -dump -insecure
w3m https://nginx2.devops-host.intranet:8443 -dump -insecure
```

## 6. Virtual Hosting with TLS termination and HTTP routing

In the previous example we used TLS termination and SNI routing but we
did not make any routing decisions based on content of HTTP request.
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
sudo cp ./nginx-in-docker/private.key /etc/nginx/private-default.key 
sudo cp ./nginx-in-docker/public.crt /etc/nginx/public-default.crt
```
for `nginx1.devops-host.intranet`
```
./nginx-in-docker/main-gen-certs.sh "nginx1.devops-host.intranet"
sudo cp ./nginx-in-docker/private.key /etc/nginx/private-0.key 
sudo cp ./nginx-in-docker/public.crt /etc/nginx/public-0.crt
```
and for `nginx2.devops-host.intranet`
```
./nginx-in-docker/main-gen-certs.sh "nginx2.devops-host.intranet"
sudo cp ./nginx-in-docker/private.key /etc/nginx/private-1.key 
sudo cp ./nginx-in-docker/public.crt /etc/nginx/public-1.crt
```

Let us apply the new configuration

```
sudo cp /6-virtual-hosting-tls-termination-http-routing.nginx.conf /etc/nginx/nginx.conf
sudo nginx -s reload
```

Finally, let us check that everything works as expected, starting with 
```
w3m https://nginx1.devops-host.intranet:8443 -dump
w3m https://nginx1.devops-host.intranet:8443 -dump
```
to make sure that Round Robin load balancing is used for "/" path for 
`nginx1.devops-host.intranet`.

Accessing "/alpha" and "beta" paths lead to "/" path on different backs
as expected:

```
w3m https://nginx1.devops-host.intranet:8443/alpha -dump
w3m https://nginx1.devops-host.intranet:8443/beta -dump
```
while accessing "/gamma" path leads to "/delta" path and also features
Round Robin load balancing:
```
w3m https://nginx1.devops-host.intranet:8443/gamma -dump
w3m https://nginx1.devops-host.intranet:8443/gamma -dump
```
The static content is available as well, this time via HTTPS:
```
w3m https://nginx1.devops-host.intranet:8443/static-legacy -dump
w3m https://nginx2.devops-host.intranet:8443 -dump
```
As we can see in this particular example, when we specify certificates
exmplicitly (instead of using `map` block) via `ssl_certificate` and 
`ssl_certificate_key` directives we do not need to make `http` user an
owner of private keys as in example 5 above. This is because in this
case certificates are read by the master process that runs from under
"root" account.


## 7. Virtual hosting with LetsEncrypt TLS certificate generated by certbot with HTTP-01 challange

### Update Nginx configuration

Let us look at the new configuration:
```
cat ./7-virtual-hosting-static-tls-certbot-http-01.nginx.conf
```

we see that we have 3 virtual hosts:
- `nginx.devops-host.intranet`
- `nginx0-manjaro.devopshive.link` 
- `nginx1-manjaro.devopshive.link` 

 The first one is configured similarly to the second example while the remaining two will be reachable from outside once we register our domain name and configure AWS Route53 and our firewall to make our NGINX reachable from internet.

* Please note that `devopshive.link` is used purely as an example, you should pick and register your own domain name so that `nginx0-manjaro.devopshive.link` looks like `nginx0-manjaro.your-domain-name` in your case.

After applying the new configuration

```
sudo cp ./7-virtual-hosting-static-tls-certbot-http-01.nginx.conf /etc/nginx/nginx.conf
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index0.html
sudo sed -i "s/nginx/nginx0/g" /usr/share/nginx/html/index0.html
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index1.html
sudo sed -i "s/nginx/nginx1/g" /usr/share/nginx/html/index1.html
sudo nginx -s reload
```

and running 
```
w3m http://nginx.devops-host.intranet:8080 -dump
```
we see the static "nginx" webpage loaded 
while trying to run

```
w3m http://nginx0-manjaro.devopshive.link -dump
w3m http://nginx1-manjaro.devopshive.link -dump
```
would result in error because the domain name is not registed yet.

### Make sure that nginx running on your Manjaro host is reachable from other VMs on the same network. 
Prior to registering `nginx0-manjaro.devopshive.link` domain name we need to make sure that we can reach our NGINX from at least other VM in the same subnet. 
Our Manjaro host uses iptables that works as a firewall and might prevent us from exposing NGINX to the internet.  
Let us configure iptables first to make sure it doesn't block our HTTP and HTTPS connections from ouside the host.
As the first step please read https://docs.docker.com/network/iptables/ and make sure you understand how iptables chains work when Docker is installed.
Then run `sudo iptables -S` and to avoid problems with iptables blocking nginx make sure you have
```
-A OUTPUT  -j ACCEPT 
``` 
as the first rule in "OUTPUT" rule group, 
```
-A INPUT -j ACCEPT
```
as the first group in "INPUT" rule group
and 
```
-A DOCKER-USER -j ACCEPT
```
in "DOCKER-USER" group.

This will make sure that iptables doesn't block anything from/to our Manjaro host. Please note that such unsecure way of configuring iptables is only acceptable for development purposes. For production you should carefully fine-tune your iptables rules to expose only your services and nothing else (along with introducing other security best-practices).

The easiest way to modify the rules and make the changes persistent is to edit `/etc/iptables/iptables.rules` file by adding the lines above to corresponding places inside the file
and then running
```
sudo iptables-restore < /etc/iptables/iptables.rules
```
This way the rules are re-loaded by `iptables` systemd service (you can check that via running `sudo systemctl status iptables`).

You can also add the following line

```
-A INPUT -p tcp -m multiport --dports 8080,8443 -m state --state NEW -j LOG --log-prefix "New Connection " --log-level 6
```
to the top of ` /etc/iptables/iptables.rules` 

and then use
```
sudo journalctl -k -f
```
to see logs of new HTTP and HTTPS connections on ports 8080 and 8443 correspondigly.
Alternatively you could use `tcpdump -i any port 8443 or port 8080 -n` to
monitor HTTP and HTTPS traffic. This approach, however, requires 
special syntax to show only new connections to make the output less
bloated (see
https://serverfault.com/questions/798745/tcpdump-capture-new-connections-only). 

Once all this is done run the following commands from another VM in the same subnet to make sure that 

### Make sure that our hypervisor firewall (if enabled) is configured to
pass through incoming HTTP and HTTPS connections

See https://pve.proxmox.com/wiki/Firewall

### Register a new domain using Route53 
An important prerequisite to this step is having a pubic IP address allocated to you by your internet provider.
Please follow the instructions from https://github.com/Alliedium/awesome-devops/blob/main/17_networks_ssl-termination_acme_route53_06-oct-2022/README.md
and make sure that you add "A" record "nginx0-manjaro.devopshive.link" in the hosted zone (which is created automatically) pointing to your public IP.

You can either run
```
nslookup nginx0-manjaro.devopshive.link
```
or
```
dig nginx0-manjaro.devopshive.link
```
Please note that both `dig` and `nslookup` require `bind` package installed:
```
sudo pacman -S bind
```
This can be checked via
```
sudo pacman -Fy 
sudo pacman -F dig
sudo pacman -F bind
```
(see https://wiki.archlinux.org/title/Pacman#Search_for_a_package_that_contains_a_specific_file for details).


### Expose ports 8443 and 8080 on NGINX host to internet

We already checked that we can reach NGINX on our Manjaro host from other VM so now let us configure our home lab firewall and expose port 8080 on public IPs port 80 and port 8443 - on public IPs port 7443. The exact way to do it greatly deepends on your infrastructure and your hardware manufacturer but usually configuration can be done by creating entries in firewall and port forwarding sections on your home lab router.

The reason we expose port 8080 on public IPs port 80 (and not 7808 for intance) is requirement of ACME server for HTTP-01 challange to be able to reach our webserver on exactly port 80.
As a result our port mapping will look like this:

```
7443 -> 8443
80   -> 8080
```

Please note that LetsEncrypt doesn't provide a list of public IP
addresses used for certificate validation (see
https://letsencrypt.org/docs/faq/) which means we are forced to
keep our web server's port 80 opened to the whole internet to allow
HTTP-01 validation. If it is a problem you then you might be interested
in DNS-01 validation (see section 8 below).

At this stage commands 

```
w3m http://nginx0-manjaro.devopshive.link -dump
w3m http://nginx1-manjaro.devopshive.link -dump
```
should open static pages served by NGINX.


### Install certbot along with certbot nginx plugin:
Install the plugin
```  
sudo pacman -S certbot certbot-nginx
certbot plugins # just to see which plugins are installed
```
and study its parameters

 ```
certbot --help nginx
certbot --help all
```

### Registering LetsEncrypt account
Lets Encrypt account is used for remembering expiration dates of certificates issued to user and notifying them about certificates that are close to expiration. Under normal circumstances certificates should not get too close to expiration if automatic certificate renewal is configured correctly (see below). However, if this happens, LetsEncrypt needs to know an email address to send the expiration warning emails to (see https://letsencrypt.org/docs/expiration-emails/ and https://community.letsencrypt.org/t/what-is-the-email-used-for-when-i-run-certbot-at-the-first-time/119911 for details). 

There are 2 ways to perform LetsEncrypt account registration:
#### a) Registering LetsEncrypt account explicitly
either via 
```
sudo certbot register --email you-email@address.com # the provided email will be used for expiration warning emails
```
or via providing `--register-unsafely-without-email` which  enables registering an account with no email address. Acording to the `certbot` documentation this is strongly discouraged, because you will be unable to receive notice about impending expiration or revocation of your certificates or problems with your Certbot installation that will lead to failure to renew.

#### b) Registering LetsEncrypt account implicitly
via providing either `--email` parameter or `--register-unsafely-without-email` to the first call of `certbot run` or `certbot certonly` or just `certbot` command.

Either of the methods above makes certbot remember the LetsEncrypt account details on your machine and you are no longer required to provide neither `--email` nor `--register-unsafely-without-email` for all subsequent calls on certbot (on that particular machine).

### Rate limits and staging environment
Lets Encrypt enforces rate limits to allow for the service to be used
by as many people as possible - see https://letsencrypt.org/docs/rate-limits for details about rate limits for production enrvironment.
Staging Environment (see
https://letsencrypt.org/docs/staging-environment/) allows to debug
various problems with certificate issuing and introduces much higher
rate limits. Commands `certonly` and `run` used in the section below support `--test-cert` flag
that switches `certbot` to the staging environment. It is recommended to
test things with `--test-cert` flag first and only then issue the
certificate in production mode by removing this flag.

### Issue certifiates via certbot with HTTP-01 challange

Let us finally trigger an automatic issuing and installation of certificates: 

```
sudo certbot run --nginx -d nginx0-manjaro.devopshive.link -d nginx1-manjaro.devopshive.link --http-01-port 8080 --https-port 8443 # you can skip "run" and write just certbot ....
```

This will automatically identify appropriate places inside our `nginx.conf` and specify certificates for both of the virtual hosts.

Please mind the parameters `--http-01-port` and `--https-port`, the first tells certbot that for HTTP NGINX listens on 8080 instead of standard port 80 while the second one forces certbot to configure TLS on port 8443 instead of of standard 443 (which is what we need because we agreed earlier that we use 8080 for HTTP and 8443 for HTTPS). It is important to realize that `--http-01-port` doesn't change the port which ACME sever tries to access for HTTP-01 challange.


Alternatively we could have run

```
sudo certbot run --nginx -d nginx0-manjaro.devopshive.link  --http-01-port 8080 --https-port 8443
sudo certbot run --nginx -d nginx0-manjaro.devopshive.link -d nginx1-manjaro.devopshive.link --http-01-port 8080 --https-port 8443
```

in which case the first command would have generated the certificate only for one of the domain names while the second one would extend the certificate to the second name.

Now we can also see the certificates managed by certbot:
```
sudo certbot certificates # this should output one certificate for two domains
```

or delete the certificate (DO NOT RUN THAT PLEASE until you complete all the steps for this example)

```
sudo certbot delete --cert-name nginx0-manjaro.devopshive.link
sudo certbot certificates
```

Finally, you can trigger simulate renewal (renewal) certificate(s) with just one command:

```
sudo certbot renew --dry-run # remove '--dry-run' to perform actual renewal
```

### Check that all works as expected

by running

```
w3m https://nginx0-manjaro.devopshive.link:7443 -dump
w3m https://nginx1-manjaro.devopshive.link:7443 -dump
```

Please note that we do not need `-insecure` flag anymore!

### Automatic renewal
On Arch Linux and Manjaro `certbot` comes with `certbot-renew.timer` and
`certbot-renew.service` which calls certbot twice a day to make sure
that certificates are up to date (see
https://wiki.archlinux.org/title/certbot#Automatic_renewal). This timer
is however disabled by default and can be found via
```
sudo systemctl list-unit-files|grep certbot
```
and enabled via

```
sudo systemctl enable certbot-renew.timer --now
```

After that you can see this timer in the list of all active timers:
```
sudo systemctl list-timers --all
```

## 8. Virtual hosting with LetsEncrypt TLS certificate generated by certbot with DNS-01 challange

### Install dns-route53 and nginx plugins 
The reason we also need "nginx" plugin is because we will include some NGINX
config files that are shipped as part of "certbot-nginx" package. 
```
sudo pacman -S certbot-dns-route53 certbot-nginx
```
### Investigate the new NGINX configuration
In this example we will use two other domain names:
- 'nginx2-manjaro.devopshive.link'
- 'nginx3-manjaro.devopshive.link'

to make sure that certificate for this example is separate from the
certificate used in the previous example with HTTP-01 challange.

Let us have a look at the configuration:
```
cat ./8-virtual-hosting-static-tls-certbot-dns-01.nginx.conf
```

As we can see it contains references to certificate at `/etc/letsencrypt/live/nginx2-manjaro.devopshive.link`
which doesn't exist at the moment as we haven't run `certbot` just yet
to issue this certificate. 

Additionall this NGINX configuration "includes" 
```
# configuration file /etc/letsencrypt/options-ssl-nginx.conf:
# This file contains important security parameters. If you modify this file
# manually, Certbot will be unable to automatically provide future security
# updates. Instead, Certbot will print and log an error message with a path to
# the up-to-date file that you will need to refer to when manually updating
# this file. Contents are based on https://ssl-config.mozilla.org

ssl_session_cache shared:le_nginx_SSL:10m;
ssl_session_timeout 1440m;
ssl_session_tickets off;

ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers off;

ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
```
along with
```
ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
```
both of which are used to improve security of our NGINX configuration. Please
refer to https://scaron.info/blog/improve-your-nginx-ssl-configuration.html for explanation of each of the parameters.


### Create records of type "A" for new 3d level domain names in Route53
for 
- 'nginx2-manjaro.devopshive.link'
- 'nginx3-manjaro.devopshive.link'

that map each of the names to our public IP address

Please follow instructions from https://github.com/Alliedium/awesome-devops/blob/main/17_networks_ssl-termination_acme_route53_06-oct-2022/README.md to create these
records in Route53

### Create IAM bot user with programmatic access to Route53
`certbot` will require a special user with programmatic access only that
has permissions to create and delete records in our new hosted zone.
Please follow instuctions from https://github.com/Alliedium/awesome-devops/blob/main/17_networks_ssl-termination_acme_route53_06-oct-2022/README.md to create the user
but make sure to use this policy: https://certbot-dns-route53.readthedocs.io/en/stable/#sample-aws-policy-json (you need to replace "YOURHOSTEDZONEID" with your hosted zone id).
Then you need to generate credentials for programmatic access and put
them into `~/.aws/config` according
to
https://certbot-dns-route53.readthedocs.io/en/stable/#welcome-to-certbot-dns-route53-s-documentation
Finally, copy `~/.aws` to `/root/.aws`:
```
sudo cp -r ~/.aws /root/.aws
```
to make sure that "root" user also has this programmatic access. You can
use AWS CLI to make sure that programmatic access is
configured correctly. It is recommended to use AWS CLI v2 which can be
installed via

```
sudo pacman -R aws-cli # remove AWS CLI v1 if it is intalled
sudo pacman -S aws-cli-v2
```
Once AWS CLI is installed you can run

```
aws route53 list-hosted-zones # check that current user has access
sudo aws route53 list-hosted-zones # check that "root" has access
```
to make sure that both "root" and your current user can read information
about the hosted zone (this doesn't verify that the bot user can
create new records). 

The reason we need to create a copy of `.aws` inside "root" home folder
is because when we run `sudo certbot ...` aws credentials located in `/root/.aws`
are be used instead of the credentials in `~/.aws`.


### Issue the certificate via DNS-01 challange
If you have port forwarding `80->8080` still configured on your homelab
firewall it is recommended you disable it to make sure that `certbot`
fails to HTTP-01 challange just in case.

Now it is time to generate LetsEncrypt certificate via `certbot` using
DNS-01 challange:
```
sudo certbot certonly --dns-route53 -d nginx2-manjaro.devopshive.link -d nginx3-manjaro.devopshive.link --preferred-challenges=dns
```
This command (may take a few seconds to run) generates a certificate at
```
/etc/letsencrypt/live/nginx2-manjaro.devopshive.link/
```
but doesn't install it into NGINX (thanks to `certonly` subcommand). 
We can check that via
```
sudo certbot certificates
```

### Deploy the new NGINX configuration:
Now we have the certificate ready and it is time to configure NGINX:

```
sudo cp ./8-virtual-hosting-static-tls-certbot-dns-01.nginx.conf /etc/nginx/nginx.conf
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index2.html
sudo sed -i "s/nginx/nginx2/g" /usr/share/nginx/html/index2.html
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index3.html
sudo sed -i "s/nginx/nginx3/g" /usr/share/nginx/html/index3.html
```
Trying to run after the commands above
```
sudo nginx -s reload
```
would result in error because `http` user under which NGINX runs doesn't
have access to `/etc/letsencrypt/live/` folder where our certificate is
located. There are two ways to fix that. The first would be running
`sudo systemctl restart nginx.service`. It works because when NGINX
starts its master process has "root" permissions (while all
sub-processes run under "http" user - see section 5 above). The second
way would be changing the owner of `/etc/letsencrypt/live/` to `http`
user:

```
sudo chown -R http:http /etc/letsencrypt/live
```

### Making sure that everything works as expected
If all steps above are followed correctly then each of the following
commands would open its corresponding NGINX static welcome page: 
```
w3m https://nginx2-manjaro.devopshive.link:7443 -dump
w3m https://nginx3-manjaro.devopshive.link:7443 -dump
```

### Manual certificate renewal
The certificates can be renewed manually at anytime via
```
sudo certbot renew 
```
This command, however, doesn't restart NGINX/reload its configuration
because `certbot` didn't use NGINX plugin for issuing certificates.

Thus, we need to make sure to load NGINX config via
```
sudo nginx -s reload # or sudo systemctl reload nginx.service
```
or just restart the service
```
sudo systemctl restart nginx.service
```

### Automatic renewal
Since DNS-01 challange doesn't assume we use NGINX plugin to manage
NGINX configuration automatically we need to add
```
--post-hook 'systemctl reload nginx.service'
```
to `ExecStart` command in
```
/usr/lib/systemd/system/nginx.service
```
to make sure that NGIXN configuration is reloaded automatically after
the certificate renewal. After that please do not forget to run
```
sudo systemctl daemon-reload
```
so that systemd picks up your changes.

## References
### Docker
- https://docs.docker.com/engine/tutorials/networkingcontainers/
- https://github.com/samos123/docker-veth/blob/master/docker-veth.sh
- https://docs.docker.com/network/iptables/
- https://hub.docker.com/r/nginxdemos/hello/

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
- https://www.youtube.com/watch?v=7VAI73roXaY
- https://levelup.gitconnected.com/multiplex-tls-traffic-with-sni-routing-ece1e4e43e56
- https://github.com/Alliedium/awesome-devops/blob/main/17_networks_ssl-termination_acme_route53_06-oct-2022/README.md
- https://letsencrypt.org/docs/challenge-types/
- https://letsencrypt.org/docs/rate-limits/
- https://www.nginx.com/blog/using-free-ssltls-certificates-from-lets-encrypt-with-nginx/#auto-renewal
- https://nandovieira.com/using-lets-encrypt-in-development-with-nginx-and-aws-route53
- https://certbot-dns-route53.readthedocs.io/en/stable/#welcome-to-certbot-dns-route53-s-documentation
- https://certbot.eff.org/instructions?ws=nginx&os=arch
- https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=intermediate&openssl=1.1.1k&guideline=5.6
- https://github.com/certbot/certbot/blob/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf
- https://scaron.info/blog/improve-your-nginx-ssl-configuration.html
- https://serverfault.com/questions/997614/setting-ssl-prefer-server-ciphers-directive-in-nginx-config
- https://wiki.archlinux.org/title/certbot#Automatic_renewal
- https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2
