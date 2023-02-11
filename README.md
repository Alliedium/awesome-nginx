# awesome-nginx

# Getting started

## Installing nginx
### Manjaro/Arch Linux
```
sudo pacman -S nginx
```

## Serving static content

### Single static page
```
sudo cp ./1-static-page.nginx.conf /etc/nginx/nginx.conf
sudo nginx -s reload
curl http://127.0.0.1:8080
curl http://nginx1.mkde0.intranet:8080 --resolve nginx1.mkde0.intranet:8080:127.0.0.1
```

### Virtual hosting with static pages
```
sudo cp ./2-virtual-hosting-static.nginx.conf
sudo cp /usr/share/nginx/html/index.html /usr/share/nginx/html/index2.html
sudo sed -i "s/nginx/nginx2/g" /usr/share/nginx/html/index2.html
curl http://127.0.0.1:8080
curl http://nginx1.mkde0.intranet:8080 --resolve nginx1.mkde0.intranet:8080:127.0.0.1
curl http://nginx2.mkde0.intranet:8080 --resolve nginx2.mkde0.intranet:8080:127.0.0.1
```

## Running upstream web servers
- Run nginx demos web servers
```
docker run --name nginx-demo1 -d nginxdemos/hello
docker run --name nginx-demo2 -d nginxdemos/hello
docker run --name nginx-demo3 -d nginxdemos/hello
```
- Show mapping between docker networks, IP addresses of the containers
  and veths

Let us refer to
https://docs.docker.com/engine/tutorials/networkingcontainers/ and
verify

Docker networks:
```
❯ docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
29022f4329f5   bridge    bridge    local
ae410447d1ce   host      host      local
66bf26e5b59f   none      null      local
```
Linux bridges and links:
```
❯ ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: ens18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP mode DEFAULT group default qlen 1000
    link/ether 22:05:2c:25:96:e4 brd ff:ff:ff:ff:ff:ff
    altname enp0s18
8: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP mode DEFAULT group default 
    link/ether 02:42:f7:58:80:58 brd ff:ff:ff:ff:ff:ff
22: vethffd9984@if21: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP mode DEFAULT group default 
    link/ether e6:5c:4a:3f:51:99 brd ff:ff:ff:ff:ff:ff link-netnsid 0
24: vetha2803cf@if23: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP mode DEFAULT group default 
    link/ether 56:8a:d2:4e:0c:76 brd ff:ff:ff:ff:ff:ff link-netnsid 1
26: veth3d8bdad@if25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP mode DEFAULT group default 
    link/ether ca:de:b8:c0:90:71 brd ff:ff:ff:ff:ff:ff link-netnsid 2
```
Mapping between containers, IP addresses and bridges
```
❯ docker inspect -f '{{.Name}} - {{.NetworkSettings.IPAddress }} - {{.NetworkSettings.Networks}}' $(docker ps -aq)
/nginx-demo3 - 172.32.0.4 - map[bridge:0xc00014a600]
/nginx-demo2 - 172.32.0.3 - map[bridge:0xc0002f8000]
/nginx-demo1 - 172.32.0.2 - map[bridge:0xc00014acc0]
```

Download the script for mapping between veths and containers
```
wget https://raw.githubusercontent.com/samos123/docker-veth/master/docker-veth.sh
```
Show the mapping between veths and containers

```
❯ sudo ./docker-veth.sh
veth3d8bdad@if25 a0aa26a1d335 nginx-demo3
vetha2803cf@if23 2b33979ddb52 nginx-demo2
vethffd9984@if21 c2ed21e1b401 nginx-demo1
```
Why IPs start with `172.32`?

Here is why:
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



## Access webservers running inside containers via a text based web
browser Lynx

```
lynx http://172.32.0.3 --dump
```

## Let us see how Nginx servers are configured.
by looking at

https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello
https://github.com/nginxinc/NGINX-Demos/blob/master/nginx-hello/hello.conf

let us refer to 

https://docs.nginx.com/nginx/admin-guide/web-server/serving-static-content/
http://nginx.org/en/docs/http/ngx_http_sub_module.html#example

## References
### Docker
- https://docs.docker.com/engine/tutorials/networkingcontainers/
- https://github.com/samos123/docker-veth/blob/master/docker-veth.sh

### Nginx

- http://nginx.org/en/docs/
- http://nginx.org/en/docs/beginners_guide.html
- https://www.baeldung.com/linux/nginx-docker-container
- https://github.com/digitalocean/nginxconfig.io
- https://www.digitalocean.com/community/tools/nginx
- https://github.com/trimstray/nginx-admins-handbook
- https://github.com/h5bp/server-configs-nginx
- https://artifacthub.io/packages/helm/bitnami/nginx
- https://github.com/nginxinc/NGINX-Demos/tree/master/nginx-hello
- https://hub.docker.com/r/nginxdemos/hello/
- https://www.youtube.com/watch?v=7VAI73roXaY
