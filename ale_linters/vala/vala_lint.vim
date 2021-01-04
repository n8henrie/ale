" Author: Atsuya Takagi <asoftonight@gmail.com>
" Description: A linter for Vala using Vala-Lint.

let g:ale_vala_vala_lint_enable_config = get(g:, 'ale_vala_vala_lint_enable_config', 0)
let g:ale_vala_vala_lint_config_filename = get(g:, 'ale_vala_vala_lint_config_filename', 'vala-lint.conf')

function! ale_linters#vala#vala_lint#GetCommand(buffer) abort
    let l:command = 'io.elementary.vala-lint '

    if ale#Var(a:buffer, 'vala_vala_lint_enable_config')
        let l:config_filename = ale#Var(a:buffer, 'vala_vala_lint_config_filename')
        let l:config_path = ale#path#FindNearestFile(a:buffer, l:config_filename)
        if !empty(l:config_path)
            let l:command .= '-c ' . l:config_path . ' '
        endif
    endif

    return l:command . '%s'
endfunction

function! ale_linters#vala#vala_lint#Handle(buffer, lines) abort
    let l:pattern = '^\s*\(\d\+\)\.\(\d\+\)\s\+\(error\|warn\)\s\+\(.\+\)\s\([A-Za-z0-9_\-]\+\)'
    let l:output = []

    for l:line in a:lines
        " remove color escape sequences since vala-lint doesn't support
        " output without colors
        let l:cleaned_line = substitute(l:line, '\e\[[0-9;]\+[mK]', '', 'g')
        let l:match = matchlist(l:cleaned_line, l:pattern)

        if len(l:match) == 0
            continue
        endif

        let l:refined_type = l:match[3] is# 'warn' ? 'W' : 'E'
        let l:cleaned_text = substitute(l:match[4], '^\s*\(.\{-}\)\s*$', '\1', '')

        let l:lnum = l:match[1] + 0
        let l:column = l:match[2] + 0
        let l:type = l:refined_type
        let l:text = l:cleaned_text
        let l:code = l:match[5]

        call add(l:output, {
        \   'lnum': l:lnum,
        \   'col': l:column,
        \   'text': l:text,
        \   'type': l:type,
        \   'code': l:code,
        \})
    endfor

    return l:output
endfunction

call ale#linter#Define('vala', {
\   'name': 'vala-lint',
\   'output_stream': 'stdout',
\   'executable': 'io.elementary.vala-lint',
\   'command': function('ale_linters#vala#vala_lint#GetCommand'),
\   'callback': 'ale_linters#vala#vala_lint#Handle',
\   'lint_file': 1,
\})
