#!/bin/bash
# Run the whole Valkey lab and capture transcripts.
# Binaries: set VALKEY_BIN_DIR to the folder holding valkey-server and
# valkey-cli (built from the official source tarball), or put them on PATH.
set -u
LAB="$(cd "$(dirname "$0")" && pwd)"
cd "$LAB"
BIN_DIR="${VALKEY_BIN_DIR:-}"
if [ -n "$BIN_DIR" ]; then SERVER="$BIN_DIR/valkey-server"; CLI="$BIN_DIR/valkey-cli"; else SERVER=valkey-server; CLI=valkey-cli; fi
T="$LAB/transcripts"
mkdir -p "$T" data-rdb data-aof data-repl-primary data-repl-replica data-evict
P="-p 18080"; R="-p 19080"; E="-p 19081"
wait_ping() { for i in $(seq 1 50); do $CLI "$@" ping 2>/dev/null | grep -q PONG && return 0; sleep 0.2; done; echo "SERVER DID NOT START"; return 1; }
ts() { date '+%H:%M:%S.%N' | cut -c1-12; }

# ---------- t00 version and help ----------
{
  echo "\$ valkey-server --version"; $SERVER --version
  echo "\$ valkey-cli --version"; $CLI --version
  echo "\$ valkey-server --help (first 40 lines)"; $SERVER --help 2>&1 | head -40
  echo "\$ valkey-cli --help (first 30 lines)"; $CLI --help 2>&1 | head -30
  echo "Source used: valkey-9.1.3.tar.gz, the GitHub tag archive for tag 9.1.3"
  echo "(github.com/valkey-io/valkey/archive/refs/tags/9.1.3.tar.gz),"
  echo "sha256 184e34ed2d9b51879b682b5b15205e2b9d677c60280e3cb453be8f520d04e293,"
  echo "built with: make -j4 BUILD_TLS=no   (gcc 13.3.0, GNU Make 4.3, x86_64)"
  echo "Note: https://download.valkey.io/releases/valkey-9.1.3.tar.gz returned"
  echo "HTTP 403 to a plain curl request from this machine, so the GitHub tag"
  echo "archive of the same release was used instead."
} > "$T/t00-version-and-help.txt" 2>&1
$SERVER --help > "$T/t00-server-help-full.txt" 2>&1 || true
$CLI --help > "$T/t00-cli-help-full.txt" 2>&1 || true

# ---------- Phase 1: RDB server, data types, expiry, INFO, RDB persistence ----------
rm -f data-rdb/dump.rdb
$SERVER "$LAB/valkey-primary.conf" > "$T/t01-server-rdb.log" 2>&1 &
SRVPID=$!
{
  echo "Server started from valkey-primary.conf (bind 127.0.0.1, port 18080,"
  echo "dir ./data-rdb, appendonly no, save 3600 1). Background PID $SRVPID."
  wait_ping $P
  echo "\$ PING"; $CLI $P ping
  echo "\$ INFO server (selected lines)"; $CLI $P info server | grep -E 'valkey_version|redis_version|tcp_port|process_id|uptime_in_seconds'
  echo "\$ CONFIG GET port bind appendonly dir"; $CLI $P config get port bind appendonly dir
} > "$T/t01-start-and-config.txt" 2>&1

run_cli() { # file, then commands as args are read from stdin heredoc by caller
  :
}
{
  echo "== Strings: a community noticeboard's counters and a notice =="
  echo "\$ SET notice:current \"Board games night moves to Friday this week\""; $CLI $P set notice:current "Board games night moves to Friday this week"
  echo "\$ GET notice:current"; $CLI $P get notice:current
  echo "\$ INCR notice:views"; $CLI $P incr notice:views
  echo "\$ INCR notice:views"; $CLI $P incr notice:views
  echo "\$ INCRBY notice:views 10"; $CLI $P incrby notice:views 10
  echo "\$ GET notice:views"; $CLI $P get notice:views
  echo "\$ SET notice:current \"... (edited)\" then GET — last write wins"
  $CLI $P set notice:current "Board games night is on Friday, hall B" >/dev/null; $CLI $P get notice:current
  echo "\$ MSET club:name \"Riverside Board Game Club\" club:room \"Hall B\""; $CLI $P mset club:name "Riverside Board Game Club" club:room "Hall B"
  echo "\$ MGET club:name club:room"; $CLI $P mget club:name club:room
  echo "\$ TYPE notice:views / STRLEN notice:current / EXISTS / DEL"
  $CLI $P type notice:views; $CLI $P strlen notice:current; $CLI $P exists notice:current no:such:key; $CLI $P del no:such:key
} > "$T/t02-strings.txt" 2>&1

