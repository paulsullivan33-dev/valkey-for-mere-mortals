# Installing Valkey

Outcome: a Valkey server and client on
your machine, proved by the version
check every route must pass — and an
honest account of which route this
guide ran and which it only read about.

## The check

However you install it, the proof is
the same two commands:

```
valkey-server --version
valkey-cli --version
```

The lab's copies answer (transcript
`valkey-lab/transcripts/t00-version-and-help.txt`):

```
Valkey server v=9.1.3 sha=00000000:1 malloc=jemalloc-5.3.0 bits=64 build=34e9ebdb4fb06db3
valkey-cli 9.1.3
```

The server has almost no `--help` of
its own — a screen of usage lines; it
is configured by file, not by flags,
which is chapter 4's subject. The
*client's* help is the long one, and
the lab captured both in full
(`t00-server-help-full.txt`,
`t00-cli-help-full.txt`) before trusting
either.

## The route the lab used: build the official source release

Valkey 9.1 was the newest release line
when this guide was written, and its
newest patch release was **9.1.3**
(26 October 2026, per the project's
download page). The lab built it from
source on an Ubuntu 24.04 machine with
gcc 13.3.0 and GNU Make 4.3:

```
tar xzf valkey-9.1.3.tar.gz
cd valkey-9.1.3
make -j4 BUILD_TLS=no
src/valkey-server --version
```

The build took a few minutes on four
cores and produced `src/valkey-server`,
`src/valkey-cli`, and
`src/valkey-benchmark`. Nothing was
installed system-wide; the lab ran the
binaries straight from the build tree,
and `valkey-lab/run-lab.sh` takes their
folder in a `VALKEY_BIN_DIR` variable
for exactly that reason. `BUILD_TLS=no`
is the default and means this copy
cannot speak TLS; a build that needs
encrypted connections adds
`BUILD_TLS=yes` and the OpenSSL
development files — documented-only
here, since the lab never ran it.

Two honest notes about obtaining the
file. First, the canonical address,
`download.valkey.io/releases/valkey-9.1.3.tar.gz`,
answered a plain `curl` request from
this machine with **HTTP 403**, so the
lab fetched the same release as the
GitHub tag archive
(`github.com/valkey-io/valkey/archive/refs/tags/9.1.3.tar.gz`,
SHA-256
`184e34ed2d9b51879b682b5b15205e2b9d677c60280e3cb453be8f520d04e293`)
and recorded that in the transcript. A
tag archive and the release tarball are
both the project's own files for the
same tag; their checksums differ
because the packaging differs, so do
not expect the hash above to match a
tarball fetched from the other address.
Second, everything in this guide was
verified against 9.1.3. Command
spellings are stable across the 7.2,
8.x, and 9.x lines this guide's
examples use, but your copy's own
behaviour outranks this guide wherever
the two disagree.

## The other routes, documented only

The lab did not walk through these
doors and will not pretend to have:

- **Distribution packages.** Debian and
  Ubuntu package Valkey (the server as
  `valkey-server`, the client in
  `valkey-tools` on some releases), and
  the version you get depends on your
  distribution release — often an older
  line than 9.1. Check what yours offers
  before assuming.
- **The official container image**,
  `valkey/valkey` on Docker Hub, in
  default, `trixie`, and `alpine`
  variants per version. Useful for a
  quick server; this guide's lab wanted
  the process where it could watch it.
- **Homebrew** on macOS: `brew install
  valkey`.

Whichever door you use, finish with the
check at the top. The version lines are
the handshake between your machine and
the rest of this guide.

Check: `valkey-server --version` prints
`9.x` (or at least a 7.2-or-later line),
and `valkey-cli --version` agrees. If
both do, chapter 4 starts your server.
