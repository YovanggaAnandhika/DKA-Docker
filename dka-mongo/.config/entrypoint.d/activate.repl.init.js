const replSetEnabled = process.env.DKA_REPL_ENABLED;
const replSetName = process.env.DKA_REPL_NAME;

if (replSetEnabled === "true"){
    print('replication is enabled. activating ...')
    try {
        // Cek apakah replikasi sudah diinisialisasi
        const status = rs.status();
        if (status.ok) {
            print(`Replica set "${replSetName}" is already initialized.`);
        } else {
            throw new Error("Replica set not properly initialized.");
        }
    } catch (e) {
        print(`Initializing replica set "${replSetName}"...`);
        rs.initiate();

        print(`Replica set "${replSetName}" initialized successfully.`);
    }
}else{
    print('replication is not enabled')
}