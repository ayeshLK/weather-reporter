import ballerina/websubhub;
import weatherReporter.config;
import ballerina/task;
import weatherReporter.persistence;
import ballerina/log;
import ballerina/http;

isolated client class WeatherInfoClient {
    private final string apiKey;
    private final http:Client clientEp;

    isolated function init(string apiKey, string baseUrl, *http:ClientConfiguration config) returns error? {
        self.apiKey = apiKey;
        self.clientEp = check new (baseUrl, config);
    }

    isolated remote function retrieveInfo(string cityName) returns json|error {
        string servicePath = string`/weather?q=${cityName}&appid=${self.apiKey}`;
        return self.clientEp->get(servicePath);
    }
}

final WeatherInfoClient weatherInfoClient = check new(config:API_KEY, config:WEATHER_INFO_API);

isolated class WeatherInfoReportJob {
    *task:Job;
    private final string cityName;

    isolated function init(string cityName) {
        self.cityName = cityName;
    }

    public isolated function execute() {
        json|error response = weatherInfoClient->retrieveInfo(self.cityName);
        if response is json {
            error? persistingResult = persistence:produceKafkaMessage(self.cityName, response);
            if persistingResult is error {
                log:printError("Error occurred while persisting the weather information ", err = persistingResult.message());
            }
        }
    }
}

public isolated function startWeatherReport(string cityName) returns task:JobId|error {
    WeatherInfoReportJob job = new (cityName);
    task:JobId jobId = check task:scheduleJobRecurByFrequency(job, 1); 
    return jobId;
}

// todo: implement the consumer notification properly
public isolated function startNotification(websubhub:VerifiedSubscription msg) returns error? {

}
