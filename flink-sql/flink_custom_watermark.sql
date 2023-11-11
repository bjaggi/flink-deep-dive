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
  


INSERT INTO newr_metrics_watermarked_tbl SELECT account,timestampMs,durationMs,metricName,counter, gauge, attributes  from newr_metrics;
https://developer.confluent.io/courses/apache-flink/event-time-exercise/



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




INSERT INTO `metric-1h-aggregations`
SELECT
window_start AS `window_ts`,
TIMESTAMPDIFF(SECOND, window_start, window_end) AS `window_duration`,
account,
metric_type,
metric_name,
attributes,
sum(counter_delta) AS `counter_delta`,
LAST_VALUE(counter_cumulative) AS `counter_cumulative`,
min(gauge_min) AS `gauge_min`,
max(gauge_max) AS `gauge_max`,
LAST_VALUE(gauge_latest) AS `gauge_latest`,
SUM(gauge_count) AS `gauge_count`,
SUM(gauge_sum) AS `gauge_sum`
FROM TABLE(TUMBLE(TABLE `metric-1m-aggregations` , DESCRIPTOR(window_ts), INTERVAL '1' HOURS))
GROUP BY window_start, window_end, metric_name, metric_type, account, attributes;

