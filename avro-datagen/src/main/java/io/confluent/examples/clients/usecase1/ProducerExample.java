package io.confluent.examples.clients.usecase1;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.serialization.StringSerializer;
import io.confluent.kafka.serializers.KafkaAvroSerializer;
import org.apache.kafka.common.errors.SerializationException;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.Instant;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import com.newrelic.metrics.*;

public class ProducerExample {

    private static final String TOPIC = "newr_metrics";
    private static final Properties props = new Properties();
    private static String configFile;

    @SuppressWarnings("InfiniteLoopStatement")
    public static void main(final String[] args) throws IOException, ExecutionException {



          // Load properties from a local configuration file
          // Create the configuration file (e.g. at '$HOME/.confluent/java.config') with configuration parameters
          // to connect to your Kafka cluster, which can be on your local host, Confluent Cloud, or any other cluster.
          // Documentation at https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/java.html
          configFile = "/Users/bjaggi/confluent/examples/clients/avro/src/main/resources/ccloud.properties";
          if (!Files.exists(Paths.get(configFile))) {
            throw new IOException(configFile + " not found.");
          } else {
            try (InputStream inputStream = new FileInputStream(configFile)) {
              props.load(inputStream);
            }
          }


        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 0);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, KafkaAvroSerializer.class);
        int partitionNo = 0;
        try (KafkaProducer<String, DataPoint> producer = new KafkaProducer<String, DataPoint>(props)) {

            for (long i = 0; i < 10; i++) {

              Map<String,String> map = new HashMap<String,String>();
              map.put("newrKey", "newrValue"+i);
              //map.put("newrKey2", "newrValue2");
              CumulativeCounter cCtr = CumulativeCounter.newBuilder()
              .setCumulativeValue(10L)
              .setDeltaValue(1L)
              .build();


              int randomCount = (int) (Math.random() * 10);
              EventBatch eventBatch = null;

              for (int counter = 0; counter < randomCount; counter++) {
                CumulativeCounter localcCtr = CumulativeCounter.newBuilder().setCumulativeValue(counter)
                  .setDeltaValue(counter == 0 ? 0 : 1L)
                  .build();

                Gauge guage = Gauge.newBuilder()
                  .setCount(counter)
                  .setLatest((double) counter)
                  .setMax(counter)
                  .setMin(counter)
                  .setSum(counter)
                  .build();

                DataPoint dpCtr = DataPoint.newBuilder()
                  .setAccount(counter)
                  .setAttributes(map)
                  .setDurationMs(15000)
                  .setMetricName("my.counter")
                  .setCounter(localcCtr)
                  .setGauge(null)
                  .setTimestampMs(Instant.now().plusSeconds(15 * counter))
                  .build();

                DataPoint dpGuage =  DataPoint.newBuilder()
                .setAccount(1)
                .setAttributes(map)
                .setDurationMs(15000)
                .setMetricName("my.guage")
                .setGauge(guage)
                .setCounter(null)
                .setTimestampMs(Instant.now().plusSeconds(15*counter))
                .build();

                eventBatch = EventBatch.newBuilder().setDataPoints( Arrays.asList(dpCtr,dpGuage)).build();
              }
                eventBatch.getDataPoints().forEach( dp -> {
                  System.out.println(dp);
                  final ProducerRecord<String, DataPoint> record = new ProducerRecord<String, DataPoint>(TOPIC, dp );
                 Future<RecordMetadata> metaData = producer.send(record);
                  try {
                    System.out.println("Message written on Partition : "+ metaData.get().partition());
                  } catch (InterruptedException e) {
                    e.printStackTrace();
                  } catch (ExecutionException e) {
                    e.printStackTrace();
                  }
                });


                Thread.sleep(1000L);
            }

            producer.flush();
            System.out.printf("Successfully produced 1 messages to a partition number %d%n and", partitionNo );

        } catch (final SerializationException e) {
            e.printStackTrace();
        } catch (final InterruptedException e) {
            e.printStackTrace();
        }

    }

}
