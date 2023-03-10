import weather_reporter.config;
import ballerina/http;

public type WeatherItem record {
    int id;
    string main;
    string description;
    string icon;
};

public type Main record {
    decimal temp;
    decimal feels_like;
    decimal temp_min;
    decimal temp_max;
    int pressure;
    int humidity;
    int sea_level;
    int grnd_level;
};

public type Wind record {
    decimal speed;
    int deg;
    decimal gust;
};

public type Sys record {
    int 'type;
    int id;
    string country;
    int sunrise;
    int sunset;
};

public type WeatherReport record {
    record {|
        decimal lon;
        decimal lat;
    |} coord;
    WeatherItem[] weather;
    string base;
    Main main;
    int visibility;
    Wind wind;
    record {|
        int all;
    |} clouds;
    int dt;
    Sys sys;
    int timezone;
    int id;
    string name;
    int cod;
};

final http:Client openWeatherClient = check new(config:WEATHER_INFO_API,
        retryConfig = {
            interval: config:CLIENT_RETRY_INTERVAL,
            count: config:CLIENT_RETRY_COUNT,
            backOffFactor: 2.0,
            maxWaitInterval: 20
        },
        timeout = config:CLIENT_TIMEOUT
);

# Retrieves weather report for a given location.
#
# + location - Name of the location
# + return - A `WeatherReport` or else an `error`
public isolated function getWeatherReport(string location) returns WeatherReport|error {
    return openWeatherClient->get(string`/weather?q=${location}&appid=${config:API_KEY}`);
}
