# Matryoshka Zig — Documentation Plan (002)

New version of `matryoshka-io-docs-plan-001.md`. That version is stale (frozen at INTR 5),
listed superseded doc versions, and predates the mkdocs decision below. Superseded, not
overwritten — see `matryoshka-io-docs-plan-001.md` for the prior version.

---

## Session Log

### 2026-07-03 — DOC 1 session (docs plan created)
**Participants**: human + Claude

Full record of this session's decisions and findings, kept at the top of this doc per
owner instruction: all session info goes at the very beginning of the doc plan.

**Decisions made this session**:
- Docs will not be planned as one big upfront effort — work proceeds iteratively, stage by
  stage (DOC 1, DOC 2, ...), scoped only when reached.
- Docs will mix mkdocs-generated pages (from markdown) with content generated from Zig
  sources (autodocs).
- Sibling repo `tofu` (`/home/g41797/dev/root/github.com/g41797/tofu`) is the prototype for
  this mkdocs + autodocs approach — read for reference, not yet borrowed from.
- `kitchen/` folder rule confirmed: tofu scatters its housekeeping files across many
  locations (root scripts, `docs_site/`, `docs/`, `.github/workflows/`), but matryoshka-io
  follows the Odin `matryoshka` repo's convention instead — all tools/scripts/configs live
  under `kitchen/` and its subfolders only.
- Audit method: read files directly inline in this session (not delegated to a subagent),
  owner explicitly chose this over an Explore-agent delegation for full traceability.
- Audit paths confirmed by owner: tofu repo (whole repo, not just one folder — housekeeping
  is scattered there); Odin `matryoshka/kitchen/`; matryoshka-io's own `kitchen/`.

**What was produced this session**:
- Full audit of tofu's doc-generation flow (scripts, `build.zig` docs step, mkdocs config,
  CI workflow, local-preview gap) — see "Stage DOC 1" section below for the tables and
  flow diagram.
- Comparison note: Odin `matryoshka/kitchen/` has dedicated preview scripts that tofu lacks.
- Finding: matryoshka-io already has `.github/workflows/docs.yml` (copied from tofu) with no
  supporting infra yet built — open item for a future DOC stage.
- This file (`matryoshka-io-docs-plan-002.md`) created as the new version of
  `matryoshka-io-docs-plan-001.md` (stale, frozen at INTR 5).
- `design/context.md` and `design/STATUS.md` updated to point at this version; a matching
  DOC 1 entry added to STATUS.md's own Session Log.

**Also confirmed/saved to Claude memory this session** (persists across future sessions,
not just this doc): docs-tooling decision, tofu-as-prototype pointer, kitchen/ rule pointer.

---

## Background (read first)

- Docs will be a mix of mkdocs-generated pages (from markdown) and content generated from
  Zig sources (autodocs). Owner decision.
- Sibling Zig project `tofu` (`/home/g41797/dev/root/github.com/g41797/tofu`) is the working
  prototype for this approach. Its doc flow is audited below.
- `kitchen/` folder rule: all tools, scripts, configs, and other housekeeping infrastructure
  live under `kitchen/` and its subfolders — same purpose as the Odin `matryoshka` repo's
  `kitchen/` (`/home/g41797/dev/root/github.com/g41797/matryoshka/kitchen`).
- Work proceeds iteratively, stage by stage (DOC 1, DOC 2, ...). No whole-project plan in
  advance — each stage is scoped and executed on its own.
- Current project state (see `STATUS.md`): 161/161 tests passing. Stage 9 (Docs) is next
  after EXMPL 4c. Two stories complete, 66 example files, sources of truth at rules-010,
  patterns-008, plan-031, model-003, api-reference-016.

---

## Stage DOC 1 — tofu audit (this version)

Audit only. No borrowing, no implementation, no `kitchen/` or `.zig` changes this stage.

### Housekeeping layout in tofu

Unlike matryoshka/matryoshka-io's single `kitchen/` folder, tofu's housekeeping is
scattered: root scripts (`docs_zig.sh`, `docs_site.sh`), `docs_site/` (mkdocs project),
`docs/` (generated output, committed), `.github/workflows/docs.yml` (CI), plus unrelated
root scripts (`zbta_*.sh`) and editor config (`.idea`, `.vscode`, `.run`).

### Doc flow — scripts and responsibilities

