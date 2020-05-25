#!/bin/sh
set -e

PUID=${PUID:=0}
PGID=${PGID:=0}
SECURE=${SECURE:=false}
SEEDRATIO=${SEEDRATIO:=0}
SEEDTIME=${SEEDTIME:=0}

LOGPATH=${LOGPATH:='/logs.log'}

if [ ! -f /conf/aria2.conf ]; then
    cp /preset-conf/aria2.conf /conf/aria2.conf
    chown $PUID:$PGID /conf/aria2.conf
    if [ $SECRET ]; then
        echo "rpc-secret=${SECRET}" >> /conf/aria2.conf
    fi
    
    if [ $SECURE = 'true' ]; then
        echo "" >> /conf/aria2.conf
        echo "rpc-secure=true" >> /conf/aria2.conf
        echo "rpc-certificate=$CERTIFICATE" >> /conf/aria2.conf
        echo "rpc-private-key=$PRIVATEKEY" >> /conf/aria2.conf
    fi
    
    echo "" >> /conf/aria2.conf
    echo "seed-ratio=$SEEDRATIO" >> /conf/aria2.conf
    echo "seed-time=$SEEDTIME" >> /conf/aria2.conf
fi

if [ -f /conf/aria2.conf ]; then
    list=`wget -qO- https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_best.txt|awk NF|sed ":a;N;s/\n/,/g;ta"`
    if [ $list ]; then
        if [ -z "`grep "bt-tracker" /conf/aria2.conf`" ]; then
            sed -i '$a bt-tracker='${list} /conf/aria2.conf
        else
            sed -i "s@bt-tracker.*@bt-tracker=$list@g" /conf/aria2.conf
        fi
    fi
fi

chown $PUID:$PGID /conf || echo 'Failed to set owner of /conf, aria2 may not have permission to write /conf/aria2.session'

if [ ! -f /conf/aria2.session ]; then
    touch /conf/aria2.session
    chown $PUID:$PGID /conf/aria2.session
else
    cp /conf/aria2.session /conf/aria2-copy.session
fi

touch ${LOGPATH}
chown $PUID:$PGID ${LOGPATH}

darkhttpd /aria2-ng --port 80 &

exec s6-setuidgid $PUID:$PGID aria2c --conf-path=/conf/aria2.conf --log=${LOGPATH}
