docker network create shared_network

docker compose -f docker-compose-kafka.yml -f docker-compose-hos1.yml -f docker-compose-hos2.yml -f docker-compose-hos3.yml up

<!--
docker compose -f docker-compose-kafka.yml up

docker compose -f docker-compose-hos1.yml up
docker compose -f docker-compose-hos2.yml up
docker compose -f docker-compose-hos3.yml up
-->