import ballerina/websubhub;
import ballerinax/kafka;
import weatherReporter.config;

// Producer which persist the current in-memory state of the Hub & weather details
kafka:ProducerConfiguration statePersistConfig = {
    clientId: "hub-state-persist",
    acks: "1",
    retryCount: 3
};
public final kafka:Producer statePersistProducer = check new (config:KAFKA_BOOTSTRAP_NODE, statePersistConfig);

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
