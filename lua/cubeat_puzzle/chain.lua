
local floor = math.floor
local Horizontal, Vertical = {}, {}
local Chain3H, Chain4H, Chain5H, Chain3V, Chain4V, Answer = 
  {len=3, dir=Horizontal, base_id=30000}, 
  {len=4, dir=Horizontal, base_id=40000}, 
  {len=5, dir=Horizontal, base_id=50000}, 
  {len=3, dir=Vertical, base_id=3000}, 
  {len=4, dir=Vertical, base_id=4000},
  {len=1, dir=Vertical, base_id=10000}
  
-- private methods --

local intersect_add__ = {}

intersect_add__[Horizontal] = {
  [Horizontal] = function(self, other, height_limit) -- H intersect H
    if (other.x < self.x and other.en - self.x <= 1) or                        -- if x1 is left of x0
       (other.x > self.x and other.x <= self.x + 2 and self.en - other.x <= 1) -- if x1 is right of x0
    then                                        
      if other.y == self.y and other.color ~= self.color then
        table.insert(self.intersects, other)
      elseif other.y < self.y then
        table.insert(self.intersects, other)
      end      
    end
  end,  
  [Vertical]   = function(self, other, height_limit) -- V intersect H
    if other.len + self.y <= height_limit then                   
      if other.x >= self.x + (self.len-3) and other.x <= self.x + 2 and other.y <= self.y then
        if self.y > other.en or other.color ~= self.color then
          table.insert(self.intersects, other)
        end        
      end
    end
  end
  }

intersect_add__[Vertical]   = {
  [Horizontal] = function(self, other, height_limit) -- H intersect V
    if other.en >= self.x and other.x <= self.x and other.color ~= self.color then
      if self.len == 3 and (other.y == self.y + 1 or other.y == self.y + 2) then
        table.insert(self.intersects, other) 
      elseif self.len == 4 and other.y == self.y + 2 then
        table.insert(self.intersects, other) 
      end
    end    
  end,
  [Vertical]   = function(self, other, height_limit) -- V intersect V
    if other.x == self.x and self.en + other.len <= height_limit and self.color ~= other.color then
      if self.len == 3 and (other.y == self.y + 1 or other.y == self.y + 2) then
        table.insert(self.intersects, other) 
      elseif self.len == 4 and other.y == self.y + 2 then
        table.insert(self.intersects, other) 
      end
    end    
  end
  }

local function intersect_add_(self, other, height_limit) -- hand-made double dispatch
  intersect_add__[self.dir][other.dir](self, other, height_limit)
end

local function analyze(expr)
  return floor(expr / 100),   -- color
         floor(expr % 100 / 10),     -- pos x
         floor(expr % 10)            -- pos y
end

local function display(self) 
  return tostring(self.base_id/1000)..tostring(self.color)..tostring(self.x)..tostring(self.y) 
end

local function Chain_eq(a, b) return a.id == b.id end

local function shallow_copy(self) 
  local o = {color = self.color, x = self.x, y = self.y, en = self.en, id = self.id}
  setmetatable(o, getmetatable(self))
  o.intersects = self.intersects -- shallow
  o.answers = self.answers       -- shallow
  return o
end

local function ctor_of(proto)
  return function(expr)
    local o = {}
    o.intersects_ptr, o.answers_ptr = 1, 1
    o.color, o.x, o.y = analyze(expr)
    o.en = proto.dir == Horizontal and o.x + proto.len - 1 or o.y + proto.len - 1
    o.id = proto.base_id + o.color*100 + o.x*10 + o.y
    o.scopy = shallow_copy
    setmetatable(o, {__index = proto, __eq = Chain_eq, __tostring = display})
    return o
  end
end

local ANS = ctor_of(Answer)

-- remove_chain_from_map --

function Answer:remove_from_map(map)
  for y = self.y, map.height - 1 do
    map[y][self.x] = map[y+1][self.x] -- pull down everything on the same column
  end
  map[map.height][self.x] = 0
