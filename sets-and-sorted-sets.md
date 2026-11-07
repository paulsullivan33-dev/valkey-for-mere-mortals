# Sets and sorted sets

Outcome: two types that look alike and
are not — the **set**, for "who is in
this group", and the **sorted set**, for
"who is winning" — each run for real
against the club's Friday night.

## Sets: membership, with duplicates refused

A set is a collection of unique
strings, in no promised order. The lab
signed players up for Friday (transcript
`valkey-lab/transcripts/t05-sets-and-sorted-sets.txt`):

```
$ SADD friday:players Ada Ben Ada Cleo
3
$ SCARD friday:players
3
$ SISMEMBER friday:players Ben
1
$ SISMEMBER friday:players Dan
0
```

Ada was added twice and counted once:
`SADD` answers with how many members
were *new*, and the set simply refuses
the duplicate. That refusal is the
type's whole gift — "have I seen this
before?" answered by the structure
itself. `SMEMBERS` lists everyone (in
an order you must not rely on — it
changed between the set's members, not
between runs of the command, but the
contract is *unordered*), `SREM` removes,
and `SPOP` removes and returns a random
member, the raffle command.

Sets earn their keep in combination:

```
$ SADD friday:bringing Ada Ben
$ SINTER friday:players friday:bringing
Ada
Ben
```

`SINTER` is the overlap, `SUNION` the
combined group, `SDIFF` the members of
the first who are absent from the
second — set algebra as single
commands, atomic like everything else
on the single thread. Tags, followers,
permissions, and "users who have not
yet been emailed" are all this shape.

## Sorted sets: the leaderboard type

A sorted set also holds unique members,
but each carries a **score**, a number,
and the set is kept ordered by score:

```
$ ZADD leaderboard 120 Ada 95 Ben 140 Cleo 95 Dan
4
$ ZREVRANGE leaderboard 0 -1 WITHSCORES
Cleo
140
Ada
120
Dan
95
Ben
95
$ ZINCRBY leaderboard 30 Ben
125
$ ZREVRANK leaderboard Cleo
0
```

`ZREVRANGE` reads highest first;
`ZRANGE` reads lowest first. Equal
scores — Dan and Ben at 95 — are ordered
by the member's alphabetical order,
which is why Dan prints before Ben; a
leaderboard that needs a different
tie-break must fold it into the score.
`ZINCRBY` is the counter of this type:
Ben's 30 new points moved him to 125
and second place without any client
reading the board first. `ZREVRANK` is
0-based, so Cleo's 0 means *first*.
`ZSCORE`, `ZCARD`, `ZREM`, and range
queries by score (`ZRANGEBYSCORE`, in
its modern `ZRANGE ... BYSCORE` form)
complete the everyday kit.

Scores are double-precision numbers.
Timestamps fit in them comfortably,
which is why sorted sets also serve as
delayed-job schedules and time-ordered
feeds — score by the time something is
due, and ask for everything due by now.
That pattern is named here from the
documentation; the lab ran the
leaderboard, and `criteria.md` keeps
the two separate.

Check: `TYPE leaderboard` prints
`zset`, and after your own `ZINCRBY`,
`ZSCORE` shows the sum, not the
increment. If it shows the increment,
you used `ZADD` — which *replaces* a
member's score — and knowing which of
the two you meant is most of this
chapter.