{
  echo "== Hashes: one club member as fields of one key =="
  echo "\$ HSET member:ada name \"Ada\" games_owned 42 favourite \"chess\""
  $CLI $P hset member:ada name "Ada" games_owned 42 favourite "chess"
  echo "\$ HGETALL member:ada"; $CLI $P hgetall member:ada
  echo "\$ HINCRBY member:ada games_owned 1"; $CLI $P hincrby member:ada games_owned 1
  echo "\$ HGET member:ada favourite"; $CLI $P hget member:ada favourite
  echo "\$ TYPE member:ada"; $CLI $P type member:ada
} > "$T/t03-hashes.txt" 2>&1

{
  echo "== Lists: a noticeboard queue, newest pushed left, worked from the right =="
  echo "\$ LPUSH queue:notices n1 n2 n3 ; LRANGE 0 -1 ; RPOP ; LLEN"
  $CLI $P lpush queue:notices "fix the hall light" "order score pads" "book friday hall" >/dev/null
  $CLI $P lrange queue:notices 0 -1; $CLI $P rpop queue:notices; $CLI $P llen queue:notices; $CLI $P lrange queue:notices 0 -1
} > "$T/t04-lists.txt" 2>&1

{
  echo "== Sets: who is coming on Friday (no duplicates, no order) =="
  echo "\$ SADD friday:players Ada Ben Ada Cleo ; SMEMBERS ; SISMEMBER ; SCARD"
  $CLI $P sadd friday:players Ada Ben Ada Cleo; $CLI $P smembers friday:players; $CLI $P sismember friday:players Ben; $CLI $P sismember friday:players Dan; $CLI $P scard friday:players
  echo "\$ SADD friday:bringing Ada Ben ; SINTER friday:players friday:bringing"
  $CLI $P sadd friday:bringing Ada Ben >/dev/null; $CLI $P sinter friday:players friday:bringing
  echo "== Sorted sets: the club leaderboard, members scored =="
  echo "\$ ZADD leaderboard 120 Ada 95 Ben 140 Cleo 95 Dan"
  $CLI $P zadd leaderboard 120 Ada 95 Ben 140 Cleo 95 Dan
  echo "\$ ZREVRANGE leaderboard 0 -1 WITHSCORES (highest first)"
  $CLI $P zrevrange leaderboard 0 -1 withscores
  echo "\$ ZINCRBY leaderboard 30 Ben ; ZRANK / ZREVRANK Cleo"
  $CLI $P zincrby leaderboard 30 Ben; $CLI $P zrevrank leaderboard Cleo; $CLI $P zscore leaderboard Ben
} > "$T/t05-sets-and-sorted-sets.txt" 2>&1

{
  echo "== Streams: an append-only log of noticeboard posts =="
  echo "\$ XADD board:log * action post author Ada text \"friday moved\""
  ID1=$($CLI $P xadd board:log '*' action post author Ada text "friday moved"); echo "returned id: $ID1"
  ID2=$($CLI $P xadd board:log '*' action post author Ben text "hall B confirmed"); echo "returned id: $ID2"
  echo "\$ XLEN board:log"; $CLI $P xlen board:log
  echo "\$ XRANGE board:log - +"; $CLI $P xrange board:log - +
  echo "\$ XREAD COUNT 1 STREAMS board:log 0"; $CLI $P xread count 1 streams board:log 0
} > "$T/t06-streams.txt" 2>&1

