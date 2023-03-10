import ballerina/mime;
import ballerina/lang.runtime;
import ballerina/log;
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
                newsDispatchClients[newsReceiverId] = check new (newsReceiver);
            }
        }

        if newsDispatchClients.length() == 0 {
            runtime:sleep(60);
            continue;
        }
        WeatherReport|error weatherReport = getWeatherReport(location);
        if weatherReport is error {
            runtime:sleep(60);
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
                removeNewsReceiver(newsReceiverId);
            }
        }
        runtime:sleep(60);
    }
}
