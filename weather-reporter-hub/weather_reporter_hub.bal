import ballerina/http;
import weather_reporter.config;
import ballerina/task;
import ballerina/websubhub;

isolated map<task:JobId> notificationSenders = {};
isolated map<websubhub:VerifiedSubscription> newsReceiversCache = {};

service /hub on new websubhub:Listener(config:HUB_PORT) {

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
        if !validNotificationSenderExists(subscription.hubTopic) {
            task:JobId notificationService = check startNotificationSender(subscription.hubTopic);
            lock {
                notificationSenders[subscription.hubTopic] = notificationService;
            }
        }
        string newsReceiverId = string `${subscription.hubTopic}-${subscription.hubCallback}`;
        lock {
            newsReceiversCache[newsReceiverId] = subscription;
        }
        check startNotificationReceiver(subscription);
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

isolated function validNotificationSenderExists(string location) returns boolean {
    lock {
        return notificationSenders.hasKey(location);
    }
}

isolated function isValidNewsReceiver(string location, string newsReceiverId) returns boolean {
    boolean subscriberAvailable = true;
    lock {
        subscriberAvailable = newsReceiversCache.hasKey(newsReceiverId);
    }
    return validNotificationSenderExists(location) && subscriberAvailable;
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