{
  echo "== Expiry, measured with a clock =="
  echo "start: $(ts)"
  echo "\$ SET notice:flash \"Doors open 6.30pm tonight only\" EX 3"; $CLI $P set notice:flash "Doors open 6.30pm tonight only" EX 3
  echo "\$ TTL notice:flash (immediately)"; $CLI $P ttl notice:flash
  echo "\$ GET notice:flash"; $CLI $P get notice:flash
  echo "sleeping 4 seconds... ($(ts))"; sleep 4
  echo "after: $(ts)"
  echo "\$ GET notice:flash (after the TTL)"; $CLI $P get notice:flash; echo "(empty reply above means the key is gone)"
  echo "\$ EXISTS notice:flash"; $CLI $P exists notice:flash
  echo "\$ TTL notice:current (a key with no expiry)"; $CLI $P ttl notice:current
  echo "\$ PERSIST / EXPIRE on a normal key:"
  $CLI $P set notice:temp "x" >/dev/null; $CLI $P expire notice:temp 100; $CLI $P ttl notice:temp; $CLI $P persist notice:temp; $CLI $P ttl notice:temp; $CLI $P del notice:temp >/dev/null
} > "$T/t07-expiry.txt" 2>&1

{
  echo "== Transactions and atomic counters =="
  echo "\$ MULTI / INCR notice:views / INCR notice:views / EXEC (via a pipe)"
  printf 'MULTI\nINCR notice:views\nINCR notice:views\nEXEC\n' | $CLI $P
  echo "\$ GET notice:views"; $CLI $P get notice:views
  echo "== A slow command blocks everyone: a long Lua loop, timed =="
  echo "Starting a long EVAL in the background at $(ts), then timing a PING."
  ( time $CLI $P eval "local x=0 for i=1,400000000 do x=x+i end return x" 0 ) > "$T/t12-eval.out" 2>&1 &
  EVALPID=$!
  sleep 0.5
  echo "PING issued at $(ts) while the loop is running:"
  T1=$(date +%s.%N); $CLI $P ping; T2=$(date +%s.%N)
  echo "PING round trip while blocked: $(echo "$T2 $T1" | awk '{printf "%.2f", $1-$2}') seconds"
  wait $EVALPID
  echo "EVAL result and its wall time:"; cat "$T/t12-eval.out"
  T1=$(date +%s.%N); $CLI $P ping >/dev/null; T2=$(date +%s.%N)
  echo "PING round trip after it finished: $(echo "$T2 $T1" | awk '{printf "%.3f", $1-$2}') seconds"
} > "$T/t12-transactions-and-blocking.txt" 2>&1

{
  echo "\$ INFO (full, before persistence test)"; $CLI $P info
} > "$T/t11-info-full.txt" 2>&1
{
  echo "\$ INFO memory (selected)"; $CLI $P info memory | grep -E 'used_memory_human|used_memory_peak_human|maxmemory_human|mem_fragmentation_ratio'
  echo "\$ INFO stats (selected)"; $CLI $P info stats | grep -E 'total_commands_processed|instantaneous_ops_per_sec|keyspace_hits|keyspace_misses|evicted_keys'
  echo "\$ INFO keyspace"; $CLI $P info keyspace
  echo "\$ DBSIZE"; $CLI $P dbsize
  echo "\$ MEMORY USAGE leaderboard"; $CLI $P memory usage leaderboard
  echo "\$ MEMORY USAGE member:ada"; $CLI $P memory usage member:ada
} > "$T/t11-info-and-memory.txt" 2>&1

{
  echo "== RDB persistence: snapshot, stop without saving, restart, data must survive =="
  echo "Keys before: $($CLI $P dbsize)"
  echo "\$ BGSAVE"; $CLI $P bgsave; sleep 1
  echo "\$ LASTSAVE"; $CLI $P lastsave
  ls -lh data-rdb/
  echo "\$ SHUTDOWN NOSAVE at $(ts) (server must NOT write a fresh snapshot on exit)"
  $CLI $P shutdown nosave 2>&1 || true
  sleep 1
  echo "Server process alive? $(kill -0 $SRVPID 2>/dev/null && echo yes || echo no)"
} > "$T/t08-persistence-rdb.txt" 2>&1
wait $SRVPID 2>/dev/null

