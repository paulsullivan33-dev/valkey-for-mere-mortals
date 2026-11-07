# Strings and counters

Outcome: the string type — the plainest
value Valkey holds — worked for real:
set, get, replace, and the atomic
increments that make strings the
counter type of the whole tool.

## A string is a key's simplest value

A **string** value is a run of bytes up
to 512 MB: text, a number kept as text,
a small piece of JSON, whatever you
like. The lab's fixture throughout this
guide is a fictional community
noticeboard and the board-game club
that runs it. Its current notice is a
string (transcript
`valkey-lab/transcripts/t02-strings.txt`):

```
$ SET notice:current "Board games night moves to Friday this week"
OK
$ GET notice:current
Board games night moves to Friday this week
$ STRLEN notice:current
38
```

`SET` returns `OK`. `GET` on a key that
does not exist returns an empty reply —
the client's way of printing *nil*,
nothing there. That emptiness is an
answer, not an error; `EXISTS
notice:current no:such:key` returned
`1` in the lab, counting how many of
the named keys are real.

## Last write wins, in full

The lab then edited the notice:

```
$ SET notice:current "Board games night is on Friday, hall B"
OK
$ GET notice:current
Board games night is on Friday, hall B
```

The old text is not archived, merged,
or warned about. It is gone. That is
chapter 1's rule at its smallest scale,
and it is what every client of a shared
server must design for: if two writers
can set the same key, the later one is
the truth, and there is no built-in way
to ask what the truth used to be.
(Watch-style optimistic locking exists
— `WATCH`/`MULTI` — and is named in
chapter 13's territory; for a notice
that one editor owns, replacement is
the correct behaviour.)

## Counters: the atomic increment

A string that holds a number can be
incremented as a command, not as a
read-modify-write in your code:

```
$ INCR notice:views
1
$ INCR notice:views
2
$ INCRBY notice:views 10
12
```

This matters because of chapter 2's
single thread. `INCR` runs start to
finish inside the server with no other
command interleaved, so a hundred
clients incrementing at once produce
exactly a hundred — no locks, no lost
updates, no retry loop in your program.
`INCRBYFLOAT` does the same for decimal
amounts, and `DECR` and `DECRBY` count
down. A counter on a key that does not
exist starts at 0, so the first `INCR`
answers 1, as the lab's did.

## Setting several at once

`MSET` and `MGET` handle batches:

```
$ MSET club:name "Riverside Board Game Club" club:room "Hall B"
OK
$ MGET club:name club:room
Riverside Board Game Club
Hall B
```

`MSET` is atomic as a group — no client
can observe half of it — which makes it
the right tool when several facts must
change together or not at all.

Two more everyday options, stated here
and used later: `SET key value NX` sets
only if the key does **not** exist (the
building block of simple locks and
first-come claims), and `SET key value
EX 60` sets a value and a 60-second
expiry in one command — chapter 10
lives on that form. `GETDEL` and
`GETEX` read a value while deleting it
or changing its expiry; know they exist
before you build the same thing from
two commands with a race between them.

Check: `TYPE notice:views` prints
`string`, and two `INCR`s in a row
differ by exactly one. If `GET` on your
counter prints words, someone stored
text in it — `INCR` would now answer
with an error, which is the server
protecting the counter, not breaking it.
