# Limits

Outcome: the honest boundary of the
tool, in one place — what Valkey cannot
do, cannot promise, and must not be
trusted with — with each limit either
measured in the lab or labelled as
documented. The criteria keep the two
apart.

## One thread: one slow command blocks everyone

An instance executes commands one at a
time (chapter 2). The lab measured what
that means: a Lua loop running for
2.98 seconds held a concurrent `PING`
for **2.48 seconds**; freed, the same
`PING` took 0.003 seconds (transcript
`valkey-lab/transcripts/t12-transactions-and-blocking.txt`).
The lab's loop was artificial, but its
real-world shapes are not: a `KEYS *`
over a huge keyspace, a `SMEMBERS` or
`HGETALL` over an enormous value, a
long script, a delete of a giant key.
The defences are habits — scan instead
of `KEYS` (the `SCAN` family exists so
reads can be paged), keep values modest,
treat scripts as code that holds the
whole server — because the thread has
no pre-emption to save you. Vertical
scaling and sharding across a cluster
are the structural answers, and both
are outside the single instance this
guide ran.

## The dataset lives in RAM

Memory is the storage. When the dataset
outgrows the machine, the choices are a
bigger machine, a cluster, or a limit —
and the limit's behaviour is worth
seeing once, small. The lab set
`maxmemory 2mb` with the `allkeys-lru`
**eviction policy** and pushed 3,000
keys of about 1,000 bytes each at a
third server instance (transcript
`valkey-lab/transcripts/t14-eviction.txt`):

```
$ DBSIZE after the writes
1256
evicted_keys:1767
used_memory_human:2.00M
maxmemory_human:2.00M
```

The server held its 2 MB line by
throwing away 1,767 keys — writes that
returned `OK` and data that is simply
not there any more. (1,256 kept plus
1,767 evicted is slightly more than
3,000 attempted because eviction works
from samples and timing; the counts in
the transcript are the server's own.)
Eviction is the *right* behaviour for a
cache that must never take the machine
down, and a silent data-loss machine
for anything else — and with no
`maxmemory` set, the other failure
waits instead: the process grows until
the operating system kills it. There is
no setting where Valkey politely spills
the dataset to disk; disk is for
persistence files, not for overflow.

## Persistence is a trade, not a save button

Chapter 11 measured the shapes; the
limit form is: **RDB can lose everything
since the last snapshot** — minutes or
an hour, by your schedule — and **AOF
can lose about a second** with
`appendfsync everysec`, at the cost of
writing every change to disk and
periodically rewriting the journal.
Neither is synchronous with the client's
`OK`: a write can be acknowledged and
still be lost to a machine crash inside
the window. (Process-kill survival was
measured; machine-crash windows are as
the documentation states them and are
listed documented-only.) A system that
cannot lose the write needs its database
of record — chapter 15's table — with
Valkey in front of it, not instead of it.

## Transactions stop at one instance — and below

`MULTI`/`EXEC` groups commands
atomically on one server (chapter 14),
with no rollback. Across a **cluster**,
there are no multi-key transactions at
all unless the keys are arranged to
share a slot (the project's *hash tags*),
because the keys may live on different
servers with no coordinator to make
them agree. Clustering itself was not
run by this lab, so that sentence is
documented-only — but the shape of the
limit follows from what was run: the
atomicity this guide demonstrated is
the single thread's, and a second
server is exactly what a thread is not.

## Smaller print, honestly stated

- **A replica can be behind.** Asynchronous
  replication means reads from a replica
  can be stale, and a primary that dies
  can take its unreplicated writes with
  it. Chapter 12 measured lag 0 on
  loopback with one write; production
  lag is a number you monitor, not a
  constant.
- **No schema, no queries.** There is no
  way to ask for "members whose
  favourite is chess" except fetching
  and filtering yourself. Data you need
  to *query* belongs in a database;
  Valkey answers by key.
- **Security is a deployment property.**
  Valkey has passwords, ACLs, and TLS
  (all documented-only here — the lab's
  copy was even built without TLS). The
  lab's protection was `bind 127.0.0.1`
  and nothing else. An unpassworded
  Valkey reachable from a network should
  be treated as already shared with
  everyone on it.
- **Big keys are a hazard of their own.**
  One key can hold a 512 MB string or a
  list of millions; every operation on
  it still runs on the one thread, and
  deleting it can itself be a slow
  command. Many small keys beat few
  giant ones, almost always.

Check: name the limit in this chapter
that your own most likely Valkey use
would meet first — the thread, the RAM,
the loss window, or the missing schema
— and the chapter that hands you its
mitigation. If you can, you know the
tool's size, which is what makes it
safe to use at full strength.