| Script/file | Responsibility |
|---|---|
| `build.zig` `docs` step (`b.step("docs", ...)`) | `zig build docs` — builds two `addObject` targets (`tofu` lib, `cookbook` recipes) with `use_llvm`/`use_lld`, installs each `getEmittedDocs()` output via `addInstallDirectory` into `docs_site/docs/apidocs` and `docs_site/docs/recipes` respectively |
| `docs_zig.sh` | Thin wrapper: `zig build docs`, prints progress lines |
| `docs_site.sh` | Full local build: calls `docs_zig.sh`, then `cd docs_site && mkdocs build` — one-shot, no serve |
| `docs_site/mkdocs.yml` | mkdocs-material config: nav, theme, plugins (awesome-pages, minify, open-in-new-tab, git-revision-date-localized); `site_dir: ../docs` (output goes to repo-root `docs/`, the GitHub Pages source) |
| `docs_site/docs/mds/*.md` | Hand-written narrative doc pages (overview, mantra, installation, patterns, etc.) — the "from md" half |
| `docs_site/docs/index.md`, `blog/index.md` | Site home + blog stub |
| `docs_site/overrides/partials`, `docs_site/scripts` | Present but empty — no custom theme overrides or dedicated scripts actually in use yet |
| `.github/workflows/docs.yml` | CI: on push to `main` touching `docs_site/**`, `src/**`, `recipes/**`, `build.zig` → checkout, setup-zig, run `docs_zig.sh`, install mkdocs-material + plugins via pip, `mkdocs build`, upload+deploy to GitHub Pages |
| `docs/` (repo root) | Committed generated output (`mkdocs build` target dir) — apidocs, mds output, recipes wasm bundle, sitemap |

### Local preview — gap found

No dedicated script. `_notes.txt` records manual commands only — `mkdocs serve` (implied,
standard mkdocs) is not used; instead notes show
`python3 -m http.server 8080 --directory zig-out/docs_site/docs/recipes/` for the recipes
wasm demo. tofu has no committed "regenerate + preview locally" single script; workflow is
ad hoc.

### Flow diagram (as it exists in tofu today)

```
Local:
  zig build docs  ->  docs_site/docs/{apidocs,recipes}/   (autodoc, generated-from-source half)
  cd docs_site && mkdocs build  ->  ../docs/               (final site, md + autodoc merged)
  (no committed local-preview script; manual `python -m http.server` noted for one case)

CI (.github/workflows/docs.yml, push to main):
  checkout -> setup-zig 0.15.2 -> docs_zig.sh (zig build docs)
  -> pip install mkdocs-material + 4 plugins -> mkdocs build (in docs_site/)
  -> upload-pages-artifact (path: docs/) -> deploy-pages
```

### Cross-repo comparison

matryoshka-io already has `.github/workflows/docs.yml` — an exact copy of tofu's (same
paths, same pip plugins, same steps) — but none of the supporting infra exists yet: no
`docs_zig.sh`, no `docs_site/`, no `build.zig` `docs` step, no committed `docs/` output.
The CI workflow was pre-copied ahead of the infra it depends on. Open item for a future
DOC stage: decide whether to keep it pre-copied or hold back until infra exists.

Odin matryoshka's approach differs: `kitchen/mkdocs.yml` + `kitchen/tools/build_site.sh`,
`generate_apidocs.sh`, `preview_apidocs.sh`, `preview_site.sh` (dedicated preview scripts,
unlike tofu) + `kitchen/docs/apidocs` (committed odin-doc output) — everything under one
`kitchen/` folder, consistent with matryoshka-io's own `kitchen/` convention. Its CI
(`.github/workflows/docs.yml`) not read this pass — odin-language specific tooling
(`odin-doc` binary instead of `zig build docs`); flag for later comparison only if useful,
since matryoshka-io is Zig, not Odin.

---

## Stage DOC 2 — confirm tofu + Odin "mix" decision

Decision + audit only, this version. Not yet implemented — DOC 3+ will build it.

### Odin `matryoshka/kitchen/` audit

Full contents read: `.github/workflows/docs.yml`, `kitchen/mkdocs.yml`,
`kitchen/tools/build_site.sh`, `generate_apidocs.sh`, `preview_apidocs.sh`,
`preview_site.sh`, `get_odin_doc.sh`.

What Odin's `kitchen/` already has, self-contained in one folder (matching
matryoshka-io's own `kitchen/` convention, unlike tofu's scattered layout):
- `kitchen/mkdocs.yml` — mkdocs-material config, `docs_dir: docs`, `site_dir: output`
  (both relative to `kitchen/`, not repo root like tofu).
- `kitchen/tools/build_site.sh` — one-shot: regenerate apidocs, then `mkdocs build`.
- `kitchen/tools/preview_apidocs.sh` — regenerate apidocs, `python3 -m http.server 8000`
  on `kitchen/docs/apidocs` only. tofu has no equivalent (its `_notes.txt` only notes a
  manual one-off command for the recipes wasm demo).
