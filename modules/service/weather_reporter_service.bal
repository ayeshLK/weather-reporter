import ballerina/websubhub;
import ballerinax/kafka;
import weatherReporter.config;
import ballerina/lang.value;
import ballerina/task;
import ballerina/mime;
import weatherReporter.persistence;
import ballerina/log;
import ballerina/http;
import weatherReporter.connections as conn;

final http:Client weatherInfoClient = check new(config:WEATHER_INFO_API,
        retryConfig = {
            interval: config:MESSAGE_DELIVERY_RETRY_INTERVAL,
            count: config:MESSAGE_DELIVERY_COUNT,
            backOffFactor: 2.0,
            maxWaitInterval: 20
        },
        timeout = config:MESSAGE_DELIVERY_TIMEOUT
);

isolated class WeatherReporter {
    *task:Job;
    private final string cityName;

    isolated function init(string cityName) {
        self.cityName = cityName;
    }

    public isolated function execute() {
        string servicePath = string`/weather?q=${self.cityName}&appid=${config:API_KEY}`;
        json|error response = weatherInfoClient->get(servicePath);
        if response is json {
            error? persistingResult = persistence:updateWeatherInfo(self.cityName, response);
            if persistingResult is error {
                log:printError("Error occurred while persisting the weather information ", err = persistingResult.message());
            }
        }
    }
}

public isolated function startWeatherReporter(string cityName) returns task:JobId|error {
    WeatherReporter weatherReporter = new (cityName);
    task:JobId jobId = check task:scheduleJobRecurByFrequency(weatherReporter, config:REPORTER_SCHEDULED_TIME_IN_SECONDS); 
    return jobId;
}

public function startSubscriberNotification(websubhub:VerifiedSubscription subscriber) returns error? {
    kafka:Consumer consumerEp = check conn:createMessageConsumer(subscriber);
    websubhub:HubClient hubClientEp = check new (subscriber, 
        retryConfig = {
            interval: config:MESSAGE_DELIVERY_RETRY_INTERVAL,
            count: config:MESSAGE_DELIVERY_COUNT,
            backOffFactor: 2.0,
            maxWaitInterval: 20
        },
        timeout = config:MESSAGE_DELIVERY_TIMEOUT
    );
    _ = @strand { thread: "any" } start pollForNewUpdates(hubClientEp, consumerEp);
}

isolated function pollForNewUpdates(websubhub:HubClient clientEp, kafka:Consumer consumerEp) returns error? {
    do {
        while true {
            kafka:ConsumerRecord[] records = check consumerEp->poll(config:POLLING_INTERVAL);
            var result = notifySubscribers(records, clientEp, consumerEp);
            if result is error {
                log:printError("Error occurred while sending notification to subscriber ", err = result.message());
            }
        }
    } on fail var e {
        _ = check consumerEp->close(config:GRACEFUL_CLOSE_PERIOD);
        return e;
    }
}

isolated function notifySubscribers(kafka:ConsumerRecord[] records, websubhub:HubClient clientEp, kafka:Consumer consumerEp) returns error? {
    foreach var kafkaRecord in records {
        byte[] content = kafkaRecord.value;
        string message = check string:fromBytes(content);
        json payload =  check value:fromJsonString(message);
        websubhub:ContentDistributionMessage distributionMsg = {
            content: payload,
            contentType: mime:APPLICATION_JSON
        };
        var response = clientEp->notifyContentDistribution(distributionMsg);
        if (response is error) {
            return response;
        } else {
             _ = check consumerEp->commit();
        }
    }
}
