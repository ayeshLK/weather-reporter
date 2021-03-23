import ballerinax/kafka;

const string BOOTSTRAP_SERVER = "localhost:9092";
const int RETRY_COUNT = 3;

kafka:ProducerConfiguration mainProducerConfig = {
    bootstrapServers: BOOTSTRAP_SERVER,
    clientId: "main-producer",
    acks: "1",
    retryCount: RETRY_COUNT
};

kafka:Producer mainProducer = checkpanic new (mainProducerConfig);

public function publishContent(string topicName, json payload) returns error? {
    byte[] content = payload.toJsonString().toBytes();
    check mainProducer->send({ topic: topicName, value: content });
    check mainProducer->'flush();
}