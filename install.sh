#!/usr/bin/env bash
# runcom をこのマシンに展開する。
# 既存ファイルは *.bak.<timestamp> に退避してからシンボリックリンクに置き換える。
# 何度実行しても同じ結果になる（冪等）。
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ts="$(date +%Y%m%d%H%M%S)"

link() {
  local src="$repo/$1" dst="$2"

  if [[ ! -e $src ]]; then
    echo "skip    $1 (リポジトリに存在しない)" >&2
    return
  fi

  mkdir -p "$(dirname "$dst")"

  if [[ -L $dst ]]; then
    if [[ "$(readlink "$dst")" == "$src" ]]; then
      echo "ok      $dst"
      return
    fi
    rm "$dst"
  elif [[ -e $dst ]]; then
    mv "$dst" "$dst.bak.$ts"
    echo "backup  $dst -> $(basename "$dst").bak.$ts"
  fi

  ln -s "$src" "$dst"
  echo "link    $dst"
}

link .zshrc            "$HOME/.zshrc"
link .vimrc            "$HOME/.vimrc"
link .gitconfig        "$HOME/.gitconfig"
link .gitignore_global "$HOME/.gitignore_global"
link init.el           "$HOME/.emacs.d/init.el"

# git の identity はマシンごとに持つ（リポジトリには入れない）
if [[ ! -f "$HOME/.gitconfig.local" ]]; then
  cat > "$HOME/.gitconfig.local" <<'EOF'
[user]
	name =
	email =
EOF
  echo ""
  echo "作成: ~/.gitconfig.local — user.name と user.email を書いてください"
fi

echo ""
echo "完了。新しいシェルを開くか 'exec zsh' で反映されます。"
