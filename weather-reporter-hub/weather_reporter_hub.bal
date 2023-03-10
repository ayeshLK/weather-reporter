import ballerina/http;
import ballerina/websubhub;

isolated string[] locations = [];
isolated map<websubhub:VerifiedSubscription> newsReceiversCache = {};

service /hub on new websubhub:Listener(9000) {

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

    remote function onSubscriptionValidation(readonly & websubhub:Subscription subscription) returns websubhub:SubscriptionDeniedError? {
        string newsReceiverId = string `${subscription.hubTopic}-${subscription.hubCallback}`;
        boolean newsReceiverAvailable = false;
        lock {
            newsReceiverAvailable = newsReceiversCache.hasKey(newsReceiverId);
        }
        if newsReceiverAvailable {
            return error websubhub:SubscriptionDeniedError(
                    string `News receiver for location ${subscription.hubTopic} and endpoint ${subscription.hubCallback} already available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
        }
    }

    remote function onSubscriptionIntentVerified(readonly & websubhub:VerifiedSubscription subscription) returns error? {
        boolean localtionUnavailble = false;
        lock {
            if locations.indexOf(subscription.hubTopic) is () {
                locations.push(subscription.hubTopic);
                localtionUnavailble = true;
            }
        }
        string newsReceiverId = string `${subscription.hubTopic}-${subscription.hubCallback}`;
        lock {
            newsReceiversCache[newsReceiverId] = subscription;
        }
        if localtionUnavailble {
            _ = start startSendingNotifications(subscription.hubTopic); 
        }
    }

    remote function onUnsubscriptionValidation(readonly & websubhub:Unsubscription unsubscription) returns websubhub:UnsubscriptionDeniedError? {
        string newsReceiverId = string `${unsubscription.hubTopic}-${unsubscription.hubCallback}`;
        boolean newsReceiverNotAvailable = false;
        lock {
            newsReceiverNotAvailable = !newsReceiversCache.hasKey(newsReceiverId);
        }
        if newsReceiverNotAvailable {
            return error websubhub:UnsubscriptionDeniedError(
                    string `News receiver for location ${unsubscription.hubTopic} and endpoint ${unsubscription.hubCallback} not available`,
                    statusCode = http:STATUS_NOT_ACCEPTABLE
                );
        }
    }

    remote function onUnsubscriptionIntentVerified(readonly & websubhub:VerifiedUnsubscription unsubscription) returns error? {
        string newsReceiverId = string `${unsubscription.hubTopic}-${unsubscription.hubCallback}`;
        removeNewsReceiver(newsReceiverId);
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