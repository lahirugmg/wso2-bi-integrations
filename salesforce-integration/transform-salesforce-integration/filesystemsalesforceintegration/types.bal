# Represents the Salesforce configuration.
type SalesforceConfig record {|
    string baseUrl;
    OAuth2Config auth;
|};

# Represents the OAuth2 configuration.
type OAuth2Config record {|
    string clientId;
    string clientSecret;
    string refreshToken;
    string refreshUrl;
|};

# Represents a Contact record.
type Contact record {|
    string FirstName;
    string LastName;
    string Email;
    string Phone?;
    string Department?;
    string Title?;
    string MailingCity?;
    string MailingCountry?;
|};

# Represents the contacts data structure.
type ContactsData record {|
    Contact[] contacts;
|};