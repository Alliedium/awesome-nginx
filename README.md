# awesome-nginx

# Getting started
## Running upstream web servers
- Run nginx demos web servers
```
docker run --name nginx-demo1 -d nginxdemos/hello
docker run --name nginx-demo2 -d nginxdemos/hello
docker run --name nginx-demo3 -d nginxdemos/hello
```
- Show mapping between docker networks, IP addresses of the containers
  and veths
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
