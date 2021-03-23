# Apache Kafka based Weather Reporter #

* This module contains a `Weather Reporter` backed by **Apache Kafka Service**.
* This module will be periodically retrieve weather updates via open-API and publish it to a **kafka-topic** and subscribers who are subscribed to that particular topic could retrieve weather updates.

## Prerequisetes ##

* Ballerina SwanLake Alpha3+
* Ballerina Kafka V2.1.0-alpha5+
* Apache Kafka 2.7.0

## How to Build and Deploy ##