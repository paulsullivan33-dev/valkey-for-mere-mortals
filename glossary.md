# Glossary

The terms, collected in one place. Each
is defined the way this guide uses it.

**AOF (append-only file)** — The journal
form of persistence: every write command
appended to a log (in modern Valkey, a
directory with a base file, incremental
files, and a manifest), replayed on
restart. Set by `appendonly yes`.

**Atomic** — Done as one indivisible
step. Because commands execute one at a
time, a single command — and an
`EXEC` block — cannot be interleaved
with another client's commands.

**Bind** — The network addresses a
server listens on. The lab's
`bind 127.0.0.1` means this machine
only.

**Cluster** — Several Valkey servers
splitting one dataset between them
(sharding), with their own replication
and failover. Documented-only in this
guide.

**Eviction** — Deleting keys to keep
memory under a `maxmemory` limit, by a
policy such as `allkeys-lru`. Measured
in the lab: 1,767 keys evicted at a
2 MB limit.

**Expiry / TTL** — A countdown attached
to a key, after which the server
deletes it. `TTL` reports seconds left,
-1 for no expiry, -2 for no such key.

**Hash** — A value that is a record of
named fields under one key, updated
field by field with `HSET` and friends.

**Hit / miss** — A key lookup that found
its key, or did not. Their ratio is a
cache's report card, in `INFO stats`.

**Keyspace** — All the keys in a
server's numbered databases, reported
by `INFO keyspace`.

**Last write wins** — The rule that a
later `SET` simply replaces an earlier
value; there is no merge and no old
version kept.

**List** — An ordered value you push
onto and pop off of at either end;
pushed left and popped right, a queue;
popped left, a stack.

**Primary** — The server a replica
copies from. Called the master in some
commands and output.

**RDB** — The snapshot form of
persistence: the whole dataset written
to one file, `dump.rdb`, by `BGSAVE`
or on a `save` schedule.

**Replica** — A server copying a
primary's dataset and applying its
writes; read-only by default. Set up
with `replicaof host port`.

**RESP** — The text protocol clients
and servers speak; why a transcript of
commands reads almost exactly like what
went over the wire.

**Sentinel** — The project's system for
watching primaries and promoting a
replica when one fails. Documented-only
in this guide.

**Set** — An unordered value of unique
members; duplicates are refused.
`SINTER`, `SUNION`, and `SDIFF` combine
sets.

**Sorted set** — A set whose members
carry numeric scores and are kept in
score order; the leaderboard type.
Also called a zset, after its `Z`
commands.

**Stream** — An append-only log value
whose entries the server names with
increasing ids of timestamp and
sequence; read by range or from a
position you left off at.

**String** — The plainest value: bytes,
text, or a number held as text — and,
with `INCR`, the counter type.
