import ballerina/http;
import ballerinax/salesforce;

configurable record {
    string baseUrl;
    record {
        string clientId;
        string clientSecret;
        string refreshToken;
        string refreshUrl;
    } auth;
} sfConfig = ?;

// Initialize Salesforce client
final salesforce:Client salesforceClient = check new (config = {
    baseUrl: sfConfig.baseUrl,
    auth: {
        clientId: sfConfig.auth.clientId,
        clientSecret: sfConfig.auth.clientSecret,
        refreshToken: sfConfig.auth.refreshToken,
        refreshUrl: sfConfig.auth.refreshUrl
    }
});

service / on new http:Listener(8080) {
    resource function get account/[string accountId]() returns Account|error {
        // Get account information from Salesforce
        Account account = check salesforceClient->getById(
            sobjectName = "Account",
            id = accountId,
            returnType = Account
        );
        return account;
    }

    resource function get accounts() returns Account[]|error {
        string soql = string `SELECT Name, Industry, Phone, Website, BillingCity, BillingCountry 
                             FROM Account`;
        stream<Account, error?> accountStream = check salesforceClient->query(soql = soql);
        Account[] accounts = [];
        check from Account account in accountStream
            do {
                accounts.push(account);
            };
        return accounts;
    }

    resource function post account(@http:Payload Account account) returns salesforce:CreationResponse|error {
        salesforce:CreationResponse response = check salesforceClient->create(
            sObjectName = "Account",
            sObject = account
        );
        return response;
    }
}