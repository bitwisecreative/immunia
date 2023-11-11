-- title:   Immunia
-- author:  Bitwise Creative
-- desc:    Simple 1-bit immunity puzzle game
-- site:    https://github.com/bitwisecreative/immunia
-- license: MIT License
-- version: 0.1
-- script:  lua

-- seed rng
math.randomseed(tstamp())

-- int won't overflow like pico8...
f=0

-- screen size
sw=240
sh=136

-- cell grid is 13x6 :[]
-- 0=empty, 1=wbc, 2=bacteria, 3=virus
grid={}

function BOOT()

  -- grid test
  for y=1,6 do
    grid[y]={}
    for x=1,13 do
      local r=rint(0,3)
      local t='empty'
      if r==1 then t='wbc' end
      if r==2 then t='bacteria' end
      if r==3 then t='virus' end
      grid[y][x]=gen_cell(t,x,y)
    end
  end

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
  print("Immunia",16,5,0,false,3)

  -- ;)
  bxoffset=16
  spr(240,0+bxoffset,127)
  print("itwisecreative.com",9+bxoffset,129,0)

  -- draw game board
  for y=1,6 do
    for x=1,13 do
      cell=grid[y][x]
      draw_cell(cell) -- todo (?): y,x is redundant between grid data and cell data...
      -- global anim update
      if f%7==0 then
        cell.a=cell.a+1
        if cell.a>6 then cell.a=1 end
      end
      --
    end
  end

end

function gen_cell(t,x,y)
  local e={
    t=t, -- type (empty, wbc, bacteria, or virus)
    x=x,
    y=y,
    r=rint(0,3),
    f=rint(0,3),
    a=1, -- anim, all three use same anims...
    s={ -- shield -> na for virus...
      {1,1,1},
      {1,1,1},
      {1,1,1}
    }
  }
  return e
end

function draw_cell(c)
  local sx=c.x*16 -- this works as-is because of the margin...
  local sy=c.y*16+10
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
  if c.t=='empty' then
    sprnum=96
  end
  spr(sprnum+((c.a-1)*2),sx,sy,-1,1,c.f,c.r,2,2)
  -- shield
  if drawshield then
    if c.s[1][1] then
      pix(sx+6,sy+6,shieldcolor)
      pix(sx+7,sy+6,shieldcolor)
      pix(sx+6,sy+7,shieldcolor)
    end
    if c.s[2][1] then
      pix(sx+8,sy+6,shieldcolor)
    end
    if c.s[3][1] then
      pix(sx+9,sy+6,shieldcolor)
      pix(sx+10,sy+6,shieldcolor)
      pix(sx+10,sy+7,shieldcolor)
    end
    if c.s[1][2] then
      pix(sx+6,sy+8,shieldcolor)
    end
    if c.s[2][2] then
      pix(sx+8,sy+8,shieldcolor)
    end
    if c.s[3][2] then
      pix(sx+10,sy+8,shieldcolor)
    end
    if c.s[1][3] then
      pix(sx+6,sy+9,shieldcolor)
      pix(sx+6,sy+10,shieldcolor)
      pix(sx+7,sy+10,shieldcolor)
    end
    if c.s[2][3] then
      pix(sx+8,sy+10,shieldcolor)
    end
    if c.s[3][3] then
      pix(sx+10,sy+9,shieldcolor)
      pix(sx+10,sy+10,shieldcolor)
      pix(sx+9,sy+10,shieldcolor)
    end
  end
  --spr(96,sx,sy,-1,1,0,0,2,2)
  --print(e,sx+6,sy+6,1)
  -- `spr(id x y colorkey=-1 scale=1 flip=0 rotate=0 w=1 h=1)`
  --spr(96,x,y,-1,1,0,0,2,2)
end

-- inclusive
function rint(min,max)
  return math.floor(math.random()*(max-min+1))+min;
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

