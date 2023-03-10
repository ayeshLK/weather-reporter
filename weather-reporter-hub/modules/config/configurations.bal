import ballerina/os;

# The port that is used to start the hub
public configurable int HUB_PORT = 9000;

# Weather Info API base URL
public configurable string WEATHER_INFO_API = "https://api.openweathermap.org/data/2.5";

# Weather Info API client Key
public final string API_KEY = os:getEnv("OPEN_WEATHER_APP_KEY");

# Weather reporter scheduler running frequency
public configurable decimal REPORTER_SCHEDULED_TIME_IN_SECONDS = 1800.0;

# The period between retry requests
public configurable decimal CLIENT_RETRY_INTERVAL = 3;

# The maximum retry count
public configurable int CLIENT_RETRY_COUNT = 3;

# The message delivery timeout
public configurable decimal CLIENT_TIMEOUT = 10;
