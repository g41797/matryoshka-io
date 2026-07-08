#!/usr/bin/env bash
# Renders kitchen/diagrams/src/*.dot into kitchen/docs/assets/diagrams/ as
# SVG (docs site) and PNG (fallback for viewers that don't inline SVG, e.g.
# forums/Discord). Run by hand after editing a .dot source; NOT wired into
# build_site.sh/preview_site.sh/CI — rendered output is committed to git
# and may be hand-tweaked, so nothing here should overwrite it silently
# as part of an automated build.
set -euo pipefail

repo_root="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
src_dir="$repo_root/kitchen/diagrams/src"
out_dir="$repo_root/kitchen/docs/assets/diagrams"

mkdir -p "$out_dir"

for src in "$src_dir"/*.dot; do
    [ -e "$src" ] || continue
    name="$(basename "$src" .dot)"
    dot -Tsvg "$src" -o "$out_dir/$name.svg"
    dot -Tpng "$src" -o "$out_dir/$name.png"
    echo "rendered $name.svg + $name.png"
done
