const hostname = process.env.DKA_HOSTNAME || "127.0.0.1";
const replSetName = process.env.DKA_REPL_NAME || "rs0";

if (process.env.DKA_REPL_ENABLED === "true") {
    let isInitialized = false;
    try {
        // rs.conf() akan error jika belum di-init
        if (rs.conf()) { isInitialized = true; }
    } catch (e) {
        isInitialized = false;
    }

    if (!isInitialized) {
        print(`[Init] 🚀 Initializing replica set "${replSetName}" at ${hostname}:27017...`);
        const res = rs.initiate({
            _id: replSetName,
            members: [
                { _id: 0, host: `${hostname}:27017` }
            ]
        });
        print(`[Init] Result: ${JSON.stringify(res)}`);
    } else {
        print(`[Init] ✅ Replica set already configured. Skipping initiation.`);
    }
} else {
    print(`[Init] ℹ️ Replication not enabled (DKA_REPL_ENABLED=false).`);
}