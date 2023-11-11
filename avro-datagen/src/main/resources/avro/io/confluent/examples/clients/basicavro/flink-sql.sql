CREATE TABLE newr_metrics_tbl (
  `account` INT,
  `timestampMs` TIMESTAMP(3),
  `durationMs` BIGINT,
  `metricName` STRING ,
  `counter` ROW<`cumulativeValue` BIGINT, `deltaValue` BIGINT>,
  `gauge` ROW<`min` DOUBLE, `max` DOUBLE, `sum` DOUBLE, `count` DOUBLE, `latest` DOUBLE>,
  `attributes` MAP<STRING, STRING>      
);

CREATE TABLE newr_metrics_watermarked_tbl (
  `account` INT,
  `timestampMs` TIMESTAMP(3),
   WATERMARK FOR `timestampMs` AS timestampMs - INTERVAL '5' SECOND,
  `durationMs` BIGINT,
  `metricName` STRING ,
  `counter` ROW<`cumulativeValue` BIGINT, `deltaValue` BIGINT>,
  `gauge` ROW<`min` DOUBLE, `max` DOUBLE, `sum` DOUBLE, `count` DOUBLE, `latest` DOUBLE>,
  `attributes` MAP<STRING, STRING>      
);
  


### time format : 2023-11-03 16:44:08.034

INSERT INTO newr_metrics_tbl SELECT account,timestampMs,durationMs,metricName,counter, gauge, attributes  from newr_metrics;
INSERT INTO newr_metrics_watermarked_tbl SELECT account,timestampMs,durationMs,metricName,counter, gauge, attributes  from newr_metrics;
https://developer.confluent.io/courses/apache-flink/event-time-exercise/

SELECT 
	  CASE
    WHEN counter_cumulative IS NOT NULL THEN 'counter'
    WHEN gauge_sum IS NOT NULL THEN 'gauge_sum'
    ELSE 'other'
  END AS `metricType` , 
  window_start,
  window_end,
  account,
  metricName,
  attributes,
  counter_delta,
  counter_cumulative,
  gauge_min,
  gauge_max,
  gauge_latest,
  gauge_count
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
  FROM TABLE(TUMBLE(TABLE `newr_metrics_watermarked_tbl` , DESCRIPTOR(timestampMs), INTERVAL '1' MINUTES))
  GROUP BY window_start, window_end, metricName, account, attributes);

  CASE
    WHEN counter.cumulativeValue IS NOT NULL THEN 'counter'
    WHEN gauge.`sum` IS NOT NULL THEN 'gauge'
    ELSE 'other'
  END AS `metricType`,

select account, attributes,  metricName,  sum(counter.deltaValue) , sum(gauge.`sum`)  
from TABLE(  TUMBLE(TABLE newr_metrics_tbl , DESCRIPTOR($rowtime), INTERVAL '5' SECONDS))    group by metricName, account, attributes;

select account, attributes,  metricName,  sum(counter.deltaValue) `counter_delta` , LAST_VALUE(counter.cumulativeValue) `latest_counter_cumalative` , sum(gauge.`sum`)  
from TABLE(  TUMBLE(TABLE newr_metrics_watermarked_tbl , DESCRIPTOR(timestampMs), INTERVAL '5' SECONDS))    group by metricName, account, attributes;


select window_start, window_end, account, attributes,  metricName,  sum(counter.deltaValue) , sum(gauge.`sum`)  from TABLE(  TUMBLE(TABLE newr_metrics_tbl , DESCRIPTOR($rowtime), INTERVAL '5' SECONDS))    group by window_start, window_end, metricName, account, attributes;



CREATE TABLE nr_dataPoints3 (
`dataPoints` ARRAY<ROW<`account` INT NOT NULL, `timestampMs` TIMESTAMP(3) NOT NULL, `durationMs` BIGINT NOT NULL, `metricName` STRING NOT NULL, `counter` ROW<`cumulativeValue` BIGINT NOT NULL, `deltaValue` BIGINT>, `gauge` ROW<`min` DOUBLE NOT NULL, `max` DOUBLE NOT NULL, `sum` DOUBLE NOT NULL, `count` DOUBLE NOT NULL, `latest` DOUBLE>, `attributes` MAP<STRING, STRING NOT NULL> NOT NULL> NOT NULL> ) WITH (
  'connector' = 'kafka',
  'topic' = 'newr.metrics',
  'properties.bootstrap.servers' = 'pkc-ep9mm.us-east-2.aws.confluent.cloud:9092',
  'properties.group.id' = 'newr_cg',
  'scan.startup.mode' = 'earliest-offset',
  'format' = 'avro',
  'properties.security.protocol' = 'SASL_SSL',
  'properties.sasl.mechanism' = 'PLAIN',
  'properties.sasl.jaas.config' = 'org.apache.flink.kafka.shaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="JLUQNLOZEQ7ATG2J" password="33PMvW3t03WuPOyNZZyoV1sbhQzdHmySYpL6pVHK9Ywz2AczQewE/5JdOKfS3TeN";' 
);

CREATE TABLE nr_dataPoints (
`dataPoints` STRING );
INSERT INTO nr_dataPoints2 SELECT * from `newr_metrics`;

INSERT INTO newr_metrics_tbl2 SELECT account,timestampMs,durationMs,metricName,counter, gauge, attributes  from newr_metrics;;





CREATE TABLE newr_metrics_tbl (  `account` INT,  `timestampMs` BIGINT,  `metricName` STRING ) WITH (  'connector' = 'kafka',  'topic' = 'newr.metrics',  'properties.bootstrap.servers' = 'pkc-ep9mm.us-east-2.aws.confluent.cloud:9092',  'properties.group.id' = 'newr_cg',  'scan.startup.mode' = 'earliest-offset',  'format' = 'avro',  'properties.security.protocol' = 'SASL_SSL',  'properties.sasl.mechanism' = 'PLAIN',  'properties.sasl.jaas.config' = 'org.apache.flink.kafka.shaded.org.apache.kafka.common.security.plain.PlainLoginModule required username="JLUQNLOZEQ7ATG2J" password="33PMvW3t03WuPOyNZZyoV1sbhQzdHmySYpL6pVHK9Ywz2AczQewE/5JdOKfS3TeN";' );