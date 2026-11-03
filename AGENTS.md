# DOX framework

- DOX is highly performant AGENTS.md hierarchy installed here
- Agent must follow DOX instructions across any edits

## Core Contract

- AGENTS.md files are binding work contracts for their subtrees
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it

## Read Before Editing

1. Read the root AGENTS.md
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules
7. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX

Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.

## Update After Editing

Every meaningful change requires a DOX pass before the task is done.

Update the closest owning AGENTS.md when a change affects:

- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- AGENTS.md creation, deletion, move, rename, or index contents

Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts may leave docs unchanged, but the DOX pass still must happen.

## Hierarchy

- Root AGENTS.md is the DOX rail: project-wide instructions, global preferences, durable workflow rules, and the top-level Child DOX Index
- Child AGENTS.md files own domain-specific instructions and their own Child DOX Index
- Each parent explains what its direct children cover and what stays owned by the parent
- The closer a doc is to the work, the more specific and practical it must be

## Child Doc Shape

- Create a child AGENTS.md when a folder becomes a durable boundary with its own purpose, rules, responsibilities, workflow, materials, or quality standards
- Work Guidance must reflect the current standards of the project or user instructions; if there are no specific standards or instructions yet, leave it empty
- Verification must reflect an existing check; if no verification framework exists yet, leave it empty and update it when one exists

Default section order:
- Purpose
- Ownership
- Local Contracts
- Work Guidance
- Verification
- Child DOX Index

## Style

- Keep docs concise, current, and operational
- Document stable contracts, not diary entries
- Put broad rules in parent docs and concrete details in child docs
- Prefer direct bullets with explicit names
- Do not duplicate rules across many files unless each scope needs a local version
- Delete stale notes instead of explaining history
- Trim obvious statements, repeated rules, misplaced detail, and warnings for risks that no longer exist

## Closeout

1. Re-check changed paths against the DOX chain
2. Update nearest owning docs and any affected parents or children
3. Refresh every affected Child DOX Index
4. Remove stale or contradictory text
5. Run existing verification when relevant
6. Report any docs intentionally left unchanged and why

## User Preferences

When the user requests a durable behavior change, record it here or in the relevant child AGENTS.md

## Child DOX Index

This repo is flat (no subfolders) and has no child AGENTS.md. The root owns every file below.

- `setup.sh`: Bash installer and manager for the terminal toolchain described in `README.md`.
  - Commands: `install`, `auto`, `fix`, `doctor`, `update`, `status`, `help`. Options: `-y/--yes`, `-n/--dry-run`. Run with no command for a menu.
  - Targets (`ALL_TARGETS`): getnf, fonts, foot, herdr, zoxide, eza, bat, fd, fzf, delta, atuin, carapace, starship, config. Each target has `do_install_*`, `do_update_*` and `check_*` handlers dispatched by `install_target`, `update_target`, `fix_target`, `doctor_target`, `status_target`. Adding a target means updating `ALL_TARGETS`, `VERSION_CMD` (for binaries), those handlers, and `usage`.
  - Contracts: idempotent; `install` never upgrades; `doctor` and `status` change nothing; `doctor` exits 1 on failures. Every mutating command honors `--dry-run` through `run`, `run_slow` or `as_root_slow`.
  - Shell config lives in a managed block in `~/.bashrc` and `~/.zshrc` between `BEGIN_MARK` and `END_MARK`. Lines outside the block are never touched, and each edited file is backed up as `<file>.tersek-bak.<timestamp>` first. `~/.gitconfig` (delta settings) and `foot.ini` are backed up the same way before changes.
  - Remote installers are downloaded to a temp file, then executed, via `run_remote`.
  - gum is used for UI only in an interactive terminal; `TERSEK_NO_GUM=1` forces plain output.
  - Settings via environment: `FONT_FAMILY`, `FONT_SIZE`, `NERD_FONTS`, `GETNF_TAG`.
  - Verification: `bash -n setup.sh`, `./setup.sh doctor`, `./setup.sh install -n -y`.
- `setup-nushell.sh`: standalone, re-runnable script that installs Nushell, wires Starship for it, and sets herdr to open panes with `nu`. Not called by `setup.sh`.
- `README.md`: human notes to rebuild the terminal on a new machine. Keep tool names, targets and behavior consistent with `setup.sh`.
