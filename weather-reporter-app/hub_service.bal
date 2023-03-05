import ballerina/http;
import ballerina/websubhub;

isolated map<websubhub:VerifiedSubscription[]> newsReceiversCache = {};

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
        lock {
            websubhub:VerifiedSubscription[]? newsReceiversForLocation = newsReceiversCache[msg.hubTopic];
            if newsReceiversForLocation is () {
                return;
            }
            boolean newsReceiverAvailable = newsReceiversForLocation.some(receiver => receiver.hubCallback != msg.hubCallback);
            if newsReceiverAvailable {
                return error websubhub:SubscriptionDeniedError(
                    string `News receiver for location ${msg.hubTopic} and endpoint ${msg.hubCallback} already available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
            }
        }
    }

    remote function onSubscriptionIntentVerified(readonly & websubhub:VerifiedSubscription msg) returns error? {
        boolean localtionUnavailble = false;
        lock {
            if newsReceiversCache.hasKey(msg.hubTopic) {
                newsReceiversCache.get(msg.hubTopic).push(msg);
            } else {
                newsReceiversCache[msg.hubTopic] = [msg];
                localtionUnavailble = true;
            }
        }
        if localtionUnavailble {
            _ = @strand {thread: "any"} start startSendingNotifications(msg.hubTopic); 
        }
    }

    remote function onUnsubscriptionValidation(readonly & websubhub:Unsubscription msg) returns websubhub:UnsubscriptionDeniedError? {
        lock {
            websubhub:VerifiedSubscription[]? newsReceiversForLocation = newsReceiversCache[msg.hubTopic];
            if newsReceiversForLocation is () {
                return error websubhub:UnsubscriptionDeniedError(
                    string `News receiver for location ${msg.hubTopic} not available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
            }
            boolean newsReceiverNotAvailable = newsReceiversForLocation.every(receiver => receiver.hubCallback != msg.hubCallback);
            if newsReceiverNotAvailable {
                return error websubhub:UnsubscriptionDeniedError(
                    string `News receiver for location ${msg.hubTopic} and endpoint ${msg.hubCallback} not available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
            }
        }
    }

    remote function onUnsubscriptionIntentVerified(readonly & websubhub:VerifiedUnsubscription msg) returns error? {
        removeReceiver(msg.hubTopic, msg.hubCallback);
    }
}

isolated function getNewsReceivers(string location) returns websubhub:VerifiedSubscription[] {
    lock {
        if newsReceiversCache.hasKey(location) {
            return newsReceiversCache.get(location).cloneReadOnly();
        }
    }
    return [];
}

isolated function removeReceiver(string location, string callbackUrl) {
    lock {
        newsReceiversCache[location] = newsReceiversCache
                .get(location)
                .filter(receiver => receiver.hubCallback != callbackUrl);
    }
}
