-- title:   Immunia
-- author:  Bitwise Creative
-- desc:    Simple immunity puzzle game
-- site:    https://github.com/bitwisecreative/immunia
-- license: MIT License
-- version: 0.1
-- script:  lua

-- TODO: title screen
-- TODO: win/lose
-- TODO: move anims and such

-- menu: OPEN
-- requires "menu:" meta tag above...
  -- I tried everything to find a way to force open the TIC-80 game menu from code, including scouring the source code for holes.
  -- I found nada... Best bet is to create a custom menu that can be accessed by ` key or clicking menu button or a custom menu item in TIC-80 menu.
  -- TIC-80 mobile web implementation could use some improvements...
function opengamemenu()
  screen='menu'
end
GameMenu={opengamemenu}
function MENU(i)
  GameMenu[i+1]()
end

-- INIT
function BOOT()

  --pmem(0,0)
  trace('-- BOOT --')

  -- pmem map
  -- 0 = current level
  -- 1 = bgm

  -- seed rng
  math.randomseed(tstamp())

  -- int won't overflow like pico8...
  f=0

  -- current screen
  screen='game'
  --screen='title'

  -- screen size
  sw=240
  sh=136

  -- cell grid is 32px 4x4 :[]
  gsx=4
  gsy=4

  -- cells
  cells={}

  -- move
  movespeed=9
  movesperlevel=13 -- this was max solution moves from _levelgen db
  move={
    n=movesperlevel,
    p=false, -- processed
    x=0,
    y=0,
    f=0
  }

  arrowblink={false,2} -- visible, frame switch

  -- swipe detection
  swipeminmove=20
  swipe={
    x=0,
    y=0,
    b=false
  }

  -- testmap
  testmap='w0000,w1111,w2222,w3333,,,,,,,b3333,,,,,x' -- state_string...
  testmap=false

  -- bgm
  -- music(0)

  -- tiny font
  tf=tfont:new()

  -- set global levels var
  set_levels()
  -- get current level
  level=pmem(0)
  if level<1 then level=1 end
  -- random level if maxed
  if level>#levels then level=rint(1,#levels) end
  level_string=levels[level]
  -- testmap?
  if testmap then level_string=testmap end

  -- generate cells
  state_string(level_string)
  --trace(state_string())

end

-- WHAMMY!
function TIC()

  f=f+1
  cls(0)

  if screen=='title' then
    draw_title()
  end

  if screen=='help' then
    draw_help()
  end

  if screen=='menu' then
    draw_menu()
  end

  if screen=='game' then
    draw_game()
  end

end

function draw_title()
  print("Title",3,5,2,false,2)
end

function draw_help()
  print("Help",3,5,2,false,2)
end

function draw_menu()
  print("Menu",3,5,2,false,2)
end

function draw_game()
  -- frame
  rect(0,0,112,136,1)
  rect(0,128,240,8,1)

  -- title
  -- print(text x=0 y=0 color=15 fixed=false scale=1 smallfont=false) -> width`
  print("Immunia",3,5,2,false,2)
  print("Immunia",3,3,10,false,2)
  print("Immunia",3,4,0,false,2)
  line(3,18,76,18,0)

  -- level
  print("Level: ",3,30,0,false,1)
  print(numpad(level,3),38,30,10,false,1)

  -- division
  print("Bacteria",3,46,0,false,1)
  print("Division:",3,54,0,false,1)
  for ty=-1,1 do
    for tx=-1,1 do
      print(numpad(move.n,2),55+tx,48+ty,0,false,2)
    end
  end
  print(numpad(move.n,2),55,48,2,false,2)

  -- ;)
  bxoffset=1
  spr(240,0+bxoffset,127)
  print("itwisecreative.com",9+bxoffset,129,0)

  -- draw game board (grid style so empty can be dot)
  for y=1,gsy do
    for x=1,gsx do
      cell=get_cell_at(x,y)
      if cell then
        draw_cell(cell)
      else
        draw_empty(x,y)
      end
    end
  end

  -- controls
  local mx,my,mb=mouse()
  if move.f==0 then
    -- Controller/Arrows, WASD
    if btnp(0) or keyp(23) then
      move.x=0
      move.y=-1
      move.f=f
      move.n=move.n-1
    end
    if btnp(1) or keyp(19) then
      move.x=0
      move.y=1
      move.f=f
      move.n=move.n-1
    end
    if btnp(2) or keyp(1) then
      move.x=-1
      move.y=0
      move.f=f
      move.n=move.n-1
    end
    if btnp(3) or keyp(4) then
      move.x=1
      move.y=0
      move.f=f
      move.n=move.n-1
    end
    -- Swipe
    local mdir={
      x=0,
      y=0
    }
    local movedx=swipe.x-mx
    local movedy=swipe.y-my
    local absmovedx=math.abs(movedx)
    local absmovedy=math.abs(movedy)
    if absmovedx>=swipeminmove or absmovedy>=swipeminmove then
      if absmovedx>=absmovedy then
        -- x
        if movedx<0 then
          mdir.x=1
          mdir.y=0
        else
          mdir.x=-1
          mdir.y=0
        end
      else
        -- y
        if movedy<0 then
          mdir.x=0
          mdir.y=1
        else
          mdir.x=0
          mdir.y=-1
        end
      end
    end
    if mb~=swipe.b then
      if mb then
        swipe.x=mx
        swipe.y=my
      else
        if absmovedx>=swipeminmove or absmovedy>=swipeminmove then
          move.x=mdir.x
          move.y=mdir.y
          move.f=f
          move.n=move.n-1
        end
      end
      swipe.b=mb
    else
      if mb then
        --line(swipe.x,swipe.y,mx,my,1)
        if mdir.y==-1 then
          draw_arrow('up')
        end
        if mdir.y==1 then
          draw_arrow('down')
        end
        if mdir.x==-1 then
          draw_arrow('left')
        end
        if mdir.x==1 then
          draw_arrow('right')
        end
      end
    end
  else
    if f-move.f>=movespeed then
      reset_move()
      reset_cell_processed()
    end
  end

  -- inline tutorial
  local tut={}
  table.insert(tut,{
    'Welcome to Immunia!',
    'A simple puzzle game about',
    'white blood cells trying to',
    'kill all the bacteria. Move',
    'the cells with up, down, left,',
    'and right (swiping supported)',
    'to attack the bacteria.',
  })
  table.insert(tut,{
    'Good! Pretty simple, right?',
    'The lines inside the cells',
    'protect the nucleus. Attack',
    'the exposed nucleus to kill',
    'the cell. If all your cells',
    'die, but still killed all the',
    'bacteria, that\'s a win!',
  })
  table.insert(tut,{
    'Great! Just a couple more',
    'things... Spaces can be',
    'blocked. But, the map has',
    'wrap-around movement. Move',
    'right on this map until you',
    'clear it to see for yourself.',
  })
  table.insert(tut,{
    'Wonderful! One last thing...',
    'Bacteria will divide every 13',
    'moves. Be sure to kill them',
    'quickly! Enjoy the game!'
  })
  if tut[level]~=nil then
    rectb(80,0,200,#tut[level]*9+1,0)
    rect(81,0,200,#tut[level]*9,15)
    local tuty=2
    local tutc=11
    for _,line in pairs(tut[level]) do
      print(line,83,tuty,tutc)
      tuty=tuty+9
    end
  end

  -- move arrows
  -- arrows
  if f%arrowblink[2]==0 then arrowblink[1]= not arrowblink[1] end
  if arrowblink[1] then
    if move.y==-1 then
      draw_arrow('up')
    end
    if move.y==1 then
      draw_arrow('down')
    end
    if move.x==-1 then
      draw_arrow('left')
    end
    if move.x==1 then
      draw_arrow('right')
    end
  end

  -- calculate move
  if move.f>0 and not move.p then
    process_move(move.x,move.y)
    -- check win (before game over check...)
    local bacteria_cells=get_cell_count('bacteria')
    if bacteria_cells==0 then
      pmem(0,level+1)
      reset()
    else
      -- check game over
      local wbc_cells=get_cell_count('wbc')
      if wbc_cells==0 then
        reset()
        trace('lose')
      end
    end
    process_division()
    -- move processed...
    move.p=true
  end

  -- debug
  local debugx=2
  local debugy=100
  local debugc=5
  tf:print('level: '..level,debugx,debugy,debugc)
  tf:print('move: '..move.x..','..move.y..','..move.n,debugx,debugy+4,debugc)
  tf:print('mouse: '..mx..','..my..','..bint(mb),debugx,debugy+8,debugc)
  tf:print('swipe: '..swipe.x..','..swipe.y..','..bint(swipe.b),debugx,debugy+12,debugc)

end

-- build state from string, or return current state as string
function state_string(str)
  if str then
    local a = split(str, ',')
    if #a ~= gsx * gsy then
      error('State string: invalid length.')
    end
    cells = {}
    local tok = {'', 'x', 'w', 'b'}
    for i = 1, #a do
      local gv=i-1
      local x=(gv%gsx)+1;
      local y=(math.floor(gv/gsy))+1;
      local t = string.sub(a[i], 1, 1)
      if not tcontains(tok, t) then
        error('State string: invalid type.')
      end
      -- shields
      if t == 'w' or t == 'b' then
        if string.len(a[i]) ~= 5 then
          error('State string: invalid cell data (shield).')
        end
        local type = t == 'w' and 'wbc' or 'bacteria'
        local shield = {0, 0, 0, 0}
        for s = 1, 4 do
          local v = tonumber(string.sub(a[i], s + 1, s + 1))
          shield[s] = v
        end
        local cell = gen_cell(type, x, y)
        cell.s = shield
        table.insert(cells, cell)
      end
      if t == 'x' then
        local cell = gen_cell('blocked', x, y)
        table.insert(cells, cell)
      end
    end
  else
    local out = {}
    for y = 1, gsy do
      for x = 1, gsx do
        local cell = get_cell_at(x, y)
        if cell then
          local v = ''
          if cell.t == 'blocked' then
            v = 'x'
          elseif cell.t == 'wbc' then
            v = 'w'
          elseif cell.t == 'bacteria' then
            v = 'b'
          end
          if cell.t == 'wbc' or cell.t == 'bacteria' then
            v = v .. table.concat(cell.s)
          end
          table.insert(out, v)
        else
          table.insert(out, '')
        end
      end
    end
    local outstr = table.concat(out, ',')
    return outstr
  end
end

function process_move(x, y)
  -- set all cell.p to 0 (unprocessed)
  for _, e in pairs(cells) do
    e.p = 0
  end

  local function all_wbcs_move_processed()
    local all_moved = true
    for _, e in pairs(cells) do
      if e.t == 'wbc' and e.p == 0 then
        all_moved = false
        break
      end
    end
    return all_moved
  end

  local function check_row(cell)
    local r = {}
    if x == 0 then
      r = {{cell.x, 1}, {cell.x, 2}, {cell.x, 3}, {cell.x, 4}}
    end
    if y == 0 then
      r = {{1, cell.y}, {2, cell.y}, {3, cell.y}, {4, cell.y}}
    end
    local wbcs = {}
    for i = 1, #r do
      local c = get_cell_at(r[i][1], r[i][2])
      if c and c.t == 'wbc' then
        table.insert(wbcs, c)
      end
    end
    if #wbcs == 4 then
      if x < 0 or y < 0 then
        local tmp = {wbcs[4].x, wbcs[4].y}
        for i = #wbcs, 1, -1 do
          wbcs[i].p = 1
          if i == 1 then
            wbcs[i].x = tmp[1]
            wbcs[i].y = tmp[2]
          else
            wbcs[i].x = wbcs[i - 1].x
            wbcs[i].y = wbcs[i - 1].y
          end
        end
      else
        local tmp = {wbcs[1].x, wbcs[1].y}
        for i = 1, #wbcs do
          wbcs[i].p = 1
          if i == 4 then
            wbcs[i].x = tmp[1]
            wbcs[i].y = tmp[2]
          else
            wbcs[i].x = wbcs[i + 1].x
            wbcs[i].y = wbcs[i + 1].y
          end
        end
      end
    end
  end

  local limiter = 0
  while not all_wbcs_move_processed() do
    limiter = limiter + 1
    if limiter > 100 then
      error('move limiter')
      for _, e in pairs(cells) do
        e.p = 4
      end
    end
    for _, e in pairs(cells) do
      if e.t == 'wbc' and e.p == 0 then
        local tx, ty = gridloc(e.x + x, e.y + y)
        local target = get_cell_at(tx, ty)
        if not target then
          e.p = 1
          e.x = tx
          e.y = ty
        else
          if target.t == 'blocked' then
            e.p = 2
          end
          if target.t == 'wbc' then
            if target.p > 0 then
              e.p = 2
            else
              check_row(e)
            end
          end
          if target.t == 'bacteria' then
            e.p = 3
            local attack_shield = 1
            local defend_shield = 2
            if y == 1 then attack_shield = 2; defend_shield = 1 end
            if x == -1 then attack_shield = 3; defend_shield = 4 end
            if x == 1  then attack_shield = 4; defend_shield = 3 end
            e.s[attack_shield] = e.s[attack_shield] - 1
            if e.s[attack_shield] < 0 then e.d = true end
            target.s[defend_shield] = target.s[defend_shield] - 1
            if target.s[defend_shield] < 0 then target.d = true end
          end
        end
      end
    end
  end

  -- Remove dead cells
  local i = #cells
  while i > 0 do
    if cells[i].d then
      table.remove(cells, i)
    end
    i = i - 1
  end
end

function process_division()
  if move.n<0 then
    move.n=movesperlevel
    local bacs=get_cells_by_type('bacteria')
    for _,cell in pairs(bacs) do
      local open=get_empty_cross_neighbors(cell.x,cell.y)
      if #open>0 then
        local nc=gen_cell('bacteria',open[1][1],open[1][2])
        nc.s=copy(cell.s)
        table.insert(cells,nc)
      end
    end
  end
end

-- stay in grid
function gridloc(x,y)
  if x<1 then x=gsx end
  if x>gsx then x=1 end
  if y<1 then y=gsy end
  if y>gsy then y=1 end
  return x,y
end

function clone_shield(from,to)
  to.s=copy(from.s)
end

function get_cell_count(type)
  local c=0
  for k,cell in pairs(cells) do
    if cell and cell.t==type then c=c+1 end
  end
  return c
end

function get_cells_by_type(type)
  local c={}
  for k,cell in pairs(cells) do
    if cell.t==type then table.insert(c,cell) end
  end
  return c
end

function get_open_cells_from(x,y)
  -- clockwise starting at 12
  local vecs={
    {x,y-1},
    {x+1,y-1},
    {x+1,y},
    {x+1,y+1},
    {x,y+1},
    {x-1,y+1},
    {x-1,y},
    {x-1,y-1}
  }
  -- open cells...
  local o={}
  for k,v in pairs(vecs) do
    -- stay in grid...
    local gx,gy=gridloc(v[1],v[2])
    local c=get_cell_at(gx,gy)
    if not c then table.insert(o,vecs[k]) end
  end
  return o
end

function get_cross_neighbors(x,y)
  local n={}
  local vecs={
    {x,y-1},{x,y+1},{x-1,y},{x+1,y}
  }
  for k,v in pairs(vecs) do
    -- looping grid
    local gx,gy=gridloc(v[1],v[2])
    local cell=get_cell_at(gx,gy)
    if cell then table.insert(n,cell) end
  end
  --
  return n
end

function get_empty_cross_neighbors(x,y)
  local n={}
  local vecs={
    {x,y-1},{x,y+1},{x-1,y},{x+1,y}
  }
  for k,v in pairs(vecs) do
    -- looping grid...
    local gx,gy=gridloc(v[1],v[2])
    local cell=get_cell_at(gx,gy)
    if not cell then table.insert(n,{v[1],v[2]}) end
  end
  --
  return n
end

function get_neighbor_coords(x,y)
  local n={}
  local vecs={
    {x,y-1},{x,y+1},{x-1,y},{x+1,y}
  }
  for k,v in pairs(vecs) do
    -- looping grid...
    local gx,gy=gridloc(v[1],v[2])
    table.insert(n,{gx,gy})
  end
  --
  return n
end

function get_cell_at(x,y)
  -- stay in grid
  x,y=gridloc(x,y)
  for k,cell in pairs(cells) do
    if cell.x==x and cell.y==y then return cell,k end
  end
  return false
end

function get_target_loc(x,y)
  local tx=x+move.x
  local ty=y+move.y
  tx,ty=gridloc(tx,ty)
  return tx, ty
end

function get_reverse_target_loc(x,y)
  local tx=x+-move.x
  local ty=y+-move.y
  tx,ty=gridloc(tx,ty)
  return tx, ty
end

function reset_move()
  move.x=0
  move.y=0
  move.f=0
  move.p=false
end

function reset_cell_processed()
  for k,cell in pairs(cells) do
    cell.p=0
  end
end

function gen_cell(t,x,y)
  local e={
    t=t, -- type (wbc, bacteria, blocked)
    x=x,
    y=y,
    r=rint(0,3),
    f=rint(0,3),
    a=1, -- anim, all use 6 frames (same anims...)
    p=0, -- (move) processed id (0=not processed,1=moved,2=cannot move,3=attacked)
    s={0,0,0,0}, -- shield (up down left right) -> (wbc and bacteria)
    d=false -- destroy
  }
  return e
end

function draw_empty(x,y)
  local sx=(x-1)*32+112
  local sy=(y-1)*32
  local sprnum=96
  spr(sprnum,sx,sy,0,2,0,0,2,2)
end

function draw_cell(c)
  local sx=(c.x-1)*32+112
  local sy=(c.y-1)*32
  local sprnum=0 -- wbc
  local drawshield=false
  local shieldcolor=1
  if c.t=='wbc' then
    drawshield=true
  end
  if c.t=='bacteria' then
    sprnum=32
    drawshield=true
    shieldcolor=0
  end
  if c.t=='virus' then
    sprnum=64 -- no longer used...
  end
  if c.t=='blocked' then
    sprnum=128
  end
  -- spr(id x y colorkey=-1 scale=1 flip=0 rotate=0 w=1 h=1)
  spr(sprnum+((c.a-1)*2),sx,sy,0,2,c.f,c.r,2,2)
  -- shield
  local soffset=-1
  if drawshield then
    -- draw nucleus
    local ncolor=2
    if shieldcolor==1 then ncolor=10 end
    rect(sx+16+soffset,sy+16+soffset,3,3,ncolor) --inside
    rectb(sx+15+soffset,sy+15+soffset,4,4,shieldcolor) -- outside
    -- up
    if c.s[1]>0 then
      for i=1,c.s[1] do
        rect(sx+16+soffset-1,sy+16+(soffset-i)*2,4,1,shieldcolor)
      end
    end
    -- down
    if c.s[2]>0 then
      for i=1,c.s[2] do
        rect(sx+16+soffset-1,sy+16+(i*2)+1,4,1,shieldcolor)
      end
    end
    -- left
    if c.s[3]>0 then
      for i=1,c.s[3] do
        rect(sx+16+(soffset-i)*2,sy+16+soffset-1,1,4,shieldcolor)
      end
    end
    -- right
    if c.s[4]>0 then
      for i=1,c.s[4] do
        rect(sx+16+(i*2)+1,sy+16+soffset-1,1,4,shieldcolor)
      end
    end
  end
  -- draw blocked center
  if c.t=='blocked' then
    --rectb(sx+15+soffset,sy+15+soffset,4,4,4)
  end
  -- global anim update
  if f%7==0 then
    c.a=c.a+1
    if c.a>6 then c.a=1 end
  end
  --
end

function draw_arrow(dir)
  -- `spr(id x y colorkey=-1 scale=1 flip=0 rotate=0 w=1 h=1)`
  local xcenter=112+64-16
  local ycenter=32+16
  if dir=='up' then spr(160,xcenter,0,0,1,0,0,4,2) end
  if dir=='down' then spr(160,xcenter,sh-8-16,0,1,0,2,4,2) end
  if dir=='left' then spr(160,112,ycenter,0,1,0,3,4,2) end
  if dir=='right' then spr(160,sw-16,ycenter,0,1,0,1,4,2) end
end

-- inclusive
function rint(min,max)
  return math.floor(math.random()*(max-min+1))+min;
end

-- bool to int
function bint(b)
  return b and 1 or 0
end

-- dump table...
function tdump(t,no_keys)
  out='{'
  for k,v in pairs(t) do
    if type(v)=='table' then
      out=out..tdump(v,no_keys)
    else
      if no_keys then
        out=out..v..', '
      else
        out=out..k..':'..v..', '
      end
    end
  end
  out=string.sub(out,0,#out-2)..'}, '
  return out
end

-- shuffle table in place
function tshuffle(t)
  for i = #t, 2, -1 do
    local j = math.random(i)
    t[i], t[j] = t[j], t[i]
  end
end

-- removes nils from table
function tclean(t)
  for i=#t,1,-1 do -- reverse
    if i<=#t and t[i]==nil then
      table.remove(t,i)
    end
  end
end

function tsum(t)
  local n=0
  for k,v in pairs(t) do
    if v and type(v)=='number' then
      n=n+v
    end
  end
  return n
end

function tcontains(t,search)
  for k,v in pairs(t) do
    if v==search then return true end
  end
  return false
end

-- copy table by value
function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

-- left pad numbers with zero
function numpad(num,width)
  local s=tostring(num)
  while #s<width do
    s='0'..s
  end
  return s
end

function clamp(n,min,max)
  if n<min then n=min end
  if n>max then n=max end
  return n
end

-- Tiny Font (3x3)
function ctxtx(str)
  return math.floor((sw/2)-(#str*4)/2) -- screen center x coord for text
end
function split(str,sep)
 local t={}
 local s=''
 if sep == '' then sep=nil end
 for i=1,#str do
  local c=string.sub(str,i,i)
  if sep==nil then
   table.insert(t,c)
  else
   if c==sep then
    table.insert(t,s)
    s=''
   else
    s=s..c
   end
  end
 end
 table.insert(t,s)
 return t
end
tfont={}
tfont.__index=tfont
function tfont:new()
  local this={}
  local font={{},{},{}}
  local map={}
  local st={
    '000010110111110111111111101111111101100111111111111111110011111101101101101101110110111101100111111111010101010000000111010010001100100010000010000111100101010000',
    '000111111100101110110100111010010110100111101101111111110010010101101111010010010010011111111001111111010101111111000011100001010010000101000000010000010000101010',
    '000101111111110111100101101111110101111101101111100001101110010111010111101010011111111001111001111001000000010000100010010010100001001000111010100111000101010000'}
  for k,v in pairs(st) do
    for i=1,#v do
      table.insert(font[k],tonumber(string.sub(v,i,i)))
    end
  end
  this.font=font
  local sm=' ~1|a~2|A~2|b~3|B~3|c~4|C~4|d~5|D~5|e~6|E~6|f~7|F~7|g~8|G~8|h~9|H~9|i~10|I~10|j~11|J~11|k~12|K~12|l~13|L~13|m~14|M~14|n~15|N~15|o~16|O~16|0~16|p~17|P~17|q~18|Q~18|r~19|R~19|s~20|S~20|5~20|t~21|T~21|u~22|U~22|v~23|V~23|w~24|W~24|x~25|X~25|y~26|Y~26|z~27|Z~27|2~27|1~28|3~29|4~30|6~31|7~32|8~33|9~34|\'~35|"~36|+~37|-~38|.~39|?~40|<~41|[~41|{~41|(~41|>~42|]~42|}~42|)~42|/~43|\\~44|%~45|^~46|_~47|:~48|;~48|,~49|=~50|`~51|#~52|*~53'
  local sm1=split(sm,'|')
  for k,v in pairs(sm1) do
    local sm2=split(v,'~')
    map[sm2[1]]=sm2[2]
  end
  this.map=map
  setmetatable(this,tfont)
  return this
end

function tfont:print(s,x,y,c,o)
  s=tostring(s)
  -- lazy...
  if o~=nil then
    for sx=-1,1 do
      for sy=-1,1 do
        self:print(s,x+sx,y+sy,o)
      end
    end
  end
  for i=1,#s do
    local ch=string.sub(s,i,i)
    local id=self.map[ch] or 54
    local xs=id*3-2
    for cy=1,3 do
      for cx=1,3 do
        if self.font[cy][cx-1+xs]==1 then
          local px=x+((i-1)*4)+cx-1
          local py=y+cy-1
          pix(px,py,c)
        end
      end
    end
  end
end

function set_levels()
  -- first 4 levels are tutorial
  levels={
    ',,,,,,w1111,,,,,,b0000,,w1111,',
    ',,,,,,w3333,,,,,,b3333,,w3333,',
    ',,,,,,x,,b3313,b3313,x,w0003,b3313,b3313,x,w0003',
    ',,,,,,,w0330,b1331,b1331,b1331,w0330,b1331,b1331,b1331,w0330',
    ',,w0020,w1013,,b3123,w0200,,,x,w0020,w0130,w1200,b3033,,',
    'w1000,w2010,w0011,w2030,,,b3032,,,,b3333,w0022,,,,',
    ',,,,,,,x,,w1100,,b1333,w1230,,,',
    'w0001,w1000,b3333,w0210,,,w0033,,,,,,,b1233,w2000,w1130',
    ',x,x,,x,w3000,,,b0031,w0000,,,,,w2320,b1231',
    'x,w1000,,,,,,,b1232,,x,w0111,,x,w1333,b2010',
    'b1223,x,w1000,w0010,b1323,b2210,,w0002,w3101,w1012,x,,,w2000,x,b3033',
    ',x,w1200,,,b3233,w3001,,w0002,,w0011,w0110,b3333,,,',
    'x,,w0112,b0233,,b0221,,,w1010,,,w0111,w1131,,w1022,b2320',
    ',,x,,w0231,b3322,,,b2200,b2220,,,w1031,b3322,w0001,w1010',
    'w1010,,w0000,,w1201,,,b3223,,,,,,w1011,b3033,',
    'b2033,w0101,b2303,b2022,,w2100,,w0010,b3123,,,w1021,x,x,w1200,',
    ',,,w1100,,,,,,,w1000,w1000,w1000,b3333,,',
    ',,w0111,,,,,b3213,,,,x,,,,',
    ',,w0100,x,,,,,,,x,,b1132,w0113,,',
    'w1011,,w2011,,b2322,x,,w0130,b1222,,w3212,,,,,',
    'w3130,b2333,w3011,,,b3332,w0200,w1113,,,,,b2232,,x,',
    'w1101,b3232,,,x,,,,,,w0101,,,w1011,,x',
    'x,x,w3011,,,,,,w0011,,,,b3303,,b3123,',
    'x,b2322,,w0102,w1013,,w0011,w0203,,w1111,,b2100,b2023,,x,',
    ',b3333,,w1010,,w1020,b3201,,b0213,w0020,w0100,w3001,,w0211,,x',
    'x,,,,w2200,,,x,,,x,,,,b2122,',
    'w0121,b3222,,w1211,w1121,w1302,,,w1110,b0223,b3233,b0203,,,w1021,',
    'b2332,w1100,,,w0101,w0001,,x,w0131,b2331,,b2223,w1310,w1002,b2133,',
    ',x,,,b3322,,,,w0102,,,,w0301,x,,',
    'w0100,,b1220,,w0111,,,,,w0010,,w0100,w0100,,,b3323',
    'w0132,b1232,,,w1122,w0121,b0222,x,w1110,,w1000,x,b2133,b3232,x,',
    'b3023,w1001,,w1331,b1202,w0301,w0001,,,b1333,w0201,x,w3011,x,x,',
    ',b2222,,,w2120,x,,,,w3010,,,,x,,',
    ',w1013,,b2223,,w0000,b2231,,,x,b2232,w0131,,,w1310,x',
    ',b2303,,,,,,,,w1000,,,,,,',
    ',,,,,,,,b3222,w3001,,,,,,',
    'b2332,w1110,w1012,,,,w1120,x,x,w2110,,,x,b3223,w3100,',
    ',x,,b3322,,,,b3331,w0011,,,x,w1001,w1123,w1000,',
    ',,w1000,b3233,,w0023,w2110,,b0233,,,b1103,,,w0012,w0101',
    ',x,b3331,w1001,,,,,,,,x,w0100,,x,',
    'w1300,,x,,,,b2222,w0002,w0110,w1111,,x,b3233,,,',
    ',,,w1010,,,,b2221,,,,,,,,',
    'w0013,,,w1110,w0200,,w1100,b3223,b2323,,,,w1010,b3302,,w0011',
    ',x,,,w0101,,x,,,b2322,x,w1110,,,,',
    ',,b3222,,,b2232,b3233,w0301,,w0110,w2031,w1023,w1000,,,w0011',
    ',,,,,,,,,w1110,,,w3101,b3331,,',
    'w0121,,,b3233,,w1002,,b3131,,w2012,w0103,b3333,x,,w0000,w0011',
    ',b2312,,x,,b2232,,,,w1021,,,w1100,w2111,,x',
    ',w1111,b3233,,,w0202,,,b2323,w0201,b2213,x,w2111,w0111,,w0001',
    'x,,x,w0102,b2323,,w0110,w0001,x,b0011,,w1031,,,w1010,b2021',
    ',,w1110,w1103,w1000,,w1102,b2323,x,,x,,b2323,w1010,,',
    ',w0000,,w2011,,b3122,w1010,b3323,,w2000,,,,w0101,x,',
    ',x,w1010,,,x,w0101,b3323,b1331,w0010,,w3111,,w3303,,',
    ',,,,,,,b2220,,b3332,w0123,w3101,,w2120,,',
    ',,,,,,,,w2111,b2223,,,x,,,',
    'b3223,x,w1011,,,x,,,,,,b1031,x,w1101,,',
    'w3201,,,x,b1223,,w1301,w2000,x,b3321,,,,,b3003,w1301',
    ',,x,,,,,w0023,,,,x,,,,b2330',
    ',b2223,,w0310,x,x,,,,,x,,,,,',
    ',,x,w1003,w1033,b3233,w0111,,b3300,,w0100,,w0112,,b0033,w0000',
    ',x,w0101,b3323,,w0012,b3232,w2010,,,w1223,w2120,,w0301,x,b2223',
    'b1233,,w1021,b2330,w0000,w0300,x,x,,b3032,w1111,,w1110,x,,w0001',
    'w1332,b3332,b3333,b0223,,w1021,b1333,b1330,,,,w2111,,w0311,w3201,',
    'b3302,b3131,x,,,,,x,w1111,,,x,,,,',
    'x,b2222,,w0300,,w0111,,x,,,,,,,,',
    'b2222,w0011,,b2302,w3111,b2212,w1010,x,,w0001,,x,,w1110,,w1303',
    ',x,,,,,w0100,w1010,,b2332,,,,,,',
    ',w0110,b0232,,,b2232,w1010,,,w2101,w0110,b2232,,w0100,w1100,',
    ',w1010,,,,x,,,,w1000,w0100,,,b1323,x,x',
    'w0113,,,b1032,,,,,,b3313,,x,,,w1011,',
    'b2332,w1110,,x,b2030,w0020,w1201,w0301,b3322,b1132,,,,w1001,x,',
    ',,,b3222,,x,,,,,,,,w1000,,w1013',
    ',,,,w1000,,,,x,,x,,,b3303,,',
    'b2133,,w0102,x,b3122,b2232,x,w1303,w0100,,,x,,,w0301,w0001',
    ',,,x,,w0110,b3222,,,,,x,,w1010,,',
    'b1201,,,b3222,,,w0101,w1110,w0211,,,w3300,,x,x,b2032',
    ',x,x,,,,w0113,,,,b2333,,w3101,,,',
    'b2230,,,,,,,,,,,w1001,,,,',
    'b3301,,w1011,,w1022,b2213,,w1010,,w0110,w0100,,,,b0033,',
    'w3121,,b0233,,,,,,x,,,,,b3022,,',
    ',w1121,b2210,,b2221,,w1230,,b3332,,w0010,,w0000,w3110,,',
    ',,w0000,w1110,,w0102,,,,,w1010,b3323,,b2232,,',
    ',w1011,,,x,,,w1100,b2332,b2003,,,,w2010,,w0002',
    ',,,b0232,,b3302,w1031,,,,,,,,,',
    ',w1311,,,,,w3010,,,,b2322,,,,,b3022',
    ',x,,b0132,w1021,x,w0101,,x,,w1133,w0331,w1121,b0323,,b2321',
    ',b2332,w1111,b3332,,,b2232,b3113,w0313,,w0002,w1110,w0110,,w0003,',
    'b2323,,w2111,x,,,w0103,w0001,,w2101,,x,w0001,,x,b3222',
    'w0102,,,,b2123,x,,,x,,,,,,,',
    'w1010,,w1221,b2323,,w1112,,,w0111,,b3323,,,w0103,x,',
    'w1011,,,b3322,,,,x,,,,w1001,w1110,,,x',
    'x,,w2201,b2331,w0001,,,,b2001,,,,,w1301,x,w0101',
    'w0011,,w0000,,,,b3332,w0301,,,,,,x,,',
    ',w0112,w1020,,,,b3332,w1101,,,,w0131,,b2232,,w0111',
    ',x,,w2100,,,b3322,,,,w2112,,,,,',
    ',,,,,b3233,,w0112,,,,,,w1000,x,x',
    ',,b2323,,,w0310,x,x,w1011,w0101,b2022,,x,w1100,,',
    ',,b0233,w0031,w0310,,x,,,,w0111,b3021,x,,,',
    ',,,,,w3001,,b2330,,,w1110,,b2232,,,w0012',
    'b3220,w0010,,x,b2332,x,,,b2301,w1013,,w2111,x,w0101,,',
    ',w1120,b2221,w0201,w1111,,,b3222,,w0101,w1013,,,w1010,,',
    ',,,,,w0031,,,,,,b3331,x,,,',
    'w1011,,,b2223,x,,w0211,w0031,w0310,w1011,,,w0112,,b0232,b2222',
    ',,,,w1001,,b0233,b2323,,w2113,,,,,,',
    ',w1022,x,,w1001,b0323,,b0323,,w2000,b3322,w2010,,x,w2001,',
    ',,x,,,,,,,,w1003,,,b2330,,x',
    ',,,,,,,b2113,,x,w0001,,,,,',
    'x,,,x,,,,w0000,w1000,w3220,,,w1111,w1030,b3333,',
    ',b1321,w1111,,,w0011,x,w0010,,,,w0130,,x,b2333,',
    ',,w3133,w1100,x,,,x,,,,w0110,b3322,,,b2123',
    ',,x,,,x,x,,b2300,,w0101,,,b0133,,',
    'b0322,,,,,,,,,w0012,x,,,,b2330,',
    'w0111,x,,,,,,,b3232,,x,,,,x,w2001',
    'b3332,w1100,x,x,w0311,w1130,w2031,,,w0100,b3131,w0001,b0323,x,,',
    ',,b3222,,b3233,,,,,,w1331,w0100,,,,',
    ',b3022,,,,,b3202,,,,w3101,,,,,',
    'w1000,,w0131,,b1332,w0111,,b2333,b2332,,,,w1200,w0011,,w0110',
    'w1110,w1010,b3032,w0121,b2233,,x,b1222,,,w0013,,w2231,w1102,,',
    ',,x,,,,,,,,w0110,,,x,w0101,b3133',
    ',,b2232,,,,w0012,,,,,,w1010,,,',
    ',b2322,w1110,w1010,b3322,,,,,x,w1011,x,,,w1121,x',
    ',,,b2212,,,,,,x,,w0001,w0001,,,',
    'w1111,w1103,,w1001,,b3232,,w1311,,w0210,,b1233,b3233,x,w0113,b3322',
    ',,w0130,,,w1111,,w0000,w0023,w1000,b2332,,b3233,,,w0010',
    'w0111,,w1101,w1001,,x,x,,,,,,b2333,b3322,w1001,',
    ',w3111,w1100,x,,,b2222,w1010,,,x,w0013,,b3230,b2222,',
    'b3323,,,,,w0001,b3221,,,,,,,w0101,w0003,',
    ',w0001,,w0000,w0000,w0001,b3033,,w0003,,,b3333,,w3001,b3203,b3130',
    ',w0003,,,,,x,,,,b2323,w0002,,,b3013,',
    ',w0020,x,b3330,w0000,w0301,b3132,,,,w3100,,,,,',
    ',w0002,x,w2200,,b3333,w2301,b3333,,w3000,,b3331,,,w0000,w1000',
    ',,x,,,,,b2332,,,,,w0020,x,x,',
    ',,w3300,w2000,,,,,,x,b3303,,,b3310,,',
    'w0220,,,w0100,b0003,w0010,,b2233,w0100,w0022,,,b1032,,w3030,b3023',
    ',,,,,,,w0021,,,b3003,b2313,,,w0101,',
    ',w2000,,w0000,x,,w3331,,,x,w0200,w0010,b3332,b3233,b3330,',
    'w1011,b1202,w1110,,w0031,x,,,b2322,b3332,w2110,,,x,x,',
    'b3203,x,,x,w1110,,w0021,,,w1100,,,w3110,b3232,,x',
    'w0001,w1030,,b3323,b2322,,w1001,w0010,,x,,w0130,,b3233,,w1010',
    ',,,,,w3113,,,,b3233,w0101,,b2310,,,',
    'w1131,w3301,b2322,,b3322,w0010,,w0201,,x,,b2202,,x,,x',
    'b2232,,x,,,w0011,w1031,w1120,b0222,w1312,,b3102,b2223,b1132,x,w1230',
    'w3121,b2222,w0111,w1300,,,b3122,x,x,w0113,w1132,b2201,,b2232,,',
    'w0001,w1001,,x,,,,,b2233,,,,,b2223,,w0101',
    'w0103,b2213,,w0100,,,x,,w2011,,b2331,,w0201,,,b3313',
    'b3323,w0311,b2333,w1102,,w0310,,,w1031,b0223,,x,x,,w0000,',
    'w1100,b2033,,w3022,,,w2020,b3333,w0023,w0101,,b3233,,b2003,w2101,',
    ',,,w1000,b3232,,b2030,,,w1321,w1000,,,w0001,,',
    ',,,,,b2322,,w3111,,,b3200,,,,,',
    ',w0212,b2322,,,,,,b1113,b0330,b0333,,,w1301,,',
    'b3320,,w0110,,,,x,,,w1110,,b2230,w0331,b2202,b3322,',
    'x,w0100,w0101,,x,w0010,,,,b2323,,b2233,w0010,w0110,,w0001',
    'w0321,w0131,b3133,w1111,x,x,b2333,,b2232,w1011,w3010,,,b3223,,w1012',
    'w0000,,w3300,w0110,,,w2100,w0103,x,x,b3333,,x,b3203,w1002,b2212',
    'b3233,b3332,,w0210,,,w2102,w1210,w1101,,b3322,,b2320,,w0110,',
    'b0332,w0020,x,,,,x,w0010,,,b3332,,,w0021,x,',
    'w1020,,b1333,,,,w1133,,b3223,,x,,,w1113,,',
    ',,,b3322,w2122,w0013,x,,b2121,,w0201,,x,,b2213,',
    ',,,,x,,,w1001,,,,,,w0000,,b3222',
    ',,,,x,w0220,b3322,,,,,,b0202,,,',
    ',w1211,,x,x,b3032,w0110,w2103,,,w1310,b3323,w0110,,,b3232',
    'x,x,b2323,,,,x,w3233,,w0103,,,w3101,b3331,,',
    ',,,,b2220,,,,w2001,w1110,,b3123,w0100,,b2320,w0113',
    ',,,,,,b2320,,x,,x,w1110,b3222,x,,w0110',
    ',x,,,,,,w2111,,,,,b3322,w3031,b3323,',
    'b3202,,,w0011,,,,b2232,,w0001,,w0112,b2233,,w2011,w0301',
    'b3232,w1321,b2202,w1231,w0130,x,,b3233,,,,b3232,w3001,b3322,w1001,w0211',
    'w2210,x,,,,x,,w1112,,b3223,,,x,,b1233,',
    ',w0020,b3222,,,w1101,w1301,x,w2100,,w3201,b3302,w1101,b2233,,',
    'b2223,b2210,,,,,,w2100,,,,,w0111,,,',
    'x,w0200,,w0311,,w0011,b0323,,b2011,x,w1011,w1000,w1131,,b2232,',
    'b3232,b3233,w0033,x,x,x,b3232,,w1111,w1111,b2023,,w0110,,w3010,w0131',
    ',,w0001,x,,,b3333,w0011,w0100,x,,x,w0010,w1111,w1001,b2322',
    'b2322,b3333,,,,w2110,,,,x,,w1300,w3001,,,',
    'w1200,,,b3232,,b0023,w1010,w2201,w3000,b1223,,,,w1011,b2333,x',
    ',b1320,,w0000,,w1111,,x,w0202,b3223,,,,,,',
    ',w1301,w1020,b2133,,,b3233,,w1020,,,w1011,,,,',
    'b3132,x,w0120,,,x,,,,w1103,,b0223,w0110,x,,b3232',
    'x,,w0013,,,w0300,,b2232,,,b3330,b0233,w0001,,,w1130',
    'w1101,,b2222,b3333,,w1002,b3233,w0110,,,,,,w3311,,b3032',
    ',,,,,w1021,,,b3303,,b1332,,,,,',
    ',,b0301,w0013,b2202,,w1210,w0101,w0010,x,x,b2332,b3233,,,w0111',
    'b1012,w1101,b3132,w0010,w1031,,b3220,,b2323,,,,w3021,,w0101,w0132',
    ',x,x,,w0110,b3323,b2322,w1101,w0032,w0113,,b3333,x,,w0032,',
    'b2332,b3023,,,w1110,w0101,,,w0000,b3130,x,,w0201,w3001,w1130,b1002',
    'x,w0311,w3020,,,w2100,w0012,w1102,b0130,b3323,w0001,b2323,x,x,b2320,b0022',
    ',b2323,x,b3222,,,,b2232,w0110,w0030,b2210,w0001,w0013,w1101,b1213,x',
    ',x,w0110,,,w0030,,w1010,b2333,x,w2110,x,w0010,b2123,w1010,',
    ',,,b3222,b3320,w2010,x,,w2101,w0101,b2333,,,w0101,,w1001',
    ',w1010,,x,,w1010,,,,,,,b3323,,,',
    ',,,,w3110,b1323,w0031,x,,x,w0331,b2332,b2033,,,x',
    ',w0001,,,x,,,w0100,w0101,b3222,,,,b3032,x,',
    ',w1001,w1130,,b3031,,x,x,w1111,b0321,w0300,,w3100,w1000,,b3222',
    ',,x,w1200,,b2303,,b3130,,b3323,w1113,b1223,,,w1100,w3100',
    'x,w1100,x,b1322,w0021,,w1003,b2212,,,w0021,w0201,b3223,,,',
    'x,,w3103,x,,,w0103,,b3202,w3110,x,b3320,,w0211,b1221,',
    'b3323,b3332,w2123,,x,w0111,,w0111,b2223,,w1001,w2102,,w0300,,b2200',
    ',b3332,,,w0011,b1123,,w3320,,,w2010,b2222,,,,w0313',
    'w0011,w1131,,b2103,,b3232,b3213,w0011,,,,,,w0011,,',
    'w2102,w1231,,,b1321,w3101,,,b3022,w1011,b3023,,b3322,,w0003,',
    ',b2323,,,,,,,w0010,w1000,,w0010,,w0030,x,b2222',
    'w2001,x,,w1200,w2012,b3223,x,w0010,b3023,b2122,,b3333,,x,w1202,w0001',
    ',,,,,b2323,,,,x,,,,w1202,,b3212',
    'b1231,w0011,,x,,,w0101,x,w3012,w1112,,b0233,b2333,,b2122,w0303',
    ',,w1021,,,,x,,b1232,,,b1323,,,w0302,',
    ',w1010,,x,b2323,x,w2111,b3322,,w0120,,,x,,,w1100',
    ',b2022,,,x,b3232,,w1201,x,w1101,w3000,,,w0110,w0103,b2322',
    ',x,,w3103,w0311,b3133,,,b3222,x,,,,w1101,,b2233',
    'w0010,w0010,,,x,,w0010,,,,x,,,,,b3333',
    ',,x,b3331,,b3102,x,,,,,,,,x,w1111',
    ',,,,,,x,,,w0001,w0110,b2322,w3113,b2020,,',
    'w1112,,b3322,b2232,w3211,,b1012,x,x,,,x,,,,',
    'w1101,x,b3221,,,b2222,b0230,,b3233,,w1013,w3011,w2031,b1322,,w0111',
    'w1100,,,,b0323,x,x,,b2120,b2223,,,w3200,w1100,,',
    ',b3230,w0030,,w0310,w1001,,w3000,x,b1033,x,b2303,x,w2000,w1120,b3323',
    'b3322,w1001,w1201,,,,,b2322,,b3333,,x,w1100,w3001,x,',
    ',w0201,w3301,b3033,b2333,b3303,b2303,x,w1030,w0110,b3332,,b2130,w1101,w0020,x',
    ',w0110,,,w1301,b2233,x,,w1002,b3333,w1100,,x,x,,b2123',
    'b2032,,w1103,,,,,,,,w1101,b2202,w1011,b2223,,',
    ',b3232,b3120,x,w1010,x,w1011,w1130,w1000,x,,b2222,w3310,w3011,b3213,',
    'w0131,w1130,b1132,b2032,,w1112,,w0013,,b2123,w1002,w0101,b2322,b3213,,',
    ',,w0110,,,,w1100,,,,,,b2323,w0011,b2322,w0111',
    'b3333,x,,w1010,,b2322,w0111,w2331,x,x,,w1101,w0100,b2223,b2330,w0010',
    'w0110,,w0111,x,x,w1310,,w2000,,b2333,,b3312,,,,x',
    ',,w0000,b3332,,,,,w0111,,,,,,,',
    ',,,w0010,,,w3000,x,,b2222,b1333,,,,w1013,',
    ',b2222,w1231,x,,b2223,,,b2022,,,,,,,',
    ',b2200,w1131,,x,x,b2312,,w1103,b2333,w1322,w1200,w0111,,,b2323',
    'x,x,b2322,w1111,w1111,,w0210,b3322,,b3103,w0101,w1310,x,,,',
    ',,b2322,w1011,b2230,x,,,w1311,,w0313,,w0121,,w1002,b3210',
    ',w1101,w1311,b1221,,x,x,,,,,w0010,x,,,b2022',
    ',w0012,w1011,b0233,,w1101,x,b3032,b2222,,,w0010,x,b2132,w1011,w0300',
    ',,,b3133,w0011,w0010,,b3233,,,,w0102,w0100,,,',
    ',x,,,b2233,,,,,x,w1013,w1000,,x,,',
    'b2233,w0100,b1210,x,w0000,w0110,,b3221,,,w0103,,b3320,,w2130,',
    'b2332,,,w0303,,,b3322,,x,,x,,,w0101,,',
    'b3330,w0011,w1123,w1110,w0002,,,b1122,w0113,,,w1001,,x,,b2223',
    ',,,w0302,,w0011,x,b2330,b3212,,,w0000,w3011,,,',
    ',,,,w1111,x,,,,w0110,w0003,b3133,,,x,b3231',
    ',,w1123,,,b2202,,w1101,w1310,,x,w0000,b2023,b2033,,b2122',
    ',,,,w1221,,x,x,,w1101,,b2223,w1111,b2022,b0301,',
    ',,,,,,w1100,,,,,b2232,b2302,,,w0111',
    ',w0100,,w0131,b2323,,,x,,,,w2201,w2110,,,b2032',
    ',,w0221,,b2332,b3222,,,w1312,w1100,w0210,,,,,',
    ',w2001,w1111,w0010,,,,w1010,,w0000,b0012,b0021,w0111,,b1233,b3331',
    'b3223,w0011,w1002,,,w3110,w0000,b3223,b2311,x,,b2012,x,,,w1110',
    ',b2233,x,w0102,,,,x,,x,,,,w1000,,',
    ',w0120,,b1322,b3110,b2232,,,w0010,x,w1031,w1001,,,w0021,x',
    ',b3322,x,,x,w1001,,,,,w1101,x,,,,',
    ',,x,w0101,,,w0101,,w2101,,,b2222,b3223,w1102,,',
    ',,,,w0110,,,w1110,,,x,b3213,,x,,',
    ',w1210,,x,,w0101,,b3322,b3303,w1100,,w0013,,b3231,w3333,w1100',
    ',x,x,,x,,,,w0111,w0012,,,,,b3330,',
    ',,b1320,w0110,,w2010,,,,w1211,,,,b2321,,',
    ',w1121,,,,,,b3330,,,x,w1030,,x,b1022,',
    'w1101,b3222,,,,b0023,b2303,,,w0010,x,,,x,w0110,',
    ',,,,,x,,x,,,x,,,,b3332,w3010',
    ',,x,,x,,b3131,,,,,,,w1102,b3313,w2002',
    ',,,b3333,,x,,,w0101,w1111,,,b2302,,w1221,w1002',
    'w1111,,b1333,,,x,,w1001,w0013,b3232,,,w1001,,w0110,',
    ',,,,,,,,w3001,x,x,,x,b3133,w0200,',
    ',b3333,w1031,,,,,,,w1111,,,b2102,,,',
    ',w0010,,w2120,w1101,w0010,w0020,,,b2221,x,,x,b1303,x,',
    ',w0111,,b3332,,w1001,,,,,w1110,,,,,',
    ',,b3232,,,w0000,b3233,,,w3101,w1112,,b3223,w1000,,',
    'x,b3033,,,b2223,w0113,,w1300,,w1310,w1010,w1110,,,w0110,b2213',
    ',w1111,x,b3230,,,x,b1230,,,,,,,,',
    ',,,,,b3232,w0110,w0022,w0030,,w0111,w1000,,,b2302,w0001',
    ',x,,x,,,w1021,,,,w2111,,x,,,b3321',
    ',,,w1100,b3333,,b3033,,w1120,w1110,w0030,,,,x,w0001',
    ',,x,w0113,b3233,,,x,,,,,,,,w1001',
    ',w3100,,x,,b2220,,x,,,b2200,,,,x,',
    'b3233,,w1311,b2023,,,w2101,,,,,,,,,',
    'w1011,,w1001,w1132,b2313,b2222,,,w2013,w1101,,,b3321,,,w1110',
    'w0100,,b3021,b2332,,w1112,w1103,,,w0001,,,,b2222,,w1213',
    ',,,,,,b0302,w0000,,,,w0011,,x,b2231,w1010',
    'b2233,,,,,w0100,b2222,,w3201,,,b2333,x,,w1101,',
    'b3222,,,,,,,w1000,w1113,,,,,,b2222,',
    'w1101,w0110,,x,,w1301,,,,,x,,b3302,,b2233,b2332',
    'w1001,,b2213,,b3031,,,,x,,w1103,w0103,,b2303,,',
    ',b2222,,,w1011,x,x,,,x,b3231,w1010,,w1002,w3010,',
    'x,,b3231,b1233,x,,,,,,,w1111,x,,w0001,',
    ',w1312,,,x,w2101,,w2100,b3132,,,x,b3211,b3232,w0001,',
    'b1220,,,,b2232,w1012,,,,x,x,,,w3110,w1200,b0203',
    ',w1130,,,b3202,x,w1010,w1002,w1010,b2322,,,b0212,,,x',
    ',,w3101,,w0101,,b2333,,b3233,w0002,,w1032,w0210,b1322,,b3132',
    'w1211,w1013,w0111,,b3322,x,w0210,w3011,x,x,,,,b3320,b1333,w1011',
    ',w3100,,b2122,b1222,x,,,,w3001,,w2010,,,,',
    ',,,x,b2333,,,,x,,,w2013,,b3233,w2111,w1101',
    ',,,,w0000,,,,,,w1201,,,,x,b3333',
    ',,x,,,,,w0000,b3232,,,x,,x,w0110,',
    'b0003,b3333,w0002,x,,b3233,w1010,w1002,b2033,,w0100,,w0203,,,w0030',
    'w0001,w3113,b3120,,,,,,b3233,w1100,w1011,x,b3213,,x,x',
    'b3332,,,,,,b2203,w1010,,w0003,,w0121,w0011,w1110,,b3323',
    'w0002,b2233,b2332,,b3200,w0210,,,,,,w1103,x,,,x',
    'b3221,,x,,,x,,w0311,,,,w1111,w0000,,,b3322',
    ',,,b2132,,,,x,x,w1120,b3020,w0111,,,b2032,',
    ',b2303,,,w0113,w0311,b3323,,w0203,,w0111,,b3223,w1010,,',
    ',,x,b1323,,,,x,w2010,x,b2333,,w0301,,b3021,w1102',
    ',b2323,x,,w0211,,,,,,,,b3223,w1330,,',
    ',,,b1333,w0133,,x,,b2332,b3332,w1000,w2103,x,x,w1202,w1103',
    ',b3003,b2233,b2323,w3000,w3000,b2322,,,x,w1211,,w1302,,w0211,',
    'w1100,w3111,b1333,w1102,b3223,x,,,b2332,x,b3232,,w1010,,w3013,',
    ',b2322,,,b3323,b2301,w0201,w1231,w1130,w0103,,b3232,b2023,w0001,,',
    ',b2102,,x,b1333,b0132,w1103,b3222,w1320,b3302,x,,b3222,w3010,w1100,w2001',
    'w1001,,,,,,b2323,,b3222,w0000,w3011,,,,,',
    ',,,,,,w0113,b3032,x,,,,w3102,,b1203,b3323',
    ',,,,,b2333,,b0233,,b0322,,w1111,,w1221,,',
    'w1100,,w1110,,,,,,,w1111,b2322,x,,b2303,,',
    ',,,b2333,,x,w0103,b2323,w1111,,w0000,,b1322,,,',
    ',,,,b2233,b2233,w0033,,,,,,b2312,w0220,w0000,',
    'b2333,w1100,b3322,,,w1210,,b0123,x,w1101,,w0311,w2100,,w0002,b3023',
    'b3230,x,,,,x,w1010,x,,,,,,w0001,,',
    'b3222,b2122,,,w0101,,,,w1000,,,,w3000,,,',
    'b2323,w0111,b2332,,x,b2332,,x,w0101,w0111,,w0302,w2131,b3300,w0201,',
    ',w0100,w3020,,b3332,w2101,b2223,,w0110,,x,,x,x,,',
    ',,,w1101,w0003,w1101,x,b3223,w0201,,x,x,,b2223,,',
    ',,,b3320,,,x,x,x,w1111,,,,b3213,,',
    'b3312,,,,b2233,x,x,x,w1103,,,w0301,,,,w0003',
    ',w2330,,,,,,b3023,,,,,b3133,,,w0212',
    'b3232,w3201,,w0100,,,b3322,w1003,,x,w0100,,,,,',
    ',w1000,b3230,,w2102,,b3311,w1001,,,,w2010,w3101,b2323,,b3023',
    ',x,,b3332,w0001,,,,w0011,,,,,w0011,,',
    ',b2332,w2031,b2212,w0311,b1333,w1111,,,,,,b2200,,,x',
    'w2111,b3322,,,,b1303,x,b3320,b1032,w2120,w1101,w0000,x,w1001,w0300,b3023',
    'b3222,w0003,b3233,,,w0021,,w1030,w0111,b2322,,b2332,x,w0000,w1100,x',
    'w2121,x,w3011,,,w1011,b2320,b2313,,,x,w0010,,b2302,,',
    'w1100,,w0100,b2313,b1322,,,x,b2003,x,,,,w1100,x,',
    'w0300,w1201,,w0312,b3122,,,,b2000,w1031,x,b1232,,,b2321,b3333',
    'w0130,b3312,,w1100,,w0110,,w1000,b3332,b2223,x,b0223,w2011,,b3331,w1110',
    'w0010,,w0112,,b2220,b3223,,w0120,,,,b2223,,x,,',
    'w1121,,,,b3323,,w0100,,x,,b2023,,,x,,',
    'b2213,b2223,w3111,b3232,,,w1311,,b2033,w0321,,w1101,w0113,w1311,,b3232',
    'w0201,,,x,w1100,b2330,b1322,b2321,w1012,w2110,w0011,,,b2322,,',
    ',b3020,b3303,w1000,b0132,w0010,w2101,,b3310,w0010,,w1300,,,w1101,',
    'w1301,b1330,,,w0021,b3033,x,w2110,w1111,,x,x,,,w0012,b2223',
    ',w1310,b3313,b3222,w0000,,x,b2133,,w1101,w1010,,,,,',
    ',w0301,,w0110,,,,,w1300,b3222,w0012,w2130,b3322,b1313,,w1000',
    ',w0121,w0112,w1010,,b3022,,x,x,,b3232,b3230,w1001,w1010,w1130,b3332',
    'w0010,,x,b3203,b1231,,b0222,w2212,b1132,b2233,w1011,w1112,w3002,b2232,w0321,',
    ',,,,,,,,,,w2112,,b2321,w0100,b3321,',
    ',w0311,,b3323,w0210,,,w3012,x,,,,b2332,,,',
    'w1121,w0111,,b1323,,w0310,w0000,w0211,,b1323,x,x,,,b2332,w0101',
    'w3000,x,w2001,b3332,b2222,,b3203,b0233,w0211,,,w1211,,w0001,x,',
    ',b0123,b2031,x,w0012,w1101,,x,,,b3223,,,b2132,,w2100',
    'w1011,b2033,b3322,,w0202,,,b3330,w1001,,,x,,,b3233,w1010',
    ',w0011,w1110,,,x,w0000,b2223,,b3322,,,w1010,b2220,w0030,w0113',
    'x,b3322,,,w1010,b3222,w1010,w3010,,,,,,b2222,w0101,',
    'w0011,w2110,w0012,,x,x,b3222,,,w2001,,b2332,,,x,b2222',
    ',,w0000,,,w1101,w0201,w0111,b3332,,,b3213,b2032,w0001,w0112,',
    'b3233,,,w1112,,w1111,b2022,x,w0012,b2123,x,x,,,,',
    ',b2223,,w2010,,w0111,b3323,b1313,w1210,w2133,w1113,,,,b2233,b3232',
    ',x,w2000,w0312,,b0233,,,b0223,x,b3231,b2222,w2110,w0021,,w2000',
    'b2333,,,,b2303,w1123,,b1322,w1331,,,,,w1110,,b2333',
    ',b2330,w0112,w0100,,,,b2331,b2221,,x,,x,x,w1013,b3223',
    'w1001,w3102,,b2322,x,w1100,b3323,w2132,,b2320,,x,x,b3022,,',
    ',w1101,w0001,,,,,,,,,,,b3322,,b3032',
    'w1100,w1132,,b1231,w0011,b2223,,x,w1001,x,x,w1020,,b0022,,b2133',
    ',,,x,b3332,x,w1101,w1200,,b2322,,,,,w3031,w1301',
    'b2203,,w1002,b2323,b2313,b3223,x,w1121,w1210,,,,w2121,,,',
    'w0100,w1311,b2321,b3222,w2001,,,,,,,,,,,',
    'w3100,w0011,w1001,w2010,b1232,,,b0002,,b2231,,x,,w1203,b3223,',
    'x,x,,,,w0103,x,,,b3232,,,,w1010,,',
    'w1111,b3222,b1223,,w0110,w2030,w0110,,,w0112,b2232,,w3101,x,,',
    ',,,,,,,,w3003,,b0222,,,,b2223,w0100',
    'b2222,,,w0120,b3202,b2303,,w0011,,w1231,,w0110,w0111,,,b3322',
    'w1033,b3132,w2001,,,,,,,,,,,,b3013,',
    ',,w1010,w1110,,w1000,,x,b3322,,b3320,x,,x,w0101,',
    'x,,x,w1211,,b2110,,,,,,,,,,b3132',
    'w0121,,b2323,,,,,,w0110,b3323,w0233,b2233,,,w0110,b2023',
    'x,b1223,,b0333,,,,w0000,,w1210,w1011,x,b2233,w0200,,w3110',
    'w1111,,,,,,b2322,,x,b2203,x,w3002,x,,,',
    ',w0101,,b3223,,w0100,,,,,b2220,,b2233,,w0311,w0111',
    'x,w0011,w1321,x,w0011,b3123,b0333,,w1012,b2022,b3322,x,w1001,,w0111,',
    ',x,b3322,,w3013,,,,,,b3223,,,,,x',
    ',,,w1120,b2322,b2212,,,b3322,,w3312,,x,,w0330,',
    ',x,,w2123,,b2323,b0313,,w1010,x,,x,,w1030,,',
    ',,,,,x,w0030,w1011,,b3133,w3120,,b3212,,w0101,b3220',
    'w2110,b3212,x,,w1211,w0330,b2323,x,w0310,,,w1120,w0111,x,b3222,',
    ',,,w0011,w0001,,,x,,,w1101,w0000,b2310,b1230,x,x',
    ',b1303,w3220,,,,,x,,,x,,,w0010,b3331,',
    ',,,w2100,w2011,b2220,,,,b3323,,,,,,',
    ',,w0013,x,,,,,x,w1111,b3233,b3323,w0200,,w0111,b2210',
    ',w1311,x,b2222,,,,,,x,b0221,,w0031,,,',
    ',w1001,x,,,w0012,,x,w0131,,,,b3323,w1120,b2220,b3323',
    'b2232,b2223,,w0010,x,b2023,w2230,,w1110,w1101,,,,,,',
    'w3110,,b2332,,w1110,b2212,w3000,,w0201,x,,b3022,,w0110,x,x',
    ',x,,,w0001,,,,,,,b3132,x,b3032,w0311,w1101',
    ',,,,,x,,w0011,w1110,b3122,,,,,,',
    'x,x,w0120,,w1001,,w0111,b2233,x,w1301,w1000,,w0120,,b1223,b2013',
    'x,,,,w0130,,,,,b2231,,b0332,x,,,',
    ',x,,b3331,,w2121,,,,,w1101,,,x,b2233,',
    ',,w1003,w0110,,x,w0101,w1001,,b2323,,b3322,x,,x,w0202',
    'w0000,w3221,,w0311,w0001,,b3223,w1212,b2233,,,,b3102,,w0101,',
    ',b2232,,w1011,w1110,x,,w0000,,,,b3232,,,b2202,w0321',
    ',,,w0001,,b3023,w0110,b3232,,w1000,w3201,,,x,,b0230',
    ',b2332,,,,,w0011,b1231,,,w1001,,,,w1000,w0011',
    ',x,b3233,,,,b1222,w3302,,w1110,,w0103,w0112,x,b3313,w0121',
    'w1012,b3221,w0111,,w1100,,w0100,w2000,,,,,b3323,,,w0122',
    ',,,w0010,x,,,x,w3130,b3231,w0102,b2322,,,,',
    ',b2332,x,,w0013,w2010,,,b0202,,x,b2223,w1000,,w1013,',
    ',,,,w1111,,w1111,b2230,,b3313,,,,,,',
    ',w0013,,,w1102,,b0222,,x,b2323,,,x,,,',
    ',,w0111,,,,,,,w1221,b1323,,b3232,w0111,b3221,',
    ',,,,,,b0223,b1220,,,,w1111,x,w0030,b0332,x',
    'b3322,b3231,w2132,,w0110,b1332,,,,,,,,w1101,w0101,',
    'w0110,x,b3332,w0201,w1000,w0012,,b3232,,,w0011,w1011,x,,,',
    'x,,,b2223,,b2202,,b3030,,w1100,,w1113,,x,,x',
    'w1101,,b2313,,b3321,w0000,b3223,,,,,w1310,,,w0012,',
    'w0110,x,,,,,,,,,w1301,,b2333,,b3330,',
    ',,,,,b2333,,,,,w1001,,b0002,,w2001,',
    ',w1000,,,,b3323,,,,,,w2012,,b2330,,',
    ',b2333,w0031,,w1011,x,,,,,x,,b3332,w0000,w0000,',
    ',w0131,x,w1111,w1110,,x,w1110,b3333,w0022,x,b3332,,w1301,b1223,',
    ',,,x,,w3003,b0032,b2322,w0103,,x,x,,,,b1302',
    ',,w0301,b3212,b3221,,,,,,x,w2000,w3120,,,',
    ',w1020,b3022,w1112,,b3303,,w1030,,,,x,,w0002,w1030,b2322',
    ',,b3313,w3030,,,,w2001,w1110,,,b2322,w0130,b2222,w0211,',
    ',w3310,b2233,,,w0131,,,,,b2222,,,w0000,,w1000',
    'w0300,x,,b3321,,,b3311,w2110,,,w1000,w1113,,b3312,x,x',
    ',,,w3220,w0000,,b2322,,,,b3032,w1020,x,w0101,b2131,',
    ',,,w1001,,b2223,x,b2321,w1012,w1001,,,,,,',
    ',w3131,w2000,,w0221,b2132,b2320,,,,b3223,x,w0002,b2233,,',
    'b2232,,w3000,x,b2222,w2310,,b2233,,,,w0001,,b3323,w2031,w1010',
    ',w0011,,b3023,w3201,b2222,,,,,,,,,,',
    ',b2023,,b1233,,,w0331,,,x,w1111,b2231,,,,',
    ',b3031,,,b3312,,w2200,w1100,,,,x,b1332,,,w0011',
    ',b1023,,w1031,w1110,w0011,w3101,w3201,b3202,b2333,,b3333,,b2300,w1111,b3313',
    'b2323,w1311,w1311,w0101,w0210,b3333,b3233,,,b3123,b2223,,,,w2021,',
    'w0201,b2323,,,w1120,,,w0310,,,x,b2330,,b3233,,',
    'w0001,b3330,,b2313,,b3330,,w0001,w0230,,w0020,,x,b2333,w0000,x',
    'b2330,,w1101,b3322,b2332,,b3320,w3010,w0130,w1120,,,,w2310,b0203,w1310',
    'b3232,w1002,w1000,,,w1112,x,,x,b3332,,,x,b2233,w3301,w1310',
    ',w1311,,,x,b2203,b2123,w0001,w0201,,b2322,w2120,x,x,,',
    'b2203,,,,w1012,,x,,,x,b2332,b2323,,w3010,,w0130',
    ',w1101,w0010,w1101,,w0201,b2223,,,w1030,b2302,,b3333,,,x',
    'w0110,w0110,w3032,w0010,,b3222,,b3313,w1211,b1302,,,b2332,b3022,,',
    'b2303,b0012,x,,w1020,,,,w3112,,,w2202,b1202,b3322,,',
    'w1011,,b2133,,b3000,w1110,b0232,b2222,w1200,,,w1131,w0111,b2230,w0300,',
    ',,,,w1130,,,,,b2303,,,,,,b2332',
    'w3010,x,,b1203,w1111,w0020,w0220,,x,w2100,,b2231,w3003,,b2323,b1302',
    ',w2020,,,,w1201,,,,,,,b3222,,,b2312',
    ',b3112,b1032,b2212,b2323,w0011,,,,,w0233,w1011,,,,x',
    'w1000,w0310,,,w1010,w0110,b3023,b2022,,b3212,,,b2331,w1113,,x',
    ',w1020,w1001,,x,w1311,w2211,,b3323,b3202,,w1013,w0001,b2332,,',
    'x,,b2323,,,b2310,b3333,w0123,,w0011,,,,,w0101,',
    'w1101,,x,,b0332,b3232,b2330,,b3332,,w0002,w0102,,w3111,,b1222',
    ',,,,,,w1020,,,w1010,,,b3210,,,b3232',
    'b2132,,w1112,,,w1111,,w1120,b2332,w1111,,x,,x,x,b2233',
    'b2322,w1113,,w1100,w0012,w1110,b3322,b2123,b2123,,w1100,,w2020,,x,',
    'w3010,,b3321,,w1111,,,,w2101,,,b2233,,,w0001,b2223',
    ',,b3211,w3132,,w3001,w0210,,,,,b2332,,b3121,b3222,w1310',
    'b2200,b3223,,,,,x,,w0011,,,,w1010,x,b3233,w0002',
    'w3001,w0030,,b0212,w0110,b1032,b3222,w1100,w1301,,,b2322,b3032,w1101,,',
    'b1223,w3030,w1000,,w1110,w3020,x,x,,w1030,x,b3223,b3123,,b2203,',
    'b3233,,w0102,,,w1102,,,,w1000,,,,b2333,w1111,',
    ',,b2322,w1011,w3102,w1110,b0233,,,,w1001,w1130,,b2233,,',
    'x,w0112,,b0323,b2132,,b3212,b2230,w0000,b3032,w1003,w1002,,,w0011,w2213',
    'w0103,b2022,,x,,,,w1032,b2223,w1003,w0103,,,b2313,w1020,',
    ',,,b2323,b2323,x,w1001,w0110,w0000,w0013,,,,b3030,w0130,',
    'w3110,b3312,b3302,w0012,w0010,w1001,b2323,,b3332,,,b3331,,,w1011,w2211',
    'b3330,,,x,,,b1221,x,x,,w0111,,,,,',
    ',,w1011,,w0000,,w0130,,w2111,,b1323,,b2223,x,b2322,w1102',
    'b3332,,,w2112,b2323,b2232,w0001,b3322,w1111,,x,w1203,b3223,w0202,,',
    'w2002,w1303,,,,b3322,b2332,w0001,,w1011,b3223,w2010,b2322,,,w0010',
    'w0000,x,,,,w0123,,b3323,w1131,,b1132,b2003,b3332,w0111,,',
    'w1111,w1210,b0322,w0211,b3211,w2101,b2232,w1101,b2233,x,x,,x,b2033,w2101,b2233',
    ',x,w1103,,,w1011,b1322,x,,x,b2333,,,w1211,,',
    ',,x,b2333,b2023,b1133,,x,w1311,b1233,,w1100,w1121,x,w0010,',
    ',b3133,b2223,w1101,b2312,x,x,,w0113,,,,,w3000,w0001,',
    'b2322,w0030,,b1023,,w1101,b3313,x,x,,w1011,b2013,,x,w3013,',
    ',w1123,,w3111,b3323,x,b2033,,b3322,b2233,w1001,w0131,w3011,,w3210,',
    'w2111,w1010,w0011,b3322,b3023,b2023,,b3222,w0012,w0011,,b3222,w0122,,,',
    ',,b3120,b3223,x,w1321,,,,,w1002,,,,,',
    'b3303,w1130,x,,w1101,,,,,b1321,,x,,,b3213,x',
    ',,x,,,w1000,w0103,,b3323,,,,,b3223,,w1011',
    'w3020,,w1001,w0011,b2332,,,,x,b2322,,b3222,,w0311,w1112,b1230',
    'w1131,,b3032,x,,w0001,,,,,x,x,,,b2331,b3230',
    'w2011,,,,x,,b3330,b3232,,,,,b3123,w0012,w1010,',
    'b3323,w1010,b2222,w0301,w0113,w1001,w0010,w1200,,b3320,,b2322,,,x,b0223',
    ',,w1221,b2332,w0200,,,,w2011,b2212,,b3322,,w0211,w1101,w1100',
    ',b2221,w0032,,,b2233,w1200,,,w0211,,,,b3222,,x',
    ',b3232,,,b3323,,,,w0001,w1100,w1130,w1111,b2032,x,w0000,x',
    'w0101,b1103,,b1221,x,,,,b2333,b2213,x,w0000,,x,w0101,w0021',
    'b2323,,w0013,w1010,x,b3320,,,,,b2313,,x,,w1111,',
    'w1120,x,w1112,,b3323,b2323,w0001,w1101,b2303,x,,w1111,,b1232,w2111,',
    'b2133,b3323,w2011,x,w1011,,x,b2233,w1112,,,,b3323,w1100,w1311,x',
    ',,,,,,w0101,w0011,b2233,,,,w0310,,,b2321',
    'w0001,w3112,,,b3332,,b3212,,w0310,w1000,b3230,,,x,b3323,x',
    'w0030,,w1031,,w0010,b0032,,w0101,,,b2222,x,,,x,',
    'b2210,,b2233,b2003,b3332,x,w1011,w0110,b1233,w0000,w2103,,w1010,w0100,x,b0000',
    'w0101,,b3321,,b2132,w0011,w0010,b1303,x,w1110,,w1113,b2222,w0010,b0302,',
    'w1111,,,b3112,,w1301,w0010,,b3331,b2223,b2332,x,w0000,w0212,w1201,b3322',
    'x,,b3233,,x,w0103,b2022,b2323,,,,w1011,b2212,w2220,w1131,',
    ',w1100,,,b3332,,,w1100,w3311,w2103,x,w3122,b2323,,b3212,x',
    'w1021,,w1131,,w0020,b3222,w0013,,b2312,x,,w1011,b2133,x,w1201,x',
    'x,b3022,,b2132,,,,w0111,w1022,w1110,w3000,,b3133,b2213,,w1010',
    ',,,w1213,b2323,x,w1101,,x,,b3122,w0011,,w0311,,w1301',
    'w2011,b3022,w1020,x,w0111,x,b2222,b2013,x,w3100,w3110,w0201,,b3202,b2222,b3023',
    'x,,x,,b2023,x,,,,,b2323,w1300,,,,',
    'b2233,w0100,,,x,w0100,w1200,,b2222,b0303,b3333,w0002,w1110,b3220,x,w1213',
    'x,b3012,,,b3223,w1100,w1100,,w0120,w0020,w0010,w0101,,b0033,,b3222',
    'b3202,,x,,w2012,w1102,,b2032,b2212,,,w1112,,w2112,x,b0122',
    'w1011,x,x,b1332,,,w1001,w1211,,w1013,,b2233,x,w0110,,b0223',
    'w0120,w2000,,,w0111,w1100,,,,,b3233,,b3232,,,',
    ',w0100,b2320,w2111,,b2332,w1210,x,,,,w1113,b3233,b2123,w0010,x',
    ',b3332,w0000,,w1021,w3320,b2232,,,,,w1101,w0100,w0031,b3321,',
    ',,,x,,,x,w1021,,b3233,b3223,w1011,,,,',
    'b2333,w0001,w1203,x,,w0030,,,w1013,,b1331,,x,w0111,,b3232',
    ',,,b2132,w0110,,w1021,,b2223,,,,w0010,b3333,w1210,',
    ',,,b3033,w3311,x,b2333,x,b0221,,w1100,,w0101,,,',
    'w0003,,b2333,,w1121,w1111,x,w1110,w1300,,x,b3232,b2332,w1021,,b3330',
    'w1020,w2020,,b2323,,,,,,,w0112,x,,,b3223,w1100',
    ',w3001,w0001,,x,w0030,w1001,w1221,b2123,,,w0100,,b3202,,b3313',
    'b0322,,,b2332,,,,,,w1101,,w0310,,x,,',
    'x,w1101,w1001,,,w0000,x,w1010,b1313,w2100,x,w0011,b2323,,b3233,',
    'w1021,x,w1100,w1133,,,b2022,w3001,b2232,w1110,w0021,x,b0313,,x,',
    ',w2011,w0300,,b3331,,,w0000,b2223,b2133,,w1132,b0333,w2112,w0100,',
    ',,w0311,b3023,b2232,b0211,w1110,w0101,w1020,,w1110,b2010,,w1110,,',
    ',w1103,,b3303,b3223,w2111,b2313,,,,,,w1101,,w0100,w0111',
    'x,b2223,w1102,w0302,,,,w1100,b2323,,,,w0101,w1130,b2333,',
    ',,,x,b3222,,w1001,,,w0001,,x,x,b0230,,w0010',
    'w1111,,,,w1211,,,,b2332,,w0033,,,w3121,b0313,b0323',
    'w1102,b2323,w0212,,w1300,,,b3022,x,,w2011,b3020,x,w1000,b2023,',
    'b0220,w3011,b2332,w0211,x,x,b2232,,,w0031,,b2332,w0202,,w1021,',
    'b1333,,,b2333,b2322,,w1210,w1010,b2322,w0203,w1110,b2102,w1302,w1020,,',
    'x,,w1010,b2332,,x,b2222,w0301,w2123,,,x,w1230,w1113,w1101,b2232',
    'x,,,,w0001,w1010,b2033,b2203,,,w0130,b2222,,,,',
    'w1101,x,w0211,x,w1211,w0111,x,w0001,,b3320,w1101,,b3232,,b0232,b3213',
    ',,,w3110,,,,w2001,,b3322,,,,,,b2323',
    'w0112,w1112,,w0013,,,b1323,b2333,x,,w0210,,,b2323,,',
    'b3110,b1222,,b1333,b2222,w0003,,w3001,w2000,,w3103,x,w1011,x,w1110,',
    ',,,b2323,w1112,w0003,x,b3203,,,,x,,b2333,,w1322',
    'b3331,,w1320,x,w1100,,w0100,w0101,,,,b0333,w1210,b3122,w0130,',
    'b3223,,w2111,,,,w2011,x,x,w3001,w0213,b3213,b3332,x,w1000,w1011',
    ',,w0010,,w0130,b3202,,,,,w0003,b2332,,b3233,w0011,',
    'b2323,w3102,b2203,b2332,w0011,,w0100,,w3221,,b3232,x,x,,w3313,x',
    ',w0001,,,w0020,w1130,b1232,x,x,,,w3101,b2332,,,b3330',
    'w1002,w1113,,,,w2100,x,w1010,b3223,x,b3233,,,b3123,,w2310',
    'x,,w2112,,w1100,b3322,,,w0300,b3223,x,,w1010,,x,b1232',
    ',w1111,w0100,b3132,b2333,w1003,x,b1313,x,,,w1011,,x,w2031,',
    'b1232,,w0111,w1110,w0100,b3320,b2202,w1012,,,,,,w0200,,w0110',
    'x,b1323,w2112,b2322,b3023,x,w0311,,x,b3122,w1110,w1300,,,w1023,w2101',
    'b2222,x,,,b1030,,w3220,,x,b2333,,,w1110,,w1103,w2300',
    ',,,,w3313,,,b2323,,,,w0101,w0110,b2221,,b3322',
    'b2332,w0110,,,,b2320,,w1221,,,,,b2133,,,w0010',
    'x,b2322,b2332,b3233,w1103,,,,w0110,w1100,,w3110,,,b2220,w0013',
    'x,,x,b3223,,w3011,,w1010,w3110,x,b2323,,b3222,b3222,w1011,w0203',
    ',w1230,w2311,,x,w1001,b2220,b2230,b2032,w0011,x,x,,b2232,,w0010',
    'w0120,,,w0310,w0112,,,b1223,b2230,,b2302,b3213,,,,w0110',
    ',,w0130,b2200,,,,,,,,b3323,,b1222,,w0110',
    ',,,w0013,,w2011,w1210,b3223,,,,,b3233,w0110,b2333,',
    'b2130,,b2312,w1102,,,,,,w3211,,,b3313,,,x',
    'b2013,b3233,w3012,w1001,b2202,,x,w1011,w3101,w3321,b2222,b2213,w0011,x,,',
    ',,,w0012,,,w1010,,w0011,x,,w0131,b2022,,x,b3202',
    ',,b3312,w1201,,x,w0131,,b2222,,b2032,,,w0110,,w0000',
    ',x,x,b1322,b2112,w1113,b2333,x,w2200,,,w0300,w0210,b2130,,',
    'x,,,w0100,x,,b3232,x,,w1010,,,,,b3223,w2100',
    ',w2000,,x,w1002,,,b3213,b0333,,,,,b2303,,',
    ',,b0333,w2002,b1230,w1000,,w0000,w0100,w0101,b3123,,,w0010,b1032,',
    'w0120,b2222,b1230,,x,w0001,,,w1110,b2021,b2222,,x,x,w0210,w0110',
    ',,,,,w2131,b2232,x,w1001,b0322,b3132,w0003,b2312,,,w0310',
    'w1102,,,,b2222,x,b2231,x,b3132,w2001,w3301,b2333,,b2232,w3100,w0122',
    ',b2023,,,,w1131,w1011,,b1200,b2201,w1210,b3223,x,b0330,,',
    ',,,,,,b2222,,,w0310,b3313,,w0110,,,',
    'b3023,w3201,,w0101,x,b2233,w0000,w0100,w1131,x,w0020,,b2233,b2323,,x',
    'b2223,w0110,b3003,b2302,x,b1233,w0011,b2032,b2330,w0001,w1212,w0323,,,w1101,b2333',
    ',b3232,w1131,w0111,b2321,,w3001,,b1222,,w0101,,b1223,,w1021,',
    ',x,,,w0001,w1010,,,b3113,,b2023,b2231,w0010,,,x',
    ',b2322,b2322,w1100,b2333,w1011,,,w2111,,w0101,w1002,,w3011,b2233,',
    ',,w1011,,w0000,,x,,w0011,,,b2323,,w2000,b2323,',
    ',,,b3222,w3002,b1333,,,w0111,w1200,,,,,w0031,b3233',
    ',b2233,,,w1221,w0110,b2303,,w0111,,w0110,,b2212,,,b2132',
    ',,b3220,w1100,w1110,,x,,,,,,w0301,b0000,,b3332',
    'w1133,,,,,,b3032,,,w1300,b2323,,b3220,,w0110,b2232',
    'w0002,b3210,,w2103,,,x,,b3232,,x,,,,,b3212',
    'w0210,,b2223,,,w1110,w0101,b2332,b3132,w1110,w1031,w0111,,,,b3123',
    'b0233,w1102,,b1320,,w0101,w0330,b2033,x,,w1001,x,,w1001,b2223,',
    'w0001,,x,,w0121,,w1010,w0011,x,b3333,w1021,b2333,,b2332,,',
    'w2011,b2322,b1232,,w2030,,x,w2110,w3201,,w0302,b0212,,w0101,b3323,b2323',
    'b3222,b2332,b3222,,w0001,,,x,w0110,,w1000,b0232,w1033,,w0100,w1020',
    'x,,,b3131,,,w0131,,w0000,b3232,,w1100,,w0000,,',
    'b3322,w1011,b2112,x,w0100,x,,b3022,,x,w1200,w0000,,w0100,b1333,w1111',
    'w0121,,,b3321,w0100,b2201,,w1123,w1101,x,b3322,w2231,,b2022,w1010,',
    'w2101,,w0300,b3333,,,,x,b2312,,w0031,w0010,b2233,,,',
    ',b2303,,b3232,b3321,w1101,w1001,w3331,x,x,b3332,w1011,w0002,b2203,x,b2232',
    ',,w0031,,w0110,,,,,b0333,b0203,,,,,b3233',
    ',b2022,x,b1222,,w1010,w1012,,,,w1100,w0000,x,b2322,w1030,',
    'w3112,x,w2102,x,,b2230,b2332,w2130,b3233,b3333,x,w1011,,w0201,,b3332',
    'b3133,w0123,b2322,w1310,b2031,x,,x,,x,b3312,,,,,w1111',
    'b2023,,,,,,x,w3100,,,,,,,,b3233',
    ',w2112,w1100,x,b3321,b2032,b0333,w0301,b3023,b3302,w0001,,,b3232,w1001,',
    'b3022,,x,w0011,x,,w3300,,b3321,,,b2322,,w1010,,b3130',
    ',x,,b2323,b3233,,,b1323,,,b1220,w2131,,w1102,w1101,',
    ',x,,w1110,w0000,,b2333,,,,,,w2200,b3322,,',
    ',,,w2001,x,w2121,b2322,b3323,w0110,b3313,w0101,x,,x,b3013,w1101',
    'w0010,,b2123,,,b3212,,,,x,,,,w1202,,',
    ',x,,w1102,b0330,w1112,b3031,b3321,b3021,x,w3001,b0033,,x,w1111,b3121',
    'b1303,b3222,,w1211,,b3312,x,x,w0001,,,b2233,w0211,,b3222,w3001',
    ',b2220,,b3230,w0130,w3100,b2033,b3213,w3012,x,,x,w1011,w2030,,b3331',
    ',b3233,,,w1011,,,b3310,,,w1011,b2333,x,x,w0010,',
    ',b2023,w0101,w0002,,w0000,x,,b1322,,,,,w0000,,b3303',
    'w0100,w3100,,w1121,w2110,b3023,,,,b3312,b3212,b3233,w1111,,b2320,',
    ',,b2313,,w1111,,b3323,w0010,w1111,,b3313,w0100,w0100,b2332,w1102,x',
    ',x,,w2113,,w0010,b3223,b0223,w0101,,w1110,x,,,b3222,x',
    'b2333,b3333,,b2312,w0011,,,,w0010,,w0101,b2133,,w0330,,w0101',
    ',w1010,,,w1001,x,w3111,w1101,b3232,b3333,w1020,,,,b2213,',
    ',x,,,b2232,x,,b2212,w1221,b0323,w1001,w0101,b2011,,w2211,w1103',
    'w1010,w0102,,b3320,,,w0011,b3213,b3033,w0111,,,w0110,w0020,,',
    ',b2223,w1113,w1010,w3201,,w1113,b2323,,,b1220,,,b2322,b2103,',
    'b2233,b0232,b3203,w0131,w1211,x,,b0322,w3002,b3232,b3332,w0010,w1101,,,',
    ',,b3133,,b2030,,b2322,w3111,b2330,,,w1000,w1113,,,',
    'b2332,,w3110,,,,,w1300,b2232,,w1111,,b2233,b0312,w3111,',
    ',w1000,,,w2010,b3232,,,,w0011,w3110,,x,b2203,b2132,',
    'x,b3123,,,,b3302,w1122,w0010,w1031,b3033,,w0000,w0300,x,b3123,',
    'w0111,w3102,,b2230,,w3101,b3023,w2111,b1122,,b2020,,b2222,w3100,w3230,',
    'b2333,,w1110,,,,,b2332,,w1000,w0011,b3302,w1100,,w2100,',
    ',b2323,,b2222,,,,,,w1020,b2133,w0031,w3121,x,w1001,',
    'b3333,,,w1011,w1120,,b1212,b2322,w0011,b2033,w0001,w1303,x,,w0101,',
    'w1011,b0322,w0311,b2013,,b2321,b0233,b0333,,,w1000,w1100,x,,w1110,',
    'b2132,b1203,,w1010,b3132,w0000,w0011,,,,w0231,b2232,,w0201,w0312,',
    'w0000,b2123,x,w3000,w0231,x,,w0121,,,,b2320,b2232,,,b2322',
    'w0111,b3322,,,,,,,,,,w0110,,,b3012,x',
    'w2110,,b3311,,,x,w0113,,b2322,b2230,,w0010,,,,',
    'b1332,w0312,b2320,w1231,w1102,w1100,b3011,b2231,b3233,,x,w1030,,,b3223,w1000',
    ',w0010,b2320,,,,,b3231,x,,,b2320,w1121,w0313,b3322,w0000',
    ',,,b1221,,b2222,,b2232,w2101,,w1310,,x,,w0301,b2220',
    ',w1200,w1000,w2110,b3221,,w1013,,w2011,x,b1333,,x,b1332,w1103,b3222',
    'b3302,b0022,,,w0011,b2223,w3111,w1301,w1030,b2231,b3212,w0230,w2031,,x,',
    ',w0100,b3323,x,b2231,b3232,,w1100,,w1003,w0110,b3302,w0013,w2011,,x',
    ',w0110,,b2223,,w3011,x,b2330,,w1101,w1102,w0120,,b2222,b1232,w1101',
    'b2332,w2000,,,,w0010,,x,,,,x,b3232,w0021,,',
    'w2112,b2222,,b2233,,b3130,,,w1001,x,w1132,w0101,w0101,b2233,,',
    'b2320,,,,w2100,,,w1111,x,,,b3223,w1011,,,',
    'w1011,b2321,b1331,,,,w1030,,,w3310,b3323,,,,,',
    ',w1111,,,,b2332,x,,w0102,,x,,,,b3322,',
    'w1100,w0100,b3331,,w2131,w1031,b2323,,b3213,,w0010,,w3011,,x,',
    ',w0030,b2103,,w0103,,,,,,,b3303,,,,b3212',
    'b2122,,,w0110,,b3313,w2101,,w2302,w1023,b3032,x,,w1212,b2233,w0111',
    ',,,,b3331,w0011,b2133,,w0311,b2320,w0112,w1313,,x,,',
    'b2223,,x,,,w0131,,,x,b2223,w1000,b3032,x,,,w1121',
    'b2323,w3021,w1001,x,x,b3332,w0000,,w1002,,w1123,b3323,x,,b2022,',
    'w0010,b3223,w3301,w0100,w2231,,,b3332,,,w0011,,,,b2212,w0101',
    ',,,w1101,,,,,w0103,b2323,,,,b2223,,',
    'w1001,w1000,w0011,x,b2332,b2222,b3301,,w1030,b2201,w0101,,,,,w0102',
    ',b1232,b2033,,,w1110,w1100,,,,w1133,,,b3322,,',
    'w1000,,,w3030,b0220,b2323,w1000,x,x,w1200,x,w1000,b2010,w1110,b2232,',
    ',w0300,,w0111,,b2303,b3322,,,w1311,w1000,b0223,x,,,w1110',
    ',,b2232,x,w0012,b3332,w1001,,,w1111,,w1111,x,w0101,b3323,',
    ',,b2222,w3010,,,w0012,w0302,,b2222,,w1210,,b2223,,w1100',
    ',w1011,b2223,w0000,b2332,,w1010,x,w0211,x,w1011,,x,,b3223,',
    ',,,,,b0303,b2322,,b2232,w3110,,w0100,,,w0031,',
    'x,b3233,w1303,b0033,,b0333,w0110,x,b3210,b3202,w0032,b2122,x,w3130,w1010,b3203',
    ',,b1332,w1000,w2002,,,b2323,w2021,x,x,w1302,b3210,b0323,w1110,',
    ',b3323,w0022,w0210,b0232,w3110,,w1000,b3221,b1230,w1110,b1232,w1101,,,b2223',
    ',,,,b2333,x,b3323,w1111,w0100,b3223,,x,,w1002,w1111,w0020',
    'w0310,,b3202,,,b2323,,b3123,,,w0001,b0302,,w0111,,w1000',
    'w1113,w2110,w2001,b3222,b2233,w1102,,x,b1320,,b1323,x,,w0000,w1100,b3333',
    'w1121,,,w1100,b2323,,x,,b2022,w0000,w0011,w1321,,w1021,b3223,',
    'w1000,w0312,w1000,b3302,,w2001,,b2033,b3331,,w1010,,w0120,b3312,,b1323',
    'b3233,w1110,x,,b1023,,w0110,w0010,,w0110,,w1011,,b2033,b3233,w1100',
    'b2022,,w0103,x,b2233,,b2132,,,,w3100,,,,,',
    'x,x,,w1102,b1312,w2020,,,w1021,w2111,x,w0203,,b1022,b3311,b3302',
    'w0111,,,,,,,b3222,w0000,b3232,w0113,,,b3322,,w1101',
    'x,b2212,b3233,x,w1110,w0011,,w0113,,b2222,w2000,w3011,b3222,w1013,,',
    ',w0212,,b2312,,w0202,b3222,,b3212,b2233,b0321,,w1103,w0000,,w2110',
    ',,,,w1212,,b0233,w1010,w1001,,b3132,w1010,w0203,b3222,x,',
    ',b2333,,w0101,x,b0323,w1000,,b3320,w1012,b1320,w0113,w1000,w0002,x,b0021',
    'b3222,,,,b3213,,,w0130,,,,w0103,,b0332,,',
    'w1021,x,,b2232,b3023,,b2322,,,b2023,,w1111,w1001,,w1310,b2022',
    'b2222,,w0111,w0011,x,w0120,x,b3023,,w0010,w1110,w1031,,b3222,b2301,b1222',
    'w0100,w0211,,x,w3111,b1223,,b2302,w2010,,,w1121,b2233,b2223,w0003,',
    'b0302,w1101,b3321,b2233,x,,,b2223,,x,w0003,x,,w3111,,',
    'b1233,,,,b3332,b3003,,,w3111,w0301,w2120,,x,w0111,b0023,b3232',
    'w0101,x,w0300,w2011,b3232,w0110,,,w0111,b3123,,w1103,x,,,b2322',
    'w0000,w0000,,x,x,,w1310,w0020,w0103,w0000,,b3203,b0333,b3033,b3133,',
    'w3010,b3333,,b2333,,,w1102,,b3330,w2202,w1010,b2033,,,w0100,',
    'b3033,x,b3133,w0010,,,x,,b0332,,,,w0001,x,,w2030',
    'w1113,w2213,x,x,b3323,b2233,x,w1201,b3321,b2233,,w0020,,,w2001,w1130',
    ',b3321,,,b2232,w3310,,w0301,x,w1011,,x,,b3221,,x',
    'w0101,,w0311,x,b2203,w3003,,b2222,b2132,w1000,x,w1011,b2132,b3232,x,w0010',
    ',,w2102,b3203,x,,,,,w0101,,b3232,x,,b2102,x',
    'w1001,b0320,w1110,x,b3231,b2223,,,w3100,w1110,b3332,x,b0221,b3023,w1122,w1110',
    ',,,,w1131,x,b0232,,,,,b2133,w2010,x,x,b2232',
    'w0110,w1300,,w1110,,w1011,w1101,,,,b2023,,b3300,,b3231,w0100',
    ',w0011,b2103,b1203,w3300,b3213,x,,b3222,,,w1110,x,x,w0111,w1010',
    'b3323,w0101,,,b3123,w0020,w1012,b1222,w0001,,b2333,,,,w0301,',
    'w3001,x,,b3312,,b3022,,w3310,,b3332,x,b2232,w0101,w0101,x,',
    'b3210,b3222,,b2233,,w0101,,w1011,,w1130,b3232,w3211,,,b3032,',
    'x,w0200,b2232,w0001,b3023,b3230,,x,,w1010,w1030,b2222,w0130,b1222,x,w1000',
    'w1011,b0213,,b2213,w0110,,w0100,b3320,b2322,w0300,b3222,,,w1000,w0100,',
    ',b0322,b0223,x,w0010,b2113,b2033,,b0222,,,w0301,,,,w3111',
    ',,b3033,b0322,,,,w2100,,,b1332,b3333,w0100,x,w1000,w2320',
    'w1001,,,,,b3323,w1111,w1200,b2223,b3322,w1100,,x,,,w1110',
    'b1321,w0113,b2020,w0013,,x,b0322,b3323,w0003,,,w1330,b3322,,,w1000',
    ',b2222,w3001,,b2212,,,w0103,,,,x,x,,,b3132',
    'b2122,,b2202,b3320,w0001,b3030,w1111,b2223,b2220,,w0122,w0201,,w0131,w1110,x',
    'w0010,,b3233,,w3120,b2230,,,b0131,w1020,w0100,x,,b1322,w1001,',
    'w0000,,,w0131,b3032,w2110,b0321,,,,w0112,b3122,,b1333,,',
    'b3132,x,,w1101,b2203,b3322,w0201,,w2200,b3203,w0100,w0120,,,w0101,b2200',
    'b2212,,w0103,w0111,w1000,b3313,,w0010,b2312,,x,w0012,b2232,x,w0013,b3313',
    ',,,b2233,,,,b1122,b3230,w3012,,,w1000,,b0032,',
    'w1001,,w1111,x,b2021,b3222,b3222,b3230,,,,w0011,,w2011,,x',
    'w3113,w0111,,b3303,w1120,,b3333,,w1103,w0000,b3201,b2122,b3223,x,b3333,',
    ',w1101,,,w0100,,b2322,b0313,,w0101,,b3321,,b2011,,',
    ',w2111,b2232,,,,,,,w1100,,b3322,,,,',
    ',b2023,w1000,,w0010,b2211,w0131,w1121,b3002,b3222,b2232,w0310,x,,b3023,w0001',
    'b0322,b3133,b1332,b3322,w1211,,w1102,b3222,x,b0232,,w0021,,w1211,w2030,x',
    'w1321,b0200,w1100,,,x,,b2231,w0102,w0101,x,,b2212,b1332,,',
    'b2033,b2310,w0101,b2323,b3233,b3222,b3112,,w2010,w0111,b1032,w1102,,,w3011,w1011',
    'b3032,b0223,b0223,w0021,,b3232,w1011,x,,b2303,,w2013,b3202,w1111,,x',
    ',,w1010,,,w1102,b2221,b3333,w1203,b2311,,,x,,b1033,w0001',
    'w3311,w1111,b2123,x,w0111,b2310,w1123,,b2233,b2223,,b2232,w1131,,b3331,',
    'w0000,w1000,w1301,,,b0333,b2323,,x,,,w2011,x,b2221,b2200,x',
    ',x,,b3102,,b2303,,,,x,w2303,,,,,b3323',
    'w1000,b3331,w3011,b2211,x,b3320,w1001,b3122,b3311,b3232,x,w0011,w0311,w0110,,',
    ',,,,b2232,w1113,,,w0021,b3300,,x,,b2323,b3221,w3013',
    'w3103,,x,b3322,b3032,w0211,w1010,b2300,w0011,,,,b3232,w0103,w0011,b2023',
    'w1011,b3232,w1201,w1103,w0121,b1332,,,b3323,,,w3111,b3322,w1003,b2232,',
    ',w1111,b3220,b2030,w3331,,w1100,,w0100,b2323,w1202,b1320,w3001,,b2222,b2232',
    'b2302,w1201,b2303,w0021,,,b2300,w1211,,x,b3223,w1013,x,x,b2323,',
    'b0233,w1300,b2022,x,w2120,w1101,b1223,b1303,b2332,b1322,w0010,b0232,w1010,x,x,w1133',
    'x,x,w1311,b1122,b1233,,w1220,,x,,,w1000,,w1133,b0322,b2322',
    ',b2333,w1113,w1111,w1000,,,b3232,w2011,,b1212,,,w2101,b3332,w2110',
    'b1213,w1111,,,b2332,x,,,w1121,b3312,,w0111,,,b2331,',
    'x,w1310,w2000,b3012,b1322,w3110,w1111,w1103,b2332,x,b2232,x,w3010,b0222,,',
    ',w0000,,b3333,w0010,,w0012,w0131,,b3022,,,b2323,w0001,,',
    'w0012,b0201,w1011,,,,w1001,,,x,w0001,x,b2231,b2330,,x',
    ',w0000,,,b0211,,w1011,b3222,,x,b0232,,b3221,,w1120,w3131',
    'x,b1232,x,,,,,,w0210,,,b3333,,,w0111,w1002',
    'w2000,,w2110,x,,w0011,x,,,b2222,,x,,,,b2223',
    'b2333,w1102,,b3333,,w1201,x,w2100,b3130,b2323,b2031,,x,w0101,w1100,w1300',
    'w1102,b3322,,b2332,,,,,,,w0121,b0222,,w0002,b2133,w1111',
    'b2002,,w1011,w1011,,w1102,w3121,,b3323,,w3310,b2233,b2223,w1300,,b2221',
    'w1020,w1100,b2223,b2323,,w0011,b3302,w3002,,x,w1030,x,,b2023,b2231,x',
    'w1001,,b2230,,,w0111,,,w0001,w0101,b3221,,,b3333,,',
    'x,w1102,w1001,b2233,,w3110,b3202,,x,b3323,b2330,b3222,,w1000,,w1010',
    ',b1300,w1001,,b1232,w0100,w0010,b1221,b2332,b3322,w1321,,w1120,w0020,,',
    'w0001,,w0101,,,w3020,,b2203,,b2223,,b3033,,,,',
    'b3030,b3223,x,,w1111,,w1120,,,w1011,b3333,,w0013,x,b0322,x',
    'w1100,,b2213,,w0110,w0113,b2323,w1300,b0330,x,w0102,b3302,,,,x',
    ',,b3222,,w0311,b1232,x,w0121,x,,,w1110,w1000,w0010,b3312,x',
    'w3010,b3132,,,,x,b2223,,x,,b2221,x,,w1102,w0031,w0210',
    'w0113,w0310,b0223,,w2011,,x,w1031,b3222,,b2332,,,x,,w1032',
    ',,,b3313,,b3332,b3303,w1101,,,b2332,w1103,w1012,,w0033,w1110',
    ',x,,w1012,w1001,,,,b3003,,w1031,,,,b1223,',
    'x,b3002,w0011,b2223,w1210,,,,,,x,b2321,w3111,w0221,b2031,b3320',
    'w1310,w1210,,,b3332,b3233,,,x,b0203,w1011,,w3101,x,,x',
    'x,w0021,b3022,x,b2123,,,b2333,w1002,,w1110,,,,,x',
    ',b3333,b2330,w0011,w1120,x,w0030,b3223,,,w0113,,b3323,w1131,w0310,',
    'w3101,,,w0011,b1233,b2233,w0000,,x,w1100,,,,w3011,w0101,b2232',
    ',,b3133,w0313,w1203,,b1130,,x,b3023,,b0223,,w3001,w0013,w3311',
    'b2232,,b1033,,w2010,b3223,w0001,w1000,b2202,x,w1101,b2222,x,w0010,,w1001',
    'x,b2333,,w0111,,w0112,w1100,x,w2110,,b3022,b2333,w1130,w3023,,b2213',
    ',w2002,,,,w3101,b2322,w0002,,w1021,,w1120,b2203,w0110,b1333,b3122',
    ',,w1001,,x,,b3323,w1031,w2210,b0323,,w1000,b3223,w0011,w2000,b2221',
    ',b2223,,b2303,w1011,w2002,,x,x,w1011,b1322,,,x,w2311,',
    ',b3302,w1111,w0031,w0121,b2202,,,w0310,b3320,b2232,w0101,b3332,w0101,,',
    'b3320,x,w1100,w1011,b3322,w1131,w1110,b2302,x,x,b2321,w1023,b1322,b3332,,',
    'b2123,w1030,x,x,w1000,w1101,b2313,b3030,w3030,b3303,,w2200,,,w1020,',
    'w1101,x,,b3330,w1013,w1000,b3022,,,w0001,b3022,w0200,,b3103,,',
    ',,w0002,,w0010,,,,,w2011,b2302,,b0223,b2032,w1231,w0111',
    'b3233,,,,,w0300,,,w1100,b1223,,w2111,,,b3332,',
    ',x,,,w1103,b3122,w1110,x,b2212,w0100,w1100,w1201,b2131,x,b1222,',
    ',x,x,b1123,b0313,,,w3303,,,,,w0101,,b0223,',
    'w0001,w1001,b3233,w0110,,w0110,w2100,w1122,,b0232,,,,b0303,b2202,',
    'b3232,x,,x,w1011,,b3222,x,b2332,w3210,w1111,b2323,w0101,b3322,w0301,w0102',
    'b2333,,w1011,,b2312,,,w0111,,,,w1111,,w3113,b3333,w1211',
    'b0023,x,,b0233,w0301,w0102,w3011,w0110,x,w0001,b1232,w1212,b0111,b3323,,b2332',
    'b2222,x,b3223,w1110,w0111,w1100,w0000,,,,b3132,,w2010,x,,x',
    'w0210,b2322,b2202,w1130,w1202,w1001,,b2231,w1110,b2332,,,,w0203,b1322,b3323',
    'b1023,x,,,,,w0202,w0302,x,b1332,w2012,x,,b2222,,',
    'w1110,b3311,b3332,w2111,b3222,w0301,b3332,,x,x,w0121,w2111,x,,b2233,w2010',
    ',w0110,w1021,,b2202,w0130,b2230,w0110,,b3332,,,w1001,b2311,b2331,w3001',
    'w2130,w1121,w1210,,b2100,,b1332,,x,w1002,w1001,b3233,,b3203,b2133,w0001',
    'w2022,w1102,,w0100,x,b3220,w0113,b0033,,,w1222,b3223,,b3330,,',
    'b3213,b3032,,,x,w2010,w1010,,,w0011,w1211,b3203,,,x,b3223',
    ',w1100,w1100,,w0010,x,,w1310,,b2130,,,b3122,,w1023,b2323',
    'w3011,b2233,,w3111,,,,b2213,b3133,x,,,,,,',
    'x,,w2110,x,,,,b3123,w0131,,,,w0001,b3222,b3212,x',
    'w0001,,w1100,x,,x,w1100,b1302,b1123,w2100,w1000,,,,b3121,',
    ',b2023,,b3131,,,,,,b3302,w1111,w0100,,b3330,,w1100',
    'b0201,,w3010,w1001,w3200,b3332,x,w2000,,w2200,,b3333,b2333,,,',
    'b3133,b3313,,b3030,w0100,w2210,,,x,w0000,b2320,,w0200,w2000,w2000,x',
    ',b3303,b3233,,,,,,x,,,,,w1102,,w0000',
    'b3302,w1011,w1111,,w2000,b3222,b2202,,x,,b3322,,b3232,w3030,,w0101',
    'w1102,,w0001,,w1111,b2320,w0100,x,w1111,,x,x,b3222,b3023,b3312,b3133',
    'x,,,w1010,,w1011,b3222,,b2331,,,b0232,x,w1102,b1020,',
    'w3010,,,,w1021,b3331,x,b3303,,w2000,w0011,b2222,b3203,,,w0111',
    'b2233,x,w1121,w0123,b2332,,w1230,,b2322,x,b1332,w1111,,,b3033,',
    'w0310,,w1110,w2111,x,w3101,x,b2332,b2332,b1323,x,b2123,,w1103,w3111,b2022',
    ',b2322,,x,w0000,,w0033,b3302,x,,,b3222,,,x,',
    ',,b1210,,w0103,b0313,,w1300,,,,b3223,b3301,,,',
    'w0203,w3110,w2130,,b1122,b2322,b0232,b2233,,,w1001,,w1000,b2322,b2131,',
    ',b3320,,w0101,,,,w1011,,,b2233,,,,,',
    'b3311,,b2322,,b2312,w0011,,,,,b3232,w0010,,,,w0321',
    'w3311,,w3101,,b2223,,,,b2232,w0000,w2330,b2222,b3013,,,b3223',
    ',,b2333,x,,w1101,,,w0002,x,,,w1001,,,b2322',
    ',b3122,,,,,b3323,,w0100,b0232,,,,w2301,,',
    ',x,b3320,b3303,,w1300,,b2322,b2222,b3330,w1000,x,w0013,w1321,x,w0110',
    'w1010,,w1301,b0203,b2220,,w2030,x,w1101,,w1103,x,b1333,x,b3323,b3322',
    'b2332,b2232,w0101,b2023,w3201,w1011,w0100,b2222,b2232,x,b3000,w0310,x,,w2111,',
    'w3211,,,,,b3223,,,b3022,w0110,w1131,,w1121,b2332,,',
    'w0100,b3112,,w1001,b3323,w0121,b2323,b0233,,w1000,w2111,b1310,w0012,x,b2202,',
    'b0232,w1001,,b0132,,x,w1101,w1110,,b2032,,b2233,w1300,b3232,b1320,',
    'x,b3332,,b2222,,w0132,,b2221,w0010,,x,b3230,w1300,x,w1303,b1322',
    'w0001,w3101,,x,w1001,,b2222,w1111,,b2132,b3233,w1111,b2322,,,b3203',
    'w1111,,,,,b1133,,,,w1010,b3222,,,x,b1033,',
    'w1101,b3220,w0110,,w0101,b2323,x,,b3301,w2111,w0001,w1000,b3132,,b2203,b1330',
    ',,b0233,b2332,,b2220,,b2132,w2000,,,w0013,x,,,',
    'b3312,,w0031,,,,b3120,w3011,b2320,,b2133,w1001,w0010,,b0232,w3002',
    'w0212,,b3013,b2203,,b3023,w1210,w1132,w1031,b2232,,,b2323,,,',
    'x,x,b3322,w1101,,,,b2302,,w0101,b3022,w1011,,w0223,x,b3223',
    ',,x,x,,b2233,w1011,x,,,b2233,w2110,,,,w0011',
    'b3322,w1000,,w2030,,b0332,,,b3223,b0323,,,,,w0111,w1103',
    ',w3110,,,b0233,b2303,,,w1030,x,,x,,b2132,,',
    ',b3233,w2310,,,x,w1001,w3201,w1011,w0011,w0113,x,b3223,b3132,b3221,b2333',
    'w1131,b2122,,w0103,b3023,w2110,x,b1223,w3011,b3310,x,,,,b3202,x',
    'b3332,x,x,w1130,b3222,b3310,w0101,b2202,w1112,b0323,x,w2110,w0001,b2230,,w0111',
    'w1213,x,w0100,b2212,w1212,b3323,b2222,b3322,w1211,,w1332,b2332,,b1323,b0132,w0110',
    ',b1323,,b3330,,,x,,b2122,b1200,w1111,w0311,b3022,,w3101,',
    ',,b3333,,b0312,,,w0001,w1320,b3032,b3313,,,w2111,w2211,b2232',
    ',,b2332,,w0112,w0021,x,b3231,w3100,b2233,w0113,b2233,x,b3332,w0120,w1311',
    'b2231,,,w1001,w1020,b0232,b0322,,w1000,,w2023,,,x,w0010,b3323',
    'b0233,b2303,b2221,w1000,w0033,,,w3101,,,w1111,,b2223,b3230,w0021,',
    ',b2323,w2110,w1210,w1111,,b3013,b1320,,w1111,b2203,w1231,b2322,w1001,b1222,b3333',
    ',,,w0221,,w2011,,b3333,,,,b2232,w1011,,,',
    'w2011,w1001,,b3323,,w1011,,,w0001,x,b3323,w1100,,x,b1320,w0100',
    'x,,w1121,w1320,,,,b3323,w1011,b2332,x,,b2330,x,w1010,',
    'x,b3212,,w3011,,w1021,,,w0301,w1211,b3232,w0110,b2233,w2100,,b3322',
    'w1011,,,b0222,w1000,b2032,w0001,,w2110,b3211,,,,b2323,b3322,w0120',
    'x,b2233,w2101,,b3333,,w1001,w0201,x,w1311,w0011,b2323,b3233,,b3233,w2013',
    'b2130,b2122,w1101,w0310,,b2022,,w1011,b2022,,w1212,,b2303,b3333,w1011,w1111',
    ',,w0330,w1300,b3310,b3123,b2123,b2122,x,w0230,b2202,x,x,,w0102,',
    'b2222,w1121,b3222,b3302,w1131,w0111,b3131,w1121,w1100,w1010,,b2223,x,x,,b1300',
    'b2230,,x,,w2101,,b3332,,,,,,w1001,b2331,w1011,',
    'w0001,,b3122,,b0232,,,,,,,,w1031,b0313,b2032,w3011',
    'w3013,w3010,w1311,b2303,x,w1100,b2232,x,b3323,x,b1322,,w0110,b3332,,w0000',
    'b3223,w1101,,,,b2323,b1232,w2113,w1110,w1233,b3222,,b1320,b0121,w0001,',
    'w0101,,,,w0100,b1313,w3031,b2032,,b2212,w2121,b2312,,b2221,,w3000',
    'w1001,w1312,w0200,b2223,w1000,w0111,b2221,x,,x,,b3223,w3101,b3203,b1321,',
    ',,,,x,b2333,w2010,,w1030,,,x,,,b3233,',
    'b2233,,w0001,b1023,,,,w2111,,,,,b3301,w0011,,',
    ',b3223,,w1011,w1111,w3020,w3100,b2222,b2103,b1312,,w1023,b2332,w1331,x,b1312',
    'w1210,b3332,,w1211,,,b2232,x,b2032,,b2132,,,,w3100,',
    'w0001,x,x,b3232,,w1001,,b2323,,b2213,w1000,,w1323,,w2001,b2133',
    ',,,,b3233,w0001,,,,,,,w0111,,w0110,b3322',
    'b2333,w1010,w0011,b3023,w0010,b2310,,,w0202,b0203,b3223,,,b1323,,w0231',
    ',,w1100,b2133,,,,,b1322,,,,w0101,,,',
    ',,,w0011,,w1200,,b3333,,,b2322,b2232,,w0113,,w1121',
    'w1112,w1111,w2101,b2323,b2232,w3000,b1011,,b2020,w0101,,x,x,b3333,w0101,x',
    'x,x,w1110,,w1101,w1301,w0000,b1232,b0332,b2233,b3332,b2022,,,w2310,b3220',
    ',b3322,,w1003,x,b1232,b2032,b0322,,,,,x,w0011,,w0021',
    'b1332,w1000,b2233,,b3203,b0221,w1100,w1103,b3322,,w1100,w3113,,b1332,w3100,b3222',
    'x,w1111,w2111,b3313,b2323,,,b2233,w1301,,,w0201,w2133,b2322,,x',
    ',,b2322,x,w1200,,x,b3133,w1311,,,x,,,w3100,',
    ',w0111,,,,b3333,,b3231,,,w0111,,,b2132,,w3000',
    'b0332,,w1011,x,w1310,x,b3331,b2233,b2033,w1310,,b3313,w3111,,,w0303',
    'b3323,,,x,,,,,x,b3223,w0110,,x,w0310,,',
    ',b2212,,w3110,,b2302,b2113,,b3232,w1003,w0301,,,w3200,w0111,w1111',
    'x,,x,,x,,b2332,w1301,w0010,,,w0011,w0020,,b3323,',
    'w2000,,x,,,,w0113,,b2312,x,b3030,,b0032,w0010,b2232,w0130',
    'b0223,x,w1000,,,w0113,b3333,b3333,,w0100,,,w1303,x,,x',
    'w0300,w1111,b3332,,,w0101,,x,w0101,,x,b2333,w0011,b3233,,w1310',
    'w3111,x,,b0201,w0101,x,,b3223,b1222,b2223,x,,w0000,,,w0230',
    'w3010,,,,x,b2322,,,w1120,,,,,b3230,,b1232',
    'b2322,w1012,b2323,,w0023,b3332,,w1031,w1021,x,,,x,w1011,b3331,w1110',
    'w1002,b2332,w1001,w3000,b2322,,b1313,w0011,,b3312,,w3011,,,,',
    'x,w1002,b3230,,,b2322,b1222,b0232,w1030,w0111,,b3230,,w0113,w0100,',
    ',w1011,,,,b3203,,,x,w0101,,,x,b3232,,',
    'w3100,w1002,b3223,,,,w0210,b3321,x,,b2222,w1121,w1012,w1030,x,x',
    'b3223,b0302,,w1031,b3312,b0332,w1210,x,,b2213,w1310,w3132,w3120,,,w0300',
    ',,w1001,,w0001,,w0100,x,b3333,,,,w1021,,,b2303',
    'w0012,w0200,,,w0011,b0333,,,w0020,b2130,,b2332,x,,,',
    ',x,,b2323,w1000,,b2232,,w1010,,w1311,w1200,w0301,x,b2222,b3223',
    'w1101,w1320,,b2231,,,x,,b2323,,b3222,w1111,,,w0012,x',
    'x,w0112,b2231,,,,x,,b3320,,,w0111,w0110,b3222,,x',
    ',w1132,b3223,w1021,b2312,,b1332,w0101,,,b3230,b2321,b2302,w0110,w3100,',
    ',,,,w2110,,w1011,b3133,b0233,b0222,b3130,,,,,',
    'w1020,,b3223,w0110,w3100,b2322,x,w3100,w0100,,x,,,b3232,x,',
    'b3332,,b2322,w0213,w0310,,,w1111,,b2323,,,x,,,x',
    'w1011,,w1100,w0101,,,,b2222,b2323,w0002,,,,x,b2333,',
    'w1131,x,b3232,w3110,w1011,x,b0223,,b3322,w3020,,w1100,w1310,b3230,x,b2323',
    'b3332,,x,,w1002,b3130,,w0131,b3323,w0330,b0330,,,,,',
    ',w0001,,,,x,,,w0301,b2322,x,,x,b2233,w2011,',
    'w0031,,b3312,,b3002,,x,x,b0232,w0123,w0000,w0100,x,b2331,w1030,',
    ',b2333,w0111,x,b2222,,,w1101,w1000,b3232,w1000,,w1030,x,,b1230',
    ',b3323,,b1323,,b3223,,w1201,w0320,,,b3230,w2300,,w0230,',
    'x,w0301,b2232,b3200,b3122,w3010,b2323,,w3010,w2111,,,,,w0311,w1310',
    'b2223,,b2213,b2320,w0313,b2331,w1210,w0003,w0110,b3231,,b2232,w1011,,w0100,',
    'w0102,b0310,w1211,,b2332,,b3320,,,,,,b3331,x,w2000,',
    'w0031,b3203,x,w0001,w1101,,b2222,,,b2222,w1331,,w0010,w1011,b3233,b2123',
    ',,b3323,,w1211,,w1010,w0110,,w0101,b1223,,b2322,,w1211,',
    'x,,,w3000,w0010,,w1001,x,b0221,b2232,,x,w0012,b2322,,',
    ',,w0000,,b3322,,,w2001,b0220,b2212,w3021,,,w1100,w2011,b3222',
    'w0010,x,,,w1012,x,,x,b3231,,,b2332,,,b1230,w1111',
    'b2233,w1100,w1110,,w2130,x,w0101,w2120,w3001,b3332,b2323,b2330,b2321,,,x',
    ',w1111,b3230,,,b3323,w0111,x,,w0011,,w1210,x,w0000,b3133,',
    'b3033,w2230,w0022,w0000,,,b3333,b0133,b1323,,x,b3030,w3100,b0233,b3002,w2300',
    ',w0102,w0010,b3310,x,b0203,b2231,b2033,w0000,b3123,w0200,w0013,x,w3003,x,b1233',
    'w1001,b1333,w1000,,,,x,,x,,,w2212,,,,b3331',
    'w0300,b0323,,,b0333,b3013,,w0033,,,x,w0020,,b3303,x,',
    'w0001,,,w3210,w1100,,,,,b3220,,x,,b2332,b3323,w0001',
    ',,,,b2222,,,w2110,,,w1101,b1211,w1200,,b2223,w0011',
    ',x,b3303,,w1201,,w1011,,x,b3332,x,,w1021,,,',
    'w0010,x,w1001,b3222,b2302,,w0100,w1102,b3323,b2202,,,b3220,w1110,b0332,w0010',
    ',w2112,w2101,b3230,x,b3330,,b3332,w0010,,,,x,x,b1300,w1100',
    'b2333,w2110,,w0102,x,b0222,,b2333,,,b2231,w0111,,b3302,,w0113',
    'x,w2000,w1111,b2313,x,w1200,,,w3021,w0000,b3212,b2231,x,,b3323,',
    'b3302,w1110,b0323,w1301,b3232,,w1103,w1302,,b3221,w1101,,b1223,w1111,b1323,b3323',
    'b0223,x,b2233,b3322,x,x,w1110,,w0311,b2232,w1030,,b3322,w0000,w2110,w1103',
    'w1300,b2323,w0011,w0001,b2132,,w1111,,b0233,w1111,,b2320,b3221,,b3203,b2330',
    'x,b3320,w1201,,w2010,w2000,b2323,w2011,b3211,b3210,,x,w1102,w1313,,',
    ',,w0011,,b2013,,,,b3220,,,w2011,w0032,b2133,,b2320',
    ',b2321,b3220,,b3022,,,,w0020,b3323,,b0213,w2112,w1113,,',
    ',,,,,x,w1202,,x,,,,b2032,x,b1332,b3023',
    'b2202,,b3033,,b2323,x,w2110,b2031,w1201,w3301,b2333,,w1012,w2312,b1223,b2022',
    'b3012,b3212,x,x,b3033,w1111,x,w1010,,b0233,w1111,w0200,w0210,b2322,b0220,w1010',
    ',b3221,w1101,b1231,b3333,w1010,b3032,,w0113,x,w1133,b3231,,w0002,x,w2121',
    'w1301,b3022,,b3233,,b2333,,,w0000,w1012,,w0020,w1013,,b2332,w1100',
    ',b2322,,,w0210,b2200,b1310,w2010,b3330,w0300,w1110,,,b1122,,w0111',
    'b3013,b1323,,,w0011,x,w0011,w1011,w1000,,b3133,,b3322,b1022,w2022,',
    'x,b2302,,w0121,,w1202,,w0311,,b2333,b3333,b3320,w2311,x,w3030,b3332',
    'b3321,,b2100,w0110,,b2303,w0012,b3313,b0331,x,w1113,,w1121,b1332,w0130,x',
    'w0310,b2323,,w0310,b3023,b2322,,,w1103,b3323,w1101,,,w0200,,',
    'w1110,w0021,,b3022,,b3333,w1120,w0031,w0300,,,b2332,,b0223,b0222,b2322',
    'w0303,w0112,w0112,,b2322,,,b2222,b2323,w0110,b2332,,b1232,w0110,b3033,w3100',
    ',x,w1011,,b2232,b3332,,w0032,b2223,,,,w2212,b3113,,',
    ',,w1001,,b3333,,,b1333,,w3111,w0210,,w0010,,b3032,',
    'w1122,,x,w0101,b2123,w0000,,,w0001,,,b3232,b2333,w0101,w1310,',
    'b3221,,b2322,w0010,w1010,,,,x,,,x,w0001,b3313,,w1021',
    ',w1111,w0012,w0031,,b3231,,w0011,b3213,,,w1021,,b3221,b3323,',
    'w1001,w1001,,w3100,,,,b2220,,,b2321,,w0300,b3233,,',
    'w0311,w1130,b2332,,w0110,b3233,x,,b2223,,w1100,,x,,w2013,w0112',
    ',b2332,b3332,,x,x,w1011,w1021,x,,w0130,b0212,w1110,b0332,w1201,b2232',
    ',,,w1110,w0100,,b3033,b2212,b3233,w1101,w1003,w3320,x,b2302,b2333,w1111',
    'w0310,b3333,b2220,,x,,w0031,b0232,,,w1101,b3322,,,,',
    ',w0020,w3011,b1333,,,x,w1311,w1020,w1120,,b2232,,,b3333,b2331',
    ',,,,,b2012,b3333,,,w0201,,,,w0001,w0011,b2213',
    'w1011,b3332,w1010,,,b3232,b0022,w2331,,,b1123,,b3230,,x,w1130',
    'w0011,b2322,w1110,w0010,b1233,,,w1000,,,w0111,,,w0031,b0003,b3310',
    ',,b3230,,b3222,,,w2101,,,b3023,w1120,w1102,,w1130,b2123',
    ',,w0000,b3232,,,w1001,b3120,b2321,w1031,b3233,,,w2211,,',
    'b3123,,b2332,b2122,w1000,w1111,w1101,,b2302,b2222,b3232,w3011,w2100,,w2012,b2223',
    ',,b3332,b1222,,b2233,,x,b1222,w1000,w3002,w0000,w3110,b3302,w1100,',
    'w1110,,,,b2223,b3332,w1102,x,,w0110,b2322,,,,b2233,w2300',
    'x,x,,w0000,,w1113,,,,b2322,b2223,x,,,w1103,b2213',
    ',w0111,,b2302,b3222,b3332,w0011,b1323,x,,w0100,b2313,w0113,,,w1210',
    ',w0110,,,,w0010,w1102,b3333,b0223,,x,x,w1130,b2233,,x',
    'b3313,b2030,b3333,w3111,,w2130,,,,w3330,b2321,,b3233,,w3230,b2232',
    'b1333,w0003,,,,w0121,w1031,,b2013,,,b2323,,b2033,,',
    'w0010,b2230,w0231,w1110,,,b3332,w2132,,b2232,b3232,w0000,,,,',
    ',b2012,x,w1100,,b3332,,w1201,x,b3100,w1001,b2123,x,,w0111,w1011',
    'w1011,b2323,x,w1103,,x,,b1330,w1000,w1103,,,,,,b1320',
    'w1111,b2333,w1110,w3001,w2033,w0100,x,b2233,b1331,,,,x,b3022,,x',
    'b3233,b3130,,,w1013,,,b2323,b2110,b3030,w1300,,w0001,w2112,,',
    ',,b2232,x,w0011,,w0101,,b2223,x,,,,,w0011,b2102',
    ',b3232,,,b1232,,x,,b3202,,w0213,,b3032,,,w3010',
    'b3302,b2232,b3033,w3020,,x,x,w1002,b3231,w2201,,w0230,w3111,b3221,x,w0101',
    ',b3232,,,w0110,w1112,,b3333,,x,,w1011,w1230,x,b2032,b2223',
    'w0013,w0300,,b3211,,w3000,b1232,w0110,w0001,x,,b2322,w0111,b0222,,b0233',
    'b2333,w1132,,,w0110,b2033,w0000,b2222,w1313,,w0110,,,,b2320,b3232',
    'w0021,b2131,w1330,,,x,,,,,b1221,b2202,w1230,b3323,x,w0010',
    'x,b3032,b3122,,b3213,w0100,b1303,w2030,,x,x,,,w0112,,',
    ',,w1120,,,,b3333,w3130,x,b3232,,x,b2231,,,w0111',
    ',w0011,,w1001,,w1113,b2332,b2222,x,,,x,b3221,,,',
    'b3332,,w0000,,w3120,,w1121,w3111,w2003,,,w1011,b3333,,b2322,b2232',
    'x,x,b1333,,b2103,,,x,b3322,w0020,w2212,b2223,,w0001,,w0100',
    ',,w1011,w0120,b3330,b2331,,,b3023,b2230,x,,w3010,b3122,w0001,b2022',
    ',,,,b3220,b0023,,b2202,,,w0010,,b1223,b3133,w3311,',
    'b3303,x,b2223,b2002,b0313,x,,,,w1300,b2330,w1210,x,,b3020,w3131',
    'w0310,,w2100,,b2232,b0322,,,b2333,b0232,,w3001,b1220,w0010,x,x',
    'w0000,,w0101,w0101,b2333,,,b1322,b2230,b1222,w0110,w0002,b1223,w1320,b2232,',
    ',b3302,x,w0002,,x,w1101,b3333,,w1000,,,b2333,b3031,b2222,w0033',
    'b3220,b3032,,b3222,w0101,b3203,,,w1030,w1213,w3212,b2222,,b2232,x,',
    'w0111,,w2100,w2033,b3333,,w1101,,b3232,b3123,w0001,w0121,,,b0112,b3333',
    'w1011,,b2222,b2220,x,,,,,b2320,w0003,,w1200,w1110,b2222,b0322',
    ',w1213,w0210,w1001,b2220,w0023,,b3122,b1223,b2230,,w1132,,b3323,b2233,',
    'b3222,,b2223,w0032,,,b3203,x,,w1301,w1010,,,x,w0001,b2321',
    'w1032,b2033,,,,b2232,,b2222,x,,w2010,,,b3323,,w1211',
    'w0101,w1011,b3230,b1333,b2202,w0303,b0223,,b3233,b0223,,w1233,x,x,x,w0110',
    'w0102,b3222,,b2030,b0223,,,,w1011,b2222,b3223,w1001,w0111,,,',
    'w0100,,b2323,,,b0322,,b3230,,,,w2300,w0000,,b1020,',
    ',,w3113,x,b3223,,b3333,,,,x,,x,,,w0011',
    'w1121,b2301,,w0100,b3331,b3232,w0201,w0121,b3030,,,b0000,x,b2333,x,',
    'w0220,b0323,b2121,,b3333,b1223,,b3302,,,w0101,w0010,w0000,,,w2011',
    ',,b3232,b3133,w1120,w0010,w0011,b2230,b2332,w1012,,b3323,b2313,b0120,w0101,w0102',
    'w1010,b3032,w0121,x,,b2223,w1202,b3032,x,w1120,b3302,w1111,,x,b1233,w0001',
    'b3333,b2222,x,w3001,x,w1021,b1222,b3022,,w2111,,,b2322,w0011,x,w2010',
    ',,,,,b3201,,,,,w2013,,b3232,,b2202,',
    'b3221,,x,w0030,,b0332,,,,b0020,,,,,,',
    'b2231,,,,,,w1110,,b3032,w3011,b3202,,,b1203,b3213,',
    'w0101,b2223,b2021,,,x,x,w0132,w0101,x,b2033,,,w0001,b2223,b3332',
    'b3231,,w1311,b3310,w0123,b2233,,,b1323,w0000,w0000,b1213,w2000,x,b2221,w1111',
    'w1101,b3303,,,,,,b2221,,b2022,x,b0223,,w0030,,x',
    ',,,b3203,,,w3110,,b2133,,,,,b0313,,',
    ',w0100,,,,w0010,,w1010,b1310,b0113,w0011,b2103,b3032,w0011,b3332,w2100',
    'w1110,,b2012,x,,b2120,,x,x,b3313,w1321,b2023,b1333,w0131,b2233,w1100',
    'x,b3133,w0111,w1120,,,x,b1320,,b3033,b0232,w0131,b3231,b3220,,'
  }
end

-- <TILES>
-- 000:0000000000000010000010110000110000110000000100000010000001100000
-- 001:0000000010000000110100000011000000001100000010000000011000000100
-- 002:0000000000000101000001110000100000010000001100000001000001100000
-- 003:0000000001000000111000000001000000001000000001100000010000000110
-- 004:0000000000000010000001110000100000010000001100000001000001100000
-- 005:0000000010100000111000000001000000001000000001000000011000000100
-- 006:0000000000001010000011110011000000010000011000000010000001100000
-- 007:0000000010100000111000000001000000001100000010000000011000000100
-- 008:0000000000000101000001110000100000110000000100000110000000100000
-- 009:0000000001000000110100000011000000001000000011000000100000000110
-- 010:0000000000000010000001110000100000110000000100000110000000100000
-- 011:0000000010100000111000000001000000001100000010000000010000000110
-- 016:0010000001100000000100000011000000001100000010110000000100000000
-- 017:0000011000000100000010000000110000110000110100000100000000000000
-- 018:0010000000010000001100000000100000000110000000010000000100000000
-- 019:0000010000000110000001000000100000010000111000000100000000000000
-- 020:0010000001100000000100000000100000000110000001010000000000000000
-- 021:0000011000000100000010000000110000110000110100001000000000000000
-- 022:0010000001100000000100000011000000001100000000110000001000000000
-- 023:0000011000001000000011000001000001100000101000001000000000000000
-- 024:0110000000100000011000000001000000001100000010110000000100000000
-- 025:0000010000001000000011000001000001100000101000000000000000000000
-- 026:0110000000100000000100000011000000001100000010110000000100000000
-- 027:0000010000001000000011000001000000100000110000000100000000000000
-- 032:0000000000000000000010100010111100011111001111110001111100111111
-- 033:0000000000000000101010001111000011111100111110001111110011111000
-- 034:0000000000000000000101010000111100111111000111110011111100011111
-- 035:0000000000000000010100001111010011111000111111001111100011111100
-- 036:0000000000000000000010100000111100011111001111110001111100111111
-- 037:0000000000000000101000001111000011111100111110001111110011111000
-- 038:0000000000000000000001010000111100111111000111110011111100011111
-- 039:0000000000000000010100001111000011111000111111001111100011111100
-- 040:0000000000000010000010100000111100011111011111110001111100111111
-- 041:0000000000100000101000001111000011111100111110001111111011111000
-- 042:0000000000000100000001010000111100111111000111110111111100011111
-- 043:0000000001000000010100001111000011111000111111101111100011111100
-- 048:0001111100111111000111110011111100001111000101010000000000000000
-- 049:1111110011111000111111001111100011110100010100000000000000000000
-- 050:0011111100011111001111110001111100101111000010100000000000000000
-- 051:1111100011111100111110001111110011110000101010000000000000000000
-- 052:0001111100111111000111110011111100001111000001010000000000000000
-- 053:1111110011111000111111001111100011110000010100000000000000000000
-- 054:0011111100011111001111110001111100001111000010100000000000000000
-- 055:1111100011111100111110001111110011110000101000000000000000000000
-- 056:0001111101111111000111110011111100001111000001010000010000000000
-- 057:1111110011111000111111101111100011110000010100000100000000000000
-- 058:0011111100011111011111110001111100001111000010100000100000000000
-- 059:1111100011111110111110001111110011110000101000001000000000000000
-- 064:0000000000000001000000100000010100000101000001010000001000000001
-- 065:0000000010000000010000000010000000100000001000000100000010000000
-- 066:0000000000000001000000100000010000000100000001000000001000000001
-- 067:0000000010000000010000001010000010100000101000000100000010000000
-- 068:0000000000000001000000100000010000000100000001000000001000000001
-- 069:0000000010000000010000000110000001100000011000000100000010000000
-- 070:0000000000000001000000100000010000000100000001000000001000000001
-- 071:0000000010000000010000000010000000100000001000000100000010000000
-- 072:0000000000000001000000100000010000000100000001000000001000000001
-- 073:0000000010000000010000000010000000100000001000000100000010000000
-- 074:0000000000000001000000100000011000000110000001100000001000000001
-- 075:0000000010000000010000000010000000100000001000000100000010000000
-- 080:0000000100000001000011010000101100001010000010100000001000000000
-- 081:1000000010000000101100001100100001001000010010000100000000000000
-- 082:0000000100000001000011010001001100010010000100100000001000000000
-- 083:1000000010000000101100001101000010010000100100001000000000000000
-- 084:0000000100000001000011010000101100001100000011000000010000000000
-- 085:1000000010000000101000001110000010100000101000001010000000000000
-- 086:0000000100000001000000110000011100001011000010110000100100000000
-- 087:1000000010000000101100001100100001001000010000000100000000000000
-- 088:0000000100000001000000110000111100010010000100100000001000000000
-- 089:1000000010000000110000001111000010010000100100001001000000000000
-- 090:0000000100000001000000010000111100001101000011010000010100000000
-- 091:1000000010000000110000001110000001010000010010000100000000000000
-- 096:0000000000000000000000000000000000000000000000000000000000000001
-- 097:0000000000000000000000000000000000000000000000000000000010000000
-- 098:0000000000000000000000000000000000000000000000000000000000000001
-- 099:0000000000000000000000000000000000000000000000000000000010000000
-- 100:0000000000000000000000000000000000000000000000000000000000000001
-- 101:0000000000000000000000000000000000000000000000000000000010000000
-- 102:0000000000000000000000000000000000000000000000000000000000000001
-- 103:0000000000000000000000000000000000000000000000000000000010000000
-- 104:0000000000000000000000000000000000000000000000000000000000000001
-- 105:0000000000000000000000000000000000000000000000000000000010000000
-- 106:0000000000000000000000000000000000000000000000000000000000000001
-- 107:0000000000000000000000000000000000000000000000000000000010000000
-- 112:0000000100000000000000000000000000000000000000000000000000000000
-- 113:1000000000000000000000000000000000000000000000000000000000000000
-- 114:0000000100000000000000000000000000000000000000000000000000000000
-- 115:1000000000000000000000000000000000000000000000000000000000000000
-- 116:0000000100000000000000000000000000000000000000000000000000000000
-- 117:1000000000000000000000000000000000000000000000000000000000000000
-- 118:0000000100000000000000000000000000000000000000000000000000000000
-- 119:1000000000000000000000000000000000000000000000000000000000000000
-- 120:0000000100000000000000000000000000000000000000000000000000000000
-- 121:1000000000000000000000000000000000000000000000000000000000000000
-- 122:0000000100000000000000000000000000000000000000000000000000000000
-- 123:1000000000000000000000000000000000000000000000000000000000000000
-- 128:0000000000111111011000000100111101011111010110110101110101011110
-- 129:0000000011111100000001101111001011111010110110101011101001111010
-- 130:0000000000111111011000000100111101011111010110110101110101011110
-- 131:0000000011111100000001101111001011111010110110101011101001111010
-- 132:0000000000111111011000000100111101011111010110110101110101011110
-- 133:0000000011111100000001101111001011111010110110101011101001111010
-- 134:0000000000111111011000000100111101011111010110110101110101011110
-- 135:0000000011111100000001101111001011111010110110101011101001111010
-- 136:0000000000111111011000000100111101011111010110110101110101011110
-- 137:0000000011111100000001101111001011111010110110101011101001111010
-- 138:0000000000111111011000000100111101011111010110110101110101011110
-- 139:0000000011111100000001101111001011111010110110101011101001111010
-- 144:0101111001011101010110110101111101001111011000000011111100000000
-- 145:0111101010111010110110101111101011110010000001101111110000000000
-- 146:0101111001011101010110110101111101001111011000000011111100000000
-- 147:0111101010111010110110101111101011110010000001101111110000000000
-- 148:0101111001011101010110110101111101001111011000000011111100000000
-- 149:0111101010111010110110101111101011110010000001101111110000000000
-- 150:0101111001011101010110110101111101001111011000000011111100000000
-- 151:0111101010111010110110101111101011110010000001101111110000000000
-- 152:0101111001011101010110110101111101001111011000000011111100000000
-- 153:0111101010111010110110101111101011110010000001101111110000000000
-- 154:0101111001011101010110110101111101001111011000000011111100000000
-- 155:0111101010111010110110101111101011110010000001101111110000000000
-- 161:0000000100000011000001110000111500011155001115550111555511155555
-- 162:1000000011000000111000005111000055111000555111005555111055555111
-- 176:0000000100000011000001110000111500011155001115550111111101111111
-- 177:1155555515555555555555555555555555555555555555551111111111111111
-- 178:5555551155555551555555555555555555555555555555551111111111111111
-- 179:1000000011000000111000005111000055111000555111001111111011111110
-- 192:0001100000100100111001111000000101000010100000011001100111100111
-- 193:0001100000144100111441111444444101444410144444411441144111100111
-- 240:4444444444444444411444444111111441144114411441144111111444444444
-- </TILES>

-- <WAVES>
-- 000:123466789aabfffffffffbba98653210
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- 003:133348434346451576657789aa248820
-- 004:4556678899abbbcdddccbaaa98877655
-- 005:00112211001122110011221100112211
-- 010:799aaaaaaa98765544444455677899aa
-- </WAVES>

-- <SFX>
-- 000:33c033003300430043004300430053005300630063006300730073008300830093009300a300a300a300b300b300c300d300d300e300f300f300f300152000000200
-- 001:700070007000800080009000a000b000c000d000e000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000f000461000000000
-- 012:05000500050015001500250025003500450055006500750085009500a500c500d500f500f500f500f500f500f500f500f500f500f500f500f500f500432000000000
-- 013:5600560066006600660076007600860096009600a600b600b600c600d600e600f600f600f600f600f600f600f600f600f600f600f600f600f600f600432000000000
-- 016:05c00500050015001500150015002500250035004500550075009500a500d500f500f500f500f500f500f500f500f500f500f500f500f500f500f500202000000800
-- 017:05c00500050015001500150015002500250035004500550075009500a500d500f500f500f500f500f500f500f500f500f500f500f500f500f500f500202000000400
-- 018:05c00500050015001500150015002500250035004500550075009500a500d500f500f500f500f500f500f500f500f500f500f500f500f500f500f500272000000200
-- 020:05c00500050015001500150015002507250735074507550775079507a507d507f507f507f507f500f500f500f500f500f500f500f500f500f500f500a02000000800
-- 021:05c00500050015001500150015002507250735074507550775079507a507d507f507f507f507f500f500f500f500f500f500f500f500f500f500f500a02000000400
-- 022:05c00500050015001500150015002507250735074507550775079507a507d507f507f507f507f500f500f500f500f500f500f500f500f500f500f500a02000000200
-- 024:05c0050005001500150015001500250d250d350d450d550d750d950da50dd50df50df50df50df50df50df500f500f500f500f500f500f500f500f500a02000000800
-- 025:05c0050005001500150015001500250d250d350d450d550d750d950da50dd50df50df50df50df50df500f500f500f500f500f500f500f500f500f500a02000000400
-- 026:05c0050005001500150015001500250d250d350d450d550d750d950da50dd50df50df50df50df50df50df50df50df500f500f500f500f500f500f500a01000000200
-- </SFX>

-- <PATTERNS>
-- 000:600002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:600002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000400002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000600002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b00002000000000000000000000000000000000000000000d00002000000000000000000000000000000000000000000
-- 002:60341a600018600016000000000000000000b00018000000000000000000000000000000d0001800000040001600000060001c60001a60001800000000000000000040001840001a40001600000000000000000000000000000000000000000060001a60001860001600000000000000000080001800000040001a400018400016000000600016000000400016000000800018000000400016000000b00018000000400016000000d0001a00000040001660001c600018600016400016000000
-- 003:60341a600018b00016000000000000000000400018000000000000000000000000000000d0001800000040001600000060001c60001a60001800000000000000000040001840001a40001600000000000000000000000000000000000000000060001a600018600016000000000000000000800018000000600016800016600018000000600016400018600016000000d00018000000400016000000b00018000000400016000000d0001a00000040001660001cb00018600016400016000000
-- 004:6000d00000000000d00000006000d80000006000d00000006000d00000000000d00000006000d80000000000000000006000d00000000000d00000006000d80000006000d00000006000d00000000000d00000006000d80000000000000000006000d00000000000d00000006000d80000000000000000006000d00000000000d00000006000d80000000000000000006000d00000000000d00000006000d80000000000000000006000d00000000000d00000006000d80000006000d0000000
-- 005:6000d00000006000c80000006000d80000006000d00000006000d00000006000c86000c86000d80000006000c80000006000d00000006000c80000006000d80000006000d00000006000d00000006000c86000c86000d80000006000c86000c86000d06000c86000c86000c86000d80000006000c80000006000d00000006000c80000006000d80000006000c80000006000d00000006000c86000c86000d80000006000c86000c86000d00000006000c80000006000d80000006000d0000000
-- 006:60341c60001a600018000000000000000000b0001a000000000000000000000000000000d0001a00000040001800000060001e60001c60001a00000000000000000040001a40001c40001800000000000000000000000000000000000000000060001c60001a60001800000000000000000080001a00000040001c60001a40001800000060001800000040001800000080001a000000400018000000d0001a000000400018000000b0001c00000040001860001ed0001a600018400018000000
-- 007:40341c60001ab0001800000000000000000040001a000000000000000000000000000000d0001a000000b0001800000060001e40001c60001a00000000000000000040001a90001c40001800000000000000000000000000000000000000000060001c40001a600018000000000000000000d0001a000000600018b0001860001a00000060001840001a60001800000090001a000000600018000000d0001a000000600018000000d0001c00000040001860001eb0001a600018400018000000
-- </PATTERNS>

-- <TRACKS>
-- 000:1c00002010001c05002016001005002006001c0500201600000000000000000000000000000000000000000000000000ad0000
-- </TRACKS>

-- <SCREEN>
-- 000:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 001:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 002:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000011001100110000000000000000000000001100110000000000000000000000001100110000000000000000000000000000110011000000000000
-- 003:111aaaaaaaa11111111111111111111111111111111111111111111111111aaaa1111111111111111111111111111111111111111111111100000000000011001100110000000000000000000000001100110000000000000000000000001100110000000000000000000000000000110011000000000000
-- 004:111000000001111111111111111111111111111111111111111111111111100001111111111111111111111111111111111111111111111100000000001111111111110000000000000000000000001111111100000000000000000000111111110000000000000000000000000000111111110000000000
-- 005:1110000000011aaaa11aa1111aaaa11aa1111aaaa1111aa11aaaaaaaa111100001111aaaaaaaa1111111111111111111111111111111111100000000001111111111110000000000000000000000001111111100000000000000000000111111110000000000000000000000000000111111110000000000
-- 006:111220000221100001100111100001100111100001111001100000000111122221111000000001111111111111111111111111111111111100000000110000000000001100000000000000000011110000000011000000000000000011000000001111000000000000000000001111000000001100000000
-- 007:11111000011110000aa00aa110000aa00aa1100001111001100000000aa11aaaa11aa000000001111111111111111111111111111111111100000000110000000000001100000000000000000011110000000011000000000000000011000000001111000000000000000000001111000000001100000000
-- 008:111110000111100000000001100000000001100001111001100002222001100001100222200001111111111111111111111111111111111100000011000000000000000011000000000000001100000000000000110000000000001100000000000000110000000000000000110000111100000011000000
-- 009:111110000111100000000001100000000001100001111001100001111001100001100111100001111111111111111111111111111111111100000011000000000000000011000000000000001100000000000000110000000000001100000000000000110000000000000000110000000000000011000000
-- 010:111110000111100220022001100220022001100001111001100001111001100001100111100001111111111111111111111111111111111100111100000000000000000011110000000011110000000000000000001100000000110000000011110000001111000000001111000000111100000000110000
-- 011:111aa0000aa110011001100110011001100110000aaaa001100001111001100001100aaaa00001111111111111111111111111111111111100111100000000000000000011110000000011110000000000000000001100000000110000000000000000001111000000001111000000000000000000110000
-- 012:111000000001100110011001100110011001122000000221100001111001100001122000000001111111111111111111111111111111111100001100000000000000000011000000000000110000001111000000001111000011110000000011110000001100000000000011000000111100000000111100
-- 013:111000000001100110011001100110011001111000000111100001111001100001111000000001111111111111111111111111111111111100001100000000000000000011000000000000110000000000000000001111000011110000000000000000001100000000000011000000000000000000111100
-- 014:111222222221122112211221122112211221111222222111122221111221122221111222222221111111111111111111111111111111111100111100000000111100000000111100000011000000101111010000001100000000110000101011110101000011000000001100101010111101010100110000
-- 015:1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111001111000000001aa100000000111100000011000000101aa101000000110000000011000010101aa101010000110000000011001010101aa101010100110000
-- 016:1111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111000011000000001aa100000000110000001111000000101aa101000000111100001111000010101aa101010000111100001111001010101aa101010100111100
-- 017:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001100000000111100000000110000001111000000101111010000001111000011110000101011110101000011110000111100101010111101010100111100
-- 018:111000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111111111111111100111100000000000000000011000000000000110000000000000000001100000000110000000000000000001100000000000011000000000000000000110000
-- 019:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100111100000000000000000011000000000000110000001111000000001100000000110000000011110000001100000000000011000000111100000000110000
-- 020:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001100000000000000000011110000000011110000000000000000001111000011110000000000000000001111000000001111000000000000000000111100
-- 021:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100001100000000000000000011110000000011110000000000000000001111000011110000000011110000001111000000001111000000111100000000111100
-- 022:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000011000000000000001100000000000000110000000000000000110000000000001100000000000000001100000000000011000000000000000011000000
-- 023:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000011000000000000001100000000000000110000000000000000110000000000001100000000000000001100000000000011000000111100000011000000
-- 024:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000110000000011110000000000000000001100000000000011000000000000000011000000000000110000000000000000110000000000001100000000
-- 025:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000110000000011110000000000000000001100000000000011000000000000000011000000000000110000000000000000110000000000001100000000
-- 026:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000001111111100000000000000000000000011111111111100000000000000000000111111111111000000000000000000001111111111110000000000
-- 027:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000001111111100000000000000000000000011111111111100000000000000000000111111111111000000000000000000001111111111110000000000
-- 028:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000011001100000000000000000000000011001100110000000000000000000000001100110011000000000000000000001100110011000000000000
-- 029:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000011001100000000000000000000000011001100110000000000000000000000001100110011000000000000000000001100110011000000000000
-- 030:111001111111111111111111111001110011111aaa111aaa111aa1111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 031:11100111110001100110110001100111001111aa1aa1aa1aa1aaa1111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 032:11100111100100100110100100100111111111aaa1a1aaa1a11aa1111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 033:11100111100011110001100011100111001111aa11a1aa11a11aa1111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 034:111000001100011110111100011100010011111aaa111aaa11aaaa111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 035:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 036:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 037:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 038:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 039:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 040:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 041:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 042:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 043:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 044:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 045:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 046:111000011111111111111100111111111111111001111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000
-- 047:111001101100001100001000001100011000011111100001111111110000001100000000000011111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000
-- 048:111000011011001000111100111001001001101001011001111111110222201102222222222011111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000
-- 049:111001101011001000111100111000111001111001011001111111000222201102222222222011111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000000000000000111100000000000000
-- 050:111000011100001100001110001100011001111001100001111111022222201100000002222011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 051:111111111111111111111111111111111111111111111111111111022222201111110002222011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 052:111111111111111111111111111111111111111111111111111111000222201111110222200011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 053:111111111111111111111111111111111111111111111111111111110222201100000222200011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 054:111000011001111111001111111001111111111111001111111111110222201102200002222011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 055:111001101111001101111100001111100011000011001111111111000222200002200002222011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 056:111001101001001101001000111001001101001101111111111111022222222000022222200011111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 057:111001101001100011001110001001001101001101001111111111022222222011022222201111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 058:111000011001110111001000011001100011001101001111111111000000000011000000001111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 059:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 060:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 061:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 062:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 063:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 064:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 065:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 066:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 067:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 068:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000011001100110011001100000000000000000000000000000000000000
-- 069:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000011001100110011001100000000000000000000000000000000000000
-- 070:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000110011111111111111110000000000000000000000000000000000000000
-- 071:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000110011111111111111110000000000000000000000000000000000000000
-- 072:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001111111100001111111111000000000000000000000000000000000000
-- 073:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000
-- 074:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111100001111111100000000000000000000000000000000000000
-- 075:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111111111111111100000000000000000000000000000000000000
-- 076:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001111111100001111111111000000000000000000000000000000000000
-- 077:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000
-- 078:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000111101010100001010101100000000000000000000111100000000000000
-- 079:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000111101010102201010101100000000000000000000111100000000000000
-- 080:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000001101010102201010101111000000000000000000111100000000000000
-- 081:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000001101010100001010101111000000000000000000111100000000000000
-- 082:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111111111111111100000000000000000000000000000000000000
-- 083:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111100001111111100000000000000000000000000000000000000
-- 084:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111000000000000000000000000000000000000
-- 085:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001111111100001111111111000000000000000000000000000000000000
-- 086:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111111111111111100000000000000000000000000000000000000
-- 087:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000111111111100001111111100000000000000000000000000000000000000
-- 088:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000011111111111111110011000000000000000000000000000000000000
-- 089:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000011111111111111110011000000000000000000000000000000000000
-- 090:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001100110011001100110000000000000000000000000000000000000000
-- 091:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000001100110011001100110000000000000000000000000000000000000000
-- 092:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 093:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 094:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 095:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 096:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 097:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 098:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111110000
-- 099:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111110000
-- 100:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100000000000000000000111100
-- 101:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100000000000000000000111100
-- 102:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000111111111111111100001100
-- 103:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000111111111111111100001100
-- 104:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111111111111111111001100
-- 105:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111111111111111111001100
-- 106:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011110011111111001111001100
-- 107:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011110011111111001111001100
-- 108:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111100111100111111001100
-- 109:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111100111100111111001100
-- 110:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000110011111111000011111111001100
-- 111:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000110011111111000011111111001100
-- 112:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000110011111111000011111111001100
-- 113:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000111100000000000000000000000000001111000000000000000000000000000011110000000000000000110011111111000011111111001100
-- 114:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111100111100111111001100
-- 115:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111100111100111111001100
-- 116:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011110011111111001111001100
-- 117:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011110011111111001111001100
-- 118:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111111111111111111001100
-- 119:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110011111111111111111111001100
-- 120:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000111111111111111100001100
-- 121:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000110000111111111111111100001100
-- 122:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100000000000000000000111100
-- 123:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000111100000000000000000000111100
-- 124:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111110000
-- 125:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111111111110000
-- 126:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 127:144444444111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- 128:144444444111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 129:141144444100110011111111100111111111111111111111111111111111111110011100111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 130:141111114111100000101110111110000110001110000100001110001110000100000111100110110001111110000110001100101111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 131:141144114100110011101010100100011100100100011100110100100101100110011100100110100100111100011100110100000111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 132:141144114100110011100000100111000100011100011100111100011101100110011100110001100011100100011100110101010111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 133:141111114100111000100100100100001110001110000100111110001110000111000100111011110001100110000110001101010111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 134:144444444111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- 135:111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
-- </SCREEN>

-- <PALETTE>
-- 000:aeaeae555555b13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

