-- title:   Immunia
-- author:  Bitwise Creative
-- desc:    Simple immunity puzzle game
-- site:    https://github.com/bitwisecreative/immunia
-- license: MIT License
-- version: 0.1
-- script:  lua

-- menu: OPEN
-- requires "menu:" meta tag above...
  -- I tried everything to find a way to force open the TIC-80 game menu from code, including scouring the source code for holes.
  -- I found nada... Best bet is to create a custom menu that can be accessed by ` key or clicking menu button or a custom menu item in TIC-80 menu.
  -- Not impressed with TIC-80 mobile web implementation...
function opengamemenu()
  trace("Open Game Menu")
end
GameMenu={opengamemenu}
function MENU(i)
  GameMenu[i+1]()
end

-- INIT
function BOOT()

  trace('-- BOOT --')

  -- TODO: Hi! So, now that you have solve data... you can limit the puzzles to n moves before the bacteria divides! that'll make the puzzles more difficult ;)
  -- Probably just set to the max solve length for all levels :P

  -- pmem map
  -- 0 = selected difficulty
  -- 1 = d1 wins
  -- 2 = d2 wins
  -- 3 = d3 wins
  -- 4 = d4 wins
  -- 5 = d5 wins
  -- 6 = d1 losses
  -- 7 = d2 losses
  -- 8 = d3 losses
  -- 9 = d4 losses
  -- 10 = d5 losses
  -- 11 = bgm setting

  -- seed rng
  math.randomseed(tstamp())

  -- int won't overflow like pico8...
  f=0

  -- current screen
  screen='game'

  -- difficulty (1-5)
  difficulty=pmem(0)
  if not difficulty then difficulty=1 end
  difficulty=clamp(difficulty,1,5)
  difficulty=rint(1,5)
  trace('difficulty: '..difficulty)

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
  move={
    n=0,
    p=false, -- processed
    x=0,
    y=0,
    f=0,
    d={} -- destroy cell ids
  }

  arrowblink={false,2} -- visible, frame switch

  -- swipe detection
  swipeminmove=20
  swipe={
    x=0,
    y=0,
    b=false
  }

  -- test maps...
  -- 0:empty,1:wbc,2:bacteria,3:blocked
  testmaps={
    wbc={
      {2,3,0,0},
      {0,0,0,0},
      {0,0,0,1},
      {0,0,0,0}
    },
    debug={
      {0,0,0,0},
      {0,0,0,0},
      {0,0,0,0},
      {0,0,0,0}
    }
  }
  testmap='wbc'
  -- you can do testmap='random' also...
  testmap=false
  --testmap='random'

  -- start bgm
  --music(0)

  -- tiny font
  tf=tfont:new()

  -- difficulty level 1 through 5 stars
  -- level gen dev...
  if not testmap then
    levelgen()
  end

  -- populate (grid style)
  if testmap then
    for y=1,gsy do
      for x=1,gsx do
        local r=0
        if testmap=='random' then
          if rint(1,2)==1 then -- chance for cell on random testmap
            r=rint(1,3)
          end
        else
          r=testmaps[testmap][y][x]
        end
        if r>0 then
          if r==1 then t='wbc' end
          if r==2 then t='bacteria' end
          if r==3 then t='blocked' end
          local cell=gen_cell(t,x,y)
          set_random_shield(cell)
          table.insert(cells,cell)
        end
      end
    end
  end

end

-- WHAMMY!
function TIC()
  f=f+1
  cls(0)

  if screen=='game' then
    draw_game()
  end

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
      move.n=move.n+1
    end
    if btnp(1) or keyp(19) then
      move.x=0
      move.y=1
      move.f=f
      move.n=move.n+1
    end
    if btnp(2) or keyp(1) then
      move.x=-1
      move.y=0
      move.f=f
      move.n=move.n+1
    end
    if btnp(3) or keyp(4) then
      move.x=1
      move.y=0
      move.f=f
      move.n=move.n+1
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
          move.n=move.n+1
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
  -- debug
  local debugx=2
  local debugy=18
  local debugc=5
  tf:print('difficulty: '..difficulty,debugx,debugy,debugc)
  tf:print('move: '..move.x..','..move.y..','..move.n,debugx,debugy+4,debugc)
  tf:print('mouse: '..mx..','..my..','..bint(mb),debugx,debugy+8,debugc)
  tf:print('swipe: '..swipe.x..','..swipe.y..','..bint(swipe.b),debugx,debugy+12,debugc)

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
    -- first, process wbc movement... multiple passes...
    local wbcs={}
    for k,cell in pairs(cells) do
      if cell.t=='wbc' then table.insert(wbcs,{cell,k}) end
    end
    local limit=0;
    while not all_wbcs_processed(wbcs) do
      limit=limit+1
      if limit>20 then
        trace('!!!WBC MOVE WHILE LOOP LIMIT BROKEN!!!')
        break
      end
      for k,wbc in pairs(wbcs) do
        local cell=wbc[1]
        if cell.p==0 then
          local tx,ty=get_target_loc(cell.x,cell.y)
          local target=get_cell_at(tx,ty)
          if not target then -- empty -- can move (wbc can only move when empty...)
            -- move wbc
            cell.x=tx
            cell.y=ty
            cell.p=1
          else
            if target.t~='wbc' or target.p>0 then -- if target is not wbc, or wbc is processed...
              cell.p=2
            end
          end
        end
      end
    end
    -- next, process attacking...
    for k,wbc in pairs(wbcs) do
      local cell=wbc[1]
      local cell_index=wbc[2]
      if cell.p==2 then
        local tx,ty=get_target_loc(cell.x,cell.y)
        local target,target_index=get_cell_at(tx,ty)
        if target then
          -- bacteria
          if target.t=='bacteria' then
            process_attack(cell,cell_index,target,target_index)
            cell.p=3
          end
        end
      end
    end
    -- process cells to destroy
    -- (mark them nil, then "clean" the table at the very end of TIC())
    for k,v in pairs(move.d) do
      cells[v]=nil
    end
    -- clean cells table
    tclean(cells)
    -- check win (before game over check...)
    local bacteria_cells=get_cell_count('bacteria')
    if bacteria_cells==0 then
      trace('win')
      -- todo inc wins
      reset()
    else
      -- check game over
      local wbc_cells=get_cell_count('wbc')
      if wbc_cells==0 then
        reset()
        trace('lose')
        -- todo inc losses
      end
    end
    -- move processed...
    move.p=true
  end
end

function levelgen()

  local function place_random_cell(t)
    local added=false
    local x,y
    while not added do
      x=rint(1,gsx)
      y=rint(1,gsy)
      local c=get_cell_at(x,y)
      if not c then
        local cell=gen_cell(t,x,y)
        added=true
        table.insert(cells,cell)
      end
    end
    return x,y
  end

  local function build_move(dir)

  end

  -- difficulty (global) 1-5 affects number of moves (shields)
  local p=difficulty*16
  local max=math.ceil(p/5)
  local min=max-difficulty
  local num_moves=rint(min,max)
  trace('moves: '..min..','..max)

  -- generate and place blocked cells
  local num_blocked=rint(0,3)
  for i=1,num_blocked do
    place_random_cell('blocked')
  end

  -- generate and place wbc cells
  local num_wbc=rint(2,math.ceil(num_moves/2))
  for i=1,num_wbc do
    place_random_cell('wbc')
  end

  -- generate and place bacteria cells
  local num_bacteria=rint(2,math.ceil(num_moves/2))
  for i=1,num_bacteria do
    place_random_cell('bacteria')
  end

  -- STRATEGY: randomly doing shields and stuff just doesn't work. You have to build the level step by step (forwards or backwards...)
  -- Start with all bacteria shields full
  local bacs=get_cells_by_type('bacteria')
  for k,cell in pairs(bacs) do
    cell.s={3,3,3,3}
  end
  -- Clone initial cells state
  local initial_state=copy(cells)
  -- Apply random movements and manipulate shields until wbcs win
  while get_cell_count('bacteria')>0 and false do
    local rm=rint(1,4) -- up,down,left,right
    local mx=0
    local my=0
    if rm==1 then my=-1 end
    if rm==2 then my=1 end
    if rm==3 then mx=-1 end
    if rm==4 then mx=1 end
    move.x=mx
    move.y=my
    -- calc shield vecs (default up)
    local attack_shield=1
    local defend_shield=2
    if rm==2 then
      attack_shield=2
      defend_shield=1
    end
    if rm==3 then
      attack_shield=3
      defend_shield=4
    end
    if rm==4 then
      attack_shield=4
      defend_shield=3
    end
    -- TODO: not DRY... copied from draw_game()
    -- first, process wbc movement... multiple passes...
    local wbcs={}
    for k,cell in pairs(cells) do
      if cell.t=='wbc' then table.insert(wbcs,{cell,k}) end
    end
    local limit=0;
    while not all_wbcs_processed(wbcs) do
      limit=limit+1
      if limit>20 then
        trace('!!!WBC MOVE WHILE LOOP LIMIT BROKEN!!!')
        break
      end
      for k,wbc in pairs(wbcs) do
        local cell=wbc[1]
        if cell.p==0 then
          local tx,ty=get_target_loc(cell.x,cell.y)
          local target=get_cell_at(tx,ty)
          if not target then -- empty -- can move (wbc can only move when empty...)
            -- move wbc
            cell.x=tx
            cell.y=ty
            cell.p=1
          else
            if target.t~='wbc' or target.p>0 then -- if target is not wbc, or wbc is processed...
              cell.p=2
            end
          end
        end
      end
    end
    -- next, process attacking...
    for k,wbc in pairs(wbcs) do
      local cell=wbc[1]
      local cell_index=wbc[2]
      if cell.p==2 then
        local tx,ty=get_target_loc(cell.x,cell.y)
        local target,target_index=get_cell_at(tx,ty)
        if target then
          -- bacteria
          if target.t=='bacteria' then
            local av=0 -- attacking shield
            local dv=0 -- defending shield
            if move.x<0 then
              av=3
              dv=4
            end
            if move.x>0 then
              av=4
              dv=3
            end
            if move.y<0 then
              av=1
              dv=2
            end
            if move.y>0 then
              av=2
              dv=1
            end
            -- wbc attack
            wbc.s[av]=wbc.s[av]+1
            if wbc.s[av]>3 then wbc.s[av]=3 end
            -- bacteria defend
            bacteria.s[dv]=bacteria.s[dv]-1
            if bacteria.s[dv]<0 then table.insert(move.d,bacteria_index) end -- bacteria died
            cell.p=3
          end
        end
      end
    end
    -- process cells to destroy
    -- (mark them nil, then "clean" the table at the very end of TIC())
    for k,v in pairs(move.d) do
      cells[v]=nil
    end
    -- clean cells table
    tclean(cells)
    
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

function grid_full()
  for y=1,gsy do
    for x=1,gsx do
      local c=get_cell_at(x,y)
      if not c then return false end
    end
  end
  return true
end

function clone_shield(from,to)
  to.s=copy(from.s)
end

function set_random_shield(cell)
  for i=1,4 do cell.s[i]=rint(0,3) end
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

function process_attack(wbc,wbc_index,bacteria,bacteria_index)
  --trace('ATTACK: '..wbc_index..'->'..bacteria_index)
  local av=0 -- attacking shield
  local dv=0 -- defending shield
  if move.x<0 then
    av=3
    dv=4
  end
  if move.x>0 then
    av=4
    dv=3
  end
  if move.y<0 then
    av=1
    dv=2
  end
  if move.y>0 then
    av=2
    dv=1
  end
  -- wbc attack
  wbc.s[av]=wbc.s[av]-1
  if wbc.s[av]<0 then table.insert(move.d,wbc_index) end -- wbc died
  -- bacteria defend
  bacteria.s[dv]=bacteria.s[dv]-1
  if bacteria.s[dv]<0 then table.insert(move.d,bacteria_index) end -- bacteria died
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

function all_wbcs_processed(wbcs)
  for k,wbc in pairs(wbcs) do
    local cell=wbc[1]
    if cell.p==0 then return false end
  end
  return true
end

function reset_move()
  move.x=0
  move.y=0
  move.f=0
  move.p=false
  move.d={}
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
    s={0,0,0,0} -- shield (up down left right) -> (wbc and bacteria)
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
  -- todo: move anims?
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
 if s~='' then
  table.insert(t,s)
 end
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
        if self.font[cy][cx-1+xs]==1 then pix(x+((i-1)*4)+cx-1,y+cy-1,c) end
      end
    end
  end
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

-- <PALETTE>
-- 000:aeaeae555555b13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

