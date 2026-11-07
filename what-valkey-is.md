# What Valkey is

By the end of this chapter you can say,
in one sentence, what Valkey holds and
how it holds it — and state the one rule
that decides what it is safe to trust
it with.

## A server whose whole job is remembering, fast

**Valkey** is a program that runs as a
**server** — a process that waits for
requests — and stores data as **keys**
mapped to **values**. A key is a name,
a string like `notice:current` or
`leaderboard`. A value is more than a
string: it can be a string, a small
record of fields (a **hash**), an
ordered **list**, an unordered **set**,
a **sorted set** scored like a
leaderboard, or a **stream**, an
append-only log. Chapters 5 to 9 take
one type at a time.

You talk to it with **commands**, short
text instructions sent over a network
connection, usually by its own command
line client:

```
SET notice:current "Board games night is on Friday, hall B"
GET notice:current
INCR notice:views
```

The dataset lives in the server's
**memory** (RAM), not on disk. That is
the whole reason it is fast: no disk
reads stand between a question and its
answer. It is also the whole reason for
this guide's rule, below. Valkey began
in 2024 as a fork — a copy that went
its own way — of Redis 7.2, the last
version of that project under its old
open-source licence, and it is now a
Linux Foundation project under the BSD
licence. Its own `INFO` output still
carries a `redis_version:7.2.4` field
for compatibility, next to the honest
one, `valkey_version:9.1.3` — the lab
saw both (transcript
`valkey-lab/transcripts/t01-start-and-config.txt`).

Why run a separate server instead of a
variable in your own program? Because a
server is **shared**: ten programs, in
three languages, on two machines, can
all read and write the same keys. And
because it **outlives** any one client:
your script can exit, and the counter
it incremented is still there for the
next script. How long "still there"
lasts is a configured choice, not a
promise — chapter 11.

## The rule: a shared, mutable present

Everything in this guide follows from
one sentence:

> **Valkey is a shared, mutable present:
> every client sees the latest write,
> the last write wins, and data survives
> a restart only if you configured
> persistence — what is only in memory
> is only in memory.**

Each clause was measured in the lab:

- **Shared and mutable.** Two clients
  connected to the same server see the
  same keys. The lab wrote
  `club:next_meeting` on a primary and
  read it back on a *different server*,
  its replica (chapter 12).
- **Last write wins.** The lab set
  `notice:current` twice; the second
  `GET` returned only the second text.
  There is no merge and no history for
  ordinary keys: a `SET` replaces, it
  does not negotiate (chapter 5).
- **Survival is configured, not
  default-magic.** With an RDB snapshot
  taken, data survived a stop and
  restart. With the AOF (append-only
  file) on, data survived even a
  `kill -9`. With neither on, the same
  `kill -9` and restart returned an
  empty server — **database size 0**
  (transcripts
  `valkey-lab/transcripts/t08-persistence-rdb.txt`,
  `t09-persistence-aof.txt`, and
  `t13-no-persistence.txt`).

The rule is not a warning against
Valkey; it is what Valkey *is for*. A
shared present is exactly what a
counter, a leaderboard, a session store,
or a queue wants — provided you choose,
deliberately, which of those also need
to survive a restart, and pay for the
persistence mode that gives it to them.

Check: say the rule out loud once,
including the last clause. If you can
also name one kind of data you would
*not* keep only in memory, you have
this chapter.
