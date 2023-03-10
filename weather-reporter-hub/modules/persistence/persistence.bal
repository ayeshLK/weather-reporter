import weather_reporter.connections as conn;
import weather_reporter.open.weather as weatherApi;

public isolated function publishWeatherNotification(string location, weatherApi:WeatherReport weatherReport) returns error? {
    json payload = weatherReport.toJson();
    byte[] serializedContent = payload.toJsonString().toBytes();
    check conn:messagePersistProducer->send({
        topic: location,
        value:  serializedContent
    });
    check conn:messagePersistProducer->'flush();
}
