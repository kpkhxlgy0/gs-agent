#!/bin/sh
if [ "$(uname)" = "Darwin" ]; then
    # docker-machine create --driver virtualbox default
    # docker-machine upgrade default
    # eval "$(docker-machine env default)"
    SUDO=
else
    # sudo ip addr add 172.17.42.1/16 dev docker0
    SUDO=sudo
fi
case $1 in
    start)
        if [ "$(uname)" = "Darwin" ]; then
            docker-machine ssh default "docker run --name registrator -d -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator -ip=\"172.17.42.1\" etcd://172.17.42.1:2379/backends"
        else
            sudo docker run --name registrator -d -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator -ip="172.17.42.1" etcd://172.17.42.1:2379/backends
        fi
        $SUDO docker run --name etcd -d -p 2379:2379  quay.io/coreos/etcd -addr 172.17.42.1:2379
        $SUDO docker run --name mongodb -d -p 27017:27017 -d mongo
        $SUDO docker run -d --name lookupd -p 4160:4160 -p 4161:4161 nsqio/nsq /nsqlookupd
        $SUDO docker run -d --name nsqd -p 4150:4150 -p 4151:4151  nsqio/nsq /nsqd   --broadcast-address=172.17.42.1   --lookupd-tcp-address=172.17.42.1:4160
        $SUDO docker run -d --name statsd -p 80:80 -p 8125:8125/udp -p 8126:8126  kamon/grafana_graphite
        $SUDO docker run -d --name etcd-browser -p 0.0.0.0:8000:8000 --env ETCD_HOST=172.17.42.1 --env ETCD_PORT=2379  --env AUTH_USER=admin --env AUTH_PASS=admin etcd-browser
        $SUDO docker run -d --name registry -e SETTINGS_FLAVOR=dev -e STORAGE_PATH=/tmp/registry -v /data/registry:/tmp/registry  -p 5000:5000 registry
        ;;
    restart)
        $SUDO docker restart  etcd mongodb nsqd lookupd statsd etcd-browser registry registrator
        ;;
    stop)
        echo TODO
        ;;
esac
