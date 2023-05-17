import ballerina/http;

public isolated service class ResponseErrorInterceptor {
    *http:ResponseErrorInterceptor;

    remote isolated function interceptResponseError(error err)
    returns http:InternalServerError|http:NotFound|http:NotAcceptable {
        if err.message().includes(NO_ROWS_ERROR_MSG) {
            return <http:NotFound>{body: {errmsg: USER_NOT_FOUND}};
        }
        return <http:InternalServerError>{body: {message: err.message()}};
    }
}