import ballerina/http;
import ballerina/websubhub;

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

    remote function onSubscriptionValidation(websubhub:Subscription msg) returns websubhub:SubscriptionDeniedError? {
    }

    remote function onSubscriptionIntentVerified(websubhub:VerifiedSubscription msg) returns error? {
    }

    remote function onUnsubscriptionValidation(websubhub:Unsubscription msg) returns websubhub:UnsubscriptionDeniedError? {
    }

    remote function onUnsubscriptionIntentVerified(websubhub:VerifiedUnsubscription msg) returns error? {
    }
}
