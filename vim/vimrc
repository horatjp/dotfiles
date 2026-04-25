" ===============================
" 基本設定
" ===============================
syntax enable                       " シンタックスハイライト
set encoding=utf-8                  " 文字エンコーディング
set fileencoding=utf-8              " ファイル保存時のエンコーディング
set fileencodings=utf-8,sjis,euc-jp " 読み込み時の文字コード自動判別
set number                          " 行番号表示
set relativenumber                  " 相対行番号表示(移動に便利)
set cursorline                      " カーソル行をハイライト
set showmatch                       " 対応する括弧を強調表示
set matchtime=1                     " 括弧強調の表示時間

" ===============================
" インデント・タブ設定
" ===============================
set expandtab                      " タブをスペースに変換
set tabstop=4                      " タブ幅
set shiftwidth=4                   " 自動インデント幅
set softtabstop=4                  " タブキー押下時のスペース数
set autoindent                     " 自動インデント
set smartindent                    " スマートインデント

" ファイルタイプ別のインデント設定
augroup fileTypeIndent
    autocmd!
    autocmd FileType javascript,typescript,json,yaml,html,css setlocal tabstop=2 shiftwidth=2 softtabstop=2
    autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
augroup END

" ===============================
" 検索設定
" ===============================
set hlsearch                       " 検索結果をハイライト
set incsearch                      " インクリメンタルサーチ
set ignorecase                     " 大文字小文字を区別しない
set smartcase                      " 大文字が含まれる場合は区別する
set wrapscan                       " 検索時に最後まで行ったら最初に戻る

" ===============================
" 表示設定
" ===============================
set laststatus=2                   " ステータスラインを常に表示
set cmdheight=2                    " コマンドラインの高さ
set showcmd                        " 入力中のコマンドを表示
set wildmenu                       " コマンドライン補完を拡張モードに
set wildmode=list:longest,full     " 補完モード
set list                           " 不可視文字を表示
set listchars=tab:▸\ ,trail:·,extends:»,precedes:«,nbsp:% " 不可視文字の表示方法

" ===============================
" 編集設定
" ===============================
set backspace=indent,eol,start     " バックスペースで削除できるもの
set clipboard=unnamed              " クリップボード連携(WSLでは要設定)
set autoread                       " 外部でファイルが変更されたら自動で読み込む
set hidden                         " バッファを隠せるようにする
set confirm                        " 保存されていないファイルがあるときは確認

" ===============================
" バックアップ・スワップ設定
" ===============================
set nobackup                       " バックアップファイルを作らない
set noswapfile                     " スワップファイルを作らない
set noundofile                     " undoファイルを作らない

" ===============================
" 音・ビープ設定
" ===============================
set belloff=all                    " ビープ音を全て無効化
set visualbell                     " ビープ音の代わりに画面フラッシュ
set t_vb=                          " 画面フラッシュも無効化

" ===============================
" マウス設定
" ===============================
if has('mouse')
    set mouse=a                    " マウス操作を有効化
    if has('mouse_sgr')
        set ttymouse=sgr
    elseif v:version > 703 || v:version is 703 && has('patch632')
        set ttymouse=sgr
    else
        set ttymouse=xterm2
    endif
endif

" ===============================
" カラースキーム
" ===============================
set termguicolors                  " 24bitカラーを有効化
set background=dark                " ダークモード
colorscheme slate
highlight Normal ctermbg=NONE guibg=NONE
highlight NonText ctermbg=NONE guibg=NONE
highlight SpecialKey ctermbg=NONE guibg=NONE
highlight EndOfBuffer ctermbg=NONE guibg=NONE

" ===============================
" ディレクトリ自動作成
" ===============================
augroup vimrc-auto-mkdir
  autocmd!
  autocmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)

  function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir) && (a:force || input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
      call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
    endif
  endfunction
augroup END

" ===============================
" fzf統合
" ===============================
" 環境に応じてfzfのパスを自動検出
if executable('fzf')
  " macOS (Homebrew)
  if isdirectory('/usr/local/opt/fzf')
    set rtp+=/usr/local/opt/fzf
  " macOS (Apple Silicon - Homebrew)
  elseif isdirectory('/opt/homebrew/opt/fzf')
    set rtp+=/opt/homebrew/opt/fzf
  " Linux (Linuxbrew)
  elseif isdirectory('/home/linuxbrew/.linuxbrew/opt/fzf')
    set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf
  " 手動インストール
  elseif isdirectory($HOME . '/.fzf')
    set rtp+=$HOME/.fzf
  endif

  " Ctrl+P でファイル検索
  nnoremap <C-p> :FZF<CR>
endif

" ===============================
" ファイルタイプ別設定
" ===============================
filetype plugin indent on          " ファイルタイプ検出とプラグイン・インデントを有効化

" ===============================
" 末尾の空白を可視化・削除
" ===============================
" 保存時に末尾の空白を自動削除
autocmd BufWritePre * :%s/\s\+$//e

" ===============================
" ファイル末尾に改行を追加
" ===============================
set fixendofline                   " ファイル末尾に改行を自動追加
set endofline                      " ファイル末尾の改行を保持

" ===============================
" キーマッピング
" ===============================
" ESCキー2回で検索ハイライト解除
nnoremap <Esc><Esc> :nohlsearch<CR>


