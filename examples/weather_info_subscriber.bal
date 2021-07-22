import ballerina/websub;
import ballerina/log;


@websub:SubscriberServiceConfig { 
    target: ["http://localhost:9000/hub", "colombo"],
    leaseSeconds: 36000 
} 
service / on new websub:Listener(9091) {
    remote function onSubscriptionValidationDenied(websub:SubscriptionDeniedError msg) returns websub:Acknowledgement? {
        log:printInfo("onSubscriptionValidationDenied invoked");
        return {};
    }

    remote function onSubscriptionVerification(websub:SubscriptionVerification msg) returns websub:SubscriptionVerificationSuccess {
        log:printInfo("onSubscriptionVerification invoked");
        return {};
      }

    remote function onEventNotification(websub:ContentDistributionMessage event) 
                        returns websub:Acknowledgement|websub:SubscriptionDeletedError? {
        log:printInfo("onEventNotification invoked ", contentDistributionMessage = event);
        return {};
    }
}
