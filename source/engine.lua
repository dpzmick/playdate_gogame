import "util"

-- game state
cursorLoc = {x=1, y=1}
N = 9;
cells = createGrid(N)

function addStone(x,y,color)
  if cells[x][y] == nil then
    cells[x][y] = color
    return true
  end

  -- FIXME else show an error
  -- FIXME ko rules
  -- FIXME disallow suicide
end

-- to check if a group gets killed, we floodfill around all the groups?
-- should I use an uptree structure to join these groups?
-- this bit of the problem is a bit interesting

function killStones()
  --print("killing")

  -- learn all of the groups on the board
  -- group is id'd by the first cell we encounter in the group
  -- save the group for _every_ cell (or nil if no stone)
  local cellGroups = createGrid(N)

  function dfsGroup(x,y,groupColor,groupID)
    if x <= 0 or x > N or y <= 0 or y > N then
      return
    end

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

  --tprint(groupLiberties)

  -- kill any stones with zero liberties
  -- FIXME if the elimination of standing groups is triggered by a new stone
  -- which also has zero liberties, then the new stone should not get killed
  -- until the first added group is removed.
  -- in other words, we should only remove one stone at a time
  for x=1, N do
    for y=1, N do
      local groupID = cellGroups[x][y]
      if groupID ~= nil then
        local liberties = groupLiberties[groupID]
        if liberties == 0 then
          --print("Cell at ", x, y, "is dead")
          cells[x][y] = nil
        end
      end
    end
  end
end
