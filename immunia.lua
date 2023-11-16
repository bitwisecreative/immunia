-- title:   Immunia
-- author:  Bitwise Creative
-- desc:    Simple 1-bit immunity puzzle game
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


-- seed rng
math.randomseed(tstamp())

-- int won't overflow like pico8...
f=0

-- screen size
sw=240
sh=136

-- cell grid is 13x6 :[]
gsx=13
gsy=6

-- cells
cells={}

-- move
movespeed=7
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
testmaps={
  wbc={
    {2,3,0,0,0,1,0,0,0,0,0,0,0},
    {0,0,0,0,0,1,0,0,0,0,0,0,0},
    {0,0,4,1,1,1,1,1,4,0,0,0,0},
    {0,0,0,0,0,1,0,0,0,0,0,0,0},
    {0,0,0,0,0,1,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0,0},
  },
  virus={
    {0,0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,3,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0,0},
    {0,0,0,0,0,0,0,0,0,0,0,0,0},
  }
}
testmap='wbc'
testmap='virus'
testmap=false

-- virus speed (when clones, moves every turn)
virusspeed=3
virusin=virusspeed

-- bacteria speed (division)
bacteriaspeed=3
bacteriain=bacteriaspeed

-- INIT
function BOOT()

  -- populate (grid style)
  for y=1,gsy do
    for x=1,gsx do
      -- test map
      if testmap then
        local r=testmaps[testmap][y][x]
        if r>0 then
          if r==1 then t='wbc' end
          if r==2 then t='bacteria' end
          if r==3 then t='virus' end
          if r==4 then t='blocked' end
          local cell=gen_cell(t,x,y)
          -- random shield degen
          for y=1,3 do
            for x=1,3 do
              cell.s[x][y]=rint(0,1)
            end
          end
          -- but nucleus always 1
          cell.s[2][2]=1
          -- append
          table.insert(cells,cell)
        end
      else
        -- chance of cell
        if rint(1,5)==1 then
          local r=rint(1,4)
          if r==1 then t='wbc' end
          if r==2 then t='bacteria' end
          if r==3 then t='virus' end
          if r==4 then t='blocked' end
          local cell=gen_cell(t,x,y)
          -- random shield degen
          for y=1,3 do
            for x=1,3 do
              cell.s[x][y]=rint(0,1)
            end
          end
          -- but nucleus always 1
          cell.s[2][2]=1
          -- append
          table.insert(cells,cell)
        end
      end
    end
  end

  -- tiny font
  tf=tfont:new()

end

