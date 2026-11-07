# Replication

Outcome: a primary and a replica
running side by side on loopback, a
write crossing from one to the other,
and the replica's refusal to take
writes of its own — plus the patience
lesson the sync taught on the way.

## Two servers, one dataset

**Replication** keeps a copy of a
server's dataset on another server.
The copy is a **replica**; the source
is its **primary**. The lab ran the
primary on its usual port 18080 with a
no-persistence config
(`valkey-lab/valkey-repl-primary.conf`)
and the replica on port 19080 — the
lab's assigned port plus 1000, the
standing rule for extra instances —
with one extra line in
`valkey-lab/valkey-replica.conf`:

```
replicaof 127.0.0.1 18080
```

That line is the whole setup. On
startup the replica connects to the
primary, receives a full copy of the
dataset (a **full sync** — the primary
produces a snapshot for it, in this
lab's case sent directly over the
network rather than via a disk file),
and then applies each new write as it
arrives.

## The patience lesson

Replication is not instant, and the
lab's first run proved it by failing:
the script wrote too early, read empty
keys on the replica, and saw
`master_link_status:down`. The primary
deliberately delays a diskless sync by
`repl-diskless-sync-delay`, **5 seconds
by default**, in case more replicas are
about to ask. The corrected run polled
until the link came up — attempt 13 of
a twice-a-second poll, about 6 seconds
(transcript
`valkey-lab/transcripts/t10-replication.txt`):

```
  attempt 13: master_link_status=up
$ On the PRIMARY: SET club:next_meeting "Friday 7pm, hall B"
OK
$ On the REPLICA: GET club:next_meeting
Friday 7pm, hall B
```

The write crossed. The primary's own
`INFO replication` showed
`connected_slaves:1` and the replica
`state=online, offset=132, lag=0` — the
offset counts bytes of the replication
stream, and a lag of 0 means the
replica had applied everything at the
moment of asking. "At the moment of
asking" is doing real work in that
sentence: replication is **asynchronous**,
the primary never waits for the replica
before answering its own client, so
under load — or across a slow network —
a replica can trail behind, and a read
from it can be a read of the recent
past. Loopback and one write is the
kindest possible case, and the guide
says so rather than generalising from it.

## The replica refuses writes

```
$ On the REPLICA: SET club:next_meeting "sneaky change"
READONLY You can't write against a read only replica.
$ On the REPLICA: GET club:next_meeting
Friday 7pm, hall B
```

By default a replica is read-only
(`replica-read-only yes`). That protects
the copy's one job — being a faithful
mirror — and gives you read capacity:
reads can be spread over replicas for
data that tolerates being a moment
stale. The setting can be turned off,
and turning it off creates two writers
whose changes meet nowhere — a state
with no correct outcome, and a strong
candidate for the worst configuration
this guide mentions.

What replication is *not*: it is not
backup (a `FLUSHALL` replicates
faithfully and instantly), and it is
not automatic failover. If the primary
dies, the replica keeps its data and
keeps refusing writes until something
promotes it — `REPLICAOF NO ONE` by
hand, or **Sentinel**, the project's
monitoring-and-promotion system, or a
**cluster**, which also splits the
dataset across servers (**sharding**).
Sentinel and clustering are real,
documented, and entirely unrun by this
lab; `criteria.md` lists them as
documented-only, and the chapters claim
nothing for them beyond this paragraph.

Check: on a replica, `INFO replication`
shows `role:slave` and
`master_link_status:up`; on its primary
the same command shows `role:master`
and a connected slave. If the link says
`down` six seconds after startup,
chapter 17 starts there.
