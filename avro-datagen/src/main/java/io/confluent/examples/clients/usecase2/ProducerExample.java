package io.confluent.examples.clients.basicavro;

import org.apache.flink.avro.generated.actors_compact;
import org.apache.flink.avro.generated.customer_requests;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;
import org.apache.kafka.common.serialization.StringSerializer;
import io.confluent.kafka.serializers.KafkaAvroSerializer;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.io.FileInputStream;
import java.io.InputStream;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;


public class ProducerExample {

    private static final String TOPIC_CUSTOMERS =  "customer_requests_raw_avro";
    private static final String TOPIC_ACTOR =  "actors_compact_raw_avro";
    private static final Properties props = new Properties();
    private static String configFile;

    @SuppressWarnings("InfiniteLoopStatement")
    public static void main(final String[] args) throws IOException, ExecutionException, InterruptedException {
        customer_requests cr;
        actors_compact ar;

        // Load properties from a local configuration file
        // Create the configuration file (e.g. at '$HOME/.confluent/java.config') with configuration parameters
        // to connect to your Kafka cluster, which can be on your local host, Confluent Cloud, or any other cluster.
        // Documentation at https://docs.confluent.io/platform/current/tutorials/examples/clients/docs/java.html
        configFile = "/Users/bjaggi/confluent/flink-deep-dive/use_case_1/avro-datagen/src/main/resources/ccloud.properties";
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
        final int partitionNo = 0;
        KafkaProducer<String, customer_requests> requestsKafkaProducer = new KafkaProducer<String, customer_requests>(props) ;
        KafkaProducer<String, actors_compact> actorKafkaProducer = new KafkaProducer<String, actors_compact>(props) ;
        long numRecords = 10000;
        long numTimes = 10000;
        Future<RecordMetadata> metaData = null;
        for (long t = 0; t < numRecords; t++) {
            for (long i = 0; i < numRecords; i++) {
                cr = customer_requests.newBuilder()
                        .setId("420")
                        .setUserId("bjaggi")
                        .setCompanyId(100L)
                        .setTimestampMs(System.currentTimeMillis())
                        .build();


                final ProducerRecord<String, customer_requests> record = new ProducerRecord<String, customer_requests>(TOPIC_CUSTOMERS, cr);
                requestsKafkaProducer.send(record);
                System.out.println("sent cusomter request record");
            }

            for (long i = 0; i < numRecords; i++) {
                ar = actors_compact.newBuilder()
                        .setId("420")
                        .setCompanyId(100)
                        .setLoginInformationId(420)
                        .setEmailAddress("bjaggi@confluent.io")
                        .setEventTimestamp(System.currentTimeMillis())
                        .build();
                ;

                final ProducerRecord<String, actors_compact> arecord = new ProducerRecord<String, actors_compact>(TOPIC_ACTOR, ar);
                actorKafkaProducer.send(arecord);
                System.out.println("sent actor record");
            }
        }
    }

}