const username = process.env.DKA_MONGO_USERNAME || "root";
const password = process.env.DKA_MONGO_PASSWORD;
const adminDb = db.getSiblingDB("admin");

print("[User] 🔎 Checking cluster write availability...");

let checkCount = 0;
const maxChecks = 100;

while (!db.isMaster().ismaster && checkCount < maxChecks) {
    print(`[User] ⏳ Status: SECONDARY/STARTUP. Waiting for election (${checkCount + 1}/${maxChecks})...`);
    sleep(1000);
    checkCount++;
}

if (!db.isMaster().ismaster) {
    print("[User] ❌ ERROR: Node failed to become PRIMARY. User operations restricted.");
} else {
    print("[User] 👑 Node is PRIMARY. Managing users...");

    // Pastikan username valid sebelum memanggil getUser
    const existingUser = adminDb.getUser(username);

    if (!existingUser) {
        print(`[User] 👤 Creating root user: ${username}...`);
        adminDb.createUser({
            user: username,
            pwd: password,
            roles: [{ role: "root", db: "admin" }]
        });
        print(`[User] ✅ User '${username}' created successfully.`);
    } else {
        print(`[User] 🆗 User '${username}' already exists. Skipping.`);
    }
}