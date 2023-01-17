function createGrid(n)
  grid = {}
  for x=1, n do
    grid[x] = {}
    for y=1, n do
      grid[x][y] = nil
    end
  end
  return grid
end

-- from stack overflow
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
