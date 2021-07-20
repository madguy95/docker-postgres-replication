#!/bin/bash

if [ ! -s "$PGDATA/PG_VERSION" ]; then
	
	echo "First time run init configuration postgresql"
	echo "*:*:*:$PG_REP_USER:$PG_REP_PASSWORD" > ~/.pgpass
	chmod 0600 ~/.pgpass
	until ping -c 1 -W 1 ${POSTGRES_MASTER}
	do
		echo "Waiting for master to ping..."
		sleep 1s
	done
	su postgres
	rm -rf ${PGDATA}/*
	until pg_basebackup -h ${POSTGRES_MASTER} -D ${PGDATA} -U ${PG_REP_USER} -X stream -P
	do
		echo "Waiting for master to connect..."
		sleep 1s
	done
	echo "host replication all 0.0.0.0/0 md5" >> "$PGDATA/pg_hba.conf"

	set -e
	# if [ ! -z $PG_STANDBY ]; then
	# 	echo "Enable standby mode"
	# 	touch $PGDATA/standby.signal
	# fi
	# cp ./standby.signal ${PGDATA}/standby.signal
	mkdir -p $PGDATA/pg_log

	cat > ${PGDATA}/postgresql.conf <<EOF 
hot_standby = on
max_standby_streaming_delay = 30s
wal_receiver_status_interval = 10s 
hot_standby_feedback = on
listen_addresses = '*' # Listen to all IPs
primary_conninfo = 'host=${POSTGRES_MASTER} port=5432 user=$PG_REP_USER password=$PG_REP_PASSWORD'
recovery_target_timeline = 'latest'
wal_log_hints = on
archive_mode = on # Allow archiving
archive_command = '/bin/date' # Use this command to archive the logfile segment, which is unarchived here.
wal_level = replica #turn hot standby
max_wal_senders = 32 # This setting can have up to several stream replication connections, almost a few from, set a few
wal_keep_segments = 64 # Set the maximum number of xlogs reserved for stream replication, one is 16M, pay attention to the machine disk 16M*64 = 1G
wal_sender_timeout = 60s # Set the timeout period for stream replication host to send data
max_connections = 300 # This setting should be noted that the max_connections from the library must be larger than the main library.
shared_buffers = 2GB
effective_cache_size = 2GB

# - Where to Log -
log_destination = 'csvlog'              # Valid values are combinations of
                                        # stderr, csvlog, syslog, and eventlog,
                                        # depending on platform.  csvlog
                                        # requires logging_collector to be on.
log_file_mode = 0600
# This is used when logging to stderr:
logging_collector = off          # Enable capturing of stderr and csvlog
                                        # into log files. Required to be on for
                                        # csvlogs.
                                        # (change requires restart)
										# off in standby mode

# These are only used if logging_collector is on:
log_directory = './pg_log'                # directory where log files are written,
                                        # can be absolute or relative to PGDATA
log_filename = 'postgresql-%a.log' # log file name pattern,
                                        # can include strftime() escapes
log_rotation_age = 1440
log_rotation_size = 0
log_truncate_on_rotation = on
log_min_duration_statement = 5000 #milliseconds  this can generate logs of "slow queries" on your system. 
shared_preload_libraries = 'auto_explain'
auto_explain.log_min_duration = '5s'
log_line_prefix =  '%t:%r:%u@%d:[%p]: '
EOF
	chown postgres. ${PGDATA} -R
	chmod 700 ${PGDATA} -R
fi
if [ ! -z $PG_STANDBY ]; then
	echo "Enable standby mode"
	su postgres -c "touch $PGDATA/standby.signal"
fi

if [ ! -z $PG_REWIND ]; then
	echo "pg_rewind synchonorize WAL"
	su postgres -c "pg_rewind --target-pgdata=$PGDATA --source-server='host=${POSTGRES_MASTER} port=5432 dbname=$POSTGRES_DB user=$PG_REP_USER password=$PG_REP_PASSWORD'"
fi
sed -i 's/wal_level = hot_standby/wal_level = replica/g' ${PGDATA}/postgresql.conf
exec "$@"

