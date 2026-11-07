# Troubleshooting

Outcome: the failures this lab actually
met, plus the standard ones the
chapters equip you to diagnose — each
with the check that separates "server
problem" from "I am talking to the
wrong thing".

## Connection refused

```
Could not connect to Valkey at 127.0.0.1:6379: Connection refused
```

The lab produced exactly this line —
repeatedly, in an early eviction run —
and the cause is the usual one: the
client was aimed at a port where no
server was listening. In the lab's case
a script variable had been overwritten,
so the client asked the default port
6379 while the server waited on 19081.
The diagnosis order never changes:

1. Is a server running? Look for the
   process and its startup log — the
   line `Ready to accept connections
   tcp` is the server saying so itself.
2. On which port? `INFO server`'s
   `tcp_port` from a working client, or
   the `port` line of the config the
   server was actually started with.
3. Are the client's `-p` and the
   server's port the same number? Most
   connection-refused stories end here.

A *timeout* rather than a refusal
points elsewhere — a firewall or a
wrong address — and belongs to the
network layer this guide's loopback lab
never met; it is named, not diagnosed.

## The key that is not there

`GET` prints nothing and you are sure
you set it. Eliminate in this order:
**wrong database** (`SELECT` state
differs between clients; `DBSIZE` and
`INFO keyspace` tell you where the keys
actually are), **wrong server** (the
port check above), **expiry** (`TTL`
answers -2 for a dead key, and chapter
10's keys die on purpose), **eviction**
(`INFO stats`: if `evicted_keys` is
moving, chapter 16 happened), and
**last write wins** (another client
`SET` or `DEL`eted it; the server did
exactly what it was told). In a guide
whose rule is chapter 1's, "the key
vanished" is never a mystery category —
it is one of those five, and four of
them leave evidence in `INFO`.

## The replica that will not link

Chapter 12's first run is the worked
example: `master_link_status:down` at
one second after startup was not a
failure at all — the primary delays a
diskless sync by 5 seconds by default,
and the link was `up` by about six.
Patience first, then: the replica's own
log names its state line by line
(`Connecting to PRIMARY`, `sync
started`); the primary's `INFO
replication` shows whether it sees the
replica and in what state; and a link
still down after a minute on loopback
is almost always a wrong port in
`replicaof` or a primary that is not
the server you think it is. A link that
flaps up and down under load is a
capacity story, beyond this lab.

## The snapshot that never happens

`INFO persistence` reports the last
snapshot's status and time. If `BGSAVE`
answers with an error, read it fully —
the common causes are a `dir` the
server cannot write and a disk with no
room, both visible the moment you look
(the lab's `dump.rdb` was 631 bytes; a
real one is the size of your dataset,
compressed). If snapshots silently
never occur on schedule, read the
`save` lines actually in effect with
`CONFIG GET save` — a config that says
`save ""` is a server told *never* to
snapshot, which is chapter 11's third
server wearing a disguise.

## The server that got slow

Other clients' `PING` times are the
canary: the lab's blocked `PING` took
2.48 seconds during a 2.98-second
command. `INFO stats` gives
`instantaneous_ops_per_sec`;
`SLOWLOG GET` lists the commands the
server itself judged slow, with their
durations — start there, not with
guesses. The usual suspects are chapter
16's: a `KEYS *`, a giant value being
read whole, an unindexed-everything
script. One more suspect lives outside
the server: expiry and eviction churn
on a memory-tight instance shows up as
CPU spent housekeeping, visible in
`INFO cpu` and the memory section's
fragmentation — chapter 13's habit of
making the server describe itself is
the whole method.

Check: pick the failure above that you
have actually met (in this lab or
elsewhere) and say which check settled
it. The list is short on purpose: most
Valkey trouble is a wrong port, a wrong
database, or a true sentence from
chapter 1 arriving as a surprise.
