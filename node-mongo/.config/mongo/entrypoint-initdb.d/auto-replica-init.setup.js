
(function() {
  // Initialize the replica set
  const isInitiate = process.env.DKA_DB_MONGO_CLUSTER_IS_PRIMARY !== undefined
      ? process.env.DKA_DB_MONGO_CLUSTER_IS_PRIMARY === 'true'
      : false;
  if (isInitiate) {
    rs.initiate();
  }
})();