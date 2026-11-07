# Writing criteria for this guide

Every "for Mere Mortals" guide is written to the same nine-point
standard, so a reader who trusts one can trust the rest. Here it
is, with the verification notes for this particular guide below.

1. **Fix it first.** Reader outcomes lead, not action items: each
   chapter opens by naming the outcome it delivers, shows a check
   the reader can run to confirm they got it, and a reasonable
   reader finishes able to state what was done, what it means,
   and what to try next.
2. **Plain language.** Short sentences, everyday vocabulary,
   technical terms defined on first use. No slang, and no
   idioms that only make sense in one country — the reader may
   be translating as they go.
3. **No dead ends.** A guide never tells the reader to do
   something it cannot show them how to verify. Every claim a
   reader relies on — an install, a command, an output — is
   something this guide demonstrates or clearly labels
   documented-only below.
4. **Live-verified where it matters.** Procedures are run for
   real in the guide's lab wherever the build machine allows it,
   and the transcripts kept in the repository are the evidence.
   What could not be run is listed honestly below, never
   presented as if it had been.
5. **General audiences.** Nothing in this guide — examples,
   fixtures, names, addresses — is modelled on any particular
   reader or author's real life, network, or organisations.
   The lab's traffic is the lab talking to itself.
6. **Standalone.** A reader needs this guide, its lab, and
   nothing else. Where another guide would genuinely help, it
   is pointed to once, by name, and the chapter still completes
   without it.
7. **Honest about limits.** The limits chapter names what the
   tool cannot do: command execution is single-threaded per
   instance, so one slow command blocks every client (measured:
   a 2.98-second Lua loop held a `PING` for 2.48 seconds); the
   dataset lives in RAM, so size is bounded by memory and a
   `maxmemory` limit is enforced by evicting keys (measured:
   1,767 evicted at a 2 MB limit); persistence is a trade-off,
   not a save button — RDB snapshots can lose everything since
   the last snapshot, and AOF with `appendfsync everysec` can
   lose about a second of writes in a machine crash while
   costing disk on every write; there are no multi-key
   transactions across a cluster, and even on one instance a
   transaction has no rollback; and replication is
   asynchronous, so a replica can lag and a dead primary can
   take unreplicated writes with it.
8. **The one rule is in the text, early.** Chapter 1 and the
   README state the rule plainly — *Valkey is a shared, mutable
   present: every client sees the latest write, the last write
   wins, and data survives a restart only if you configured
   persistence; what is only in memory is only in memory* —
   before any procedure depends on it, and later chapters point
   back to it where the rule bites: the replaced notice, the
   counter nobody coordinates, and the server that came back
   from a crash with zero keys because nobody configured it.
9. **Builds clean.** The site builds with MkDocs in strict mode
   with no warnings, and a fresh reader following the chapters
   in order reaches the stated outcome of each.

## Verification notes for this guide

The build machine is an Ubuntu 24.04 sandbox. Valkey **9.1.3**
(the newest patch release of the 9.1 line, released
26 October 2026) was built from the project's official source
release with gcc 13.3.0 and GNU Make 4.3 (`make -j4
BUILD_TLS=no`). The file was obtained as the GitHub tag archive
`valkey-9.1.3.tar.gz`
(github.com/valkey-io/valkey/archive/refs/tags/9.1.3.tar.gz,
SHA-256
184e34ed2d9b51879b682b5b15205e2b9d677c60280e3cb453be8f520d04e293)
because the canonical
`download.valkey.io/releases/valkey-9.1.3.tar.gz` address
returned HTTP 403 to a plain curl request from this machine;
both are the project's own files for the same tag, and the
substitution is recorded in transcript t00 rather than hidden.
Binaries ran from the build tree, not installed system-wide.
The lab is in `valkey-lab/`: config files for each server
(`valkey-primary.conf`, `valkey-aof.conf`,
`valkey-repl-primary.conf`, `valkey-replica.conf`,
`valkey-evict.conf`), one driver (`run-lab.sh`) that ran every
phase and captured every transcript into
`valkey-lab/transcripts/`, and a fixture seed file in
`valkey-lab/fixtures/`. All servers bound 127.0.0.1 only: the
primary on port 18080, the replica on 19080, the eviction
instance on 19081. The fixture is a fictional community
noticeboard and board-game club.

Run for real, with transcripts as evidence:

- Version and help captured first (t00): `valkey-server
  --version` reports 9.1.3 (jemalloc build), and the server's
  short usage plus the client's full help were saved before
  anything else was trusted.
- Starting from a lab config file (t01): `PING` answered
  `PONG`; `INFO server` reported `valkey_version:9.1.3`,
  `redis_version:7.2.4` (the compatibility field), and
  `tcp_port:18080`; `CONFIG GET` confirmed port, bind,
  appendonly, and dir from the file.
- Strings (t02): `SET`/`GET`/`STRLEN`, last-write-wins on an
  edited notice, `INCR`/`INCRBY` taking a view counter
  1, 2, 12, `MSET`/`MGET`, `TYPE`, `EXISTS`, `DEL`.
- Hashes (t03): `HSET` returning 3 new fields, `HGETALL`,
  `HINCRBY` 42 to 43, `HGET`.
