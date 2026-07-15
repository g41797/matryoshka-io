# Docs-site cleanup candidates (Stage H, deferred)

These files are superseded by the docs restructuring and already dropped from  
`mkdocs.yml` nav. Left in place on disk for owner review — not deleted.

Stub/scratch content, superseded by the new site structure:
- `docs/matryoshka-based-systems.md`
- `docs/concepts/index.md`
- `docs/concepts/print-server-the-system.md`
- `docs/concepts/print-server-with-matryoshka.md`
- `docs/cookbook/index.md`
- `docs/matryoshka-storytelling-003.md`
- `docs/matryoshka-readme-chat.md`
- `docs/matryoshka-io-chat-prolog.md`
- `docs/test-example-story.md`
- `docs/building-blocks/core-concepts.md`
- `docs/building-blocks/observable-by-human.md`

Superseded by their `docs/addendums/*.md` house-style rewrites:
- `docs/slot-vs-ref-counting.md`
- `docs/tag-vs-tagged-union.md`
- `docs/typeErasedQueue-vs-mailbox.md`

Not yet accounted for by any page (see plan's open flags):
- `docs/matryoshka-io-slot-handle-A.png`, `docs/matryoshka-io-slot-handle-B.png` — owner
  decision was to leave alone for now; revisit if a page needs a rendered diagram.

When ready to delete: `mkdocs build --strict` should stay clean (no "not included in nav"  
warnings for these paths) after removal.
