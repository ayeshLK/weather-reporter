import ballerina/mime;
import ballerina/lang.runtime;
import ballerina/log;
import weather_reporter.config;
import weather_reporter.open.weather as weatherApi;
import ballerina/websubhub;

isolated function startSendingNotifications(string location) returns error? {
    map<websubhub:HubClient> newsDispatchClients = {};
    while true {
        log:printInfo("Running news-alert dispatcher for ", location = location);
        websubhub:VerifiedSubscription[] currentNewsReceivers = getNewsReceivers(location);
        final readonly & string[] currentNewsReceiverIds = currentNewsReceivers
            .'map(receiver => string `${receiver.hubTopic}-${receiver.hubCallback}`)
            .cloneReadOnly();

        // remove clients related to unsubscribed news-receivers
        string[] unsubscribedReceivers = newsDispatchClients.keys().filter(dispatcherId => currentNewsReceiverIds.indexOf(dispatcherId) is ());
        foreach string unsubscribedReceiver in unsubscribedReceivers {
            _ = newsDispatchClients.removeIfHasKey(unsubscribedReceiver);
        }

        // add clients related to newly subscribed news-receivers
        foreach var newsReceiver in currentNewsReceivers {
            string newsReceiverId = string `${newsReceiver.hubTopic}-${newsReceiver.hubCallback}`;
            if !newsDispatchClients.hasKey(newsReceiverId) {
                newsDispatchClients[newsReceiverId] = check createHubClient(newsReceiver);
            }
        }

        if newsDispatchClients.length() == 0 {
            runtime:sleep(config:REPORTER_SCHEDULED_TIME_IN_SECONDS);
            continue;
        }
        weatherApi:WeatherReport|error weatherReport = weatherApi:getWeatherReport(location);
        if weatherReport is error {
            log:printWarn(string `Error occurred while retrieving weather-report: ${weatherReport.message()}`, stackTrace = weatherReport.stackTrace());
            runtime:sleep(config:REPORTER_SCHEDULED_TIME_IN_SECONDS);
            continue;

        }
        foreach var [newsReceiverId, clientEp] in newsDispatchClients.entries() {
            websubhub:ContentDistributionSuccess|error response = clientEp->notifyContentDistribution({
                contentType: mime:APPLICATION_JSON,
                content: {
                    "weather-report": weatherReport.toJson()
                }
            });
            if response is websubhub:SubscriptionDeletedError {
                log:printWarn("News receiver responded with subscription-delete response, hence removing", id = newsReceiverId);
                removeNewsReceiver(newsReceiverId);
            }
        }
        runtime:sleep(config:REPORTER_SCHEDULED_TIME_IN_SECONDS);
    }
}

isolated function createHubClient(websubhub:VerifiedSubscription subscription) returns websubhub:HubClient|error {
    return new (subscription, {
        retryConfig: {
            interval: config:CLIENT_RETRY_INTERVAL,
            count: config:CLIENT_RETRY_COUNT,
            backOffFactor: 2.0,
            maxWaitInterval: 20
        },
        timeout: config:CLIENT_TIMEOUT
    });
}
