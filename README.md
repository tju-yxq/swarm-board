# Swarm Board for Codex

Run a team of Codex agents behind a live, local message board. A coordinator
splits a task, named workers investigate in parallel, and an independent
verifier checks their findings. Use the board to follow each member, send
instructions during a turn, or stop one worker while the others continue.

The current Codex runner supports **read-only investigation and review**. It uses
Codex App Server to start and control independent sessions and serves the board
on `127.0.0.1`.

## Choose an entry point

| Where | Entry point | Status |
| --- | --- | --- |
| Terminal, with Node.js and Codex installed | `node skills/swarm/codex/run.mjs` | Local runner verified with real Codex sessions. |
| Patched Codex CLI | `/swarm <task>` | Built and tested end to end on Apple Silicon with Codex `0.171.0-alpha.13.2`. |
| Codex desktop app or stock CLI | `$swarm <task>` via the bundled Skill | Stock CLI also exposes the Skill through `/skills`. Desktop invocation has yet to be tested end to end. |

The native `/swarm` patch targets the terminal UI. The desktop app uses the Skill
entry point.

## Run the board

You need Node.js 22 or newer, a current Codex CLI on your PATH, and an active
Codex sign-in.

```sh
git clone --branch codex-native https://github.com/tju-yxq/swarm-board.git
cd swarm-board
node skills/swarm/codex/run.mjs --cwd /path/to/project --workers 2 -- "Review the parser and its tests"
```

Open the URL printed as `SWARM_BOARD_URL`. Click a member to inspect its
activity. Post `@worker-1 Check the empty-input case` to steer that worker, or
use `@all` to address all started members. The board can stop an individual
worker, stop the run, or accept the results collected so far. After a run ends,
the board closes once it has been idle for 15 minutes. The terminal prints
`SWARM_RUN_DIR` if you want to inspect the saved board and transcripts.

## Use the Skill in Codex

Copy the entire [`skills/swarm`](skills/swarm) directory into the target
project at `.agents/skills/swarm`, so the Skill can find its runner and board.
Open a Codex chat for that project and enter:

```text
$swarm Review the parser and its tests. Compare the workers' findings and verify them.
```

## Build the CLI with native `/swarm`

[`native/codex-swarm.patch`](native/codex-swarm.patch) adds a command to the
upstream Codex terminal UI and launches the same local runner. To build and
start a separate patched executable:

```sh
./native/build.sh
./native/launch.sh --cd /path/to/project
```

In the new terminal session, enter:

```text
/swarm Review the parser and its tests.
```

The build defaults to the upstream `rust-v0.171.0-alpha.13.2` tag. It requires
the Rust toolchain specified by that checkout and its native build dependencies.
Use a dedicated source checkout when supplying your own. The build applies the
patch and synchronizes workspace package versions in `Cargo.lock` there. The
launcher uses the separate build with `--no-daemon`.

### Follow a Codex release

Check the patch against a clean checkout of the target release before building:

```sh
./native/build.sh --check /path/to/new-codex-checkout
./native/build.sh /path/to/new-codex-checkout
```

The check leaves the source untouched. If upstream changed the command registry
or dispatcher, refresh the patch against that release and test both command
discovery and launching a run. The board and worker runtime are maintained here
independently of the CLI patch.

## Upstream and license

This is a Codex-focused fork of [Vesperino/swarm-board](https://github.com/Vesperino/swarm-board).
See the upstream project for the original Claude Code workflow, installation,
and screenshots. The original [MIT license](LICENSE) applies.
