#!/usr/bin/env bash

set -euo pipefail

extensions=(
  # Python and notebooks
  ms-python.python
  ms-python.debugpy
  ms-python.vscode-python-envs
  astral-sh.ty
  charliermarsh.ruff
  ms-toolsai.jupyter
  ms-toolsai.jupyter-renderers
  ms-toolsai.jupyter-keymap
  ms-toolsai.vscode-jupyter-cell-tags

  # dbt
  innoverio.vscode-dbt-power-user
  samuelcolvin.jinjahtml

  vscodevim.vim
  anthropic.claude-code
)

if ! command -v codium >/dev/null 2>&1; then
  yay -S --needed vscodium-bin
fi

for extension in "${extensions[@]}"; do
  codium --install-extension "$extension"
done

# dbt Power User formats with sqlfmt
uv tool install "shandy-sqlfmt[jinjafmt]"

# VSCodium ignores unregistered folders in its extensions dir, so package the theme
theme_dir="$(dirname "$(realpath "$0")")/../.config/VSCodium/solitude-theme"
vsix="$(mktemp --suffix .vsix)"
trap 'rm -f "$vsix"' EXIT
python3 - "$theme_dir" "$vsix" <<'PY'
import pathlib, sys, zipfile
src, out = pathlib.Path(sys.argv[1]), sys.argv[2]
with zipfile.ZipFile(out, "w") as z:
    for f in src.rglob("*"):
        if f.is_file():
            z.write(f, "extension/" + f.relative_to(src).as_posix())
PY
codium --install-extension "$vsix" --force
