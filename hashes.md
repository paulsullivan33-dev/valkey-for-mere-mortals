# Hashes

Outcome: one key holding a whole small
record — a **hash** of named fields —
so a club member, a product, or a
session can be read and updated field
by field instead of as one blob.

## One key, many fields

A hash maps field names to values,
inside a single key:

```
$ HSET member:ada name "Ada" games_owned 42 favourite "chess"
3
$ HGETALL member:ada
name
Ada
games_owned
42
favourite
chess
```

(transcript
`valkey-lab/transcripts/t03-hashes.txt`).
`HSET` answers with the number of
*new* fields — 3 here — so setting the
same fields again answers 0, a quiet
way to notice you are overwriting.
`HGETALL` prints field and value in
alternating lines in the client's plain
form. `HGET member:ada favourite`
fetches one field; `HDEL` removes one;
`HEXISTS` tests for one; `HLEN` counts
them; `HKEYS` and `HVALS` list the two
halves. Field order in a reply is the
order the server keeps them, not an
order you should build meaning on.

## Updating one field touches nothing else

The hash version of the counter:

```
$ HINCRBY member:ada games_owned 1
43
```

Ada's name and favourite game were not
read, rewritten, or at risk. Compare
the string approach — one JSON blob per
member — where changing any field means
fetching the whole blob, changing it in
your program, and writing it back, with
every other writer's changes in the
gap exposed to chapter 1's last-write-
wins. A hash keeps the record shared
*inside* the server, where the single
thread makes each field update atomic.

## When a hash is the right shape

- A record with a known, small set of
  fields that different clients update
  independently: profiles, settings,
  inventory rows, session details.
- Counters that belong together: votes
  per option, stock per size — one key,
  one field each, all visible in one
  `HGETALL`.

And when it is not: hashes have no
schema. Nothing stops one client
writing `games_owned` and another
writing `gamesOwned`, and the server
will happily keep both fields forever.
The discipline a database schema would
enforce is yours to keep, in naming
conventions your whole team shares.
Very large hashes are also the wrong
shape — a hash is loaded as one value;
for thousands of fields, reconsider the
design (a key per field group, or a
real database) rather than growing one
key without limit. That sizing advice
is general practice from the project's
documentation, not something the lab's
three-field member measured.

Check: `TYPE member:ada` prints `hash`,
and `HGETALL` after your own `HSET`
shows exactly the fields you set — no
more, which is how you know no other
client has been inventing fields.
