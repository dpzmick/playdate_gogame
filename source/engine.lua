import "util"

Engine = {}

function Engine:new(n)
  local ret = {n=n, cells=createGrid(n), lastX=nil, lastY=nil}
  setmetatable(ret, self)
  self.__index = self
  return ret
end

function Engine:clone()
  local ret = Engine:new(self.n)
  ret.lastX = self.lastX
  ret.lastY = self.lastY
  for x=1,self.n do
    for y=1,self.n do
      ret.cells[x][y] = self.cells[x][y]
    end
  end
  return ret
end

function Engine:addStone(x,y,color)
  if self.cells[x][y] ~= nil then
    return false
  end

  -- to check for suicidal plays, copy engine state,
  -- insert into copy, then check if the new location survives
  local c = self:clone()
  c.cells[x][y] = color
  c.lastX = x
  c.lastY = y
  c:killStones()

  if c.cells[x][y] == nil then
    -- this was a suicidal play, detected via awkward logic in killStones
    return false
  end

  -- this is a safe insert to perform
  self.cells[x][y] = color
  self.lastX = x
  self.lastY = y
  return true

  -- should maybe do uptree style groups?
  --  - also non-trivial, state is complex
  --
  -- then do stone additon by:
  -- - add stone to cells and join/create groups
  -- - adjust liberties for all(?) groups
  -- - if the only group to die is the newly added one, reject the move
  --   - note that there should have been zero dead groups before the update

  -- FIXME ko rules
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

  -- io.write("Liberties:\n")
  -- for x=1,self.n do
  --   for y=1,self.n do
  --     local c = cellGroups[x][y]
  --     local l = groupLiberties[c]
  --     if l~=nil then
  --       io.write(string.format("%3d ", l))
  --     else
  --       io.write("nil ")
  --     end
  --   end
  --   io.write('\n')
  -- end

  -- kill any stones with zero liberties
  -- if the only group to die is the last placed group, the last move was suicide, so kill the group (addStone detects this)
  -- else, do not kill the last group

  local lastStoneGroup = nil
  if self.lastX ~= nil then
    lastStoneGroup = cellGroups[self.lastX][self.lastY]
  end

  local groupsToKill = {}
  for groupID, liberties in pairs(groupLiberties) do
    if liberties==0 then
      groupsToKill[#groupsToKill+1] = groupID
    end
  end

  local killLastStoneGroup = false
  if #groupsToKill == 1 then
    if groupsToKill[1] == lastStoneGroup then
      killLastStoneGroup = true
    end
  end

  for x=1, self.n do
    for y=1, self.n do
      local groupID = cellGroups[x][y]
      if groupID ~= nil then
        local liberties = groupLiberties[groupID]
        if liberties == 0 then
          if groupID == lastStoneGroup then
            if killLastStoneGroup then
              self.cells[x][y] = nil
            end
          else
            self.cells[x][y] = nil
          end
        end
      end
    end
  end
end

function Engine:findWinner()
  -- to remove dead stones we run the game forward many times
  -- until the state of the stones begins to stabilize
  -- then stones that are very likely dead are removed

  stoneDeadProb = createGrid()

  -- FIXME stopped here, scoring the game is non-trivial

  while true do
  end

  -- finally we remove dead stones, then count the surrounded area
  -- the score is surrounded area + captured stones for each player
end

-- FIXME track prisoners
-- FIXME allow for passing (adds a prisoner)
-- FIXME for final scoring, mark dead strings
-- FIXME termination logic
