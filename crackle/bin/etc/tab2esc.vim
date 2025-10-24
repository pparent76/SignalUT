"maps the esc key to the place were it was on the terminal
"where vim was originally developed
set completeopt=menuone,longest
set wildcharm=<Tab>
nnoremap <Tab> <Esc>
vnoremap <Tab> <Esc>gV
onoremap <Tab> <Esc>
cnoremap <S-Tab> <C-C><Esc>
inoremap <expr> <Tab> pumvisible() ? "<C-E>" : "<Esc>`^"
"triggers autocomplete with shift tab
inoremap <expr> <S-Tab> pumvisible() ? "<C-Y>" : "<C-P>"

nnoremap <Space> <Tab>
nnoremap <Backspace> <C-O>
