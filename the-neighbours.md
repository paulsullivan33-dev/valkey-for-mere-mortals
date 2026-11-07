# The neighbours

Outcome: Valkey placed among the tools
it is compared with — characterised by
job and by shape, not benchmarked, since
this lab ran none of them head to head.

## Redis

Valkey *is* Redis's closest neighbour:
it forked from Redis 7.2.4, the last
BSD-licensed release, when that project
changed its licence in 2024, and it
keeps the same wire protocol, command
names, and file formats — the lab's
server still reports `redis_version:
7.2.4` to clients that ask. Clients and
tools written for Redis generally work
against Valkey unchanged. The honest
differences are governance and licence
(Valkey is a Linux Foundation project
under the 3-clause BSD licence, guided
by maintainers from several companies)
and the years of separate development
since — Valkey 9.x has its own features
and performance work, and Redis has
gone its own way under its own terms.
Choosing between them is mostly a
licence, support, and ecosystem
decision, not a command-set decision.
This guide teaches Valkey and claims
nothing measured about Redis, which the
lab never ran.

## Memcached

The other famous in-memory store, and
the simpler one: keys to string values,
very fast, multi-threaded — and no
hashes, lists, sets, sorted sets, or
streams, no persistence, no replication
in the core design. If the whole job is
"cache these blobs by name", Memcached's
simplicity is a genuine virtue and
Valkey is more than you need. The moment
the job grows a leaderboard, a counter
that must be atomic across clients, or
data that should survive a restart, the
comparison ends — those are data-type
and persistence questions, and only one
of the two tools answers them.

## A table in the database you already have

The neighbour nobody benchmarks: for a
great many small jobs — settings, a
slow-changing leaderboard, a few
counters — a table in your existing
relational database is correct, durable,
backed up, and already understood by
your team. Choose Valkey when the
access pattern actually needs it:
very frequent small reads and writes,
atomic increments from many clients,
expiry as a first-class behaviour, or
pub/sub-shaped sharing between
processes. Choose the table when the
data is part of your record — the thing
you would restore from backup first.
Chapter 1's rule is the test: data that
must survive is only as safe as the
persistence you configured, and your
database's answer to that question is
usually stronger and already paid for.

## A variable in your own program

The zero-dependency neighbour. A counter
in your process is faster than any
network server and simpler than
anything in this guide — until a second
process needs the same counter, or the
first process restarts and the count
matters. That sentence is the entire
decision boundary: **one process, one
lifetime — a variable; many clients or
a lifetime longer than any client — a
server.** Valkey's existence, its
replication, and its persistence are
all answers to the second half of that
boundary.

## Message brokers, briefly

For the job-queue job, the neighbours
are brokers such as RabbitMQ or Kafka:
delivery guarantees, routing,
acknowledgements, and retention as
their core purpose, with matching
operational weight. A list (chapter 7)
is a queue for a cooperative afternoon;
a stream with consumer groups (chapter
9) is the middle ground inside Valkey;
a broker is where queues go when the
messages are the business. This guide
ran the first, described the second,
and merely names the third.

Check: for one piece of shared state
you know, name which neighbour *should*
hold it and why — in terms of lifetime,
writers, and survival, not speed. Speed
is the last question, and these tools
are all fast enough that it rarely
decides.
