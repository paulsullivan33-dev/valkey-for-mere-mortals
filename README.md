# Valkey for Mere Mortals

Every program eventually needs a small
piece of shared memory. A counter that
several workers must all increment. A
leaderboard that must always show the
latest score. A notice that should
delete itself at midnight. Keeping that
state inside one process means only that
process can see it; keeping it in a
full database can mean a schema, a
migration, and a query for what is
really just "remember this number".
**Valkey** takes that job over: it is a
server that holds **keys** and
**values** in memory, answers commands
over the network in well under a
millisecond on a local machine, and
lets every client share the same,
always-current picture.

One rule governs everything it does,
and this guide states it in chapter 1
and keeps pointing back to it:
**Valkey is a shared, mutable present —
every client sees the latest write, the
last write wins, and data survives a
restart only if you configured
persistence; what is only in memory is
only in memory.** The lab proved the
hard half of that sentence by pulling
the plug: a server with no persistence
configured came back from a `kill -9`
with zero keys, while its RDB and AOF
neighbours came back with everything.

The lab behind this guide ran the real
thing: **Valkey 9.1.3**, built from the
project's official source release,
against a small fictional project — a
community noticeboard with view
counters and a board-game club with a
leaderboard. Against that project the
lab started the server from a config
file on loopback port 18080; exercised
strings, hashes, lists, sets, sorted
sets, and streams with the real command
line client; set a key to live for
three seconds and watched a clock while
it died; snapshotted to an RDB file,
stopped the server *without* saving,
restarted, and read the data back; ran
an AOF server, killed it with `kill -9`
mid-flight, restarted, and read the
data back again; paired a replica on
port 19080 and watched a write on the
primary appear on the replica; timed a
`PING` at 2.48 seconds while one long
command held the server, and at
0.003 seconds once it finished; and set
a 2 MB memory limit and counted
1,767 keys evicted to keep it.

What the lab could not do, it did not
fake. Clustering, Sentinel failover,
TLS, and access-control lists are
described from the project's own
documentation and labelled
documented-only. `criteria.md` keeps
the full ledger of what was run and
what was only read.

## What this guide covers

- [**What Valkey is**](what-valkey-is.md) —
  shared memory as a server, and the one rule
- [**The moving parts**](the-moving-parts.md) —
  keys, commands, the single thread, expiry,
  persistence, and replication
- [**Installing Valkey**](installing-valkey.md) —
  the source build the lab used, the other
  routes, and the version check
- [**Your first keys**](your-first-keys.md) —
  a lab config file, the first `PING`, and
  reading the server's own report of itself
- [**Strings and counters**](strings-and-counters.md) —
  `SET`, `GET`, atomic increments, and
  last-write-wins
- [**Hashes**](hashes.md) — one key, many
  fields: records without a schema
- [**Lists**](lists.md) — push and pop: queues
  and recent-item lists
- [**Sets and sorted sets**](sets-and-sorted-sets.md) —
  who is coming, and who is winning
- [**Streams**](streams.md) — an append-only
  log with ids the server hands out
- [**Expiry**](expiry.md) — keys that delete
  themselves, measured with a clock
- [**Persistence**](persistence.md) — RDB
  snapshots, the AOF log, and the server
  that came back empty
- [**Replication**](replication.md) — a primary,
  a replica, and a write that crossed over
- [**Reading INFO**](reading-info.md) — memory,
  hits and misses, and what the server
  counts about itself
- [**Real jobs**](real-jobs.md) — counters, a
  leaderboard, a job queue, and a self-deleting
  notice, assembled
- [**The neighbours**](the-neighbours.md) —
  Redis, Memcached, a table in your database,
  and a variable in your program
- [**Limits**](limits.md) — one thread, RAM-sized
  data, persistence trade-offs, and eviction
- [**Troubleshooting**](troubleshooting.md) —
  connection refused, the key that is not
  there, the replica that will not link
- [**Glossary**](glossary.md) — the terms,
  collected in one place

## What it doesn't cover

Building a Valkey cluster, running
Sentinel for automatic failover, or
tuning for very large datasets — those
are production topics the lab did not
run, and the chapters name them as
documented-only where they belong.
Client libraries for particular
programming languages are named once
and left to their own documentation;
this guide talks to the server with its
own command line client, which every
language's library mirrors closely.
Nothing here runs a server for anyone
else: every example binds to loopback,
on the reader's own machine.

## How to use this guide

Read chapter 1 for the rule and chapter
2 for the map of parts; chapter 4 gets a
real server running, and chapters 5 to
9 teach one data type each. Chapter 11
is the one to read before you store
anything you would miss: persistence is
off more often than people think, and
the difference between the modes is
measured there, not asserted. The lab
lives in `valkey-lab/`: its config files
beside `run-lab.sh`, the driver that ran
every test, and every claim's evidence
in `valkey-lab/transcripts/`; its
distilled commands are
`examples/commands.txt` and its notes
`examples/lab-notes.txt`.

---

## Part of the series

This guide is one of the [For Mere Mortals](https://paulsullivan33-dev.github.io/mere-mortals/) guides: plain-language guides to the tools programmers and makers use.

Related guides:

- [Text Processing for Mere Mortals](https://paulsullivan33-dev.github.io/text-processing-for-mere-mortals/)
- [Vim for Mere Mortals](https://paulsullivan33-dev.github.io/vim-for-mere-mortals/)
- [Markdown for Mere Mortals](https://paulsullivan33-dev.github.io/markdown-for-mere-mortals/)

## License

The writing in this guide is licensed under [CC BY 4.0](https://github.com/paulsullivan33-dev/valkey-for-mere-mortals/blob/main/LICENSE). Code examples and lab scripts are licensed under the [MIT License](https://github.com/paulsullivan33-dev/valkey-for-mere-mortals/blob/main/LICENSE-CODE).
