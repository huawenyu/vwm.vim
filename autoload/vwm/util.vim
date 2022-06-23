" Utility functions for vim window manager

"------------------------------------------Layout traversal-----------------------------------------

" Traversal funcref signatures:
" bfr    :: dict -> int -> a
" aftr   :: dict -> int -> a

" Right recursive traverse and do
" If horz is true traverse top and bot, if vert is true traverse left and right
" node_type = { 0: 'root', 1: 'left', 2: 'right', 3: 'top', 4: 'bot', 5: 'float }
" Cache is an empty dictionary for saving special info through recursion
fun! vwm#util#traverse(target, bfr, aftr, horz, vert, float, node_type, cache)
    let l:o_wid = win_getid()

    if !(a:bfr is v:null)
        if has_key(a:target, 'wid') && a:target.wid != -1 && a:target.wid != win_getid()
            call win_gotoid(a:target.wid)
        endif
        call s:execute(a:bfr, a:target, a:node_type, a:cache)
    endif

    if !exists('a:cache.new')
        let l:wid = win_getid()
        "let l:bnr = bufnr('%')
    endif

    " Save the buffer id at each level
    if a:vert
        if has_key(a:target, 'left')
            call vwm#util#traverse(a:target.left, a:bfr, a:aftr, v:true, v:true, v:true, 1, a:cache)

            "call win_gotoid(l:wid)
            "execute(bufwinnr(l:bnr) . 'wincmd w')
        endif
        if has_key(a:target, 'right')
            call vwm#util#traverse(a:target.right, a:bfr, a:aftr, v:true, v:true, v:true, 2, a:cache)

            "call win_gotoid(l:wid)
            "execute(bufwinnr(l:bnr) . 'wincmd w')
        endif
    endif

    if a:horz
        if has_key(a:target, 'top')
            call vwm#util#traverse(a:target.top, a:bfr, a:aftr, v:true, v:true, v:true, 3, a:cache)

            "call win_gotoid(l:wid)
            "execute(bufwinnr(l:bnr) . 'wincmd w')
        endif
        if has_key(a:target, 'bot')
            call vwm#util#traverse(a:target.bot, a:bfr, a:aftr, v:true, v:true, v:true, 4, a:cache)

            "call win_gotoid(l:wid)
            "execute(bufwinnr(l:bnr) . 'wincmd w')
        endif
    endif

    if a:float
        if has_key(a:target, 'float')
            call vwm#util#traverse(a:target.float, a:bfr, a:aftr, v:true, v:true, v:true, 5, a:cache)
        endif
    endif

    if !(a:aftr is v:null)
        if !exists('a:cache.new')
            call win_gotoid(l:wid)
            "execute(bufwinnr(l:bnr) . 'wincmd w')
        endif

        call s:execute(a:aftr, a:target, a:node_type, a:cache)
    endif

    call win_gotoid(l:o_wid)
endfun


"-----------------------------------------------Misc------------------------------------------------

" If a funcref is given, execute the function. Else assume list of strings
" Arity arg represents a list of arguments to be passed to the funcref
fun! s:execute(target, ...)
    if type(a:target) == 2
        let l:Vwm_Target = s:apply_funcref(a:target, a:000)
        call l:Vwm_Target()
    else
        for l:Cmd in a:target
            if type(l:Cmd) == 2
                let l:Vwm_Target = s:apply_funcref(l:Cmd, a:000)
                call l:Vwm_Target()
            else
                execute(l:Cmd)
            endif
        endfor
    endif
endfun

fun! s:apply_funcref(f, args)
    if a:args != [v:null] && len(a:args)
      let l:F = function(eval(string(a:f)), a:args)
    else
      let l:F = a:f
    endif
    return l:F
endfun

" If Target is a funcref, return it's result. Else return Target.
fun! s:get(Target)
  if type(a:Target) == 2
    return a:Target()
  else
    return a:Target
  endif
endfun


" Returns the node in g:vwm#layouts with a given name
fun! vwm#util#lookup(name)
    let __func__ = 'vwm#util#lookup() '

    if ! has_key(g:vwm#layouts, a:name)
        echoerr __func__..a:name.." not in dictionary"
        return -1
    endif

    return get(g:vwm#layouts, a:name)
endfun


" Returns true if the buffer exists in a currently visable window
fun! s:buf_active(bid)
  return bufwinnr(a:bid) == -1 ? v:false : v:true
endfun

" Retruns a list of all active layouts
fun! vwm#util#active()
    let l:active = []

    for [next_key, next_node] in items(g:vwm#layouts)
        if next_node.active
            let l:active += [next_node]
        endif
    endfor
    return l:active
endfun

" ... = ignore
fun! s:wipe_aux_bufs(ls_init, ...)
    for l:bid in s:get_active_bufs()
        if index(a:ls_init, l:bid) < 0 && index(a:000, l:bid) < 0
            execute(l:bid . 'bw')
        endif
    endfor
endfun

fun! s:get_active_bufs()
  let l:ret = []
  for l:bid in range(1, bufnr('$'))
      if bufexists(l:bid)
          let l:ret += [l:bid]
      endif
  endfor

  return l:ret
endfun

" So I can break up the script into multiple parts without exposing multiple public functions
fun! vwm#util#SID()
  return s:SID()
endfun

fun! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun
