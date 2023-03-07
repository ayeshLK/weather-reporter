import ballerina/random;
import ballerina/mime;
import ballerina/lang.runtime;
import ballerina/regex;
import ballerina/time;
import ballerina/log;
import ballerina/websubhub;

final readonly & string[] alerts = [
    "Severe weather alert for [LOCATION] until [TIME]. We will send updates as conditions develop. Please call this number 1919 for assistance or check local media.", 
    "TORNADO WATCH for [LOCATION] until [TIME]. Storm conditions have worsened, be prepared to move to a safe place. If you are outdoors, in a mobile home or in a vehicle, have a plan to seek shelter and protect yourself. Please call this number 1919 for assistance or check local media."
];

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
            continue;
        }
        string alert = check retrieveAlert(location);
        foreach var [newsReceiverId, clientEp] in newsDispatchClients.entries() {
            websubhub:ContentDistributionSuccess|error response = clientEp->notifyContentDistribution({
                contentType: mime:APPLICATION_JSON,
                content: {
                    "weather-alert": alert
                }
            });
            if response is websubhub:SubscriptionDeletedError {
                removeNewsReceiver(newsReceiverId);
            }
        }
        runtime:sleep(60);
    }
}

isolated function retrieveAlert(string location) returns string|error {
    string alert = alerts[check random:createIntInRange(0, alerts.length())];
    alert = regex:replace(alert, "\\[LOCATION\\]", location);
    time:Utc alertExpiryTime = time:utcAddSeconds(time:utcNow(), 3600);
    alert = regex:replace(alert, "\\[TIME\\]", time:utcToString(alertExpiryTime));
    return alert;
}

