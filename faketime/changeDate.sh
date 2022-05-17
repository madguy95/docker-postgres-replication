#!/bin/sh
set -x
echo "Input time to change date (in formate [+-]Xd VD: +15d , -10d): " 
read value
DAY_MOVE=$value
echo "Restart time DB server to $DAY_MOVE"

sed -i "s/FAKETIME=.*/FAKETIME=$DAY_MOVE/g" /home/database/.env
sleep 1

cd /home/database/
docker-compose -f docker-compose-db.yml up -d --build
sleep 1

echo "Restart time app server to $DAY_MOVE"
curl --request GET --url 'http://jenkins_host:8080/view/job/app/build?token=tokenT'
sleep 5

while [ 1 = 1 ]
do
  echo "Check date now in app server"
  docker exec -it container_name /bin/sh -c "date"
  echo "Check date now in auth server"
  docker exec -it container_name /bin/sh -c "date"
  sleep 5
done