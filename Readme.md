# Apache Kafka based Weather Reporter #

* This module contains a `Weather Reporter` backed by **Apache Kafka Service**.
* This module will be periodically retrieve weather updates via open-API and publish it to a **kafka-topic** and subscribers who are subscribed to that particular topic could retrieve weather updates.

## Prerequisetes ##

* Ballerina SwanLake Alpha3+
* Ballerina Kafka V2.1.0-alpha5+
* Apache Kafka 2.7.0

## How to Build and Deploy ##

* Run following command from project root directory.

```sh
    bal run
```

## How to setup and run Apache Kafka ##

* Download **Apache Kafka** from [here](https://kafka.apache.org/downloads).

* Extract the `zip` file and go into `kafka_2.13-2.7.X` directory.

* Run following command to start the `kafka zookeeper`.

```sh
    ./bin/zookeeper-server-start.sh config/zookeeper.properties
```

* Run following command to start the `kafka broker`.

```sh
    ./bin/kafka-server-start.sh config/server.properties
```

* For more information on **Apache Kafka** go through [following guides](https://kafka.apache.org/quickstart).