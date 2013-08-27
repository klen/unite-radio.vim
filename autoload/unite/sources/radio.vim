let s:save_cpo = &cpo
set cpo&vim

" Options {{{
" -------
let s:stations = get(g:, 'unite_source_radio_stations', [
    \ ['Digitally Imported: Funky House', 'http://listen.di.fm/public3/funkyhouse.pls' ],
    \ ['Digitally Imported: Progressive', 'http://listen.di.fm/public3/progressive.pls' ],
    \ ['Digitally Imported: Lounge' , 'http://listen.di.fm/public3/lounge.pls' ],
    \ ['Digitally Imported: PsyChill' , 'http://listen.di.fm/public3/psychill.pls' ]
\ ])
let s:play_cmd = get(g:, 'unite_source_radio_play_cmd', '')
let s:process = {}
let s:source = {
\   'action_table': {},
\   'default_action' : 'execute',
\   'hooks': {},
\   'name': 'radio',
\   'syntax': 'uniteSource__Radio'
\}
" }}}

" Unite integration {{{
" -----------------

    function! unite#sources#radio#define()
        return s:source
    endfunction

    fun! s:source.gather_candidates(args, context) "{{{
        return map(copy(s:stations), "{
            \ 'word' : len(s:process) && s:process.url == v:val[1] ? '|P>'.v:val[0].'<P|' : v:val[0],
            \ 'url': v:val[1]
        \ }")
    endfun "}}}

    let s:source.action_table.execute = {'description' : 'play station'}
    fun! s:source.action_table.execute.func(candidate) "{{{
        call unite#sources#radio#play(a:candidate.url)
    endfunction "}}}

    fun! s:source.hooks.on_syntax(args, context) "{{{
        call s:hl_current()
    endfunction "}}}

    fun! s:source.hooks.on_post_filter(args, context) "{{{
        if len(s:process)
            call s:widemessage("Now Playing: " . s:process.url)
        endif
        set statusline=111
    endfunction "}}}

    fun! s:hl_current()
        syntax match uniteSource__Radio_Play  /|P>.*<P|/
            \  contained containedin=uniteSource__Radio
            \  contains
            \  	= uniteSource__Radio_PlayHiddenBegin
            \  	, uniteSource__Radio_PlayHiddenEnd

        syntax match uniteSource__Radio_PlayHiddenBegin '|P>' contained conceal
        syntax match uniteSource__Radio_PlayHiddenEnd   '<P|' contained conceal

        highlight uniteSource__Radio_Play guifg=#888888 ctermfg=Green

    endfun

" }}}

command! -nargs=? MPlay call unite#sources#radio#play(<q-args>)
command! MStop call unite#sources#radio#stop()

if !s:play_cmd
    if executable('/Applications/VLC.app/Contents/MacOS/VLC')
        let s:play_cmd = '/Applications/VLC.app/Contents/MacOS/VLC -Irc --quiet'
    elseif executable('mplayer')
        let s:play_cmd = 'mplayer -quiet -playlist'
    elseif executable('cvlc')
        let s:play_cmd = 'cvlc -Irc --quiet'
    else
        echoerr "Unite-radio player hasnt found. See :help unite-radio"
    endif
endif

fun! unite#sources#radio#play(url) "{{{
    call unite#sources#radio#stop()
    let s:process = vimproc#popen2(s:play_cmd.' '.a:url)
    let s:process.url = a:url
    call s:widemessage("Now Playing: " . s:process.url)
endfunction "}}}

fun! unite#sources#radio#stop() "{{{
    if len(s:process)
        call s:process.kill(9)
    endif
    let s:process = {}
endfunction "}}}

au VimLeavePre * MStop

fun! s:widemessage(msg) "{{{
    let x=&ruler | let y=&showcmd
    set noruler noshowcmd
    redraw
    echohl Debug | echo strpart(a:msg, 0, &columns-1) | echohl none
    let &ruler=x | let &showcmd=y
endfunction "}}}

let &cpo = s:save_cpo
unlet s:save_cpo
