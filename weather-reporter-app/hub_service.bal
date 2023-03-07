import ballerina/http;
import ballerina/websubhub;

isolated string[] locations = [];
isolated map<websubhub:VerifiedSubscription> newsReceiversCache = {};

service websubhub:Service /hub on new websubhub:Listener(9000) {

    // Topic registration is not supported by this `hub`
    remote function onRegisterTopic(websubhub:TopicRegistration msg)
        returns websubhub:TopicRegistrationError {
        return error websubhub:TopicRegistrationError(
            "Topic registration not supported", statusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Topic deregistration is not supported by this `hub`
    remote function onDeregisterTopic(websubhub:TopicDeregistration msg) returns websubhub:TopicDeregistrationError {
        return error websubhub:TopicDeregistrationError(
            "Topic deregistration not supported", statusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    // Content update is not supported by this `hub`
    remote function onUpdateMessage(websubhub:UpdateMessage msg) returns websubhub:UpdateMessageError {
        return error websubhub:UpdateMessageError(
            "Content update not supported", statusCode = http:STATUS_NOT_IMPLEMENTED);
    }

    remote function onSubscriptionValidation(readonly & websubhub:Subscription msg) returns websubhub:SubscriptionDeniedError? {
        string subscriberId = string `${msg.hubTopic}-${msg.hubCallback}`;
        boolean newsReceiverAvailable = false;
        lock {
            newsReceiverAvailable = newsReceiversCache.hasKey(subscriberId);
        }
        if newsReceiverAvailable {
            return error websubhub:SubscriptionDeniedError(
                    string `News receiver for location ${msg.hubTopic} and endpoint ${msg.hubCallback} already available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
        }
    }

    remote function onSubscriptionIntentVerified(readonly & websubhub:VerifiedSubscription msg) returns error? {
        boolean localtionUnavailble = false;
        lock {
            if locations.indexOf(msg.hubTopic) is () {
                locations.push(msg.hubTopic);
                localtionUnavailble = true;
            }
        }
        string subscriberId = string `${msg.hubTopic}-${msg.hubCallback}`;
        lock {
            newsReceiversCache[subscriberId] = msg;
        }
        if localtionUnavailble {
            _ = @strand {thread: "any"} start startSendingNotifications(msg.hubTopic); 
        }
    }

    remote function onUnsubscriptionValidation(readonly & websubhub:Unsubscription msg) returns websubhub:UnsubscriptionDeniedError? {
        string subscriberId = string `${msg.hubTopic}-${msg.hubCallback}`;
        boolean newsReceiverNotAvailable = false;
        lock {
            newsReceiverNotAvailable = !newsReceiversCache.hasKey(subscriberId);
        }
        if newsReceiverNotAvailable {
            return error websubhub:UnsubscriptionDeniedError(
                    string `News receiver for location ${msg.hubTopic} and endpoint ${msg.hubCallback} not available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
        }
    }

    remote function onUnsubscriptionIntentVerified(readonly & websubhub:VerifiedUnsubscription msg) returns error? {
        string subscriberId = string `${msg.hubTopic}-${msg.hubCallback}`;
        removeNewsReceiver(subscriberId);
    }
}

isolated function removeNewsReceiver(string newsReceiverId) {
    lock {
        _ = newsReceiversCache.removeIfHasKey(newsReceiverId);
    }
}

isolated function getNewsReceivers(string location) returns websubhub:VerifiedSubscription[] {
    lock {
        return newsReceiversCache
            .filter(newsReceiver => newsReceiver.hubTopic == location)
            .toArray().cloneReadOnly();
    }
}
