# src/ Line-of-Code Counter

## Goal

Show one number on the landing page: total lines of real code across  
`src/*.zig` (non-recursive — subfolders under `src/`, if any exist later, are  
excluded).

Recalculated on every site build. Never hardcoded.

## Counting rule

A line counts unless it is:

- empty (blank or whitespace-only),
- a comment (`//`, `///`, `//!`),
- an import line — a line that is only `@import(...)`, e.g.
  `const std = @import("std");` or `pub const polynode = @import("polynode.zig");`.

Example: `src/matryoshka.zig` counts as 0. It contains only SPDX/doc comments  
and `@import`-only lines.

## Two surfaces, one counting function

The same rule must produce the same number everywhere it's shown, so the  
counting logic lives in one place:

- `kitchen/tools/src_loc.py` — `count_src_loc()`, the shared function.
- `kitchen/hooks/count_lines.py` — mkdocs `on_page_markdown` hook. Replaces a
  `{{ src_loc() }}` placeholder in `kitchen/docs/index.md` with the current  
  count. Fires on every `mkdocs build`/`serve`, i.e. every  
  `kitchen/tools/build_site.sh` / `preview_site.sh` run.
- `kitchen/tools/count_src_loc.sh` — standalone script. Runs the same
  function and prints the number to stdout. No site build involved.

## Not yet decided

Nothing pending — which lines count was the only open question and is  
resolved above. Later refinements (e.g. treating multi-line `@import` chains,  
or expanding beyond `src/*.zig`) are out of scope for this stage.
