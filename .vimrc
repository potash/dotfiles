call pathogen#infect()
colorscheme zenburn
:set guioptions-=T  "remove toolbar
set guifont=Monospace\ 14
" tab
set tabstop=8 softtabstop=0 expandtab shiftwidth=4 smarttab

" syntax highlighting
syn on
syntax enable

set pastetoggle=<F2>

set grepprg=grep\ -nH\ $*

let g:Tex_CompileRule_dvi = 'latex -src-specials -interaction=nonstopmode $*'
let g:Tex_CompileRule_pdf = 'pdflatex -shell-escape -interaction nonstopmode $*'
let g:Tex_DefaultTargetFormat = 'pdf'
let g:Tex_MultipleCompileFormats='pdf,bibtex,pdf'
let g:Tex_GotoError=0

let g:Tex_ViewRuleComplete_dvi = 'xdvi -s 8 -keep -editor "gvim --servername xdvi --remote +\%l \%f" $* &'
let g:Tex_ViewRuleComplete_pdf = 'xpdf $*.pdf* &'
let g:tex_flavor='latex'
let g:Tex_UseEditorSettingInDVIViewer = 1

let g:Tex_IgnoredWarnings =
    \'Underfull'."\n".
    \'Overfull'."\n".
    \'specifier changed to'."\n".
    \'You have requested'."\n".
    \'Missing number, treated as zero.'."\n".
    \'There were undefined references'."\n".
	\'LaTeX Font Warning:'."\n".
    \'Latex Warning:'."\n".
    \'Citation %.%# undefined'

" This is an example vimrc that should work for testing purposes.
" Integrate the VimOrganizer specific sections into your own
" vimrc if you wish to use VimOrganizer on a regular basis. . .

"===================================================================
" THE NECESSARY STUFF
" The three lines below are necessary for VimOrganizer to work right
" ==================================================================
let g:ft_ignore_pat = '\.org'
filetype plugin indent on
" and then put these lines in vimrc somewhere after the line above
au! BufRead,BufWrite,BufWritePost,BufNewFile *.org 
au BufEnter *.org            call org#SetOrgFileType()
" let g:org_capture_file = '~/org_files/mycaptures.org'
command! OrgCapture :call org#CaptureBuffer()
command! OrgCaptureFile :call org#OpenCaptureFile()
syntax on

"==============================================================
" THE UNNECESSARY STUFF
"==============================================================
"  Everything below here is a customization.  None are needed.
"==============================================================

" The variables below are used to define the default Todo list and
" default Tag list.  Both of these can also be defined 
" on a document-specific basis by config lines in a file.
" See :h vimorg-todo-metadata and/or :h vimorg-tag-metadata
" 'TODO | DONE' is the default, so not really necessary to define it at all
let g:org_todo_setup='TODO DOING | DONE'
" OR, e.g.,:
"let g:org_todo_setup='TODO NEXT STARTED | DONE CANCELED'

" include a tags setup string if you want:
let g:org_tags_alist='{@home(h) @work(w) @tennisclub(t)} {easy(e) hard(d)} {computer(c) phone(p)}'
"
" g:org_agenda_dirs specify directories that, along with 
" their subtrees, are searched for list of .org files when
" accessing EditAgendaFiles().  Specify your own here, otherwise
" default will be for g:org_agenda_dirs to hold single
" directory which is directory of the first .org file opened
" in current Vim instance:
" Below is line I use in my Windows install:
" NOTE:  case sensitive even on windows.
let g:agenda_files = ['/home/eric/docs/org/todo.org']

function! OrgCustomColors()
    " various Org syntax item highlighting statements below
    " are the current defaults. Uncomment and edit a line if you
    " want different highlighting for the element.

    " Below are defaults for any TODOS you define. TODOS that
    " come before the | in a definition will use 'NOTDONETODO'
    " and those that come after are DONETODO
    hi! DONETODO guifg='#7F9F7F'
    hi! NOTDONETODO guifg='#CC9393'
endfunction

" vimwiki
set nocompatible
let g:vimwiki_hl_headers=1
let g:vimwiki_folding='list'

" mutt
autocmd FileType mail set spell