end

-- add_chain_to_map --
  
function Answer:add_chain_to_map(map, num)
  --local color = self.color == 0 and num or self.color
  for y = map.height - 1, self.y, -1 do
    map[y+1][self.x] = map[y][self.x]
  end
  map[self.y][self.x] = self.color
end
  
function Chain3H:add_chain_to_map(map, num)
  --local color = self.color == 0 and num or self.color
  for y = map.height - 1, self.y, -1 do 
    map[y+1][ self.x ] = map[y][ self.x ] 
    map[y+1][self.x+1] = map[y][self.x+1]
    map[y+1][self.x+2] = map[y][self.x+2]
  end
  map[self.y][ self.x ], map[self.y][self.x+1], map[self.y][self.x+2] = self.color, self.color, self.color
end

function Chain4H:add_chain_to_map(map, num)
  --local color = self.color == 0 and num or self.color
  for y = map.height - 1, self.y, -1 do 
    map[y+1][ self.x ] = map[y][ self.x ] 
    map[y+1][self.x+1] = map[y][self.x+1]
    map[y+1][self.x+2] = map[y][self.x+2]
    map[y+1][self.x+3] = map[y][self.x+3]
  end
  map[self.y][ self.x ], map[self.y][self.x+1], map[self.y][self.x+2], 
  map[self.y][self.x+3] = self.color, self.color, self.color, self.color
end

function Chain5H:add_chain_to_map(map, num)
  --local color = self.color == 0 and num or self.color
  for y = map.height - 1, self.y, -1 do 
    map[y+1][ self.x ] = map[y][ self.x ] 
    map[y+1][self.x+1] = map[y][self.x+1]
    map[y+1][self.x+2] = map[y][self.x+2]
    map[y+1][self.x+3] = map[y][self.x+3]
    map[y+1][self.x+4] = map[y][self.x+4]
  end
  map[self.y][ self.x ], map[self.y][self.x+1], map[self.y][self.x+2], 
  map[self.y][self.x+3], map[self.y][self.x+4] = self.color, self.color, self.color, self.color, self.color
end

function Chain3V:add_chain_to_map(map, num)
  --local color = self.color == 0 and num or self.color
  for y = map.height - 3, self.y, -1 do
    map[y+3][self.x] = map[y][self.x]
  end
  map[ self.y ][self.x], map[self.y+1][self.x], map[self.y+2][self.x] = self.color, self.color, self.color
end

function Chain4V:add_chain_to_map(map, num)
  --local color = self.color == 0 and num or self.color
  for y = map.height - 4, self.y, -1 do
    map[y+4][self.x] = map[y][self.x]
  end
  map[ self.y ][self.x], map[self.y+1][self.x], map[self.y+2][self.x], map[self.y+3][self.x] = self.color, self.color, self.color, self.color
end

-- intersect_add --

Chain3H.intersect_add = intersect_add_
Chain4H.intersect_add = intersect_add_
Chain5H.intersect_add = intersect_add_
Chain3V.intersect_add = intersect_add_
Chain4V.intersect_add = intersect_add_

-- answer_add --

function Chain3H:answer_add()
  for color = 1, 4 do
    for y1 = 1, self.y do 
      table.insert(self.answers, ANS(color*100 + self.x*10 + y1) )
      table.insert(self.answers, ANS(color*100 + (self.x+1)*10 + y1) )
      table.insert(self.answers, ANS(color*100 + (self.x+2)*10 + y1) )
    end
  end
end

function Chain4H:answer_add()
  for color = 1, 4 do
    for y1 = 1, self.y do 
      table.insert(self.answers, ANS(color*100 + (self.x+1)*10 + y1) )
      table.insert(self.answers, ANS(color*100 + (self.x+2)*10 + y1) )
    end
  end
end

function Chain5H:answer_add()
  for color = 1, 4 do
    for y1 = 1, self.y do 
      table.insert(self.answers, ANS(color*100 + (self.x+2)*10 + y1) )
    end
  end
