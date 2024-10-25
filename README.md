# Confluent Flink Sql deep dive
Here is a code repo for Confluent Flink Sql PoC with a customer. 

A very popular SaaS company gathers telemetry data from websites and mobile apps to track user interactions and software and hardware performance. 

There is a lot of telemetry data to be processed in realtime. At high level they analyze metrics of key data points in a 1 minute, 1 hour and 1 Day window.




# Table of Contents
1. [Scope of the Use Case 1](#poc1)
1. [Scope of the Use Case 2](#poc2)

# Scope of the Use Case 1  <a name="poc1"></a>

![use case 1](https://github.com/bjaggi/flink-deep-dive/blob/main/image/flink-poc.png)   


. Create AVRO schema using AVRO IDL   
. Generate mock AVRO data on Kafka topics.   
. Create Flink Tables on Confluent Cloud   
. Ingest data from a Kafka topic to a Flink Table.   
. Write the SQL query to process data for the required analytics.   

*Note: Customer's AVRO schema had `union` semantics, currently there is no support for `union` in Flink SQL, and we decided to create our own schema replacing union with nullable attributes. This step may not be required if the schema was in a state acceptable by Flink Sql.*

### Step1> Create a schema using AVRO IDL

[Avro IDL](https://avro.apache.org/docs/1.11.1/idl-language), is a higher-level language for creating Avro schema's.

For our Avro schema, we started with creating an IDL [file](https://github.com/bjaggi/flink-deep-dive/blob/main/avro-tools/metrics_avro.idl), present in the `avro-tools` folder . Once the IDL is in an acceptable state we converted that to `.avsc` format using the cli    `avro-tools idl IDL_FILE SCHEMA_OUTPUT_FILE`. 

*Note: This generates a schema in “protocol” format (messages, protocol).
Most of the tooling (especially default java codegen) seems to expect a schema format without those fields. Some minimal editing of the avsc may be required if you are using a PROTOCOL, use CLI : `avro-tools idl2schemata IDL_FILE OUTPUT_DIR`*


### Step2> Produce AVRO data for the schema created

A sample framework is present in the folder : `avro-datagen` , where you compile the `.avsc` file and produce sample data

Use the following command to compile the code: 
`mvn -Dcheckstyle.skip clean compile package`


### Step3> Create a FLink SQL table

The folder `flink-sql` has a file called [flink_sql.sql](https://github.com/bjaggi/flink-deep-dive/blob/main/flink-sql/flink_sql.sql).

~~~sql
CREATE TABLE newr_metrics_tbl (
  `account` INT,
  `timestampMs` TIMESTAMP(3),
  `durationMs` BIGINT,
  `metricName` STRING ,
  `counter` ROW<`cumulativeValue` BIGINT, `deltaValue` BIGINT>,
  `gauge` ROW<`min` DOUBLE, `max` DOUBLE, `sum` DOUBLE, `count` DOUBLE, `latest` DOUBLE>,
  `attributes` MAP<STRING, STRING>      
);
~~~

### Step4> Ingest Data to Flink SQL

`newr_metrics_tbl` is the Flink table and `newr_metrics` is the kafka topic, on executing of this command a job is started on Flink. Which can be monitored on the Flink Dashboard.
~~~sql
INSERT INTO newr_metrics_tbl SELECT account,timestampMs,durationMs,metricName,counter, gauge, attributes  from newr_metrics;
~~~

### Step5> SQL Analytics using Flink
~~~sql
INSERT INTO `metric-1m-aggregations` SELECT (account, metricName, attributes) AS `identity`,  sum(counter.deltaValue) AS `counter_deltaValue`, sum(gauge.`sum`) AS`gauge_sum`  from TABLE(TUMBLE(TABLE `newr_metrics_tbl` , DESCRIPTOR($rowtime), INTERVAL '1' MINUTES)) group by metricName, account, attributes;
~~~

*Note: `DESCRIPTOR($rowtime)` is using `$rowtime` hence the ingestion time, if you want a custom watermark strategy change that time to event time, show later in the section*


~~~sql
INSERT INTO `metric-1m-aggregations`
SELECT
  window_start,
  window_end,
  account,
  metricName,
  attributes,
  sum(counter.deltaValue) AS `counter_delta`,
  LAST_VALUE(counter.cumulativeValue) AS `counter_cumulative`,
  min(gauge.`min`) AS `gauge_min`,
  max(gauge.`max`) AS `gauge_max`,
  sum(gauge.`sum`) AS `gauge_sum`,
  LAST_VALUE(gauge.`latest`) AS `gauge_latest`,
  sum(gauge.`count`) AS `gauge_count`
  FROM TABLE(TUMBLE(TABLE `metric-data-points` , DESCRIPTOR($rowtime), INTERVAL '1' MINUTES);
~~~

### Custom WaterMark using Flink

Example 1 :    
~~~sql
CREATE TABLE Orders (
    user BIGINT,
    product STRING,
    order_time TIMESTAMP(3),
    WATERMARK FOR order_time AS order_time - INTERVAL '5' SECOND
) WITH ( . . . );
~~~

Reference : https://nightlies.apache.org/flink/flink-docs-release-1.10/dev/table/sql/create.html#create-table   




Example 2 :   
~~~sql
FROM TABLE(TUMBLE(TABLE `newr_metrics_watermarked_tbl` , DESCRIPTOR(timestampMs), INTERVAL '1' MINUTES))
~~~

~~~sql
INSERT INTO `metric-1m-aggregations`
SELECT
  window_start AS `window_ts`,
  TIMESTAMPDIFF(SECOND, window_start, window_end) AS `window_duration`,
  account,
 CASE
    WHEN counter_cumulative IS NOT NULL THEN 'counter'
    WHEN gauge_sum IS NOT NULL THEN 'gauge_sum'
    ELSE 'other'
  END AS `metric_type`,
  metricName AS `metric_name`,
  attributes,
  counter_delta,
  counter_cumulative,
  gauge_min,
  gauge_max,
  gauge_latest,
  gauge_count,
  gauge_sum
FROM (SELECT
  window_start,
  window_end,
  account,
  metricName,
  attributes,
  sum(counter.deltaValue) AS `counter_delta`,
  LAST_VALUE(counter.cumulativeValue) AS `counter_cumulative`,
  min(gauge.`min`) AS `gauge_min`,
  max(gauge.`max`) AS `gauge_max`,
  sum(gauge.`sum`) AS `gauge_sum`,
  LAST_VALUE(gauge.`latest`) AS `gauge_latest`,
  sum(gauge.`count`) AS `gauge_count`
  FROM TABLE(TUMBLE(TABLE `metric-data-points` , DESCRIPTOR(timestampMs), INTERVAL '1' MINUTES))
  GROUP BY window_start, window_end, metricName, account, attributes);
~~~



# Scope of the Use Case 2  <a name="poc2"></a>

High level scope is migrating existing OSS FLink SQL to CC Flink SQL   ( details in the image)
![use case 2](https://github.com/bjaggi/flink-deep-dive/blob/main/image/usecase_2.png)   

Steps taken :    
1. Create Flink Tables ( details in the flink sql folder )   
    <b>Note</b> : to delete a flink table : delete the kafka topic, its value schema and key schema 
2. To write data to a Flink table do the following    
   .   Take the schema from the kafka topic and compile them in the datagen utility here.   
    <b>Note</b> : If you have keys in the Flink table, those attributes will be moved to the key schema. If you want to produce data for key and value. you have one of the following optioms.   
    .  Create a table with these properties 
   ```
   CREATE TABLE t_joint (k INT, v STRING)
   DISTRIBUTED BY (k)
   WITH ('value.fields-include' = 'all');
   ```
   . Alter the producer schema ( merge key and value schema), and produce all data to a raw topic. As done in the usecase2. Data from ths raw topic can then be ingested to a Flink table.    
3. 




### Query/ Monitor/ Troubleshoot
. Monitor   ( Also avaible on CC UI) 
https://api.telemetry.confluent.cloud/docs/descriptors/datasets/cloud   
. Troubleshoot   
If a flink query fails, you can check the logs. Also break the query into smaller chunks to analyze the sub/inner query.   



# References
https://docs.confluent.io/cloud/current/flink/concepts/comparison-with-oss-flink.html   

https://medium.com/confluent/flink-sql-in-practice-create-your-first-table-in-confluent-cloud-20cb0cbbfa38
https://confluentinc.atlassian.net/wiki/spaces/~63bc5d3249a31f95b8733e8b/pages/3338865133/Flink+SQL+Examples+on+Confluent+Cloud

https://docs.confluent.io/cloud/current/flink/reference/statements/create-table.html#distributed-by-clause      
https://confluentinc.atlassian.net/wiki/spaces/CPFundamentals/pages/3416785013/Flink+Setup+Hands+on   
https://confluentinc.atlassian.net/wiki/spaces/~63bc5d3249a31f95b8733e8b/pages/3338865133/Flink+SQL+Examples+on+Confluent+Cloud    




