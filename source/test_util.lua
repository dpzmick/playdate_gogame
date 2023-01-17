-- utility for testing
function makeCells(n, str)
  cells = createGrid(n)

  local x = 1
  for l in str:gmatch("[^\r\n]+") do
    -- print(l)

    local y = 1
    for c in l:gmatch(".") do
      if c=='W' then
        cells[x][y] = 0
        y = y+1
      elseif c=='B' then
        cells[x][y] = 1
        y = y+1
      elseif c=='.' then
        cells[x][y] = nil -- doesn't actually store anything
        y = y+1
      elseif c==' ' then
        -- pass
      end
    end

    x = x+1
  end

  return cells
end

function cellAssert(n, c1, c2)
  for x=1,n do
    for y=1,n do
      assert(c1[x][y] == c2[x][y])
    end
  end
end

function cellPrint(n, cells)
  for x=1,n do
    for y=1,n do
      local c = cells[x][y]
      if c==0 then
        io.write('W')
      elseif c==1 then
        io.write('B')
      elseif c==nil then
        io.write('.')
      end
      io.write(' ')
    end
    io.write('\n')
  end
end

local function testMakeCells()
  cells = makeCells(4, [[
W W . .
W B . .
B B . .
. . W W
]])

  -- for x=1,4 do
  --   for y=1,4 do
  --     print(x, y, ":", cells[x][y])
  --   end
  -- end

  cellAssert(4, cells,
             {{0,   0,   nil, nil},
              {0,   1,   nil, nil},
              {1,   1,   nil, nil},
              {nil, nil, 0,   0  }})
end

testMakeCells() -- run this just in case
