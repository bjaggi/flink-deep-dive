# flink-deep-dive
deep dive into flink sql 



https://avro.apache.org/docs/1.11.1/idl-language/


For our Avro schema, I:
Started from an IDL file
Generated the schema using avro-tools idl command. This generates a schema in “protocol” format (messages, protocol).
Most of the tooling (especially default java codegen) seems to expect a schema format without those fields.





9:12 AM
Brijesh Jaggi
 so you manually removed the “protocol” segment ?





9:19 AM
Aaron Miller
 Yes, but I was also able to pass protocol to some avro-tools commands to get codegen to work.


avro-tools idl IDL_FILE SCHEMA_OUTPUT_FILE



Aaron Miller
  4 days ago
avro-tools compile protocol SCHEMA_FILE OUTPUT_DIR
(edited)



Aaron Miller
  4 days ago
This is working better:
avro-tools idl2schemata IDL_FILE OUTPUT_DIR



mvn -Dcheckstyle.skip clean compile package