-- WHAMMY!
function TIC()
  f=f+1
  cls(0)

  -- frame
  rect(0,0,sw,26,1)
  rect(0,0,16,sh,1)
  rect(sw-16,0,16,sh,1)
  rect(0,sh-14,sw,16,1)

  -- title
  -- print(text x=0 y=0 color=15 fixed=false scale=1 smallfont=false) -> width`
  print("Immunia",5,5,0,false,3)

  -- ;)
  bxoffset=4
  spr(240,0+bxoffset,125)
  print("itwisecreative.com",9+bxoffset,127,0)

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
        line(swipe.x,swipe.y,mx,my,1)
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
  -- virus speed
  print("Virus Clones: "..numpad(virusin,2),151,7,0)
  print("Bacteria Division: "..numpad(bacteriain,2),129,15,0)
  -- debug
  local debugx=150
  local debugy=124
  local debugc=3
  tf:print('move: '..move.x..','..move.y..','..move.n,debugx,debugy,debugc)
  tf:print('mouse: '..mx..','..my..','..bint(mb),debugx,debugy+4,debugc)
  tf:print('swipe: '..swipe.x..','..swipe.y..','..bint(swipe.b),debugx,debugy+8,debugc)

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
    -- virus and bacteria speed
    virusin=virusin-1
    if virusin<0 then virusin=virusspeed end
    bacteriain=bacteriain-1
    if bacteriain<0 then bacteriain=bacteriaspeed end
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
          -- viruses (easy, just kill them...)
          if target.t=='virus' then
            table.insert(move.d,target_index)
            cell.p=3
          end
          -- bacteria
          if target.t=='bacteria' then
            process_attack(cell,cell_index,target,target_index)
            cell.p=3
          end
        end
      end
    end
    -- next, process viruses
    -- if they are next to bacteria (cross) then they will try to duplicate (open cell around bacteria) if virusin==0
    -- otherwise they will try to move randomly :P (every turn)
    local add_viruses={}
    for k,cell in pairs(cells) do
      if cell.t=='virus' then
        local neighbs=get_cross_neighbors(cell.x,cell.y)
        local attached_bac=false
        for nk,ncell in pairs(neighbs) do
          if ncell and ncell.t=='bacteria' then
            attached_bac=ncell
            break
          end
        end
        if attached_bac then
          local o=get_open_cells_from(attached_bac.x,attached_bac.y)
          if #o>0 then
            -- add new virus at first open cell...
            if virusin==0 then
              local nv=gen_cell('virus',o[1][1],o[1][2])
              table.insert(add_viruses,nv)
            end
          end
        else
          -- move virus to random location
          local o=get_open_cells_from(cell.x,cell.y)
          if #o>0 then
            tshuffle(o)
            cell.x=o[1][1]
            cell.y=o[1][2]
          end
        end
      end
    end
    for k,v in pairs(add_viruses) do
      table.insert(cells,v)
    end
    -- next, process bacteria (divide if bacteriain==0) -- shield is cloned
    local add_bacteria={}
    for k,cell in pairs(cells) do
      if cell.t=='bacteria' then
        if bacteriain==0 then
          local o=get_open_cells_from(cell.x,cell.y)
          if #o>0 then
            local nb=gen_cell('bacteria',o[1][1],o[1][2])
            clone_shield(cell,nb)
            table.insert(add_bacteria,nb)
          end
        end
      end
    end
    for k,v in pairs(add_bacteria) do
      table.insert(cells,v)
    end
    -- process cells to destroy
    for i=#move.d,1,-1 do -- REVERSE!!!!!!!!!!!!!!
      if cells[move.d[i]]~=nil then
        table.remove(cells,move.d[i])
      end
    end
    -- move processed...
    move.p=true
  end

end

function clone_shield(from,to)
  for y=1,3 do
    for x=1,3 do
      to.s[y][x]=from.s[y][x]
    end
  end
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
    if v[1]<1 then v[1]=gsx end
    if v[1]>gsx then v[1]=1 end
    if v[2]<1 then v[2]=gsy end
    if v[2]>gsy then v[2]=1 end
    --
    local c=get_cell_at(v[1],v[2])
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
    local cell=get_cell_at(v[1],v[2])
    if cell then table.insert(n,cell) end
  end
  --
  return n
end

function process_attack(wbc,wbc_index,bacteria,bacteria_index)
  --trace('ATTACK: '..wbc_index..'->'..bacteria_index)
  -- shield priority is cross first, then diagonal
  -- diagonal priority is left to right, top to bottom
  -- attack (wbc) / defend (bacteria) vectors
  local av={}
  local dv={}
  if move.x<0 then
    av={{1,2},{1,1},{1,3},{2,2}}
    dv={{3,2},{3,1},{3,3},{2,2}}
  end
  if move.x>0 then
    dv={{1,2},{1,1},{1,3},{2,2}}
    av={{3,2},{3,1},{3,3},{2,2}}
  end
  if move.y<0 then
    av={{2,1},{1,1},{1,3},{2,2}}
    dv={{2,3},{1,3},{3,3},{2,2}}
  end
  if move.y>0 then
    dv={{2,1},{1,1},{1,3},{2,2}}
    av={{2,3},{1,3},{3,3},{2,2}}
  end
  -- debug
  --trace('AV: '..tdump(av,true))
  --trace('DV: '..tdump(dv,true))
  -- pwn n00bs
  for ak,vec in pairs(av) do
    if wbc.s[vec[1]][vec[2]]==1 then
      --trace('AV REM: '..tdump(vec,true))
      wbc.s[vec[1]][vec[2]]=0
      break
    end
  end
  for ak,vec in pairs(dv) do
    if bacteria.s[vec[1]][vec[2]]==1 then
      --trace('DV REM: '..tdump(vec,true))
      bacteria.s[vec[1]][vec[2]]=0
      break
    end
  end
  -- who died!?
  --trace('WBC N: '..wbc.s[2][2])
  if wbc.s[2][2]==0 then
    --trace('wbc dead... '..wbc_index)
    table.insert(move.d,wbc_index)
  end
  --trace('BAC N: '..bacteria.s[2][2])
  if bacteria.s[2][2]==0 then
    --trace('bacteria dead... '..bacteria_index)
    table.insert(move.d,bacteria_index)
  end
end

function get_cell_at(x,y)
  for k,cell in pairs(cells) do
    if cell.x==x and cell.y==y then return cell,k end
  end
  return false
end

function get_target_loc(x,y)
  local tx=x+move.x
  if tx<1 then tx=gsx end
  if tx>gsx then tx=1 end
  local ty=y+move.y
  if ty<1 then ty=gsy end
  if ty>gsy then ty=1 end
  return tx, ty
end

function get_reverse_target_loc(x,y)
  local tx=x+-move.x
  if tx<1 then tx=gsx end
  if tx>gsx then tx=1 end
  local ty=y+-move.y
  if ty<1 then ty=gsy end
  if ty>gsy then ty=1 end
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
    t=t, -- type (wbc, bacteria, virus, blocked)
    x=x,
    y=y,
    r=rint(0,3),
    f=rint(0,3),
    a=1, -- anim, all use 6 frames (same anims...)
    p=0, -- (move) processed id (0=not processed,1=moved,2=cannot move,3=attacked)
    s={ -- shield -> (wbc and bacteria)
      {1,1,1},
      {1,1,1},
      {1,1,1}
    }
  }
  return e
end

function draw_empty(x,y)
  local sx=x*16
  local sy=y*16+10
  local sprnum=96
  spr(sprnum,sx,sy,-1,1,0,0,2,2)
end

function draw_cell(c)
  local sx=c.x*16 -- this works as-is because of the margin...
  local sy=c.y*16+10
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
    sprnum=64
  end
  if c.t=='blocked' then
    sprnum=128
  end
  spr(sprnum+((c.a-1)*2),sx,sy,-1,1,c.f,c.r,2,2)
  -- shield
  if drawshield then
    if c.s[1][1]==1 then
      pix(sx+6,sy+6,shieldcolor)
      pix(sx+7,sy+6,shieldcolor)
      pix(sx+6,sy+7,shieldcolor)
    end
    if c.s[2][1]==1 then
      pix(sx+8,sy+6,shieldcolor)
    end
    if c.s[3][1]==1 then
      pix(sx+9,sy+6,shieldcolor)
      pix(sx+10,sy+6,shieldcolor)
      pix(sx+10,sy+7,shieldcolor)
    end
    if c.s[1][2]==1 then
      pix(sx+6,sy+8,shieldcolor)
    end
    if c.s[2][2]==1 then
      pix(sx+8,sy+8,shieldcolor) -- nucleus? :3
    end
    if c.s[3][2]==1 then
      pix(sx+10,sy+8,shieldcolor)
    end
    if c.s[1][3]==1 then
      pix(sx+6,sy+9,shieldcolor)
      pix(sx+6,sy+10,shieldcolor)
      pix(sx+7,sy+10,shieldcolor)
    end
    if c.s[2][3]==1 then
      pix(sx+8,sy+10,shieldcolor)
    end
    if c.s[3][3]==1 then
      pix(sx+10,sy+9,shieldcolor)
      pix(sx+10,sy+10,shieldcolor)
      pix(sx+9,sy+10,shieldcolor)
    end
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
  if dir=='up' then spr(160,sw/2-16,26,0,1,0,0,4,2) end
  if dir=='down' then spr(160,sw/2-16,106,0,1,0,2,4,2) end
  if dir=='left' then spr(160,16,sh/2-10,0,1,0,3,4,2) end
  if dir=='right' then spr(160,sw-32,sh/2-10,0,1,0,1,4,2) end
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

-- left pad numbers with zero
function numpad(num,width)
  local s=tostring(num)
  while #s<width do
    s='0'..s
  end
  return s
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
-- 161:0000000100000011000001110000111100011111001111110111111111111111
-- 162:1000000011000000111000001111000011111000111111001111111011111111
-- 176:0000000100000011000001110000111100011111001111110111111111111111
-- 177:1111111111111111111111111111111111111111111111111111111111111111
-- 178:1111111111111111111111111111111111111111111111111111111111111111
-- 179:1000000011000000111000001111000011111000111111001111111011111111
-- 240:0000000000000000011000000111111001100110011001100111111000000000
-- </TILES>

-- <WAVES>
-- 000:00000000ffffffff00000000ffffffff
-- 001:0123456789abcdeffedcba9876543210
-- 002:0123456789abcdef0123456789abcdef
-- </WAVES>

-- <SFX>
-- 000:000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000304000000000
-- </SFX>

-- <TRACKS>
-- 000:100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
-- </TRACKS>

-- <PALETTE>
-- 000:aeaeae555555b13e53ef7d57ffcd75a7f07038b76425717929366f3b5dc941a6f673eff7f4f4f494b0c2566c86333c57
-- </PALETTE>

