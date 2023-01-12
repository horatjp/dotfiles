syntax enable
set backspace=indent,eol,start
set encoding=utf-8
set expandtab
set hlsearch
set ignorecase
set laststatus=2
set list listchars=tab:\▸\-
set number
set paste
set shiftwidth=4
set smartcase
set softtabstop=4
set tabstop=4
set wildmenu
set wrapscan
set rtp+=/home/linuxbrew/.linuxbrew/opt/fzf

" Ask if a directory is created when saving a file if it does not already exist.
augroup vimrc-auto-mkdir
  autocmd!
  autocmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)

  function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir) && (a:force || input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
      call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
    endif
  endfunction
augroup END

" Move and scroll cursor with mouse.
if has('mouse')
    set mouse=a
    if has('mouse_sgr')
        set ttymouse=sgr
    elseif v:version > 703 || v:version is 703 && has('patch632')
        set ttymouse=sgr
    else
        set ttymouse=xterm2
    endif
endif
