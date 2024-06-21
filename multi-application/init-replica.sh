#!/bin/bash
mongosh <<EOF
var config = {
    "_id": "dkaReplicaSet",
    "members": [
        { "_id": 0, "host": "dka-mongo1:27017" },
        { "_id": 1, "host": "dka-mongo2:27017" },
        { "_id": 2, "host": "dka-mongo3:27017" }
    ]
};
rs.initiate(config);
EOF