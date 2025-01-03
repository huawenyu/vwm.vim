" VWM main user interface
if exists('g:vwm#active')
    finish
endif
silent! let s:log = logger#getLogger(expand('<sfile>:t'))

"-------------------------------------------Init globals-------------------------------------------
if !exists('g:vwm#pop_order')
  let g:vwm#pop_order = 'both'
endif

if !exists('g:vwm#eager_render')
  let g:vwm#eager_render = v:false
endif

let s:def_layt = {
      \  'default': {
      \      'name': 'default',
      \      'set_all': ['nonu', 'nornu'],
      \      'bot': {
      \          'h_sz': 12,
      \          'init': ['term bash'],
      \          'left': {
      \              'init': ['term bash']
      \          }
      \      }
      \  }
      \}

if !exists('g:vwm#layouts')
    let g:vwm#layouts = s:def_layt
endif

"------------------------------------Normalize node attribrutes-------------------------------------
" Root must be normalized before any child nodes
fun! s:normalize_root(node)

  if !exists('a:node.name')
    let a:node['name'] = 'root'
  endif
  if !exists('a:node.opnBfr')
    let a:node['opnBfr'] = []
  endif
  if !exists('a:node.opnAftr')
    let a:node['opnAftr'] = []
  endif
  if !exists('a:node.clsBfr')
    let a:node['clsBfr'] = []
  endif
  if !exists('a:node.clsAftr')
    let a:node['clsAftr'] = []
  endif
  if !exists('a:node.active')
    let a:node['active'] = 0
  endif
  if !exists('a:node.bid')
    let a:node['bid'] = -1
  endif
  if !exists('a:node.wid')
    let a:node['wid'] = -1
  endif
  if !exists('a:node.focus')
    let a:node['focus'] = 0
  endif
  if !exists('a:node.init')
    let a:node['init'] = []
  endif
  if !exists('a:node.update')
    let a:node['update'] = []
  endif
  if !exists('a:node.restore')
    let a:node['restore'] = []
  endif
  if !exists('a:node.set')
    let a:node['set'] = []
  endif
  if !exists('a:node.set_all')
    let a:node['set_all'] = []
  endif
  "TODO: Cache is the same as setlocal bh=wipe, make that clear.
  if has_key(a:node, 'left')
    call s:inject_abs(a:node.left)
  endif
  if has_key(a:node, 'right')
    call s:inject_abs(a:node.right)
  endif
  if has_key(a:node, 'top')
    call s:inject_abs(a:node.top)
  endif
  if has_key(a:node, 'bot')
    call s:inject_abs(a:node.bot)
  endif

endfun

fun! s:normalize_child(node)
  if !exists('a:node.name')
    let a:node['name'] = "child"
  endif
  if !exists('a:node.v_sz')
    let a:node['v_sz'] = 0
  endif
  if !exists('a:node.h_sz')
    let a:node['h_sz'] = 0
  endif
  if !exists('a:node.bid')
    let a:node['bid'] = -1
  endif
  if !exists('a:node.wid')
    let a:node['wid'] = -1
  endif
  if !exists('a:node.init')
    let a:node['init'] = []
  endif
  if !exists('a:node.update')
    let a:node['update'] = []
  endif
  if !exists('a:node.restore')
    let a:node['restore'] = []
  endif
  if !exists('a:node.focus')
    let a:node['focus'] = 0
  endif
  " set is just a convience wrapper for setlocal cmd
  if !exists('a:node.set')
    let a:node['set'] = ['bh=hide', 'nobl']
  endif
  if !exists('a:node.abs')
    let a:node['abs'] = 0
  endif
endfun

fun! s:normalize_float(node)
  if !exists('a:node.name')
    let a:node['name'] = "float"
  endif
  if !exists('a:node.x')
    echoerr "Missing key x"
  endif
  if !exists('a:node.y')
    echoerr "Missing key y"
  endif
  if !exists('a:node.width')
    echoerr "Missing key width"
  endif
  if !exists('a:node.height')
    echoerr "Missing key height"
  endif
  if !exists('a:node.relative')
    let a:node['relative'] = 'editor'
  endif
  if !exists('a:node.bid')
    let a:node['bid'] = -1
  endif
  if !exists('a:node.wid')
    let a:node['wid'] = -1
  endif
  if !exists('a:node.init')
    let a:node['init'] = []
  endif
  if !exists('a:node.update')
    let a:node['update'] = []
  endif
  if !exists('a:node.restore')
    let a:node['restore'] = []
  endif
  if !exists('a:node.focus')
    let a:node['focus'] = 0
  endif
  if !exists('a:node.focusable')
    let a:node['focusable'] = 1
  endif
  if !exists('a:node.anchor')
    let a:node['anchor'] = 'NW'
  endif
  if !exists('a:node.set')
    let a:node['set'] = ['bh=hide', 'nobl']
  endif

endfun

" Make abs = v:true default for first layer of child nodes
fun! s:inject_abs(node)
  if !exists('a:node.abs')
    let a:node.abs = v:true
  endif
endfun

fun! s:normalize_helper(node, type, cache)
  if a:type == 0
    call s:normalize_root(a:node)
  elseif 1 <= a:type && 4 >= a:type
    call s:normalize_child(a:node)
  elseif a:type == 5
    call s:normalize_float(a:node)
  endif
endfun


fun! s:normalize()
    for [next_key, next_node] in items(g:vwm#layouts)
        let iterCtx = {'depth': 0}
        call vwm#util#traverse(next_node, function('s:normalize_helper'), v:null
                    \, v:true, v:true, v:true, 0, iterCtx)
    endfor
endfun


" Initialize vwm.vim
call s:normalize()
call vwm#init()
let g:vwm#active = 1

"------------------------------------------public commands------------------------------------------
command! VwmReinit call s:normalize()
command! -nargs=+ VwmOpen call vwm#open(<f-args>)
command! -nargs=+ VwmClose call vwm#close(<f-args>)
command! -nargs=+ VwmToggle call vwm#toggle(<f-args>)
command! -nargs=0 VwmCloseAll call call('vwm#close', vwm#util#active())
command! -nargs=0 VwmRefresh call vwm#refresh()
command! -nargs=+ VwmResize call vwm#resize(<f-args>)
command! -nargs=+ VwmUpdate call vwm#update(<f-args>)

