# The moving parts

Outcome: a map of the parts inside every
Valkey server — the keyspace, the command
thread, expiry, the persistence machinery,
and replication — so a later chapter's
behaviour has a part to belong to.

## The keyspace

All your data lives in numbered
**databases** inside one server. The
default is database 0, and most users
never leave it; `SELECT 1` switches to
another, empty one. Each database is a
flat map from keys (strings) to values,
and every key has exactly one **type**:
string, hash, list, set, sorted set, or
stream. The `TYPE` command reports it,
and commands refuse to cross types — a
list command aimed at a string key gets
an error naming the wrong type. The lab
kept its whole noticeboard and club in
database 0: `INFO keyspace` reported
`db0:keys=10` at the persistence test
(transcript
`valkey-lab/transcripts/t11-info-and-memory.txt`).
Keys are often named with colons —
`member:ada`, `notice:views` — but the
colon is only a human convention; the
server sees one flat string.

## The command thread

Commands arrive over connections, and
one instance executes them **one at a
time, in order**, on a single main
thread. That sounds like a limitation
and is also a gift: because no two
commands ever run at once, an `INCR` is
**atomic** — it cannot be interrupted
halfway by another client's `INCR` —
and chapters never need locks. The cost
is real and measured: while one long
command runs, *everyone* waits. In the
lab, a Lua loop that took 2.98 seconds
held a concurrent `PING` for
**2.48 seconds**; the same `PING` took
0.003 seconds afterwards (transcript
`valkey-lab/transcripts/t12-transactions-and-blocking.txt`).
Chapter 16 returns to this. (Modern
Valkey can offload network I/O to other
threads; command *execution* stays
single-file. That distinction is from
the project's documentation and is
labelled documented-only in
`criteria.md`.)

## Expiry

Any key can carry a **time to live**
(TTL): a countdown after which the
server deletes the key on its own.
Expiry is checked both actively — the
server samples keys and removes dead
ones — and lazily, when a read finds a
corpse and reports it missing. Chapter
10 measured a 3-second TTL against a
clock. Keys without a TTL live until
deleted, evicted, or lost with the
server — chapter 1's rule again.

## Persistence

Two machines sit beside the keyspace,
both optional, both off or minimal in
different default builds, which is why
chapter 11 exists:

- **RDB**: a snapshot. On request
  (`BGSAVE`) or on a schedule (`save`
  lines in the config), the server forks
  a child that writes the whole dataset
  to one file, `dump.rdb`.
- **AOF**: a journal. With `appendonly
  yes`, every write command is also
  appended to a log file, and a restart
  replays the log. Modern Valkey writes
  it as a small directory: a base file
  plus incremental files, tracked by a
  manifest — the lab's `find` output
  shows all three (transcript
  `valkey-lab/transcripts/t09-persistence-aof.txt`).

Either, both, or neither can be on.
Neither is a legitimate choice for a
cache. It is a poor choice for the only
copy of anything.

## Replication

A server can be told `replicaof` a
**primary**. It then copies the
primary's dataset and applies every
later write, in order, as they arrive.
Replicas are read-only by default —
the lab's attempt to write to one was
refused with a `READONLY` error — and
replication is **asynchronous**: the
primary answers its client without
waiting for the replica to catch up,
so a replica can lag, and can be behind
at the moment the primary dies. Chapter
12 ran the pair and watched the link
come up. Automatic failover — promoting
a replica when the primary vanishes —
is Sentinel's or a cluster's job, not
plain replication's, and is
documented-only in this guide.

## The observer: INFO

Last, the part you will use daily: the
`INFO` command, a long self-report in
sections — server, clients, memory,
persistence, stats, replication,
keyspace. Chapter 13 reads the lab's
real output. Everything this guide
claims about a running server can be
checked against its own `INFO`.

Check: name the five parts — keyspace,
command thread, expiry, persistence,
replication — and say which one makes
`INCR` safe without locks. If you can,
the map is yours.
