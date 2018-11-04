## Comparison HazelCast vs Terracotta Ehcache

- I have decided to use Hazelcast because of the advantages like distributed caching/locking mechanism as well
as the extremely easy configuration while adapting it to your application.

- Ehcache has much more features than Hazelcast, is more mature, and has big support behind it.

- There are several other good cache solutions as well, with all different properties and solutions such as good old 
Memcache, Membase (now CouchBase), Redis, AppFabric, even several NoSQL solutions which provides key value stores with or without 
persistence. They all have different characteristics in the sense they implement CAP theorem, or BASE theorem along with transactions.
You should care more about, which one have the functionality you want in your application, again, you should consider CAP theorem or 
BASE theorem for your application.

- Hazelcast serializes everything whenever there is a node (standard-one), so the data you will save to Hazelcast must implement serialization.
TerraCotta, according to its documentation - is using bytecode insertions to automatically serialize the objects without you having to write 
serialization code yourself. I can't speak to this being more or less efficient than standard or hand-coded serialization though.


## Single object shared across JVM

- https://youtu.be/-j6cNZc5wYM?t=41m11s

- http://www.ehcache.org/documentation/3.3/clustered-cache.html