$SERVER "$LAB/valkey-primary.conf" >> "$T/t01-server-rdb.log" 2>&1 &
SRVPID=$!
{
  wait_ping $P
  echo "Restarted from the same config and data-rdb folder at $(ts)."
  echo "\$ DBSIZE after restart"; $CLI $P dbsize
  echo "\$ GET notice:current"; $CLI $P get notice:current
  echo "\$ GET notice:views"; $CLI $P get notice:views
  echo "\$ HGETALL member:ada"; $CLI $P hgetall member:ada
  echo "\$ ZREVRANGE leaderboard 0 -1 WITHSCORES"; $CLI $P zrevrange leaderboard 0 -1 withscores
  echo "\$ GET notice:flash (had a 3s TTL, long past — must still be gone)"; $CLI $P get notice:flash; $CLI $P exists notice:flash
  echo "\$ SHUTDOWN NOSAVE (clean-up)"; $CLI $P shutdown nosave 2>&1 || true
} >> "$T/t08-persistence-rdb.txt" 2>&1
wait $SRVPID 2>/dev/null

# ---------- Phase 2: AOF ----------
rm -rf data-aof/* 
$SERVER "$LAB/valkey-aof.conf" > "$T/t09-server-aof.log" 2>&1 &
SRVPID=$!
{
  wait_ping $P
  echo "AOF server up (appendonly yes, appendfsync everysec, save \"\")."
  echo "\$ SET aof:notice \"AOF wrote this\" ; INCR aof:counter x3 ; HSET aof:member name \"Cleo\""
  $CLI $P set aof:notice "AOF wrote this" >/dev/null
  $CLI $P incr aof:counter >/dev/null; $CLI $P incr aof:counter >/dev/null; $CLI $P incr aof:counter >/dev/null
  $CLI $P hset aof:member name "Cleo" >/dev/null
  echo "counter is now: $($CLI $P get aof:counter)"
  sleep 2
  echo "Files under data-aof/ after ~2 seconds:"; find data-aof -type f -exec ls -lh {} \;
  echo "\$ INFO persistence (selected)"; $CLI $P info persistence | grep -E 'aof_enabled|aof_current_size|rdb_last_bgsave_status|loading'
  echo "Stopping the server the hard way: kill -9 $SRVPID at $(ts)"
  echo "(a crash, not a shutdown — nothing gets a chance to save on exit)"
} > "$T/t09-persistence-aof.txt" 2>&1
kill -9 $SRVPID 2>/dev/null; wait $SRVPID 2>/dev/null
$SERVER "$LAB/valkey-aof.conf" >> "$T/t09-server-aof.log" 2>&1 &
SRVPID=$!
{
  wait_ping $P
  echo "Restarted after the kill, at $(ts)."
  echo "\$ GET aof:notice"; $CLI $P get aof:notice
  echo "\$ GET aof:counter"; $CLI $P get aof:counter
  echo "\$ HGETALL aof:member"; $CLI $P hgetall aof:member
  echo "\$ SHUTDOWN (clean-up)"; $CLI $P shutdown 2>&1 || true
} >> "$T/t09-persistence-aof.txt" 2>&1
wait $SRVPID 2>/dev/null

# ---------- Phase 3: no persistence at all ----------
$SERVER "$LAB/valkey-repl-primary.conf" > "$T/t13-server-nopersist.log" 2>&1 &
# reuse repl-primary conf (save "", appendonly no) purely as a no-persistence server, then stop it before replication phase
SRVPID=$!
{
  wait_ping $P
  echo "No-persistence server (save \"\", appendonly no)."
  $CLI $P set volatile:key "only in memory" >/dev/null
  echo "before kill: $($CLI $P get volatile:key)"
  echo "kill -9 $SRVPID at $(ts)"
} > "$T/t13-no-persistence.txt" 2>&1
kill -9 $SRVPID 2>/dev/null; wait $SRVPID 2>/dev/null
$SERVER "$LAB/valkey-repl-primary.conf" >> "$T/t13-server-nopersist.log" 2>&1 &
SRVPID=$!
{
  wait_ping $P
  echo "after restart: GET volatile:key ->"; $CLI $P get volatile:key; echo "(empty = gone: what is only in memory is only in memory)"
  echo "\$ DBSIZE"; $CLI $P dbsize
} >> "$T/t13-no-persistence.txt" 2>&1

# ---------- Phase 4: replication (primary already running on 18080) ----------
$SERVER "$LAB/valkey-replica.conf" > "$T/t10-server-replica.log" 2>&1 &
REPPID=$!
{
  wait_ping $R
  echo "Waiting for the replication link (the primary delays a diskless sync"
  echo "by repl-diskless-sync-delay, 5 seconds by default):"
  for i in $(seq 1 40); do
    ST=$($CLI $R info replication 2>/dev/null | grep master_link_status | tr -d '\r' | cut -d: -f2)
    echo "  attempt $i: master_link_status=$ST"
    [ "$ST" = "up" ] && break
    sleep 0.5
  done
  echo "Primary on 18080, replica on 19080 (replicaof 127.0.0.1 18080)."
  echo "\$ On the PRIMARY: SET club:next_meeting \"Friday 7pm, hall B\" ; INCR notice:views"
  $CLI $P set club:next_meeting "Friday 7pm, hall B"; $CLI $P incr notice:views
  sleep 1
  echo "\$ On the REPLICA: GET club:next_meeting"; $CLI $R get club:next_meeting
  echo "\$ On the REPLICA: GET notice:views"; $CLI $R get notice:views
  echo "\$ On the REPLICA: INFO replication (selected)"; $CLI $R info replication | grep -E 'role|master_host|master_port|master_link_status|master_last_io_seconds_ago'
  echo "\$ On the PRIMARY: INFO replication (selected)"; $CLI $P info replication | grep -E 'role|connected_slaves|slave0'
  echo "\$ Writing to the REPLICA must fail — it is read-only:"
  $CLI $R set club:next_meeting "sneaky change" 2>&1 || true
  echo "\$ REPLICA GET again (unchanged):"; $CLI $R get club:next_meeting
} > "$T/t10-replication.txt" 2>&1
$CLI $R shutdown nosave 2>&1 || true; wait $REPPID 2>/dev/null
$CLI $P shutdown nosave 2>&1 || true; wait $SRVPID 2>/dev/null

# ---------- Phase 5: eviction ----------
$SERVER "$LAB/valkey-evict.conf" > "$T/t14-server-evict.log" 2>&1 &
EVPID=$!
{
  wait_ping $E
  echo "Eviction server on 19081: maxmemory 2mb, maxmemory-policy allkeys-lru."
  echo "\$ CONFIG GET maxmemory*"; $CLI $E config get 'maxmemory*'
  echo "Writing 3000 keys of about 1000 bytes each (about 3 MB of values,"
  echo "plus per-key overhead) through a pipe:"
  python3 -c "
for i in range(3000):
    print('SET evict:key:%04d %s' % (i, 'x'*1000))
" | $CLI $E --pipe 2>&1 | tail -3
  sleep 1
  echo "\$ DBSIZE after the writes"; $CLI $E dbsize
  echo "\$ INFO stats: evicted_keys"; $CLI $E info stats | grep -E 'evicted_keys|expired_keys'
  echo "\$ INFO memory: used / max"; $CLI $E info memory | grep -E 'used_memory_human|maxmemory_human'
  echo "(DBSIZE below 3000 plus evicted_keys above 0 means the limit bit and"
  echo " the server threw older keys away to stay inside 2 MB.)"
  echo "\$ SHUTDOWN NOSAVE"; $CLI $E shutdown nosave 2>&1 || true
} > "$T/t14-eviction.txt" 2>&1
wait $EVPID 2>/dev/null
echo "LAB DONE"
