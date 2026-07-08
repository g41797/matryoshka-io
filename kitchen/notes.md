# Kitchen Notes

Running notes about `kitchen/` tooling and generated content — what's
generated vs. hand-authored, what's safe to edit directly. Not a
versioned design doc (no no-overwrite rule) — edit in place.

## Generated vs. hand-authored under kitchen/docs/

**Generated — rewritten on every `gen_examples_docs.sh` run, don't edit
by hand, edits will be lost**:
- `kitchen/docs/examples/layer1/*.md`
- `kitchen/docs/examples/layer2/*.md`
- `kitchen/docs/examples/layer3/*.md`
- `kitchen/docs/examples/layer4/*.md`
- `kitchen/docs/examples/items/*.md`
- `kitchen/docs/examples/hooks/*.md`
- `kitchen/docs/examples/helpers/*.md`
- `kitchen/docs/examples/stories/**/*.md`
- `kitchen/docs/apidocs/` (Zig autodoc output, `zig build docs`)

**Hand-authored — safe to edit directly, script never touches these**:
- `kitchen/docs/examples/index.md` — catalog overview
- `kitchen/docs/examples/polynode.md` — How-to PolyNode group
- `kitchen/docs/examples/mailbox.md` — How-to Mailbox group
- `kitchen/docs/examples/pool.md` — How-to Pool group
- `kitchen/docs/examples/io.md` — How-to Io (Select/Group/Future) group
- `kitchen/docs/examples/flow.md` — Flow (Master compositions) group

Reminder (rules-021, "Examples-catalog nav sync"): adding/removing/renaming
a file under `examples/`/`stories/` means updating both the relevant group
page above and `kitchen/mkdocs.yml`'s Examples Catalog `nav:` block — the
generation script only mirrors `.zig` files, it never touches either.
