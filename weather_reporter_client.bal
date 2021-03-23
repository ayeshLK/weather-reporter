import ballerina/http;

http:Client reporterClientEp = check new ("https://open.api.com/weather/updates");

