import "util"

Engine = {}

function Engine:new(n)
  ret = {n=n, cells=createGrid(n), lastX=nil, lastY=nil}
  setmetatable(ret, self)
  self.__index = self
  return ret
end

function Engine:addStone(x,y,color)
  if self.cells[x][y] == nil then
    self.cells[x][y] = color
    self.lastX = x
    self.lastY = y
    return true
  end

  -- FIXME else show an error
  -- FIXME ko rules
  -- FIXME disallow suicide
end

-- to check if a group gets killed, we floodfill around all the groups?
-- should I use an uptree structure to join these groups?
-- this bit of the problem is a bit interesting

function Engine:killStones()
  --print("killing")

  -- learn all of the groups on the board
  -- group is id'd by the first cell we encounter in the group
  -- save the group for _every_ cell (or nil if no stone)
  local cellGroups = createGrid(self.n)

  function dfsGroup(x,y,groupColor,groupID)
    if x <= 0 or x > self.n or y <= 0 or y > self.n then
      return
    end

    if cellGroups[x][y] ~= nil then
      return
    end

    local cell = self.cells[x][y]

    -- nothing left to explore in this direction
    if cell ~= groupColor then
      return
    end

    -- assign to the group
    cellGroups[x][y] = groupID

    for _, off in ipairs({ {1,0}, {0,1}, {-1,0}, {0,-1} }) do
      local x_off = off[1]
      local y_off = off[2]
      dfsGroup(x+x_off, y+y_off, groupColor, groupID)
    end
  end

  -- trigger the DFS
  for x=1, self.n do
    for y=1, self.n do
      local cell = self.cells[x][y] -- nil or color

      if cell ~= nil then
        if cellGroups[x][y] == nil then
          local groupID = x .. "," .. y -- string for table key
          dfsGroup(x, y, self.cells[x][y], groupID)
        end
      end
    end
  end

  -- io.write("Groups:\n")
  -- for x=1,self.n do
  --   for y=1,self.n do
  --     local c = cellGroups[x][y]
  --     io.write(string.format("%s   ", c))
  --   end
  --   io.write('\n')
  -- end

  -- liberties are assigned to a group
  local groupLiberties = {}
  for x=1, self.n do
    for y=1, self.n do
      local cell = self.cells[x][y] -- nil or color
      local groupID = cellGroups[x][y] -- nil or string

      if groupID ~= nil then
        -- could possibly skip this iteration
        local local_liberties = 0
        for _, off in ipairs({ {1,0}, {0,1}, {-1, 0}, {0, -1} }) do
          local x_off = off[1]
          local y_off = off[2]
          if x+x_off > 0 and x+x_off <= self.n and y+y_off > 0 and y+y_off <= self.n then
            local n_cell = self.cells[x+x_off][y+y_off]
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

  --tprint(groupLiberties)

  -- kill any stones with zero liberties
  -- unless the group is the group that was played
  -- FIXME need to prevent suicide placements for this logic to hold

  local safeGroup = nil
  if self.lastX ~= nil then
    safeGroup = cellGroups[self.lastX][self.lastY]
  end

  for x=1, self.n do
    for y=1, self.n do
      local groupID = cellGroups[x][y]
      if groupID ~= nil then
        local liberties = groupLiberties[groupID]
        if liberties == 0 then
          if groupID ~= safeGroup then
            --print("Cell at ", x, y, "is dead")
            self.cells[x][y] = nil
          end
        end
      end
    end
  end
end

-- FIXME allow for passing
