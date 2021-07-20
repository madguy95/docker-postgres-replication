# docker-postgres-replication

Install postgresql master/slave in docker

First of all, we need to create a docker network so our containers can communicate amongst themselves:

   - docker network create bridge-docker

Next, pull down the files and directories from github:

   - git clone https://github.com/xtinhvl/docker-postgres-replication.git
  
CD into the newly created directory named docker-pg-cluster.

   - cd docker-pg-cluster

Then you simply have to run the docker-compose up command (with  -d args to run :

   - docker-compose up -d

You can go https://www.optimadata.nl/blogs/1/nlm8ci-how-to-run-postgres-on-docker-part-3 if you want to know more

POSTGRES_USER: username db
POSTGRES_PASSWORD: password DB
POSTGRES_DB: Database name
POSTGRES_MASTER: address master node
PG_STANDBY: enter standby mode (by create standby.signal in folder ${PGDATA})
PG_REWIND: enable pg_rewind sync WAL
PG_REP_USER: username replicator
PG_REP_PASSWORD: password replicator

### ISSUE

##### 1
if postgres master server down . we can pormote slave  to new master 
```sh
$ docker exec -it container_id bash
su postgres
pg_ctl promote -D ${PGDATA}
```
Restart master server and convert to new slave 
- add PG_STANDBY: true to pg_master service 
- restart pg_master service

You also can create a new slave from image slave 
```yml
  pg_slave2:
     build: ./slave
     ports:
         - "5447:5432"
     volumes:
         - s2data:/var/lib/postgresql/data
     environment:
         - POSTGRES_USER=postgres
         - POSTGRES_PASSWORD=123456
         - POSTGRES_DB=db_app
         - POSTGRES_MASTER=pg_slave
         - PG_STANDBY=true
         - PG_REP_USER=rep
         - PG_REP_PASSWORD=123456
     networks:
        - bridge-docker
     restart: always
```

##### 2
WAL not reached or not the same 
caused: WAL on master and slave not in the same point/
solution: use pg_rewind to synchronize master and slave
```sh
docker run -it -d --name pg_rewind --network=host \
--env="PGDATA=/var/lib/postgresql/data/pgdata" \
--env="POSTGRES_HOST_AUTH_METHOD=trust" \
--volume=/home/data/master-data:/var/lib/postgresql/data:rw \
postgres:12.5 \
pg_rewind --target-pgdata=/var/lib/postgresql/data/ --source-server='host=address_master port=5445 dbname=db_app user=postgres password=123456'
```
/home/data/master-data : path to volume data need to sync WAL on host
or set PG_REWIND = true
### Note: 
   - At the moment I am using postgresql ver 12.5 and it has some different configuration from previous version..
  
How was the replication configuration handled until PostgreSQL 11?
Until PostgreSQL 11, we must create a file named: recovery.conf that contains the following minimalistic parameters. If the standby_mode is ON, it is considered to be a standby.

```sh
$ cat $PGDATA/recovery.conf
standby_mode = 'on'
primary_conninfo = 'host=$hostname port=5432 user=$rep_user password=$pass'
```
So the first difference between PostgreSQL 12 and earlier (until PostgreSQL 11) is that the standby_mode parameter is not present in PostgreSQL 12 and the same has been replaced by an empty file standby.signal in the standby’s data directory. And the second difference is the parameter primary_conninfo. This can now be added to the postgresql.conf or postgresql.auto.conf file of the standby’s data directory.

In PG12, in which several steps have been changed from the older versions, particularly the removal of recovery.conf.
Here is a short list of changes related to replication setup that have been moved from recovery.conf
restore_command => moved to postgresql.conf
recovery_target_timeline => moved to postgresql.conf
standby_mode => replaced by standby.signal
primary_conninfo => moved to postgresql.conf or postgresql.auto.conf
archive_cleanup_command => moved to postgresql.conf
primary_slot_name => moved to postgresql.conf

### Reference Docs
  - https://www.percona.com/blog/2019/10/11/how-to-set-up-streaming-replication-in-postgresql-12/
  - https://www.2ndquadrant.com/en/blog/replication-configuration-changes-in-postgresql-12/

### Related topics
  - synchronous_commit https://www.postgresql.org/docs/12/runtime-config-wal.html
