const express = require("express");
const helmet = require("helmet");
const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { 
    DynamoDBDocumentClient, 
    GetCommand, 
    PutCommand, 
    UpdateCommand, 
    DeleteCommand, 
    ScanCommand 
} = require("@aws-sdk/lib-dynamodb");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");
const dotenv = require("dotenv");
const serverless = require("serverless-http");

// Load environment variables
dotenv.config();

const app = express();
app.use(express.json());
app.use(helmet()); // Security headers

// AWS Clients
const secretsClient = new SecretsManagerClient({ region: process.env.AWS_REGION });
const dbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const docClient = DynamoDBDocumentClient.from(dbClient);

let TABLE_NAME = "RealEstateListings";
let DB_SECRET_NAME = process.env.DB_SECRET_NAME;

// Retrieve secret (DynamoDB table name) securely
async function getDBSecret() {
    try {
        const data = await secretsClient.send(new GetSecretValueCommand({ SecretId: DB_SECRET_NAME }));
        const secret = JSON.parse(data.SecretString);
        TABLE_NAME = secret.tableName; // Example secret format: { "tableName": "RealEstateListings" }
    } catch (error) {
        console.error("Error fetching secret:", error);
        process.exit(1);
    }
}

//await getDBSecret(); // Fetch secret before API starts
(async () => {
    await getDBSecret();
})();

// Input validation helper
function validateProperty(data) {
    if (!data.PropertyID || typeof data.PropertyID !== "string") return "Invalid PropertyID";
    if (!data.Title || typeof data.Title !== "string") return "Invalid Title";
    if (!data.Description || typeof data.Description !== "string") return "Invalid Description";
    if (!["Rent", "Sale"].includes(data.PropertyType)) return "Invalid PropertyType (Must be 'Rent' or 'Sale')";
    if (typeof data.Price !== "number" || data.Price < 0) return "Invalid Price";
    if (!data.PropertyLocation || typeof data.PropertyLocation !== "string") return "Invalid PropertyLocation";
    return null;
}

// ✅ Create a new property
app.post("/property", async (req, res) => {
    const error = validateProperty(req.body);
    if (error) return res.status(400).json({ error });

    try {
        const params = new PutCommand({
            TableName: TABLE_NAME,
            Item: req.body,
            ConditionExpression: "attribute_not_exists(PropertyID)", // Prevent overwriting existing data
        });

        await docClient.send(params);
        res.status(201).json({ message: "Property created successfully" });
    } catch (err) {
        res.status(500).json({ error: "Error creating property", details: err.message });
    }
});

// ✅ Get a property by ID
app.get("/property/:id", async (req, res) => {
    try {
        const params = new GetCommand({
            TableName: TABLE_NAME,
            Key: { PropertyID: req.params.id },
        });

        const data = await docClient.send(params);
        if (!data.Item) return res.status(404).json({ error: "Property not found" });

        res.status(201).json(data.Item);
    } catch (err) {
        res.status(500).json({ error: "Error fetching property", details: err.message });
    }
});

// ✅ Update a property
app.put("/property/:id", async (req, res) => {
    const { Title, Description, PropertyType, Price, PropertyLocation } = req.body;
    if (!Title && !Description && !PropertyType && !Price && !PropertyLocation) return res.status(400).json({ error: "No fields to update" });

    try {
        const params = new UpdateCommand({
            TableName: TABLE_NAME,
            Key: { PropertyID: req.params.id },
            UpdateExpression: "SET Title = :t, Description = :d, PropertyType = :ty, Price = :p, PropertyLocation = :l",
            ExpressionAttributeValues: {
                ":t": Title,
                ":d": Description,
                ":ty": PropertyType,
                ":p": Price,
                ":l": PropertyLocation,
            },
            ConditionExpression: "attribute_exists(PropertyID)", // Ensure the property exists
        });

        await docClient.send(params);
        res.status(200).json({ message: "Property updated successfully" });
    } catch (err) {
        res.status(500).json({ error: "Error updating property", details: err.message });
    }
});

// ✅ Delete a property
app.delete("/property/:id", async (req, res) => {
    try {
        const params = new DeleteCommand({
            TableName: TABLE_NAME,
            Key: { PropertyID: req.params.id },
            ConditionExpression: "attribute_exists(PropertyID)", // Prevent deletion of non-existing property
        });

        await docClient.send(params);
        res.status(200).json({ message: "Property deleted successfully" });
    } catch (err) {
        res.status(500).json({ error: "Error deleting property", details: err.message });
    }
});

// ✅ Get all properties (Paginated)
app.get("/properties", async (req, res) => {
    try {
        const params = new ScanCommand({
            TableName: TABLE_NAME,
            Limit: 10, // Adjust pagination as needed
        });

        const data = await docClient.send(params);
        res.status(200).json(data.Items);
    } catch (err) {
        res.status(500).json({ error: "Error fetching properties", details: err.message });
    }
});

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));

module.exports.handler = serverless(app);