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
    startbefore)
        if [ "$(docker images | awk '/^etcd-browser/ {print $1}')" = "" ]; then
            if [ ! -d "./etcd-browser" ]; then
                git clone git@github.com:henszey/etcd-browser.git
            fi
            cd etcd-browser
            $SUDO docker build -t etcd-browser .
            cd ..
        fi
        if [ "$(uname)" = "Darwin" ]; then
            docker-machine ssh daocloud "docker run --name registrator -d -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator -ip=\"172.17.42.1\" etcd://172.17.42.1:2379/backends"
        else
            $SUDO docker run --name registrator -d -v /var/run/docker.sock:/tmp/docker.sock gliderlabs/registrator -ip="172.17.42.1" etcd://172.17.42.1:2379/backends
        fi
        $SUDO docker run -d --name etcd -p 2379:2379  quay.io/coreos/etcd -addr 172.17.42.1:2379
        $SUDO docker run -d --name mongodb -p 27017:27017 mongo
        $SUDO docker run -d --name lookupd -p 4160:4160 -p 4161:4161 nsqio/nsq /nsqlookupd
        $SUDO docker run -d --name nsqd -p 4150:4150 -p 4151:4151  nsqio/nsq /nsqd   --broadcast-address=172.17.42.1   --lookupd-tcp-address=172.17.42.1:4160
        $SUDO docker run -d --name statsd -p 80:80 -p 8125:8125/udp -p 8126:8126  kamon/grafana_graphite
        $SUDO docker run -d --name etcd-browser -p 0.0.0.0:8000:8000 --env ETCD_HOST=172.17.42.1 --env ETCD_PORT=2379  --env AUTH_USER=admin --env AUTH_PASS=admin etcd-browser
        $SUDO docker run -d --name registry -e SETTINGS_FLAVOR=dev -e STORAGE_PATH=/tmp/registry -v /data/registry:/tmp/registry  -p 5000:5000 registry
        ;;
    restartbefore)
        $SUDO docker restart etcd mongodb nsqd lookupd statsd etcd-browser registry registrator
        ;;
    stopbefore)
        awk_registrator='/registrator$/ {print $1}'
        if [ "$(uname)" = "Darwin" ]; then
            docker-machine ssh daocloud "docker ps -a | awk '$awk_registrator' | xargs docker rm -f"
        else
            $SUDO docker ps -a | awk '/registrator$/ {print $1}' | xargs docker rm -f
        fi
        $SUDO docker ps -a | awk '/etcd$/ {print $1}' | xargs docker rm -f
        $SUDO docker ps -a | awk '/mongodb$/ {print $1}' | xargs docker rm -f
        $SUDO docker ps -a | awk '/lookupd$/ {print $1}' | xargs docker rm -f
        $SUDO docker ps -a | awk '/nsqd$/ {print $1}' | xargs docker rm -f
        $SUDO docker ps -a | awk '/statsd$/ {print $1}' | xargs docker rm -f
        $SUDO docker ps -a | awk '/etcd-browser$/ {print $1}' | xargs docker rm -f
        $SUDO docker ps -a | awk '/registry$/ {print $1}' | xargs docker rm -f
        ;;
    build)
        $SUDO docker build --no-cache --rm=true -t agent .
        ;;
    start)
        # TODO, will use name list
        if [ "$(docker images | awk '/^agent/ {print $1}')" = "" ]; then
            $0 build
        fi
        $SUDO docker run --rm=true --name agent1 -h agent_dev -it -p 8888:8888 -p 6060:6060 -e SERVICE_ID=agent1 agent
        ;;
    restart)
        # TODO, will use name list
        $SUDO docker restart agent1
        ;;
    stop)
        # TODO, will use name list
        $SUDO docker ps -a | awk '/agent1$/ {print $1}' | xargs docker rm -f
        ;;
    clean)
        $0 stop
        docker rmi -f agent
        ;;
    *)
        echo "use sub command"
        echo "    startbefore"
        echo "    restartbefore"
        echo "    stopbefore"
        echo "    start"
        echo "    restart"
        echo "    stop"
        echo "    clean"
        ;;
esac
