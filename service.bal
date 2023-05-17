import ballerinax/slack;
import ballerina/http;
import ballerina/log;
import ballerinax/vonage.sms as vs;

configurable string host = ?;
configurable string username = ?;
configurable string password = ?;
configurable string database = ?;
configurable int port = ?;
// configurable string slackToken = ?;
// configurable string api_key = ?;
// configurable string api_secret = ?;
final string slackToken = "";
final string api_key = "";
final string api_secret = "";

@http:ServiceConfig {
    interceptors: [new ResponseErrorInterceptor()]
}
isolated service / on new http:Listener(9090) {

    private final GramaCheckDao gramacheckDao;
    private final slack:Client slackClient;
    private final slack:ConnectionConfig slackConfig = {auth: {token: slackToken}};
    private final vs:ConnectionConfig smsconfig = {};
    private final vs:Client baseClient;
    private final http:Client identityValidationClient;
    private final http:Client addressValidationClient;
    private final http:Client policeValidationClient;

    public isolated function init() returns error? {
        // Initialize the database
        self.gramacheckDao = check new (host, username, password, database, port);
        self.slackClient = check new (self.slackConfig);
        self.baseClient = check new (self.smsconfig, serviceUrl = "https://rest.nexmo.com/sms");
        self.identityValidationClient = check new ("localhost:9091");
        self.addressValidationClient = check new ("localhost:9092");
        self.policeValidationClient = check new ("localhost:9093");
    }

    isolated resource function get apply(string userId, string address) returns error? {
        _ = check self.gramacheckDao.storeRequest(userId);
        http:Response _ = check self.identityValidationClient->get("/identitycheck?userId=" + userId);
        http:Response _ = check self.addressValidationClient->get("/addresscheck?userId=" + userId + "&address=" + address);
        http:Response _ = check self.policeValidationClient->get("/policecheck?userId=" + userId);
    }

    isolated resource function post sendMessage(string user_message) returns string|error {
        slack:Message messageParams = {
            channelName: "general",
            text: user_message
        };

        string postResponse = check self.slackClient->postMessage(messageParams);
        check self.slackClient->joinConversation("general");
        return postResponse;
    }

    isolated resource function post approveorDeclineCertificate(string userId, boolean approved) returns string|error {
        if approved {
            _ = check self.gramacheckDao.updateStatus(userId, APPROVED);
        } else {
            _ = check self.gramacheckDao.updateStatus(userId, DECLINED);
        }

        string user_contactNumber = check self.gramacheckDao.getConatctNumber(userId);
        string sms_message = approved ? CERTIFICATE_APPROVED : CERTIFICATE_DECLINED;
        vs:NewMessage message = {
            api_key: api_key,
            'from: "Vonage APIs",
            to: user_contactNumber,
            api_secret: api_secret,
            text: sms_message
        };

        vs:InlineResponse200|error response = self.baseClient->sendAnSms(message);
        if response is error {
            log:printError("Error sending SMS: ", err = response.message());
        }
        return sms_message;
    }

    isolated resource function get getStatus(string userId) returns string|error {
        string|error status = self.gramacheckDao.getStatus(userId);
        if status is error && status.message() == NO_ROWS_ERROR_MSG {
            return NOT_APPLIED_FOR_A_CERTIFICATE;
        }
        return status;
    }

}

