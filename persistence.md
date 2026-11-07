# Persistence

Outcome: the difference between the two
persistence modes and no persistence —
not described, but *demonstrated*:
three servers, three restarts, one
crash, and a key count after each.

## Why this chapter is the important one

Chapter 1's rule ends with "what is
only in memory is only in memory". This
chapter is where that stops being a
slogan. A Valkey server's dataset lives
in RAM. Persistence is the machinery
that copies it to disk, in one of two
shapes, both set in the config file
(chapter 4), both off-or-scheduled
depending on the file you started from.
*Never assume it is on. Read the
config.* The lab ran all three settings.

## RDB: the snapshot

**RDB** writes the whole dataset to one
file, `dump.rdb`, in the server's `dir`.
It happens when a `save` schedule line
fires (the lab's primary used `save
3600 1`: snapshot when at least 1 key
changed in an hour) or when you ask:
`SAVE` blocks the server while writing;
`BGSAVE` forks a child to write while
the server keeps answering. The lab
asked (transcript
`valkey-lab/transcripts/t08-persistence-rdb.txt`):

```
Keys before: 10
$ BGSAVE
Background saving started
$ ls -lh data-rdb/
-rw-rw---- 1 root root 631 ... dump.rdb
```

Ten small keys snapshot to 631 bytes.
Then the test that makes it a test: the
server was stopped with `SHUTDOWN
NOSAVE` — explicitly forbidden from
writing a fresh snapshot on the way
out — restarted from the same config,
and read back:

```
$ DBSIZE after restart
10
$ GET notice:current
Board games night is on Friday, hall B
$ GET notice:views
14
```

Everything present, including the hash
and the leaderboard. The cost side is
just as real: a snapshot is a point in
time. Writes after it are not in it.
A server that snapshots hourly and
crashes loses up to an hour of writes;
the snapshot *schedule is your data-loss
window*, stated in minutes and chosen
by you. RDB's virtues are the other
side of the same fact: one compact
file, trivially copied for backup,
fast to load, and no cost at all
between snapshots.

## AOF: the journal

**AOF** — append-only file — journals
every write command as it happens. The
lab's second server ran with
`valkey-lab/valkey-aof.conf`
(`appendonly yes`, `save ""`, and
`appendfsync everysec`, the setting
that asks the operating system to flush
the journal to disk about once a
second). After five writes, the
working folder held (transcript
`valkey-lab/transcripts/t09-persistence-aof.txt`):

```
appendonlydir/appendonly.aof.1.base.rdb      89 bytes
appendonlydir/appendonly.aof.1.incr.aof     221 bytes
appendonlydir/appendonly.aof.manifest        88 bytes
```

Modern Valkey's AOF is a small
directory: a base snapshot, one or more
incremental journal files, and a
manifest tying them together; the
server periodically rewrites (compacts)
the journal into a fresh base so it
does not grow forever. Then the crash
test — not a shutdown, a kill:

```
Stopping the server the hard way: kill -9
(a crash, not a shutdown — nothing gets
 a chance to save on exit)
Restarted after the kill.
$ GET aof:notice
AOF wrote this
$ GET aof:counter
3
```

All five writes survived a `kill -9`,
because with `appendfsync everysec`
they were on disk within about a
second of being made. The trade is
written in the file sizes and the
setting's name: AOF costs disk writes
on every change, its files are bigger
than one snapshot, and its worst case
is in its fsync policy — `everysec`
can lose about a second of writes in a
true machine crash; `always` loses
almost none and pays for it in speed;
`no` leaves flushing to the operating
system and can lose far more. The lab
measured survival across a *process*
kill, where even an unflushed-to-disk
journal survives in the operating
system's hands; that distinction —
process death versus machine death — is
exactly the gap between what this lab
could prove and what `criteria.md`
labels documented-only for the fsync
worst cases.

## Neither: the server that came back empty

The third run is the control experiment
(transcript
`valkey-lab/transcripts/t13-no-persistence.txt`).
A server with `save ""` and `appendonly
no` accepted a key, was killed with
`kill -9`, and restarted:

```
before kill: only in memory
after restart: GET volatile:key -> (empty)
$ DBSIZE
0
```

Not an error, not corruption: the
configured, correct behaviour. This is
the right setting for a pure cache,
whose whole value is speed and whose
contents can always be recomputed. It
is a disaster as the only copy of
anything — and it is the state a server
is in whenever somebody starts one
bare, with no config file, on a
schedule-less build. Both modes can
also be combined (RDB for fast restarts
and backups, AOF for the tighter loss
window), which is the common production
choice and is stated here, not run: the
lab ran the modes one at a time so each
result had one explanation.

Check: on your own server, run `INFO
persistence` and read `aof_enabled` and
the `rdb_last_bgsave_status` with your
own eyes, then say — out loud — what
your server would lose if it died this
second. If the honest answer surprises
you, this chapter just paid for the
whole guide.
