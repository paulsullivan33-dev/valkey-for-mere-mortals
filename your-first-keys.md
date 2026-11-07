# Your first keys

Outcome: a server running from a config
file you can read, bound to loopback on
the lab's port, answering `PING` — the
setup every later chapter assumes.

## Start it from a file, not from flags

A Valkey server takes its settings from
a **configuration file**: one
directive per line, name then value.
The lab's primary config is
`valkey-lab/valkey-primary.conf`, kept
deliberately short:

```
bind 127.0.0.1
port 18080
protected-mode yes
daemonize no
dir ./data-rdb
dbfilename dump.rdb
appendonly no
save 3600 1
```

Read it top to bottom. `bind 127.0.0.1`
means *only this machine may connect* —
the single most important line in the
file, because a Valkey server with no
password, reachable from a network, is
an open door: anyone who can connect
can read and write everything, and
chapter 16 says more. `port 18080` is
this guide's assigned lab port, not the
default 6379; using a non-default port
in a lab keeps you from colliding with
a real install. `dir` is the folder the
server works in — where its snapshot
file will land — and `save 3600 1` is a
persistence schedule (snapshot if at
least 1 key changed in 3600 seconds);
chapter 11 unpacks both. `daemonize no`
keeps the server in the foreground of
its terminal, where you can see it and
stop it with Ctrl-C; the lab ran it in
the background only so scripts could
drive it, and captured its startup log
as `valkey-lab/transcripts/t01-server-rdb.log`.

Start it:

```
valkey-server valkey-lab/valkey-primary.conf
```

## Prove it is yours and it is up

From a second terminal, with the client
pointed at the same port:

```
$ valkey-cli -p 18080 ping
PONG

$ valkey-cli -p 18080 info server
```

The lab's run answered `PONG`, and its
`INFO server` carried the lines that
matter (transcript
`valkey-lab/transcripts/t01-start-and-config.txt`):
`valkey_version:9.1.3`, the compatibility
field `redis_version:7.2.4`,
`tcp_port:18080`, and the server's own
process id. Ask the server to repeat
its config back and it confirms the
file was read, not guessed:

```
$ valkey-cli -p 18080 config get port bind appendonly dir
appendonly
no
bind
127.0.0.1
dir
/home/.../valkey-lab/data-rdb
port
18080
```

Replies from `valkey-cli` in its
one-shot form print values plainly, one
per line, with no decoration — which is
why the transcripts in this guide are
easy to compare against your own runs.

## Your first keys

Chapter 5 does strings properly; here
is the thirty-second version, to have
something in the server before you stop
it:

```
$ valkey-cli -p 18080 set club:name "Riverside Board Game Club"
OK
$ valkey-cli -p 18080 get club:name
Riverside Board Game Club
$ valkey-cli -p 18080 dbsize
1
```

`OK` is the server's receipt. `DBSIZE`
counts the keys in the current
database. You have just used the shared,
mutable present of chapter 1: run the
`GET` from a third terminal, or a
script, and it sees the same value.

## Stop it like you mean it

Three ways, in increasing violence:
Ctrl-C in its terminal; `valkey-cli -p
18080 shutdown`, which stops it *and*
saves if persistence is configured; or
`shutdown nosave`, which stops it
without a final snapshot. Chapter 11
uses the difference between those last
two as a measuring instrument. An
ordinary `kill` (SIGTERM) behaves like
a shutdown. `kill -9` is a crash — no
cleanup at all — and chapter 11 uses
that too, on purpose.

Check: `valkey-cli -p 18080 ping` prints
`PONG`, and `config get port` prints
`18080`. If the port line says 6379,
you are talking to some other server —
stop and find out whose before going on.
