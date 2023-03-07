import ballerina/random;
import ballerina/mime;
import ballerina/lang.runtime;
import ballerina/websubhub;

final readonly & string[] alerts = [
    "Severe weather alert for [LOCATION] until [TIME]. We will send updates as conditions develop. Please call this number [ALERT_LINE] for assistance or check local media.", 
    "TORNADO WATCH for [LOCATION] until [TIME]. Storm conditions have worsened, be prepared to move to a safe place. If you are outdoors, in a mobile home or in a vehicle, have a plan to seek shelter and protect yourself. Check local media for more information."
];

isolated map<websubhub:HubClient[]> notificationSenders = {};

isolated function startSendingNotifications(string location) returns error? {
    map<websubhub:HubClient> newsDispatchClients = {};
    while true {
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
            string subscriberId = string `${newsReceiver.hubTopic}-${newsReceiver.hubCallback}`;
            if !newsDispatchClients.hasKey(subscriberId) {
                newsDispatchClients[subscriberId] = check new (newsReceiver);
            }
        }
        
        if newsDispatchClients.length() == 0 {
            continue;
        }
        string alert = alerts[check random:createIntInRange(0, alerts.length())];
        foreach var [receiver, clientEp] in newsDispatchClients.entries() {
            websubhub:ContentDistributionSuccess|error response = clientEp->notifyContentDistribution({
                contentType: mime:APPLICATION_JSON,
                content: {
                    "weather-alert": alert
                }
            });
            if response is websubhub:SubscriptionDeletedError {
                removeNewsReceiver(receiver);
            }
        }
        runtime:sleep(600);
    }
}

isolated function getReceiverClients(string location) returns [websubhub:VerifiedSubscription, websubhub:HubClient][]|error {
    return getNewsReceivers(location)
        .'map(receiver => [receiver, check new websubhub:HubClient(receiver)]);
}

