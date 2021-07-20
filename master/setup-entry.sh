#!/bin/bash

if [ ! -z $PG_STANDBY ]; then
	echo "Enable standby mode"
	touch $PGDATA/standby.signal
fi

if [ ! -z $PG_REWIND ]; then
	echo "pg_rewind synchonorize WAL"
	su postgres -c "pg_rewind --target-pgdata=$PGDATA --source-server='host=${POSTGRES_MASTER} port=5432 dbname=$POSTGRES_DB user=$PG_REP_USER password=$PG_REP_PASSWORD'"
fi
exec "$@"
su postgres -c "/usr/local/bin/docker-entrypoint.sh postgres"
