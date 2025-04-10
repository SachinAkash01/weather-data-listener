import ballerina/ftp;
import ballerina/io;
import ballerina/log;

listener ftp:Listener WeatherListener = new (protocol = ftp:FTP, host = ftpHost, port = 21, auth = {credentials: {username: ftpUser, password: ftpPassword}}, path = "/data/observations/metar/decoded/", fileNamePattern = "(.*).TXT", pollingInterval = 10);

service ftp:Service on WeatherListener {
    remote function onFileChange(ftp:WatchEvent & readonly event, ftp:Caller caller) returns error? {
        do {
            foreach ftp:FileInfo addedFile in event.addedFiles {
                stream<byte[] & readonly, io:Error?> fileStream = check caller->get(addedFile.pathDecoded);
                record {|byte[] value;|}|() content = check fileStream.next();
                if content is record {|byte[] value;|} {
                    string fileContent = check string:fromBytes(content.value);
                    int|() firstLineIndex = fileContent.indexOf("\n");
                    if firstLineIndex is int {
                        string location = fileContent.substring(0, firstLineIndex);
                        log:printInfo("Received weather information from: " + location);
                    }
                } else {
                    log:printError("Failed to read weather content");
                }
            }
        } on fail error err {
            // handle error
            return error("Not implemented", err);
        }
    }

}
