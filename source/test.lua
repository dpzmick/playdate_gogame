-- a simple test script that can run on the local machine

-- shim for playdate's import function
function import(fname)
  return require(fname)
end

import "util"
import "engine"
import "test_util"

local function testCreateGrid()
  grid = createGrid(4)
  for i=1,4 do
    for j=1,4 do
      assert(grid[i][j] == nil)
    end
  end
end

local function test1()
  e = Engine:new(9)
  e:addStone(1,1,1)
  assert(e.cells[1][1]==1)
end

local function test2()
  e = Engine:new(9)
  for x=1,9 do
    for y=1,9 do
      assert(e.cells[x][y] == nil)
    end
  end
end

local function testSimpleKill()
  inpt = makeCells(5, [[
W B . . .
B . . . .
. . . . .
. . . . .
]])

  expect = makeCells(5, [[
. B . . .
B . . . .
. . . . .
. . . . .
]])

  e = Engine:new(5)
  e.cells = inpt
  e:killStones()
  cellAssert(5, e.cells, expect)
end

local function testComplexKill()
  inpt = makeCells(5, [[
W B B . .
W W W B .
B B B . .
. . . . .
]])

  expect = makeCells(5, [[
. B B . .
. . . B .
B B B . .
. . . . .
]])

  e = Engine:new(5)
  e.cells = inpt
  e:killStones()
  cellAssert(5, e.cells, expect)
end

local function testNotActuallySuicide()
  -- assume 1,2 is the most recently placed cell
  -- it (and it's group) cannot be killed on this turn
  -- all suicide is disallowed, but this move is not suicide _after_
  -- killing the white cells

  inpt = makeCells(5, [[
W B W B .
B B B B .
. . . . .
. . . . .
]])

  expect = makeCells(5, [[
. B . B .
B B B B .
. . . . .
. . . . .
]])

  e = Engine:new(5)
  e.cells = inpt
  e.lastX = 1
  e.lastY = 2
  e:killStones()
  cellAssert(5, e.cells, expect)

  -- this logic is sensitive to order, so try another variant
  inpt = makeCells(5, [[
W B W . .
W W W . .
. . . . .
. . . . .
]])

  expect = makeCells(5, [[
W . W . .
W W W . .
. . . . .
. . . . .
]])

  e = Engine:new(5)
  e.cells = inpt
  e.lastX = 1
  e.lastY = 1
  e:killStones()
  cellAssert(5, e.cells, expect)

  -- this logic is sensitive to order, so try another variant
  -- white made the last play
  inpt = makeCells(5, [[
W B W . .
B B W . .
W W W . .
. . . . .
]])

  expect = makeCells(5, [[
W . W . .
. . W . .
W W W . .
. . . . .
]])

  e = Engine:new(5)

  e.cells = inpt
  e.lastX = 1
  e.lastY = 1

  e:killStones()

  cellAssert(5, e.cells, expect)

  ----------------------

  inpt = makeCells(7, [[
B B B B B . .
B W W W B . .
B W B W B . .
B W W W B . .
B B B B B . .
. . . . . . .
]])

  expect = makeCells(7, [[
B B B B B . .
B . . . B . .
B . B . B . .
B . . . B . .
B B B B B . .
. . . . . . .
]])

  e = Engine:new(7)

  e.cells = inpt
  e.lastX = 3
  e.lastY = 3

  e:killStones()

  cellAssert(7, e.cells, expect)
end

local function testMultiCapture()
  -- a single stone captures multiple groups
  inpt = makeCells(7, [[
. . . . . . .
. . . . . . .
B B . B B B B
W W B W W W W
B B . B B B B
. . . . . . .
. . . . . . .
]])

  expect = makeCells(7, [[
. . . . . . .
. . . . . . .
B B . B B B B
. . B . . . .
B B . B B B B
. . . . . . .
. . . . . . .
]])

  e = Engine:new(7)
  e.cells = inpt
  e.lastX = 3
  e.lastY = 4
  e:killStones()
  cellAssert(7, e.cells, expect)
end

local function testNoSuicide()
  e = Engine:new(5)
  e.cells = makeCells(5, [[
. W . . .
W W . . .
. . . . .
. . . . .
. . . . .
]])

  assert(false == e:addStone(1,1,1)) -- would be suicide
end

testCreateGrid()
test1()
test2()
testSimpleKill()
testComplexKill()
testNotActuallySuicide()
testMultiCapture()
--testNoSuicide()
