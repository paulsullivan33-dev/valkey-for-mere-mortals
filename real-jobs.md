# Real jobs

Outcome: the types assembled into the
four jobs the fixture actually needed —
a shared counter, a leaderboard, a job
queue, and a self-deleting notice —
with each job's weak point named where
it is assembled, not chapters later.

## Job 1: the noticeboard's view counter

Every page of the noticeboard counts
its own views, and three small programs
all update the same count. As strings:

```
INCR notice:views
```

That is the entire implementation, and
chapter 5 showed why it is correct: the
increment is atomic on the single
thread, so the writers need no
coordination at all. The lab took the
counter to 14 across its runs —
increments, an `INCRBY 10`, and a
`MULTI` block that queued two more
increments and applied them together at
`EXEC`:

```
$ MULTI / INCR / INCR / EXEC
OK
QUEUED
QUEUED
13
14
```

(transcript
`valkey-lab/transcripts/t12-transactions-and-blocking.txt`).
A **transaction** in Valkey is that:
commands queued between `MULTI` and
`EXEC` run together with nothing
interleaved. It is deliberately smaller
than a database transaction — no
rollback; if one queued command fails
at run time, the others still apply —
and chapter 16 counts that among the
honest limits.

## Job 2: the club leaderboard

From chapter 8, unchanged: scores in a
sorted set, points added with
`ZINCRBY`, the board read with
`ZREVRANGE ... WITHSCORES`, a player's
standing with `ZREVRANK`. The job's
weak point is persistence, not the
type: a season's standings are data the
club would miss, so this server gets
the AOF config, and the choice is made
per dataset, not per server brand.

## Job 3: the hall job queue

Chapter 7's list, used as designed:
producers `LPUSH queue:notices ...`,
one worker `RPOP`s jobs in arrival
order. Its weak point was named there
and stands: a popped job is a
responsibility transferred, not
recorded — if the worker dies holding
it, no copy remains. For the hall's
three chores that trade is fine, and
the guide says plainly where it stops
being fine: anything you would pay to
recover belongs in a stream with
consumer groups (chapter 9) or a real
broker (chapter 15), not in a bare list.

## Job 4: the notice that deletes itself

Chapter 10's flash notice, generalised:

```
SET notice:flash "..." EX 10800
```

Three hours, set once by whoever posts
the evening's change, never deleted by
anyone — expiry is the janitor. Its
weak point is the mirror of its
strength: nothing archives it. A notice
with a history the club cares about
belongs in a stream (chapter 9), where
expiry is replaced by deliberate
trimming.

## The pattern underneath

Four jobs, four types, one server, ten
keys, 1.58 MB. The real skill this
guide has been teaching is the matching:
counter to string, standings to sorted
set, queue to list, announcement to an
expiring string, history to a stream —
and the chapter 1 question asked of
each: *must this survive a restart, and
what have I configured so that it
does?*

Check: take one piece of state in a
program of yours and name its type from
this chapter and its persistence answer
from chapter 11. If either answer is
"whichever it defaults to", that state
is unexamined — examine it now, on
paper, where it is cheap.
