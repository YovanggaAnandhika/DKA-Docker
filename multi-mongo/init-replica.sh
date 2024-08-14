#!/bin/bash
mongosh <<EOF
var config = {
    "_id": "dkaReplicaSet",
    "members": [
        { "_id": 0, "host": "172.28.0.2:27017" },
        { "_id": 1, "host": "172.28.0.3:27018" },
        { "_id": 2, "host": "172.28.0.4:27019" }
    ]
};
rs.reinitiate(config)
EOF