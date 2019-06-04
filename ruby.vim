function! s:DebugStringFun(desc, var)
    let l:debug_str = 'puts "' . g:DebugstringPrefixStr() . g:debugStringCounter . ' '. a:var . '"'
    return l:debug_str
endfunc

function! s:DebugStringFunExpr(expr)
    let l:debug_str = 'puts "' . g:FilelocationPrefixStr() . ' '
                \ . a:expr . ': '
                \ . '#{' . a:expr . '}'
                \ . '"'
    return l:debug_str
endfunc


" command! -buffer -nargs=0 AddDebugString put=s:DebugStringFun()
command! -buffer -nargs=0 AddDebugString
            \ put=s:DebugStringFun(g:DebugstringPrefixStr(), g:debugStringCounter)
command! -buffer -nargs=1 AddDebugStringExpr put=s:DebugStringFunExpr(<args>)
