import ballerina/http;
import ballerina/task;

string API_KEY = "01d21c186757db43aea92d2894d19ec4";
string[] availableCities = ["colombo"];

http:Client reporterClientEp = check new ("http://api.openweathermap.org/data/2.5");

function getWeatherDetails(string cityName) returns json|error {
    string servicePath = string`/weather?q=${cityName}&appid=${API_KEY}`;
    return reporterClientEp->get(servicePath, targetType = json);
}

function getTopicName(string cityName) returns string {
    return string`city-${cityName}`;
}



public class WeatherDetailsReporter {
    *task:Job;
    
    public function execute() {
        foreach var city in availableCities {
            json retrievedWeatherDetails = checkpanic getWeatherDetails(city);
            string topicName = getTopicName(city);
            checkpanic publishContent(topicName, retrievedWeatherDetails);
        }
    }
}