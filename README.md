# mg-skills

Markdown General skill library. Contains only mg-specific skills. Generic browser tools and utilities are sourced from upstream [pi-skills](https://github.com/badlogic/pi-skills).

## Skills

### chat-with-chat

Multi-system web-based AI chat automation (Grok, Claude.ai, etc.) via Chrome DevTools Protocol. No API keys required; drives the actual browser UI.

- **Directory**: `chat-with-chat/`
- **Skill Name**: `chat-with-chat`
- **Status**: ✓ Verified (Grok tested end-to-end, Claude.ai pre-configured)
- **Main Entry**: `./chat-with-chat.sh <system> "<prompt>"` (or `chat-with-claude.sh` harness for file-fed sessions)
- **Config**: `chat-tools.conf` (per-system URL patterns, input/send/bubble selectors, timeouts)
- **Logging / Capture**: `chat-log.sh <system>` (dumps full conversation history from the tab into `~/mg/logs/<system>-conversation-<ts>.txt` using rich selector fallback + document order).
- **Extras**: `extract-all.js`, `chat-log.js` (lower-level full convo extractors), `chat-upload.js` for multi-file attachments before send.

See `chat-with-chat/SKILL.md` for full documentation, setup (Chrome --remote-debugging-port=9222), health checks, anti-spiral safeguards, troubleshooting, and architecture (config-driven send/wait over CDP + puppeteer).

### read-ghc-core

Read and analyze GHC Core (`-ddump-simpl`) dumps to diagnose performance: boxing overhead, monad transformer costs, lazy knots (`<<loop>>`), allocation in hot loops, and zero-cost abstraction failures.

- **Directory**: `read-ghc-core/`
- **Skill Name**: `read-ghc-core`
- **Status**: ✓ Documented with case studies and workflow
- **Main Entry**: Read `SKILL.md` (no executable wrapper yet; use the analysis patterns directly on `.dump-simpl` files)

Key patterns covered:
- Unboxed (`Int#`, `Addr#`) vs boxed args in `$wgo` recursive loops.
- State flattening, monad machinery (`Kleisli StateT Identity` overhead vs direct functions).
- `letrec` / `LoopBreaker` for lazy knots and non-termination.
- Counting `let` allocations and tuple reconstruction inside loops.
- Quick reference table of Core idioms and verdicts.

See `read-ghc-core/SKILL.md` for the full guide, generation commands, step-by-step loop reading, case studies (State, Kleisli, lazy knots), and anti-patterns.

## Adding Skills

1. Create directory: `mkdir <skill-name>`
2. Write SKILL.md with frontmatter (name, description) + markdown body.
3. Include verified scripts and supporting files.
4. Test end-to-end.
5. Update this README.md with a concise entry.
6. Commit and push (explicit user request only).

## Deprecated

- **browser-tools/** directory: mixed pi-inherited + mg-specific code. Use `chat-with-chat/` instead. Generic tools are available in [pi-skills](https://github.com/badlogic/pi-skills).
