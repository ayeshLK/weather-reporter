import ballerina/websubhub;
import weatherReporter.config;
import ballerina/task;
import weatherReporter.'service;

listener websubhub:Listener hubListener = check new (config:HUB_PORT);
isolated map<task:JobId> availableJobs = {};
isolated map<websubhub:VerifiedSubscription> availableSubscribers = {}; 

service /hub on hubListener {
    isolated remote function onRegisterTopic(websubhub:TopicRegistration msg) returns websubhub:TopicRegistrationSuccess {
        return websubhub:TOPIC_REGISTRATION_SUCCESS;
    }

    isolated remote function onDeregisterTopic(websubhub:TopicDeregistration msg) returns websubhub:TopicDeregistrationSuccess {
        return websubhub:TOPIC_DEREGISTRATION_SUCCESS;
    }

    isolated remote function onUpdateMessage(websubhub:UpdateMessage msg) returns websubhub:Acknowledgement {
        return websubhub:ACKNOWLEDGEMENT;
    }

    isolated remote function onSubscription(websubhub:Subscription msg) returns websubhub:SubscriptionAccepted {
        return websubhub:SUBSCRIPTION_ACCEPTED;
    }

    isolated remote function onSubscriptionValidation(websubhub:Subscription msg) returns websubhub:SubscriptionDeniedError? {
        string subscriberKey = string `${msg.hubTopic}_${msg.hubCallback}`;
        lock {
            if availableSubscribers.hasKey(subscriberKey) {
                return error websubhub:SubscriptionDeniedError("Subscriber has already registered with the Hub");
            }
        }
    }

    remote function onSubscriptionIntentVerified(websubhub:VerifiedSubscription msg) returns error? {
        string cityName = msg.hubTopic;
        lock {
            if !availableJobs.hasKey(cityName) {
                task:JobId job = check 'service:startWeatherReport(cityName);
                availableJobs[cityName] = job;
            }
        }
        lock {
            string subscriberKey = string `${msg.hubTopic}_${msg.hubCallback}`;
            availableSubscribers[subscriberKey] = msg.cloneReadOnly();
        }
        check 'service:startNotification(msg);
    }
    
    isolated remote function onUnsubscription(websubhub:Unsubscription msg) returns websubhub:UnsubscriptionAccepted {
        return websubhub:UNSUBSCRIPTION_ACCEPTED;
    }

    isolated remote function onUnsubscriptionValidation(websubhub:Unsubscription msg) returns websubhub:UnsubscriptionDeniedError? {
        string subscriberKey = string `${msg.hubTopic}_${msg.hubCallback}`;
        lock {
            if !availableSubscribers.hasKey(subscriberKey) {
                return error websubhub:UnsubscriptionDeniedError("Could not find a valid subscriber on weather report for city [" 
                                + msg.hubTopic + "] with callback URL [" + msg.hubCallback + "]");
            }
        }
    }

    isolated remote function onUnsubscriptionIntentVerified(websubhub:VerifiedUnsubscription msg) {
        string subscriberKey = string `${msg.hubTopic}_${msg.hubCallback}`;
        lock {
            _ = availableSubscribers.removeIfHasKey(subscriberKey);
        }
    }
}
