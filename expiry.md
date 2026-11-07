# Expiry

Outcome: keys that delete themselves —
set with a measured lifetime, watched
against a clock as they die, and read
correctly afterwards, including the two
different "no TTL" answers.

## Set a lifetime in the same command

The noticeboard's flash notice should
exist for one evening only. The lab
gave it three seconds, so the death
could be watched (transcript
`valkey-lab/transcripts/t07-expiry.txt`):

```
start: 21:57:32.181
$ SET notice:flash "Doors open 6.30pm tonight only" EX 3
OK
$ TTL notice:flash
3
$ GET notice:flash
Doors open 6.30pm tonight only
sleeping 4 seconds...
after: 21:57:36.193
$ GET notice:flash
(empty)
$ EXISTS notice:flash
0
```

`SET ... EX 3` attaches a 3-second
**time to live** at creation. `TTL`
counts the remaining seconds down.
After the sleep, the key is simply
gone — the same empty reply as a key
that never existed, and `EXISTS` agrees
with 0. Nothing sends a notification
and nothing leaves a tombstone; expiry
is deletion, scheduled. The variants:
`PX` for milliseconds, `EXAT` and
`PXAT` for an absolute moment, and
`KEEPTTL` when a `SET` should replace a
value but keep an existing countdown.

## Reading TTL's three answers

`TTL` has exactly three kinds of reply,
and confusing them is the common
beginner error:

- A positive number: seconds remaining,
  counting down.
- `-1`: the key exists and has **no**
  expiry. The lab's `notice:current`
  answered exactly this.
- `-2`: the key does not exist at all.

The lab also walked the full lifecycle
on one key: `EXPIRE notice:temp 100`
attached a countdown to an existing key
(answer 1, it was applied), `TTL`
showed 100, `PERSIST` removed the
countdown (answer 1 again), and `TTL`
then showed -1 — expiry removed, key
kept. `EXPIRE` on a missing key
answers 0 and does nothing, which is
the safe way to learn you mistyped the
name.

## Where expiry does the work

- **Caches.** Cache a computed page or
  a database row with a five-minute
  TTL; staleness is bounded by the
  number you chose, and memory frees
  itself.
- **Sessions and codes.** Login
  sessions, one-time codes, and rate-
  limit windows ("this key counts
  attempts and dies in a minute") are
  expiry-shaped by nature.
- **Locks and leases.** A lock key with
  a TTL cannot be held forever by a
  client that crashed — though a safe
  lock needs more than a TTL alone
  (checking the lock is yours before
  releasing it), and this guide names
  that caution without building a lock
  manager.

Two honest costs. First, an expiring
key that nobody reads still gets
removed by the server's active expiry
sampling, but *when* is approximate:
the contract is "gone by the read after
its deadline", not a precision timer
for your program to synchronise on.
Second, expiry interacts with
persistence in one way worth knowing:
a key that dies is deleted from memory
and the deletion is what gets journaled
— a restart does not resurrect it. The
lab's persistence run proved the point
by accident and kept it: after the RDB
restart, the long-dead `notice:flash`
was still gone (transcript
`valkey-lab/transcripts/t08-persistence-rdb.txt`).

Check: set a key with `EX 5`, read its
`TTL` twice a second apart, and watch
the number fall; then read it after the
deadline and get the empty reply. If
the number did not fall, you are reading
a different key — or a different server.
