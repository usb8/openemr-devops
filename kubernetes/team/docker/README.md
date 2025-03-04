## Pre-setup:
- Place debezium-mysql.json and jdbc-sink.json in the same folder
  Idea is that debezium creates records of changes 
  JDBC processes those records and inserts them in replica database

## Setup:

1. Deploy
```shell
docker network create shared_network

docker compose -f docker-compose-kafka.yml -f docker-compose-hos1.yml -f docker-compose-hos2.yml -f docker-compose-hos3.yml up
# docker compose -f docker-compose-kafka.yml up
# docker compose -f docker-compose-hos1.yml up
# docker compose -f docker-compose-hos2.yml up
# docker compose -f docker-compose-hos3.yml up

docker ps -a

docker exec -it mysql-1 mysql -uroot -proot
  SELECT User, Host FROM mysql.user WHERE User='debezium';
  SHOW GRANTS FOR 'debezium'@'%';

curl -s http://localhost:8083/ | jq # Verify that Kafka connect is running
```

2. Register Connector via Kafka Connect API
```shell
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
--data @debezium-mysql.json http://localhost:8083/connectors

curl -s http://localhost:8083/connectors/ | jq # Check that it is running
curl -X GET http://localhost:8083/connectors/mariadb-connector/status # Verify the status of it

docker exec -it kafka-1 kafka-consumer-groups.sh --bootstrap-server kafka-1:9092 --group connect-mariadb-sink --describe # Verify if it receives messages
```

3. Repeat same with jdbc
```shell
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
--data @jdbc-sink.json http://localhost:8083/connectors
```

4. Verify setup
```shell
docker exec -it kafka-1 kafka-topics.sh --bootstrap-server kafka-1:9092 --list # you should see list of topics Kafak has, Check if openemr-changes.openemr and mariadb_schema_history are there. I have many topics there

docker exec -it kafka-1 kafka-console-consumer.sh --bootstrap-server kafka-1:9092 --topic mariadb_schema_history --from-beginning # To see the messages itself run this command. It should return changes to the tables architecture (like creation or dropping)
```

- If you want to see changes for a row of data, you have to use specific table name
  For example openemr-changes.openemr.test_kafka means:
  topic = openemr-changes
  schema = openemr
  table = test_kafka
  Command;
    docker exec -it kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic openemr-changes.openemr.test_kafka --from-beginning
  It should return to you json format file
  mariadb_schema_history can be replaced to any other topic you have available
  but at least mariadb_schema_history should have topic available if you've had some activity on sql server
## Trobleshoot:

1. In case of problems / if you need to do changes to the json configurations;
Delete the connectors by using:
    curl -X DELETE http://localhost:8083/connectors/<connector_name>
For example:
    curl -X DELETE http://localhost:8083/connectors/mariadb-sink
    curl -X DELETE http://localhost:8083/connectors/mariadb-sink

2. Restart the docker:
    docker restart kafka-connect
Post again the connectors like mentioned in step 9 and 10

3. The current setup for JDBC only looks for changes in specific table
defined under parameter table.name.format