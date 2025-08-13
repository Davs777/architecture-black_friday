#!/bin/bash

###
# Initialize the database through mongos router
###

# Wait for mongos router to be ready
echo "Waiting for mongos to be ready..."
until docker compose exec -T mongos_router mongo --port 27020 --eval 'print("Connected")' >/dev/null 2>&1
do
  sleep 5
done

# Enable sharding and insert test data
docker compose exec -T mongos_router mongo --port 27020 <<EOF
// Create database if not exists
use somedb

// Enable sharding for the database
sh.enableSharding("somedb")

// Create collection and shard it (if not exists)
if (db.getCollectionNames().indexOf("helloDoc") == -1) {
  db.createCollection("helloDoc")
  sh.shardCollection("somedb.helloDoc", { "age": 1 })
}

// Check if collection is empty (using count() instead of countDocuments() for MongoDB 4.4)
if (db.helloDoc.count() === 0) {
  print("Inserting test data...")
  for(var i = 0; i < 1000; i++) {
    db.helloDoc.insert({age: i, name: "ly" + i})
  }
  print("Inserted 1000 test documents")
} else {
  print("Collection already contains data, skipping insertion")
}

// Verify data distribution
printjson(db.helloDoc.getShardDistribution())
EOF

echo "Data initialization complete"