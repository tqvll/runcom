# runcom

macOS 用の dotfiles。`install.sh` がホームディレクトリからこのリポジトリへシンボリックリンクを張る。

## インストール

```sh
git clone <this repo> ~/git/runcom
~/git/runcom/install.sh
```

既存のファイルは `*.bak.<timestamp>` に退避される。何度実行しても安全。

## 構成

| ファイル | リンク先 | 内容 |
| --- | --- | --- |
| `.zshrc` | `~/.zshrc` | Prezto の読み込み、PATH、ヒストリ、エイリアス、ファジーファインダ |
| `.vimrc` | `~/.vimrc` | Vim 9 の標準機能だけで構成（プラグインマネージャ無し） |
| `.gitconfig` | `~/.gitconfig` | 現代的な既定値とエイリアス |
| `.gitignore_global` | `~/.gitignore_global` | OS とエディタが撒くファイルの無視設定 |
| `init.el` | `~/.emacs.d/init.el` | Emacs 29 以降向けのモダン構成（28 では自動フォールバック） |

## マシン固有の設定

リポジトリに入れたくない設定（identity、社用の環境変数など）は各ファイルの末尾から読み込まれる
ローカルファイルに書く。いずれも任意。

| ファイル | 用途 |
| --- | --- |
| `~/.gitconfig.local` | `user.name` / `user.email`（**未設定だと commit できない**） |
| `~/.zshrc.local` | ホスト固有の環境変数、PATH |
| `~/.vimrc.local` | Vim の追加設定 |
| `~/.emacs.d/local.el` | Emacs の追加設定 |

## 前提

- zsh + [Prezto](https://github.com/sorin-ionescu/prezto)（`~/.zprezto` に clone 済みであること）
- Vim 9 以降（macOS 同梱の `/usr/bin/vim` で可）
- Emacs 29 以降を推奨（28 でも動くが、補完まわりが簡易版になる）

## 入れておくと有効になるもの

設定側はすべて「入っていれば使う」条件分岐になっているので、無くても壊れない。

```sh
brew install fzf eza bat ripgrep fd zoxide git-delta
```

| ツール | 効果 |
| --- | --- |
| `fzf` | Ctrl-R / Ctrl-T / Alt-C がファジー検索になる（無ければ `peco` を使う） |
| `eza` | `ls` / `ll` / `la` / `lt` が git 対応の表示になる |
| `bat` | `cat` がシンタックスハイライト付きになる |
| `ripgrep` | Vim の `:grep` が rg 経由になる |
| `gopls` など | Emacs の eglot がその言語でだけ自動起動する |
