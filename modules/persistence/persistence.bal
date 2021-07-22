import weatherReporter.connections as conn;

public isolated function updateWeatherInfo(string cityName, json info) returns error? {
    check produceKafkaMessage(cityName, info);
}

isolated function produceKafkaMessage(string topicName, json payload) returns error? {
    byte[] serializedContent = payload.toJsonString().toBytes();
    check conn:statePersistProducer->send({ topic: topicName, value: serializedContent });
    check conn:statePersistProducer->'flush();
}
