# `qb` Log Filters

`qb` intentionally runs Maven output through a small stack of filters before it prints anything. The goal is not to hide failures. The goal is to keep the default `INFO` view focused on actionable build progress while pushing noisy, repetitive, or low-value chatter out of the way.

## Why The Stack Exists

Maven, Docker, Yarn, and a few plugins all emit output that is technically correct but not equally useful during normal development. Some lines are progress indicators with no decision value, repeated summaries that restate what the build already proved, warnings that are expected in common environments, or housekeeping messages that only matter when debugging the logging pipeline itself.

The filters keep the default `qb` experience centered on real errors, real warnings that usually need attention, and high-signal `INFO` progress. Anything still useful for diagnosis but not useful for routine builds gets downgraded to `DEBUG` so it remains available at higher verbosity without crowding the default output.

## Filter Rationale

### `mvnyarnclean`

Docker-wrapped Yarn output can contain progress glyphs and protocol markers that make otherwise readable lines noisy or malformed. This filter strips those markers and drops pure progress chatter so Docker build logs show the useful message, not the transport noise around it.

### `mvnreactordebug`

The Maven reactor summary repeats the entire module list near the end of a build. That is useful when diagnosing the full build graph, but it adds a large block of text right when the important result is simply whether the build passed. This filter keeps that summary available only at `DEBUG`.

### `mvndockerdebug`

Docker archive extraction lines such as `inflating:` and `extracting:` are volume-heavy and rarely actionable. They show low-level unpacking work, not a problem that needs a decision. This filter moves that chatter to `DEBUG`.

### `mvnbranchdebug`

In detached-`HEAD` worktrees, Maven can emit a branch-detection warning even though the build is otherwise healthy. That warning is real, but in this workflow it is usually expected and benign. This filter downgrades that one specific warning so normal builds are not dominated by repository-shape noise.

### `mvnparallelcondense`

Maven's parallel-execution plugin safety warning arrives as a multi-line block. The underlying point matters, but the formatting is bloated and interrupts the flow of the build log. This filter condenses that block into a single summary line while preserving the affected module and every listed plugin.

### `mvnparalleldebug`

The condensed parallel-execution warning is still diagnostic rather than operational. It is something to inspect when tuning the build, not something most developers need on every successful run. This filter moves that condensed summary to `DEBUG`.

### `mvnlevelcaps`

Some tools emit lowercase or mixed-case log levels. That inconsistency makes the output harder to scan and can break later filters that rely on stable severity labels. This filter normalizes log levels to uppercase so the printed log reads consistently and the rest of the pipeline can reason about severity cleanly.

### `mvnzerofilesnoise`

Messages like `Processed 0 files (0 non-complying).` do not help a developer decide what to do next. They confirm that nothing happened, which is usually not interesting in the default view. This filter removes that zero-work housekeeping line from filtered output so the signal stays on meaningful build events.

### `mvnlevel`

This is the actual severity gate. Everything before it decides whether a message should be rewritten, normalized, condensed, or reclassified. `mvnlevel` decides whether that message belongs in the selected verbosity at all. The default `qb` mode is `v4` (INFO), so `DEBUG` and `TRACE` stay hidden unless the user asks for more detail with `-v5` or `-v6`. The full gate is:

| Flag | Label    | What reaches the terminal |
|------|----------|---------------------------|
| v0   | silent   | nothing |
| v1   | stderr   | Maven OS stderr only, stdout suppressed |
| v2   | errors   | v1 plus qb metadata and ERROR lines |
| v3   | warnings | v2 plus WARNING lines |
| v4   | info     | v3 plus INFO lines (default) |
| v5   | debug    | v4 plus demoted DEBUG lines |
| v6   | trace    | v5 plus demoted TRACE lines |
| v7   | raw      | unfiltered Maven stdout and stderr |

### `mvncolor`

Color is the last step because the message should be categorized before it is styled. Its purpose is simple: make severity visually obvious so important lines stand out immediately.

## Intended Default Experience

With plain `qb` and no flags:

- `ERROR` stays visible
- actionable `WARNING` stays visible
- useful `INFO` progress stays visible
- diagnostic noise is pushed to `DEBUG`
- raw tool chatter only appears in raw mode

That keeps the default build output readable without throwing away information that is still valuable when debugging.
