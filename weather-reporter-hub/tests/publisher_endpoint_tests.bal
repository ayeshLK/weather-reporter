import ballerina/websubhub;
import ballerina/http;
import ballerina/mime;
import ballerina/test;

final websubhub:PublisherClient publisherClient = check new ("http://localhost:9000/hub");

@test:Config {
    groups: ["publisher"]
}
function testTopicRegistration() returns error? {
    websubhub:TopicRegistrationSuccess|websubhub:TopicRegistrationError response = publisherClient->registerTopic("test-topic");
    if response is websubhub:TopicRegistrationSuccess {
        test:assertFail("topic-registration: success response received for a failure scenario");
    }
    websubhub:CommonResponse errorDetails = response.detail();
    int responseStatus = errorDetails.statusCode;
    test:assertEquals(responseStatus, http:STATUS_NOT_IMPLEMENTED, "topic-registration: invalid response code received");
    map<string> responseBody = check errorDetails.body.ensureType();
    test:assertEquals(responseBody["hub.mode"], "denied", "topic-registration: invalid `hub.mode` received");
    test:assertEquals(responseBody["hub.reason"], "Topic registration not supported", "topic-registration: invalid `hub.reason` received");
}

@test:Config {
    groups: ["publisher"]
}
function testTopicDeregistration() returns error? {
    websubhub:TopicDeregistrationSuccess|websubhub:TopicDeregistrationError response = publisherClient->deregisterTopic("test-topic");
    if response is websubhub:TopicDeregistrationSuccess {
        test:assertFail("topic-deregistration: success response received for a failure scenario");
    }
    websubhub:CommonResponse errorDetails = response.detail();
    int responseStatus = errorDetails.statusCode;
    test:assertEquals(responseStatus, http:STATUS_NOT_IMPLEMENTED, "topic-deregistration: invalid response code received");
    map<string> responseBody = check errorDetails.body.ensureType();
    test:assertEquals(responseBody["hub.mode"], "denied", "topic-deregistration: invalid `hub.mode` received");
    test:assertEquals(responseBody["hub.reason"], "Topic deregistration not supported", "topic-deregistration: invalid `hub.reason` received");
}

@test:Config {
    groups: ["publisher"]
}
function testPublishUpdate() returns error? {
    map<string> payload = {
        "event": "publish-update"
    };
    websubhub:Acknowledgement|websubhub:UpdateMessageError response = publisherClient->publishUpdate(
        "test-topic",
        payload = payload,
        contentType = mime:APPLICATION_FORM_URLENCODED
    );
    if response is websubhub:Acknowledgement {
        test:assertFail("publish-update: success response received for a failure scenario");
    }
    websubhub:CommonResponse errorDetails = response.detail();
    int responseStatus = errorDetails.statusCode;
    test:assertEquals(responseStatus, http:STATUS_NOT_IMPLEMENTED, "publish-update: invalid response code received");
    map<string> responseBody = check errorDetails.body.ensureType();
    test:assertEquals(responseBody["hub.mode"], "denied", "publish-update: invalid `hub.mode` received");
    test:assertEquals(responseBody["hub.reason"], "Content update not supported", "publish-update: invalid `hub.reason` received");
}

@test:Config {
    groups: ["publisher"]
}
function testNotifyUpdate() returns error? {
    websubhub:Acknowledgement|websubhub:UpdateMessageError response = publisherClient->notifyUpdate("test-topic");
    if response is websubhub:Acknowledgement {
        test:assertFail("notify-update: success response received for a failure scenario");
    }
    websubhub:CommonResponse errorDetails = response.detail();
    int responseStatus = errorDetails.statusCode;
    test:assertEquals(responseStatus, http:STATUS_NOT_IMPLEMENTED, "notify-update: invalid response code received");
    map<string> responseBody = check errorDetails.body.ensureType();
    test:assertEquals(responseBody["hub.mode"], "denied", "notify-update: invalid `hub.mode` received");
    test:assertEquals(responseBody["hub.reason"], "Content update not supported", "notify-update: invalid `hub.reason` received");
}
