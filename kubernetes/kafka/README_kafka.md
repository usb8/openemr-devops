```shell
kubectl apply -f .
kubectl delete -f .

# TODO: apps run in the order
```

1. Verify that Kafka connect is running
```shell
curl -s http://localhost:30005/ | jq # should be ready after 1 min
```

3. Register Connector via Kafka Connect API; JDBC
```shell
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
--data @debezium-mysql-1.json http://localhost:30005/connectors

curl -s http://localhost:30005/connectors/ | jq # Check that it is running

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" \
--data @jdbc-sink.json http://localhost:30005/connectors
```

4. Verify more
```shell
docker exec -it mysql-1 mysql -uroot -proot
use openemr;
# describe patient_data;
# 'add a new patient'
select * from patient_data;

docker exec -it mysql-2 mysql -uroot -proot
use openemr;
select * from openemr_patient_data;
```

```shell
curl -X GET http://localhost:30005/connectors/mariadb-connector-1/status # And verify the status of it

docker exec -it kafka-1 kafka-consumer-groups.sh --bootstrap-server kafka-1:9092 --group connect-mariadb-sink --describe # Verify if it receives messages
```

5. To see the messages itself run this command. It should return changes to the tables architecture (like creation or dropping)
<!-- `docker exec -it kafka-1 kafka-console-consumer.sh --bootstrap-server kafka-1:9092 --topic mariadb_schema_history --from-beginning` -->

<!-- If you want to see changes for a row of data, you have to use specific table name
For example openemr-changes.openemr.test_kafka means:
topic = openemr-changes
schema = openemr
table = test_kafka
`docker exec -it kafka kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic openemr-changes.openemr.test_kafka --from-beginning`
It should return to you json format file
mariadb_schema_history can be replaced to any other topic you have available
but at least mariadb_schema_history should have topic available if you've had some activity on sql server -->

6. If everything is set-up correctly, you should see list of topics Kafak has:
`docker exec -it kafka-1 kafka-topics.sh --bootstrap-server kafka-1:9092 --list`
Check if openemr-changes.openemr and mariadb_schema_history are there. I have many topics there

7. To check if messages were consumed by jdbc container:
```shell
docker exec -it kafka-1 kafka-consumer-groups.sh --bootstrap-server kafka-1:9092 --group <topic_name_in_file> --describe # TODO
```
If CURRENT-OFFSET is "-" and LAG has values, then jdbc not processing messages
You can check the logs using:
    docker logs kafka-connect --tail=50

----------------------------------------
----------------------------------------
----------------------------------------

8. In case of problems / if you need to do changes to the json configurations;
Delete the connectors by using:
    curl -X DELETE http://localhost:30005/connectors/<connector_name>
For example:
    curl -X DELETE http://localhost:30005/connectors/mariadb-sink
    curl -X DELETE http://localhost:30005/connectors/mariadb-sink

Restart the docker:
    docker restart kafka-connect
Post again the connectors like mentioned in step 9 and 10

9. The current setup for JDBC only looks for changes in specific table
defined under parameter table.name.format

<!--
INSERT INTO patient_data (
    uuid, title, language, financial, fname, lname, mname, DOB, street, postal_code, city, state, country_code, 
    drivers_license, ss, occupation, phone_home, phone_biz, phone_contact, phone_cell, pharmacy_id, status, 
    contact_relationship, date, sex, referrer, referrerID, providerID, ref_providerID, email, email_direct, 
    ethnoracial, race, ethnicity, religion, interpretter, migrantseasonal, family_size, monthly_income, 
    billing_note, homeless, financial_review, pubpid, pid, genericname1, genericval1, genericname2, genericval2, 
    hipaa_mail, hipaa_voice, hipaa_notice, hipaa_message, hipaa_allowsms, hipaa_allowemail, squad, fitness, 
    referral_source, usertext1, usertext2, usertext3, usertext4, usertext5, usertext6, usertext7, usertext8, 
    userlist1, userlist2, userlist3, userlist4, userlist5, userlist6, userlist7, pricelevel, regdate, contrastart, 
    completed_ad, ad_reviewed, vfc, mothersname, guardiansname, allow_imm_reg_use, allow_imm_info_share, 
    allow_health_info_ex, allow_patient_portal, deceased_date, deceased_reason, soap_import_status, cmsportal_login, 
    care_team_provider, care_team_facility, care_team_status, county, industry, imm_reg_status, imm_reg_stat_effdate, 
    publicity_code, publ_code_eff_date, protect_indicator, prot_indi_effdate, guardianrelationship, guardiansex, 
    guardianaddress, guardiancity, guardianstate, guardianpostalcode, guardiancountry, guardianphone, guardianworkphone, 
    guardianemail, sexual_orientation, gender_identity, birth_fname, birth_lname, birth_mname, dupscore, name_history, 
    suffix, street_line_2, patient_groups, prevent_portal_apps, provider_since_date, created_by, updated_by, 
    preferred_name, nationality_country, last_updated
) VALUES (
    UNHEX(REPLACE(UUID(), '-', '')), 'Mr.', 'English', 'Insurance', 'John', 'Doe', 'B', '1980-01-01', '123 Main St', 
    '12345', 'Anytown', 'CA', 'US', 'D1234567', '123-45-6789', 'Engineer', '555-1234', '555-5678', '555-8765', 
    '555-4321', 1, 'Active', 'Spouse', NOW(), 'Male', 'Dr. Smith', '123', 1, 2, 'john.doe@example.com', 
    'john.doe@direct.example.com', 'Caucasian', 'White', 'Non-Hispanic', 'Christian', 'No', 'No', '4', '5000', 
    'No billing notes', 'No', NOW(), 'PUB121', 1, 'Generic1', 'Value1', 'Generic2', 'Value2', 'Yes', 'Yes', 'Yes', 
    'Yes', 'No', 'No', 'Squad1', 1, 'Referral', 'User text 1', 'User text 2', 'User text 3', 'User text 4', 
    'User text 5', 'User text 6', 'User text 7', 'User text 8', 'User list 1', 'User list 2', 'User list 3', 
    'User list 4', 'User list 5', 'User list 6', 'User list 7', 'standard', NOW(), '2025-01-01', 'No', '2025-01-01', 
    'VFC', 'Jane Doe', 'Guardian Name', 'Yes', 'Yes', 'Yes', 'Yes', NULL, 'Reason', 1, 'cmsportal_login', 
    'Care Team Provider', 'Care Team Facility', 'Care Team Status', 'County', 'Industry', 'Imm Reg Status', 
    '2025-01-01', 'Publicity Code', '2025-01-01', 'Protect Indicator', '2025-01-01', 'Guardian Relationship', 
    'Guardian Sex', 'Guardian Address', 'Guardian City', 'Guardian State', 'Guardian Postal Code', 'Guardian Country', 
    'Guardian Phone', 'Guardian Work Phone', 'Guardian Email', 'Sexual Orientation', 'Gender Identity', 'Birth Fname', 
    'Birth Lname', 'Birth Mname', -9, 'Name History', 'Suffix', 'Street Line 2', 'Patient Groups', 'Prevent Portal Apps', 
    'Provider Since Date', 1, 2, 'Preferred Name', 'Nationality Country', NOW()
);
-->