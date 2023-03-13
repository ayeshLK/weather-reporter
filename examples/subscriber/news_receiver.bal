import ballerina/websub;
import ballerina/log;

@websub:SubscriberServiceConfig { 
    target: ["http://localhost:9000/hub", "Colombo"]
} 
service /receiver on new websub:Listener(9091) {
    remote function onEventNotification(websub:ContentDistributionMessage event) returns websub:Acknowledgement {
        log:printInfo("Recieved weather-alert ", alert = event);
        return websub:ACKNOWLEDGEMENT;
    }
}
