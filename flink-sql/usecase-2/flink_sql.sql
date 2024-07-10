# STEP 1 : Create a customer_requests table
CREATE TABLE customer_requests (
  `id` STRING ,
  `ip_address` STRING ,
  `method` STRING ,
  `user_id` STRING ,
  `company_id` BIGINT ,
  `timestamp` STRING,
  `timestampMs` TIMESTAMP(3),
   WATERMARK FOR `timestampMs` AS `timestampMs` - INTERVAL '10' SECOND
);

desc customer_requests;

# To Drop a table in flink
# Delete the topic + schema

# STEP 1.1 : Insert data to the customer_requests table
insert into customer_requests VALUES (1), (1.1.1.1), (POST), (bjaggi) , (100),  (bjaggi);
INSERT INTO customer_requests (`id`, `ip_address`, `method`, `user_id`, `company_id`, `timestamp` , `timestampMs`) SELECT '100', '10.10.10.10', 'POST', 'bjaggi' , 100 , '1969-12-31 16:00:00' , CURRENT_ROW_TIMESTAMP();

# STEP 1.2 : Insert data to the customer_requests from a Kafka topic
insert into customer_requests  select id, 'method' , ip_address, user_id, company_id, 'timestamp' , timestampMs from customer_requests_raw_avro;


# STEP 2 : Create the actors_compact table
CREATE TABLE actors_compact (
  `company_id` BIGINT  METADATA   ,
  `login_information_id` BIGINT NOT NULL   ,
  `id` STRING ,
  `name` STRING ,
  `email_address` STRING,
  `event_timestamp` TIMESTAMP(3),
  `is_employee` BOOLEAN,
  PRIMARY KEY(`company_id`,`login_information_id`) NOT ENFORCED) ;


# STEP 2.1 : Insert into the actors_compact table
insert into actors_compact ( `company_id`, `login_information_id`,`id`,`name`, `email_address`, `event_timestamp` ) SELECT 100 , 100 , '100' , 'jaggi' , 'bjaggi@confluent.io' , CURRENT_ROW_TIMESTAMP() ;
# STEP 2.2 : Insert into the actors_compact table from a kafka topic
insert into actors_compact  select company_id, login_information_id, id, name , email_address, event_timestamp, is_employee from actors_compact_raw_avro;

# Step 3  : Join the two tables
select customer_requests.id, customer_requests.user_id , actors_compact.company_id , actors_compact.email_address
from customer_requests LEFT JOIN actors_compact
ON CAST(customer_requests.id AS BIGINT)  = actors_compact.login_information_id
AND customer_requests.company_id = actors_compact.company_id





