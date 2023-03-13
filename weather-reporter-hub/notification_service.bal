import ballerina/mime;
import ballerina/log;
import weather_reporter.config;
import weather_reporter.open.weather as weatherApi;
import ballerina/task;
import weather_reporter.persistence as persist;
import ballerinax/kafka;
import weather_reporter.connections as conn;
import ballerina/websubhub;

isolated class NotificationSender {
    *task:Job;
    private final string location;

    isolated function init(string location) {
        self.location = location;
    }

    public isolated function execute() {
        weatherApi:WeatherReport|error weatherReport = weatherApi:getWeatherReport(self.location);
        if weatherReport is error {
            log:printWarn(string `Error occurred while retrieving weather-report: ${weatherReport.message()}`, stackTrace = weatherReport.stackTrace());
            return;
        }
        error? persistResult = persist:publishWeatherNotification(self.location, weatherReport);
        if persistResult is error {
            log:printWarn(string `Error occurred while persisting the weather-report: ${persistResult.message()}`, stackTrace = persistResult.stackTrace());
        }
    }
}

isolated function startNotificationSender(string location) returns task:JobId|error {
    NotificationSender notificationSender = new (location);
    return task:scheduleJobRecurByFrequency(notificationSender, config:REPORTER_SCHEDULED_TIME_IN_SECONDS);
}

type UpdateMessageConsumerRecord record {|
    *kafka:AnydataConsumerRecord;
    weatherApi:WeatherReport value;
|};

function startNotificationReceiver(websubhub:VerifiedSubscription newsReceiver) returns error? {
    kafka:Consumer kafkaConsumer = check conn:createMessageConsumer(newsReceiver);
    websubhub:HubClient hubClient = check new (newsReceiver, {
        retryConfig: {
            interval: config:CLIENT_RETRY_INTERVAL,
            count: config:CLIENT_RETRY_COUNT,
            backOffFactor: 2.0,
            maxWaitInterval: 20
        },
        timeout: config:CLIENT_TIMEOUT
    });
    _ = start pollForNewUpdates(hubClient, kafkaConsumer, newsReceiver);
}

isolated function pollForNewUpdates(websubhub:HubClient hubClient, kafka:Consumer kafkaConsumer, websubhub:VerifiedSubscription newsReceiver) returns error? {
    string location = newsReceiver.hubTopic;
    string receiverId = string `${newsReceiver.hubTopic}-${newsReceiver.hubCallback}`;
    do {
        while true {
            UpdateMessageConsumerRecord[] records = check kafkaConsumer->poll(config:POLLING_INTERVAL);
            if !isValidNewsReceiver(location, receiverId) {
                fail error(string `Subscriber with Id ${receiverId} or topic ${location} is invalid`);
            }
            var result = notifySubscribers(records, hubClient, kafkaConsumer);
            if result is error {
                log:printError("Error occurred while sending notification to subscriber ", err = result.message());
                check result;
            } else {
                check kafkaConsumer->'commit();
            }
        }
    } on fail var e {
        log:printError(string `Error occurred while sending notification to news-receiver: ${e.message()}`, stackTrace = e.stackTrace());
        removeNewsReceiver(receiverId);
        kafka:Error? result = kafkaConsumer->close(config:GRACEFUL_CLOSE_PERIOD);
        if result is kafka:Error {
            log:printError("Error occurred while gracefully closing kafka-consumer", err = result.message());
        }
    }
}

isolated function notifySubscribers(UpdateMessageConsumerRecord[] records, websubhub:HubClient clientEp, kafka:Consumer consumerEp) returns error? {
    foreach UpdateMessageConsumerRecord kafkaRecord in records {
        websubhub:ContentDistributionMessage message = {
            content: kafkaRecord.value.toJson(),
            contentType: mime:APPLICATION_JSON
        };
        websubhub:ContentDistributionSuccess|error response = clientEp->notifyContentDistribution(message);
        if response is error {
            return response;
        }
    }
}
