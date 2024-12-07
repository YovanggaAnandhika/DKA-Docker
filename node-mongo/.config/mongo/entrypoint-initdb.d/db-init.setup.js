
(function(){
  const username = process.env.DKA_DB_MONGO_USERNAME || 'developer';
  const password = process.env.DKA_DB_MONGO_PASSWORD || 'Cyberhack2010';
// Gunakan database "admin"
  const database = db.getSiblingDB("admin");
// Check if user already exists
  const userExists = database.getUser(username);
  if (!userExists) {
    print(`Creating root user '${username}'...`);
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
})();