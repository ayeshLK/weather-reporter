import ballerina/websub;
import ballerina/log;

@websub:SubscriberServiceConfig { 
    target: ["http://localhost:9000/hub", "Colombo"],
    leaseSeconds: 36000,
    unsubscribeOnShutdown: true
} 
service /sub1 on new websub:Listener(9091) {
    remote function onEventNotification(websub:ContentDistributionMessage event) returns websub:Acknowledgement {
        log:printInfo("Recieved weather-alert ", alert = event);
        return websub:ACKNOWLEDGEMENT;
    }
}
