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
    [websubhub:VerifiedSubscription, websubhub:HubClient][] newsReceivers = [];
    while true {
        newsReceivers = check getReceiverClients(location);
        string alert = alerts[check random:createIntInRange(0, alerts.length())];
        foreach var [receiver, clientEp] in newsReceivers {
            websubhub:ContentDistributionSuccess|error response = clientEp->notifyContentDistribution({
                contentType: mime:APPLICATION_JSON,
                content: {
                    "weather-alert": alert
                }
            });
            if response is websubhub:SubscriptionDeletedError {
                removeReceiver(receiver.hubTopic, receiver.hubCallback);
            }
        }
        runtime:sleep(600);
    }
}

isolated function getReceiverClients(string location) returns [websubhub:VerifiedSubscription, websubhub:HubClient][]|error {
    return getNewsReceivers(location)
        .'map(receiver => [receiver, check new websubhub:HubClient(receiver)]);
}
