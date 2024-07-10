CREATE TABLE newr_metrics_tbl (
  `account` INT,
  `timestampMs` TIMESTAMP(3),
  `durationMs` BIGINT,
  `metricName` STRING ,
  `counter` ROW<`cumulativeValue` BIGINT, `deltaValue` BIGINT>,
  `gauge` ROW<`min` DOUBLE, `max` DOUBLE, `sum` DOUBLE, `count` DOUBLE, `latest` DOUBLE>,
  `attributes` MAP<STRING, STRING>      
);


INSERT INTO newr_metrics_tbl SELECT account,timestampMs,durationMs,metricName,counter, gauge, attributes  from newr_metrics;


select account, attributes,  metricName,  sum(counter.deltaValue) , sum(gauge.`sum`)  
from TABLE(  TUMBLE(TABLE newr_metrics_tbl , DESCRIPTOR($rowtime), INTERVAL '5' SECONDS))  
group by metricName, account, attributes;


select window_start, window_end, account, attributes,  metricName,  sum(counter.deltaValue) , sum(gauge.`sum`)  from TABLE(  TUMBLE(TABLE newr_metrics_tbl , DESCRIPTOR($rowtime), INTERVAL '5' SECONDS))    group by window_start, window_end, metricName, account, attributes;