- Lists (t04): a three-job `LPUSH` (landing in the documented
  reverse argument order), `LRANGE`, `RPOP` returning the
  first job pushed, `LLEN` 2.
- Sets and sorted sets (t05): `SADD` with a duplicate counted
  once (3 from 4 arguments), `SISMEMBER` 1 and 0, `SINTER`;
  a leaderboard built with `ZADD`, read with `ZREVRANGE
  WITHSCORES` (equal scores ordered by member name),
  `ZINCRBY` moving a player 95 to 125, `ZREVRANK` 0 for the
  leader.
- Streams (t06): two `XADD`s with server-assigned ids,
  `XLEN` 2, `XRANGE - +`, `XREAD` from position 0.
- Expiry, measured (t07): a key set with `EX 3` at a recorded
  wall-clock time read back immediately (`TTL` 3), and after
  a 4-second sleep was gone (`GET` empty, `EXISTS` 0). `TTL`
  on a persistent key answered -1; `EXPIRE`/`PERSIST`
  attached and removed a 100-second TTL.
- Transactions and blocking (t12): `MULTI` with two queued
  `INCR`s applied at `EXEC` (13, 14). A 400-million-iteration
  Lua `EVAL` ran 2.98 seconds; a `PING` issued 0.5 seconds
  into it returned after **2.48 seconds**, and after
  **0.003 seconds** once the loop finished.
- INFO and memory (t11): full `INFO` captured; with 10 keys,
  `used_memory_human:1.58M`, `keyspace_hits:33`,
  `keyspace_misses:3`, `total_commands_processed:69`,
  `db0:keys=10`; `MEMORY USAGE` 72 bytes for the leaderboard
  and 88 bytes for the member hash.
- RDB persistence (t08): `BGSAVE` wrote a 631-byte
  `dump.rdb` for 10 keys; the server was stopped with
  `SHUTDOWN NOSAVE` (no fresh snapshot on exit), restarted,
  and all 10 keys — string, counter at 14, hash, leaderboard —
  read back. The expired flash key stayed expired.
- AOF persistence (t09): with `appendonly yes` and
  `appendfsync everysec`, the working folder held the base
  RDB (89 bytes), the incremental AOF (221 bytes), and the
  manifest (88 bytes). The server was killed with `kill -9`
  and restarted; every written value read back.
- No persistence (t13): with `save ""` and `appendonly no`, a
  key present before a `kill -9` was gone after restart and
  `DBSIZE` was 0.
- Replication (t10): a replica on 19080 with
  `replicaof 127.0.0.1 18080`. The lab's first attempt read
  too early — the primary delays a diskless sync by
  `repl-diskless-sync-delay` (5 seconds by default) — and got
  empty reads with `master_link_status:down`; the final run
  polled and saw the link `up` at attempt 13 (about
  6 seconds), then a `SET` and an `INCR` on the primary read
  back on the replica, the primary reporting the replica
  `state=online, offset=132, lag=0`, and a write attempted on
  the replica refused with `READONLY`.
- Eviction (t14): a third instance with `maxmemory 2mb` and
  `allkeys-lru` received 3,000 keys of about 1,000 bytes each
  through `--pipe` (3,000 replies, 0 errors) and finished with
  `DBSIZE` 1256, `evicted_keys:1767`, and used memory held at
  exactly 2.00M.

Documented only — described from the project's documentation
and help text, not run, and the text does not claim otherwise:

- Installation routes other than the source build (distribution
  packages, the `valkey/valkey` container image, Homebrew),
  and the TLS build (`BUILD_TLS=yes`); the lab's copy has no
  TLS.
- Machine-crash data-loss windows for the AOF fsync policies.
  The lab proved survival across a *process* kill (`kill -9`),
  where the operating system and its buffers survive; the
  about-a-second figure for `appendfsync everysec` in a full
  machine crash is the documentation's, as are `always` and
  `no`.
- Sentinel (monitoring and automatic failover) and Valkey
  Cluster, including sharding and the rule that multi-key
  transactions across a cluster need keys in the same slot
  (hash tags).
- Blocking list commands (`BRPOP` and family), stream consumer
  groups (`XREADGROUP`, `XACK`, pending entries, claiming),
  `WATCH`-based optimistic locking, and the sorted-set
  delayed-job pattern.
- Multi-threaded I/O in modern Valkey: command execution was
  measured to be serial; that I/O can be offloaded to other
  threads is the documentation's distinction, not a lab result.
- Passwords, ACLs, and protected-mode behaviour beyond the
  lab's loopback-only bind; pub/sub; Lua scripting beyond the
  one blocking loop used as a stopwatch; client libraries for
  any programming language.
- The neighbouring tools in chapter 15 are characterised, not
  benchmarked; Redis itself was not run.

Fixtures are this guide's own and deliberately generic: a
community noticeboard, a board-game club, its members and its
leaderboard. No example is modelled on any real person,
network, service or organisation. Two accidents are kept in
the record rather than cleaned away: the replication phase's
first run read before the diskless-sync delay had elapsed and
is quoted in chapter 12 as the patience lesson, and an early
eviction run was lost entirely to a lab-script variable
collision (a timing variable overwrote the port-flags
variable, so every client command was refused at the default
port) — fixed, re-run end to end, and used in chapter 17 as
the worked connection-refused example.
