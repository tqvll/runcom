" ~/.vimrc — managed in ~/git/runcom
" Vim 9 以降を想定。プラグインマネージャは使わず、標準機能だけで完結させる。

" vi 互換モードで起動された場合でも行継続などが壊れないようにする
if &compatible
  set nocompatible
endif

scriptencoding utf-8

" ---------------------------------------------------------------- 文字コード
set encoding=utf-8
set fileencodings=utf-8,cp932,euc-jp,iso-2022-jp
set fileformats=unix,dos,mac
set ambiwidth=double          " ○△□ などの全角記号を2桁幅で扱う

" ---------------------------------------------------------------- 基本動作
filetype plugin indent on
syntax enable

" Vim 9 に同梱されている標準パッケージ（プラグイン追加なしで使える）
silent! packadd! matchit      " % で if/end や HTML タグも対応付ける
silent! packadd comment       " gcc / gc{motion} でコメントをトグル
silent! packadd hlyank        " ヤンクした範囲を一瞬ハイライト
silent! packadd editorconfig  " .editorconfig を自動で尊重する

set hidden
set autoread
set confirm
set history=10000
set updatetime=250
set timeoutlen=500
set ttimeoutlen=10
set belloff=all
set mouse=a
set clipboard=unnamed         " ヤンク内容をシステムのクリップボードと共有
set backspace=indent,eol,start
set formatoptions+=j          " 行連結時にコメント記号を消す
set nrformats-=octal          " 007 を8進数扱いしない

" ---------------------------------------------------------------- ファイル
set nobackup
set nowritebackup
set noswapfile
" undo はセッションをまたいで永続化する
let s:undodir = expand('~/.vim/undo')
if !isdirectory(s:undodir)
  call mkdir(s:undodir, 'p', 0700)
endif
let &undodir = s:undodir
set undofile

" ---------------------------------------------------------------- 見た目
if has('termguicolors') && $COLORTERM =~# 'truecolor\|24bit'
  set termguicolors
endif
set background=dark
silent! colorscheme habamax   " Vim 9 標準添付のダークテーマ

set number
set cursorline
set showcmd
set ruler
set laststatus=2
set showmatch
set matchtime=1
set scrolloff=5
set sidescrolloff=8
set display=lastline
set signcolumn=auto
set list
" ambiwidth=double だと全角扱いの記号（» · › ‹ など）は listchars に使えないので
" 半角幅が保証される記号だけを使う
set listchars=tab:▸\ ,trail:␣,extends:▸,precedes:◂,nbsp:⍽

" ---------------------------------------------------------------- インデント
set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set shiftround
set autoindent
set smartindent
set breakindent

augroup vimrc_indent
  autocmd!
  autocmd FileType yaml,json,html,css,scss,javascript,typescript,vue,sh,zsh
        \ setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd FileType lisp,scheme,clojure setlocal tabstop=2 softtabstop=2 shiftwidth=2
  autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4
  autocmd FileType markdown setlocal wrap linebreak
augroup END

" ---------------------------------------------------------------- 検索
set ignorecase
set smartcase
set incsearch
set hlsearch
set wrapscan
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case
  set grepformat=%f:%l:%c:%m
endif

" ---------------------------------------------------------------- 補完 / コマンドライン
set wildmenu
set wildmode=longest:full,full
if has('patch-8.2.4325')
  set wildoptions=pum         " コマンドライン補完をポップアップで出す
endif
set completeopt=menuone,noselect
set path+=**                  " :find でプロジェクト内を再帰検索

" ---------------------------------------------------------------- ウィンドウ
set splitbelow
set splitright

" ---------------------------------------------------------------- キーマップ
let mapleader = "\<Space>"

" Esc Esc でハイライト解除
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>

" 検索結果を画面中央に置く
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap * *zzzv
nnoremap # #zzzv

" 表示行単位で移動（折り返し行でも直感的に動く）
nnoremap <expr> j v:count ? 'j' : 'gj'
nnoremap <expr> k v:count ? 'k' : 'gk'

" よく使う操作
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
nnoremap <leader>e :edit<Space>
nnoremap <leader>f :find<Space>
nnoremap <leader>b :buffers<CR>:buffer<Space>

" 権限を忘れて開いたファイルを sudo で保存する
cnoremap w!! w !sudo tee >/dev/null %

" ---------------------------------------------------------------- 自動処理
" 前回閉じたときのカーソル位置を復元する
function! s:restore_cursor() abort
  let l:pos = line("'\"")
  if l:pos >= 1 && l:pos <= line('$') && &filetype !~# 'commit\|rebase'
    execute 'normal! g`"'
  endif
endfunction

augroup vimrc_misc
  autocmd!
  autocmd BufReadPost * call s:restore_cursor()
augroup END

" ---------------------------------------------------------------- マシン固有設定
if filereadable(expand('~/.vimrc.local'))
  source ~/.vimrc.local
endif
