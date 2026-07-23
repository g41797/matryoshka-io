# Matryoshka-Tk rebrand — post-rename checklist

Written before the GitHub repo rename/clone, for a **future session with no
memory of this one**, running in the freshly cloned `matryoshka-tk` folder.
Read this in full before touching anything rebrand-related.

## Safe/unsafe substitution rule (read first)

Never replace a bare `io`/`Io` token. Only replace when it is the **project
name**, matched as a whole compound:

- Safe pattern: `[Mm]atryoshka[- ][Ii]o\b` (e.g. `matryoshka-io`,
  `Matryoshka-Io`, `Matryoshka Io`) → replace with the `tk` equivalent.
- Also safe, handled separately (does not match the pattern above):
  `master-Io` (file `design/master-Io.md`, already renamed to
  `master-Tk.md` in this stage) — a one-off name, not the general pattern.
- Never touch: `std.Io`, `Io.Threaded`, `Io.Evented`, `io.concurrent`,
  `io.async`, `io.select`, `io:` parameters, `const io = ...` aliases,
  `kitchen/docs/addendums/io-101` (Zig's real `std.Io`, not this project),
  generic prose "I/O".

## Already done in this stage (local repo, before rename) — do not redo

- Renamed files matching `-io-`/`-Io-`: 12 files across `design/`,
  `kitchen/docs/`, `kitchen/_logo/`, `kitchen/defer/` (design docs, logos,
  `matryoshka-io-notation.md` → `matryoshka-tk-notation.md`,
  `what-is-matryoshka-io.md` → `what-is-matryoshka-tk.md`,
  `master-Io.md` → `master-Tk.md`).
- Ran the safe-regex text replacement (`matryoshka-io`/`Matryoshka-Io`/
  `Matryoshka Io` → `tk` equivalents, plus `master-Io` → `master-Tk`)
  across ~30 live files: `README.md`, `design/*.md` (incl. `candidates/`,
  `stories/`), `kitchen/docs/**/*.md`, `kitchen/mkdocs.yml`,
  `kitchen/defer/**/*.md`. This covers `kitchen/mkdocs.yml`'s `repo_url`/
  `repo_name` and every README badge/link URL (they used the same
  `matryoshka-io` substring).
- Verified `std.Io`/`Io.Threaded`/`io-101` untouched by diffing for those
  strings post-sed — zero hits.
- `build.zig.zon` package name (`.matryoshka`) confirmed unaffected —
  contains no "io", never touched.
- Verified 167/167 tests still pass (`kitchen/build_and_test_debug.sh`),
  `zig build docs` clean, `mkdocs build -s` clean (no new dead links from
  the renames — the "not in nav" notices for `the-shape.md` etc. are
  pre-existing, unrelated to this rebrand).
- **Explicitly excluded**: `design/STATUS-LOG.md` — append-only historical
  session log. Old entries describing past work correctly still say
  "matryoshka-io" because that was the name at the time; do not rewrite
  history. New entries going forward use the new name naturally.

## Deferred to this future session (manual work, needs judgment)

- **Local absolute paths.** `design/STATUS.md` "Sources of Truth" section
  and elsewhere reference
  `/home/g41797/dev/root/github.com/g41797/matryoshka-io/` (old folder).
  Update every such absolute path to the new clone location
  (`.../matryoshka-tk/`).
- **Git remote / repo slug references** beyond what the mechanical pass
  caught: double check `.github/workflows/*.yml` (if any hardcode the old
  repo slug beyond what GitHub's auto-redirect covers), any CI badge or
  link not matched by the `matryoshka-io` substring (e.g. if written with
  unusual casing/spacing).
- **Conceptual/mindset prose.** This stage did a mechanical name swap only.
  Any framing language that reads awkwardly now, or that should be
  rewritten to reflect "Toolkit for Building Multitasking Systems in Zig"
  as a positioning statement (not just a find-replace), needs a human
  editorial pass — README intro, manifesto, landing candidates.
- **Ambiguous "Io" mentions.** Skim for any remaining bare `Io`/`io` that
  turns out, on inspection, to actually mean the project (missed by the
  regex because of unusual formatting) — fix by hand, don't broaden the
  regex.
- **`design/STATUS.md` and plan file pointers.** Update `STATUS.md` and
  the implementation plan to reference this checklist as done, and point
  at the next plan version (per the plan-versioning rule — collapse this
  REBRAND stage to a one-line summary once it's confirmed complete).
- **`.idea/matryoshka-io.iml`** — local JetBrains project file, gitignored,
  not part of the repo. Rename/regenerate it locally if desired; not a
  repo concern.
- **`docs/`** — generated GitHub Pages output, gitignored, rebuilt by
  `mkdocs build`/CI. No manual edits needed; just rebuild after clone.
