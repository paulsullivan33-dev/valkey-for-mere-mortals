# Lists

Outcome: the list type — an ordered
sequence you push onto and pop off of —
used as the noticeboard's work queue,
with the direction of travel made
explicit, because lists punish guessing.

## Push left, pop right: a queue

A **list** is a sequence of strings
with a head (left) and a tail (right).
The lab pushed three jobs onto the left
of `queue:notices` and worked them from
the right (transcript
`valkey-lab/transcripts/t04-lists.txt`):

```
$ LPUSH queue:notices "fix the hall light" "order score pads" "book friday hall"
$ LRANGE queue:notices 0 -1
book friday hall
order score pads
fix the hall light
$ RPOP queue:notices
fix the hall light
$ LLEN queue:notices
2
```

Two things to see. First, a multi-value
`LPUSH` lands its arguments in reverse
order — the *last* argument ends up
nearest the head — because each value
is pushed onto the head in turn. Every
reader meets this once; the transcript
is this guide's turn. Second, pushing
left and popping right makes a
**queue**: first in, first out. The
first job pushed was the first job
popped. Push left and pop *left*
(`LPOP`) and the same structure is a
**stack**: last in, first out. The type
is one; the discipline is yours.

`LRANGE key 0 -1` reads the whole list
(indexes count from 0, and -1 means the
last element — negative indexes count
back from the tail throughout Valkey).
`LINDEX`, `LSET`, `LREM`, and `LTRIM`
read, replace, remove, and cut a list
down to a window; `LTRIM` paired with
`LPUSH` is the standard "keep only the
newest hundred" recent-items pattern.

## The blocking pop, and honest labels

Real queues usually wait instead of
polling: `BRPOP queue:notices 5` blocks
for up to 5 seconds and returns the
moment an item arrives. The *pattern*
is core Valkey and is described here
from the documentation; the lab's
scripted runs used plain `RPOP` so the
transcripts stay deterministic, and
`BRPOP` is listed as documented-only in
`criteria.md`. The same honesty applies
to using a list as a durable job queue
at all: a popped job that a worker then
loses is gone — the list kept no copy.
Reliable-queue patterns exist (moving
items to a processing list with
`LMOVE`, and streams with consumer
groups in chapter 9), and choosing
between "simple list queue" and "stream
that remembers" is a real decision, not
a detail. Chapter 14 assembles the
simple version and says where its edge
is.

One more limit to know by name: a list
is one value under one key, so every
push and pop is one command on chapter
2's single thread — fast, atomic, and
serial. A queue with many heavy jobs is
fine; the *commands* are tiny. What you
must not do is store the jobs' *results*
as giant list elements and wonder why
memory grew: chapter 13 shows how to
watch it grow, in the server's own
numbers.

Check: after an `LPUSH` of two items
and one `RPOP`, `LLEN` has dropped by
one and the item you got is the one you
pushed first. If you got the newest
instead, you popped from the wrong end
— say which end your queue uses, out
loud, before building on it.
