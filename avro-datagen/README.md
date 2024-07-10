# Java Producer and Consumer with Avro

This directory includes projects demonstrating how to use the Java producer and consumer with Avro and Confluent Schema Registry

### To compile the avro schemas :    
```asciidoc
cd avro-datagen
mvn package avro:schema

```





How to use these examples:

* [ProducerExample.java](src/main/java/io/confluent/examples/clients/usecase1/ProducerExample.java): see [Confluent Schema Registry tutorial](https://docs.confluent.io/platform/current/schema-registry/schema_registry_tutorial.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-avro)
* [ConsumerExample.java](src/main/java/io/confluent/examples/clients/usecase1/ConsumerExample.java): see [Confluent Schema Registry tutorial](https://docs.confluent.io/platform/current/schema-registry/schema_registry_tutorial.html?utm_source=github&utm_medium=demo&utm_campaign=ch.examples_type.community_content.clients-avro)
