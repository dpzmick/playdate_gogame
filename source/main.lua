import "CoreLibs/graphics"
import "CoreLibs/sprites"

-- imports
local gfx <const> = playdate.graphics

-- game state
local turn = 1 -- black goes first?
local cursorLoc = {x=1, y=1}
local N = 19;

function createGrid(N)
  grid = {}
  for x=1, N do
    grid[x] = {}
    for y=1, N do
      grid[x][y] = nil
    end
  end
  return grid
end

function tprint (t, s)
    for k, v in pairs(t) do
        local kfmt = '["' .. tostring(k) ..'"]'
        if type(k) ~= 'string' then
            kfmt = '[' .. k .. ']'
        end
        local vfmt = '"'.. tostring(v) ..'"'
        if type(v) == 'table' then
            tprint(v, (s or '')..kfmt)
        else
            if type(v) ~= 'string' then
                vfmt = tostring(v)
            end
            print(type(t)..(s or '')..kfmt..' = '..vfmt)
        end
    end
end


local cells = createGrid(N)

local function drawGrid(n)
  -- display size is 400x240
  -- grid is 19x19
  -- or 9x9

  -- do horizontal lines
  local sep_x <const>  = 400/(n+n/2)
  local line_x         = sep_x*(n/4)
  local line_y <const> = 20
  local line_len <const> = 200

  for i=0, n do
    gfx.drawLine(line_x, line_y, line_x, line_y+line_len)
    line_x += sep_x
  end

  -- do verical lines
  local line_x <const> = sep_x*(n/4)
  local line_len       = 400 - sep_x*(n/4) - line_x
  local sep_y <const>  = (240-40)/n
  local line_y         = 20

  for i=0, n do
    gfx.drawLine(line_x, line_y, line_x+line_len, line_y)
    line_y += sep_y
  end

  local function drawStone(x, y, color)
    x = sep_x*(x-1) + sep_x*(n/4)
    y = sep_y*(y-1) + 20

    local radius <const> = 5
    if color==1 then
      gfx.fillCircleAtPoint(x, y, radius)
    else
      -- need to clear the grid underneath
      gfx.setColor(gfx.kColorWhite)
      gfx.fillCircleAtPoint(x, y, radius)
      gfx.setColor(gfx.kColorBlack)
      gfx.drawCircleAtPoint(x, y, radius)
    end
  end

  for x=1, N do
    for y=1, N do
      local cell = cells[x][y]
      if cell ~= nil then
        drawStone(x, y, cell)
      end
    end
  end

  -- draw the cursor
  gfx.drawRect((cursorLoc.x-1) * sep_x + sep_x*(n/4) - 6,
               (cursorLoc.y-1) * sep_y + 20 - 6,
               12, 12)

  -- FIXME replace number with a stone
  gfx.drawText("NEXT: ", 5, 5)
  gfx.drawText(turn, 50, 5)
  -- drawStone(50, 13, color)
end

local function redraw()
  gfx.clear()
  drawGrid(N)
  playdate.display.flush()
end

-- to check if a group gets killed, we floodfill around all the groups?
-- should I use an uptree structure to join these groups?
-- this bit of the problem is a bit interesting

local function killStones()
  print("killing")

  -- learn all of the groups on the board
  -- group is id'd by the first cell we encounter in the group
  -- save the group for _every_ cell (or nil if no stone)
  local cellGroups = createGrid(N)

  function dfsGroup(x,y,groupColor,groupID)
    local cell = cells[x][y]

    -- nothing left to explore in this direction
    if cell ~= groupColor then
      return
    end

    -- assign to the group
    cellGroups[x][y] = groupID

    -- always work down/left so we don't get stuck in a cycle
    for _, off in ipairs({ {1,0}, {0,1} }) do
      local x_off = off[1]
      local y_off = off[2]
      dfsGroup(x+x_off, y+y_off, groupColor, groupID)
    end
  end

  -- trigger the DFS
  for x=1, N do
    for y=1, N do
      local cell = cells[x][y] -- nil or color

      if cell ~= nil then
        if cellGroups[x][y] == nil then
          local groupID = x .. "," .. y -- string for table key
          dfsGroup(x, y, cells[x][y], groupID)
        end
      end
    end
  end

  -- liberties are assigned to a group
  local groupLiberties = {}
  for x=1, N do
    for y=1, N do
      local cell = cells[x][y] -- nil or color
      local groupID = cellGroups[x][y] -- nil or string

      if groupID ~= nil then
        -- could possibly skip this iteration
        local local_liberties = 0
        for _, off in ipairs({ {1,0}, {0,1}, {-1, 0}, {0, -1} }) do
          local x_off = off[1]
          local y_off = off[2]
          if x+x_off > 0 and x+x_off <= N and y+y_off > 0 and y+y_off <= N then
            local n_cell = cells[x+x_off][y+y_off]
            if n_cell == nil then
              local_liberties = local_liberties + 1
            end
          end
        end

        -- these local liberties should be added to the total liberties for the group
        if groupLiberties[groupID] == nil then
          groupLiberties[groupID] = local_liberties
        else
          groupLiberties[groupID] = groupLiberties[groupID] + local_liberties
        end
      end
    end
  end

  tprint(groupLiberties)

  -- kill any stones with zero liberties
  for x=1, N do
    for y=1, N do
      local groupID = cellGroups[x][y]
      if groupID ~= nil then
        local liberties = groupLiberties[groupID]
        if liberties == 0 then
          print("Cell at ", x, y, "is dead")
          cells[x][y] = nil
        end
      end
    end
  end
end


-- all drawing will be event driven
playdate.stop()
redraw()

local goInputHandlers = {
  upButtonUp = function()
    cursorLoc.y = cursorLoc.y - 1
    redraw()
  end,

  downButtonUp = function()
    cursorLoc.y = cursorLoc.y + 1
    redraw()
  end,

  leftButtonUp = function()
    cursorLoc.x = cursorLoc.x - 1
    redraw()
  end,

  rightButtonUp = function()
    cursorLoc.x = cursorLoc.x + 1
    redraw()
  end,

  AButtonUp = function()
    if cells[cursorLoc.x][cursorLoc.y] == nil then
      cells[cursorLoc.x][cursorLoc.y] = turn
      if turn == 0 then
        turn = 1
      else
        turn = 0
      end
    end
    -- FIXME else show an error

    -- FIXME ko rules

    -- update game state here
    killStones()
    redraw()
  end,
}

playdate.inputHandlers.push(goInputHandlers)
