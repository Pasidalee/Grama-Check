import ballerina/sql;
import ballerinax/postgresql;
// import ballerina/time;

type Address record {|
    string? address_line1;
    string? address_line2;
    string? city;
|};

isolated client class GramaCheckDao {

    private final postgresql:Client dbClient;
    public isolated function init(string host, string username, string password, string database, int port) returns error? {
        // Initialize the database
        self.dbClient = check new (host, username, password, database, port);
    }

    isolated function storeRequest(string userId) returns error? {
        // int createdTimeStamp = time:utcNow()[0];
        sql:ParameterizedQuery query = `INSERT INTO certificate_requests (user_id) VALUES (${userId})`;
        _ = check self.dbClient->execute(query);
    }

    isolated function updateStatus(string userId, string status) returns error? {
        sql:ParameterizedQuery query = `UPDATE certificate_requests SET status = ${status} WHERE user_id = ${userId} AND 
            status != ${APPROVED} AND status != ${DECLINED}`;
        _ = check self.dbClient->execute(query);
    }

    isolated function getStatus(string userId) returns string|error {
        sql:ParameterizedQuery query = `SELECT status FROM certificate_requests WHERE user_id = ${userId} AND 
            status != ${APPROVED} AND status != ${DECLINED}`;
        return self.dbClient->queryRow(query);
    }

    isolated function getConatctNumber(string userId) returns string|error {
        sql:ParameterizedQuery query = `SELECT contact_number FROM user_details WHERE user_id = ${userId}`;
        return self.dbClient->queryRow(query);
    }

}
