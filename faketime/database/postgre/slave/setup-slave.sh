#!/bin/bash

if [ ! -s "$PGDATA/PG_VERSION" ]; then
	echo "*:*:*:$PG_REP_USER:$PG_REP_PASSWORD" > ~/.pgpass
	chmod 0600 ~/.pgpass
	until ping -c 1 -W 1 postgre_master
	do
		echo "Waiting for master to ping..."
		sleep 1s
	done
	until pg_basebackup -h postgre_master -D ${PGDATA} -U ${PG_REP_USER} -vP -W -Fp -Xs -P -R
	do
		echo "Waiting for master to connect..."
		sleep 1s
	done
	echo "host replication all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

	set -e
	cat > ${PGDATA}/postgresql.auto.conf <<EOF 
	listen_addresses = '*'
	primary_conninfo = 'host=postgre_master port=5432 user=$PG_REP_USER password=$PG_REP_PASSWORD'
EOF
	chown postgres. ${PGDATA} -R
	chmod 700 ${PGDATA} -R
fi
sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf
exec "$@"

