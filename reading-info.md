# Reading INFO

Outcome: the server's self-report —
`INFO` — read section by section
against the lab's real numbers, so
"how much memory, how busy, how healthy"
are questions you answer from output,
not from feel.

## INFO is one command with sections

`valkey-cli -p 18080 info` prints a long
report; `info memory`, `info stats`,
`info persistence`, `info replication`,
and `info keyspace` print one section
each. The lab captured the full report
as `valkey-lab/transcripts/t11-info-full.txt`
and a selected digest as
`t11-info-and-memory.txt`. Everything
below quotes the digest, taken while
the primary held the fixture's 10 keys.

## Memory: the section that sizes the rule

```
$ INFO memory (selected)
used_memory_human:1.58M
used_memory_peak_human:1.60M
maxmemory_human:0B
mem_fragmentation_ratio:5.11
```

`used_memory` is what the dataset and
the server's own structures occupy —
1.58 MB for a nearly empty server, most
of it the server itself. Per key, the
lab's `MEMORY USAGE` answers were
modest: 72 bytes for the four-member
leaderboard, 88 bytes for the
three-field hash. The lesson hides in
the proportion: *keys cost more than
their values*. A million tiny keys are
a memory design, not a rounding error,
and `MEMORY USAGE key` is how you price
one before committing to a million.

`maxmemory_human:0B` means *no limit
set* — the server will grow until the
machine objects, which is chapter 16's
eviction story. The fragmentation
ratio, 5.11, compares the memory the
operating system has given the process
with the memory the server accounts
for; on a nearly empty server the fixed
overheads dominate and the ratio looks
dramatic. It is a number to watch on a
loaded server, not to panic over on an
empty one — stated as general practice,
since the lab's server was never loaded.

## Stats: hits, misses, and a workload's shape

```
$ INFO stats (selected)
total_commands_processed:69
instantaneous_ops_per_sec:8
keyspace_hits:33
keyspace_misses:3
evicted_keys:0
```

A **hit** is a key lookup that found
its key; a **miss** is one that found
nothing. The lab's 33 hits against 3
misses is a scripted fiction's ratio,
but the reading habit is real: for a
cache, hits divided by hits-plus-misses
is the number that says whether the
cache is earning its memory, and a
falling ratio is a question about your
keys, not about the server.
`total_commands_processed` counts every
command since startup — the lab's
careful sequence cost only 69 — and
`evicted_keys:0` belongs to chapter 16:
the moment that counter moves, data is
being thrown away to fit a limit.

## Keyspace and persistence, at a glance

```
$ INFO keyspace
db0:keys=10,expires=0,avg_ttl=0
$ DBSIZE
10
```

One line per non-empty database: how
many keys, how many carry an expiry.
Chapter 11's chapter-and-verse lives in
`INFO persistence`: `aof_enabled`,
`aof_current_size`, the last snapshot's
status and time. The operating habit
this chapter is really teaching is
small: **before you trust a server,
make it describe itself** — its version,
its port, its persistence, its memory,
its role. Every one of those is one
`INFO` section away, and every
troubleshooting story in chapter 17
starts with somebody skipping this one.

Check: run `INFO keyspace` and
`DBSIZE` on your server and make the
two agree; then read
`keyspace_hits` and `keyspace_misses`
and say your hit ratio as a percentage.
If you cannot, the server is a black
box you happen to own — open it here.