- `kitchen/tools/preview_site.sh` — regenerate apidocs, `mkdocs serve` (full site, live
  reload). tofu has no equivalent either (`docs_site.sh` only does a one-shot build).
- `.github/workflows/docs.yml` — checkout, install libcmark, build the `odin-doc` renderer,
  install mkdocs-material, `build_site.sh`, upload+deploy — all paths scoped under
  `kitchen/`.

The one piece Odin cannot provide: `generate_apidocs.sh` + `get_odin_doc.sh` clone and
build an external HTML renderer (`pkg.odin-lang.org`'s `odin-doc` tool), because Odin has
no built-in doc-emit mechanism, then apply extensive `sed` post-processing (relative-path
rewriting, cache-busting, asset-copying, blank-nav-link fixes) — all workarounds for that
specific renderer's quirks. None of this applies to Zig.

### Conclusion — mix confirmed

matryoshka-io's doc infra should mix the two:
- Layout, organization, CI shape, local-preview scripts — borrow from Odin
  `matryoshka/kitchen/` (single-folder convention already required by matryoshka-io's own
  rules; preview scripts tofu lacks).
- Autodoc generation mechanism — borrow from tofu's `build.zig` `docs` step
  (Zig-native `getEmittedDocs()`), replacing Odin's external-renderer approach, which does
  not apply to Zig at all.

### Additional audit (3 findings)

1. **Zig `getEmittedDocs()` output needs no post-processing, confirmed.** tofu's generated
   `docs_site/docs/apidocs/` is just 4 files — `index.html`, `main.js`, `main.wasm`,
   `sources.tar` — a client-side WASM app that renders docs dynamically from the bundled
   `sources.tar`. `grep` for absolute `href="/"` paths found zero matches. Architecturally
   nothing like Odin's per-package static HTML tree — no analogous
   relative-path/asset-copy/cache-busting problem to work around.
2. **matryoshka-io needs 3 doc targets, not tofu's 2.** tofu's `docs` step builds 2
   `addObject` targets: `tofu` (lib) + `cookbook` (recipes, imports `tofu` + `mailbox`).
   matryoshka-io's `build.zig` already defines the equivalent shape but with three modules:
   `matryoshka` (`src/matryoshka.zig`, the lib), `examples` (`examples/examples.zig`,
   imports `matryoshka` + `helpers`), `stories` (`stories/stories.zig`, imports `matryoshka`
   + `helpers`) — plus an unexported `helpers` module used by both. A future `docs` step
   should add one `addObject`+`getEmittedDocs()`+`addInstallDirectory` target per module
   (3, or 4 if `helpers` also gets its own docs page).
3. **mkdocs nav content needs fresh authoring, not a 1:1 borrow.** Odin's `mkdocs.yml` nav
   is one page-pair (quickref + deepdive) per architecture block, sourced from
   `kitchen/docs/block*_{quickref,deepdive}.md`. matryoshka-io's existing `kitchen/docs/*.md`
   are a different shape — topical asides (storytelling docs, slot-vs-ref-counting,
   tag-vs-tagged-union, typeErasedQueue-vs-mailbox, test-example-story), not a per-layer
   quickref/deepdive pair — and matryoshka-io's real narrative source of truth lives in
   `design/` (rules, patterns, model, api-reference, stories), not `kitchen/docs/`. Neither
   prototype's nav can be borrowed as-is; nav content and structure need fresh authoring in
   a later DOC stage.

---

## Stage DOC 3 — kitchen/ doc folder layout proposal + "DOCS folder" claim check

Analysis + advice only, this version. No `.zig`, `build.zig`, `mkdocs.yml`, or actual
`kitchen/` subfolders created this stage — DOC 4+ will build it.

### Must-rule re-confirmed

All doc housekeeping — mkdocs config, generation/preview scripts, hand-written narrative
`.md` sources — must live under `kitchen/` and its subfolders. Matches Odin `matryoshka`
convention (see `[[reference_odin_matryoshka]]` memory); no new evidence contradicts it.

### "DOCS folder" claim — checked against both prototypes, refuted as stated

matryoshka-io's current pre-copied `.github/workflows/docs.yml` has:
```yaml
- uses: actions/upload-pages-artifact@v3
  with:
    path: docs/
```
Copied verbatim from tofu, where it only makes sense because tofu's `docs_site/mkdocs.yml`
sets `site_dir: ../docs` — mkdocs deliberately escapes `docs_site/` and writes the built
site into a **top-level `docs/`** folder at repo root. That's a build artifact placed
outside tofu's own housekeeping folder — the same scattered-layout problem DOC 1/DOC 2
already flagged in tofu.

Odin `matryoshka` does **not** do this: `kitchen/mkdocs.yml` sets `site_dir: output`
(i.e. `kitchen/output/`, relative to `kitchen/`), and its `.github/workflows/docs.yml`
points `upload-pages-artifact` directly at `path: kitchen/output` — no top-level `docs/`
folder exists or is needed. `actions/upload-pages-artifact` accepts any path, nested or
not; there is no GitHub Pages requirement that the artifact source be named `docs/` or
live at repo root — that naming only matters for the older, non-Actions "deploy from a
branch" Pages mode, which neither tofu nor Odin nor matryoshka-io uses.

**Conclusion**: matryoshka-io does **not** need a new top-level `DOCS` folder. Keeping
`site_dir` under `kitchen/` (Odin-style) satisfies GitHub Pages deployment identically
while also satisfying the must-rule. matryoshka-io's pre-copied `docs.yml` currently still
points at the tofu-style top-level `path: docs/` — this needs fixing once `site_dir` is
finalized in a build stage, or it will silently deploy an empty/missing artifact.

### Proposed folder/file layout (advice only, nothing created)

```
kitchen/
  mkdocs.yml                 # site_dir: output  (mkdocs config, Odin-style)
  docs/                      # hand-authored narrative source pages for mkdocs nav
    index.md                 # new: site landing page
    <existing *.md>           # matryoshka-storytelling-*.md, slot-vs-ref-counting.md,
                              # tag-vs-tagged-union.md, typeErasedQueue-vs-mailbox.md,
                              # test-example-story.md, matryoshka-readme-chat.md,
                              # matryoshka-io-chat-prolog.md — kept as-is, added to nav
    apidocs/                  # generated: matryoshka (src) module's getEmittedDocs() output
    examplesdocs/             # generated: examples module's getEmittedDocs() output —
                              # stories folded in here too (examples imports it, just like
                              # tofu's single "cookbook" target already imports mailbox),
                              # so the split stays 2-way (src vs examples), matching tofu
  tools/
    docs_zig.sh                # new: `zig build docs` wrapper (replaces tofu's docs_zig.sh)
    build_site.sh               # new: docs_zig.sh + mkdocs build (Odin-style one-shot)
    preview_apidocs.sh           # new: regenerate + local http.server, Odin-style
    preview_site.sh               # new: regenerate + mkdocs serve, Odin-style
  _logo/                          # existing, unchanged
```

Key differences from both prototypes:
- **2 generated-doc subfolders — src vs examples — matching tofu's split exactly**
  (tofu: `apidocs` for the `tofu` lib, `recipes` for the combined `cookbook` target).
  matryoshka-io: `apidocs` for `matryoshka` (src), `examplesdocs` for `examples`, with
  `stories` folded into the `examples` doc target rather than getting its own subfolder —
  same way tofu's `cookbook` target already pulls in `mailbox` alongside its own recipes.
  **This supersedes DOC 2 finding #2's "3 targets" note** — owner has directed a 2-way
  split (src/examples), not 3.
- `kitchen/docs/*.md` narrative pages already exist — DOC 3 only proposes adding an
  `index.md` landing page and wiring existing files into `mkdocs.yml`'s `nav:`, not moving
  or renaming them.
- `.github/workflows/docs.yml` needs updating: `path:` under `upload-pages-artifact`
  changes from `docs/` to `kitchen/output` (or whatever `site_dir` DOC 4+ finalizes), and
  the "Regenerate Autodoc Artifacts" step's `./docs_zig.sh` becomes
  `./kitchen/tools/docs_zig.sh` (or `zig build docs` directly — `build.zig` has no `docs`
  step yet either; that's implementation, deferred to a later DOC stage).

### Open items carried forward

- matryoshka-io's `.github/workflows/docs.yml` needs fixing: wrong `path:` (`docs/` should
  become `kitchen/output`), and references a non-existent `docs_zig.sh` and `build.zig`
  `docs` step — flagged for the stage that actually builds the infra.
- mkdocs nav content still needs fresh authoring (DOC 2 finding #3, unchanged).

---

## Stage DOC 4 — build the kitchen/ doc infra, verify locally

Implementation stage: turned the DOC 3 proposal into working infra, exactly per that
layout (2-way src/examples split, no top-level `DOCS` folder, everything under `kitchen/`).

### What was built
- `build.zig` — added a `docs` step: `addObject`+`getEmittedDocs()`+`addInstallDirectory`
  for `matryoshka` (src) → `kitchen/docs/apidocs`, and for a doc-only `edocsMod` (the
  `examples/examples.zig` root source, importing `matryoshka` + `helpers` + `stories`) →
  `kitchen/docs/examplesdocs`. `edocsMod` is separate from the runtime `emod` — folds
  `stories` in for docs purposes only, mirroring tofu's `cookbookMod` importing `mailbox`,
  without changing the existing `examples` module's public import graph.
- `kitchen/mkdocs.yml` (new) — Odin-style, `site_dir: output` (→ `kitchen/output/`),
  `docs_dir: docs`, material theme, nav wiring the 9 existing narrative `.md` files plus
  the new `index.md`; only the `search` plugin (tofu's 4 extra plugins dropped — unused).
- `kitchen/docs/index.md` (new) — landing page linking to `apidocs/`, `examplesdocs/`, and
  the narrative docs.
- `kitchen/tools/docs_zig.sh`, `build_site.sh`, `preview_apidocs.sh`, `preview_site.sh`
  (new, executable) — Odin-style path resolution (`dirname "$(readlink -f "$0")"`), no
  Odin-specific `odin-doc`/sed post-processing needed (Zig's autodoc is native).
- `.gitignore` — added `/kitchen/docs/apidocs/`, `/kitchen/docs/examplesdocs/`,
  `/kitchen/output/` (build artifacts).
- `.github/workflows/docs.yml` — fixed trigger `paths:` to match matryoshka-io's actual
  layout (`src/**`, `helpers/**`, `examples/**`, `stories/**`, `kitchen/**`, `build.zig`),
  fixed the autodoc step to `./kitchen/tools/docs_zig.sh`, fixed the mkdocs build step to
  `cd kitchen && mkdocs build -f mkdocs.yml` with only `mkdocs-material` installed, fixed
  `upload-pages-artifact` `path:` to `kitchen/output`.

### Local verification
- `zig build docs` — succeeded; `kitchen/docs/apidocs/` and `kitchen/docs/examplesdocs/`
  populated with Zig autodoc HTML/JS/WASM.
- `bash kitchen/tools/build_site.sh` — succeeded; `kitchen/output/index.html` built, with
  `apidocs/`, `examplesdocs/`, and all narrative pages present and linked in the nav.
- `zig build test -freference-trace --summary all` — 161/161 tests still pass; the new
  doc-only `edocsMod` doesn't disturb the existing build graph.
- All script output redirected to `zig-out/*.log` and inspected via `Read`/`grep`, per the
  kitchen-script-output rule — no raw stdout read.

### Deviations from the DOC 3 proposal
None — layout, script set, and 2-way target split matched the proposal exactly.

### Follow-up — reference-page nav/UX (still DOC 4 scope)
Odin's `kitchen/docs/api_reference.md` gives readers a choice ("Open here" vs "Open in new
tab") before linking into its standalone generated API site. Owner directed matryoshka-io
to skip the choice: both `apidocs/` and `examplesdocs/` are standalone generated sites
(Zig autodoc HTML/JS/WASM, not mkdocs pages), so both always open in a new tab, no prompt.
Added `kitchen/docs/api_reference.md` and `kitchen/docs/examples_reference.md` (each a
single `.md-button` with `target="_blank" rel="noopener"`), wired into a new `Reference`
nav section in `kitchen/mkdocs.yml`, and updated `kitchen/docs/index.md`'s landing links to
route through these pages instead of linking `apidocs/index.html`/`examplesdocs/index.html`
directly. Verified in the built output: both buttons render with `target="_blank"
rel="noopener"`. `zig build test` still 161/161.

---

## Stages

DOC 1 — tofu audit. DONE.
DOC 2 — confirm tofu + Odin mix decision (audit only). DONE.
DOC 3 — kitchen/ doc folder layout proposal + DOCS-folder claim check. DONE (analysis only).
DOC 4 — build kitchen/ doc infra (build.zig docs step, mkdocs.yml, tools/, docs.yml fix), verify locally. DONE.
DOC 5+ — TBD. Planned iteratively, one stage at a time, not in advance.

---

## References

- [matryoshka-model-003.md](matryoshka-model-003.md) — thinking model
- [rules-010.md](rules-010.md) — coding, doc, and process rules
- [patterns-008.md](patterns-008.md) — reusable coding patterns
- [matryoshka-io-docs-plan-001.md](matryoshka-io-docs-plan-001.md) — prior version, superseded
- tofu repo: `/home/g41797/dev/root/github.com/g41797/tofu`
- Odin matryoshka repo: `/home/g41797/dev/root/github.com/g41797/matryoshka`
