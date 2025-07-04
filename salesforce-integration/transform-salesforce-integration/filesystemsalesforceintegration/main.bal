import ballerina/io;
import ballerinax/salesforce.bulk;

configurable SalesforceConfig sfConfig = ?;

// Initialize the Salesforce bulk client
final bulk:Client salesforceClient = check new ({
    baseUrl: sfConfig.baseUrl,
    auth: {
        clientId: sfConfig.auth.clientId,
        clientSecret: sfConfig.auth.clientSecret,
        refreshToken: sfConfig.auth.refreshToken,
        refreshUrl: sfConfig.auth.refreshUrl
    }
});

public function main() returns error? {
    // Read XML file
    xml xmlContent = check io:fileReadXml("contact-sample.xml");
    io:println("Successfully read XML file");

    // Extract contacts from XML
    xml:Element[] contactElements = from xml:Element item in xmlContent/<Contact>
        select item;
    
    if contactElements.length() == 0 {
        return error("No contacts found in XML file");
    }
    io:println(string `Found ${contactElements.length().toString()} contacts`);

    // Convert XML contacts to Contact records
    Contact[] contacts = [];
    foreach xml:Element item in contactElements {
        Contact contact = {
            FirstName: (item/<FirstName>).data(),
            LastName: (item/<LastName>).data(),
            Email: (item/<Email>).data(),
            Phone: (item/<Phone>).data(),
            Department: (item/<Department>).data(),
            Title: (item/<Title>).data(),
            MailingCity: (item/<Address>/<City>).data(),
            MailingCountry: (item/<Address>/<Country>).data()
        };
        contacts.push(contact);
    }

    // Write contacts array directly to JSON file
    check io:fileWriteJson("contacts.json", contacts.toJson());
    io:println("Successfully wrote contacts to JSON file");

    // Create bulk job for Contact object
    bulk:BulkJob|error insertJob = salesforceClient->createJob(
        operation = "insert",
        sobj = "Contact",
        contentType = "CSV"
    );
    
    if insertJob is bulk:BulkJob {
        // Convert contact data to CSV string
        string csvContent = "FirstName,LastName,Email,Phone,Department,Title,MailingCity,MailingCountry\n";
        foreach Contact contact in contacts {
            csvContent += string:'join(",", 
                contact.FirstName,
                contact.LastName,
                contact.Email,
                contact.Phone ?: "",
                contact.Department ?: "",
                contact.Title ?: "",
                contact.MailingCity ?: "",
                contact.MailingCountry ?: ""
            ) + "\n";
        }
        
        // Add batch to job
        bulk:BatchInfo|error batch = salesforceClient->addBatch(insertJob, csvContent);
        if batch is bulk:BatchInfo {
            string batchId = batch.id;
            io:println("Batch added successfully. Batch ID: ", batchId);
            
            // Get batch info
            bulk:BatchInfo|error batchInfo = salesforceClient->getBatchInfo(insertJob, batchId);
            if batchInfo is bulk:BatchInfo {
                io:println("Batch info received successfully");
            } else {
                io:println("Error getting batch info: ", batchInfo.message());
            }
            
            // Get all batches
            bulk:BatchInfo[]|error batchInfoList = salesforceClient->getAllBatches(insertJob);
            if batchInfoList is bulk:BatchInfo[] {
                io:println("All batches received successfully");
            } else {
                io:println("Error getting all batches: ", batchInfoList.message());
            }
            
            // Get batch request
            error|json|xml|string batchRequest = salesforceClient->getBatchRequest(insertJob, batchId);
            if batchRequest is string {
                io:println("Batch request received successfully");
            } else if batchRequest is error {
                io:println("Error getting batch request: ", batchRequest.message());
            }
            
            // Get batch result
            error|json|xml|string|bulk:Result[] batchResult = salesforceClient->getBatchResult(insertJob, batchId);
            if batchResult is bulk:Result[] {
                foreach bulk:Result res in batchResult {
                    if !res.success {
                        io:println("Failed result: ", res.toString());
                    }
                }
            } else if batchResult is error {
                io:println("Error getting batch result: ", batchResult.message());
            }
            
            // Close job
            bulk:JobInfo|error closedJob = salesforceClient->closeJob(insertJob);
            if closedJob is bulk:JobInfo {
                io:println("Job closed successfully. State: ", closedJob.state);
            } else {
                io:println("Error closing job: ", closedJob.message());
            }
        } else {
            io:println("Error adding batch: ", batch.message());
        }
    } else {
        io:println("Error creating job: ", insertJob.message());
    }
}