# Streams

Outcome: the stream type — an
append-only log where the server hands
out ordered ids — read back three
different ways, and an honest line
between the log the lab ran and the
consumer machinery it did not.

## A log that names its own entries

A **stream** is a list of entries, each
a small set of field-value pairs, each
given an **id** by the server when it
is appended: a timestamp in
milliseconds, a dash, and a sequence
number for entries within the same
millisecond. The lab logged two posts
to the noticeboard (transcript
`valkey-lab/transcripts/t06-streams.txt`):

```
$ XADD board:log * action post author Ada text "friday moved"
1794088652171-0
$ XADD board:log * action post author Ben text "hall B confirmed"
1794088652173-0
$ XLEN board:log
2
```

The `*` means "the server picks the
id", which you should almost always
let it do: ids then increase with time
and never collide. (The numbers look
unfamiliar because they are
millisecond timestamps from this
machine's clock; the *shape* — time,
dash, sequence — is the part to learn.)

Reading back offers three lenses:

```
$ XRANGE board:log - +
1794088652171-0
action
post
author
Ada
text
friday moved
...
$ XREAD COUNT 1 STREAMS board:log 0
```

`XRANGE` takes a window by id — `-` and
`+` are the whole stream; real id bounds
give you a slice of history.
`XREAD` takes a *starting position* and
returns what came after it: reading
from `0` means from the beginning, and
reading from the last id you processed
is how a consumer resumes exactly where
it stopped, which no list in chapter 7
can offer a worker that crashed
mid-queue. `XREVRANGE` reads newest
first. Entries are never edited; a
stream is corrected by appending a
newer entry, and trimmed by id or by
length (`XTRIM`, or `MAXLEN` on
`XADD`) when history stops being worth
its memory.

## What the lab did not run

Streams go further: **consumer
groups**, where several workers share
one stream, each message is delivered
to one worker, acknowledged with
`XACK`, and left pending — visible and
reclaimable — if the worker dies. That
machinery is the serious answer to
chapter 7's lost-job problem, and it is
genuinely more machinery: groups,
pending lists, and claim timeouts all
need a chapter of their own in a guide
that runs them. This guide did not run
them, says so here and in
`criteria.md`, and teaches the plain
log, which is real and was measured.
If your job queue needs delivery
guarantees, a stream with groups is the
in-Valkey answer, and a message broker
is the neighbouring one (chapter 15).

Check: `TYPE board:log` prints
`stream`, `XLEN` counts your entries,
and the ids from two quick `XADD`s are
different and increasing. If an `XADD`
returns an error about an id equal or
smaller than the top item, you supplied
an id yourself — go back to `*` and let
the server name them.
