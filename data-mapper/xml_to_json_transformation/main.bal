import ballerina/http;

service / on new http:Listener(8080) {
    
    resource function post contacts(http:Request request) returns ContactJson[]|http:InternalServerError {
        do {
            // Get XML payload from request body
            xml xmlPayload = check request.getXmlPayload();
            
            // Transform to target JSON format
            ContactJson[] jsonContacts = [];
            
            // Navigate through XML to extract contact data
            xml contactElements = xmlPayload/<Contact>;
            
            foreach xml contactElement in contactElements {
                string firstName = (contactElement/<FirstName>).data();
                string lastName = (contactElement/<LastName>).data();
                string email = (contactElement/<Email>).data();
                string department = (contactElement/<Department>).data();
                string title = (contactElement/<Title>).data();
                
                // Extract phone number (handle both with and without phone element)
                string phoneValue = "";
                xml phoneElements = contactElement/<Phone>;
                if phoneElements.length() > 0 {
                    phoneValue = phoneElements.data();
                }
                
                // Extract mailing address information
                string mailingCity = "";
                string mailingCountry = "";
                xml addressElements = contactElement/<Address>;
                if addressElements.length() > 0 {
                    xml cityElements = addressElements/<City>;
                    xml countryElements = addressElements/<Country>;
                    if cityElements.length() > 0 {
                        mailingCity = cityElements.data();
                    }
                    if countryElements.length() > 0 {
                        mailingCountry = countryElements.data();
                    }
                }
                
                ContactJson jsonContact = {
                    FirstName: firstName,
                    LastName: lastName,
                    Email: email,
                    Phone: phoneValue,
                    Department: department,
                    Title: title,
                    MailingCity: mailingCity,
                    MailingCountry: mailingCountry
                };
                
                jsonContacts.push(jsonContact);
            }
            
            return jsonContacts;
            
        } on fail error e {
            return <http:InternalServerError>{
                body: {
                    "error": "Failed to process XML data",
                    "message": e.message()
                }
            };
        }
    }
}