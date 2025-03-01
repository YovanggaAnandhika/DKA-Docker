const username = process.env.DKA_MONGO_USERNAME;
const password = process.env.DKA_MONGO_PASSWORD;
// Gunakan database "admin"
const database = db.getSiblingDB("admin");
// Check if user already exists
const userExists = database.getUser(username);
if (!userExists) {
    // Create the root user
    database.createUser({
        user: username,
        pwd: password,
        roles: [{ role: "root", db: "admin" }]
    });
    print(`Root user '${username}' created successfully.`);
} else {
    print(`User '${username}' already exists. Skipping creation.`);
}