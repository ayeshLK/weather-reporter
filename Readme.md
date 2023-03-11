# Weather Reporter #

The project contains a Websub-compliant `hub` implementation which acts as a weather alerts distribution hub. News channels that need to receive 
weather alerts for a particular location can subscribe to the `hub` and receive periodic weather alerts. The `hub` uses [Open Weather Map](https://openweathermap.org/) API to retrieve weather reports for a given location.

Following is the high-level component diagram for this implementation.

<img src="weather-reporter-hub.png" alt="drawing" width='500'/>

## Run the System ##

### Setting up Apache Kafka ###

### Run the Hub ###

1. Get the `API_KEY` from [Open Weather Map](https://openweathermap.org/) and set up `OPEN_WEATHER_APP_KEY` environment variable.
```sh
export OPEN_WEATHER_APP_KEY="xxxx"
```

2. Go into `weather-reporter-hub` directory.
```sh
cd weather-reporter-hub
```

3. Execute the following command to run the `hub`.
```sh
bal run
```

### Run the News Receiver ###

1. Go into `examples/subscriber` directory.
```sh
cd examples/subscriber
```

2. Execute the following command to run the `hub`.
```sh
bal run news_receiver.bal
```