end

function Chain3V:answer_add()
  for color = 1, 4 do 
    table.insert(self.answers, ANS(color*100 + self.x*10 + self.y+1) )
    table.insert(self.answers, ANS(color*100 + self.x*10 + self.y+2) )
  end
end

function Chain4V:answer_add()
  for color = 1, 4 do 
    table.insert(self.answers, ANS(color*100 + self.x*10 + self.y+2) )
  end
end

-- update_heights --

function Chain3H:update_heights(heights)
  heights[ self.x ] = heights[ self.x ] + 1
  heights[self.x+1] = heights[self.x+1] + 1
  heights[self.x+2] = heights[self.x+2] + 1
end

function Chain4H:update_heights(heights)
  heights[ self.x ] = heights[ self.x ] + 1
  heights[self.x+1] = heights[self.x+1] + 1
  heights[self.x+2] = heights[self.x+2] + 1
  heights[self.x+3] = heights[self.x+3] + 1
end

function Chain5H:update_heights(heights)
  heights[ self.x ] = heights[ self.x ] + 1
  heights[self.x+1] = heights[self.x+1] + 1
  heights[self.x+2] = heights[self.x+2] + 1
  heights[self.x+3] = heights[self.x+3] + 1
  heights[self.x+4] = heights[self.x+4] + 1
end

function Chain3V:update_heights(heights)
  heights[self.x] = heights[self.x] + self.len
end

function Chain4V:update_heights(heights) 
  heights[self.x] = heights[self.x] + self.len
end

function Chain3H:not_float(heights)
  return self.y == 1 or (
    heights[ self.x ] + 1 >= self.y and  
    heights[self.x+1] + 1 >= self.y and
    heights[self.x+2] + 1 >= self.y
  )
end

function Chain4H:not_float(heights)
  return self.y == 1 or (
    heights[ self.x ] + 1 >= self.y and heights[self.x+1] + 1 >= self.y and
    heights[self.x+2] + 1 >= self.y and heights[self.x+3] + 1 >= self.y 
  )
end

function Chain5H:not_float(heights)
  return self.y == 1 or (
    heights[ self.x ] + 1 >= self.y and heights[self.x+1] + 1 >= self.y and
    heights[self.x+2] + 1 >= self.y and heights[self.x+3] + 1 >= self.y and
    heights[self.x+4] + 1 >= self.y
  )
end

function Chain3V:not_float()
  return true -- it should be impossible for vertical combinations to float
end

function Chain4V:not_float()
  return true -- it should be impossible for vertical combinations to float
end

-- (not_)too_high --

function Answer:too_high(heights, height_limit)
  return heights[self.x] + 1 > height_limit
end

function Chain3H:too_high(heights, height_limit)
  return heights[ self.x ] + 1 > height_limit or
         heights[self.x+1] + 1 > height_limit or
         heights[self.x+2] + 1 > height_limit
end

function Chain4H:too_high(heights, height_limit)
  return heights[ self.x ] + 1 > height_limit or
         heights[self.x+1] + 1 > height_limit or
         heights[self.x+2] + 1 > height_limit or
         heights[self.x+3] + 1 > height_limit
end

function Chain5H:too_high(heights, height_limit)
  return heights[ self.x ] + 1 > height_limit or
         heights[self.x+1] + 1 > height_limit or
         heights[self.x+2] + 1 > height_limit or
         heights[self.x+3] + 1 > height_limit or
         heights[self.x+4] + 1 > height_limit
end

function Chain3V:too_high(heights, height_limit)
  return heights[self.x] + self.len > height_limit 
end

function Chain4V:too_high(heights, height_limit)
  return heights[self.x] + self.len > height_limit 
end

return {ctor_of(Chain3H), ctor_of(Chain4H), ctor_of(Chain5H), ctor_of(Chain3V), ctor_of(Chain4V), ANS}
