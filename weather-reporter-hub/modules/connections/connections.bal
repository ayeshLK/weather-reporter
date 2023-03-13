import weather_reporter.config;
import ballerina/websubhub;
import ballerinax/kafka;

// Producer which persist the messages related to weather details
kafka:ProducerConfiguration messagePersistConfig = {
    clientId: "message-persist-client",
    acks: "1",
    retryCount: 3
};
public final kafka:Producer messagePersistProducer = check new (config:KAFKA_BOOTSTRAP_NODE, messagePersistConfig);

# Creates a `kafka:Consumer` for a subscriber.
# 
# + message - The subscription details
# + return - `kafka:Consumer` if succcessful or else `error`
public isolated function createMessageConsumer(websubhub:VerifiedSubscription message) returns kafka:Consumer|error {
    string groupName = string `${message.hubTopic}_${message.hubCallback}`;
    kafka:ConsumerConfiguration consumerConfiguration = {
        groupId: groupName,
        topics: [message.hubTopic],
        autoCommit: false
    };
    return check new (config:KAFKA_BOOTSTRAP_NODE, consumerConfiguration);  
}
