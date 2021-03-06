----------------
local ffi = require "ffi"
ffi.cdef( io.open('c:\\libs\\cpp\\SDL\\ffi_SDL.h', 'r'):read('*a'))
local SDL = ffi.load('c:\\libs\\cpp\\SDL\\SDL')
package.path = "c:\\local_gitrepo\\luajit-opencl"..package.path
local GL = require "gl"
local GLU= require "glu"
----------------
local randomseed, rand, floor, abs = math.randomseed, math.random, math.floor, math.abs
local random = function(n) 
  n = n or 1; 
  return floor(rand()*abs(n)) 
end

local function new_grid(w, h) 
  local grid = {}
  w, h = w or 15, h or 15
  for y = 1, h+2 do
    grid[y] = {}
    for x = 1, w+2 do
      grid[y][x] = 0
    end
  end
  return grid
end

local function grid_print(grid, w, h)
  w, h = w or 15, h or 15
  if not grid then return end
  for y = 2, h+1 do
    for x = 2, w+1 do 
      io.write(string.format("%d ", grid[y][x]))
    end
    print()
  end
end

local function neighbor_count(old, y, x, h, w)
  --[[local count = 0
  for i=1, #dir do
    local ny, nx = y + dir[i][1], x + dir[i][2]
    if ny < 1 then ny = h
    elseif ny > h then ny = 1 end
    if nx < 1 then nx = w
    elseif nx > w then nx = 1 end
    if old_grid[ny][nx] > 0 then count = count + 1 end
  end]]
  local count = (old[y-1][x-1] + old[y-1][x] + old[y-1][x+1]) +
                (old[y][x-1]   +               old[y][x+1])   +
                (old[y+1][x-1] + old[y+1][x] + old[y+1][x+1])
  return count
end

local rule1 = {0, 0, 1, 1, 0, 0, 0, 0, 0}
local rule2 = {0, 0, 0, 1, 0, 0, 0, 0, 0}
local function ruleset(now, n)
  return now > 0 and rule1[n+1] or rule2[n+1]
end

local function wrap_padding(old, w, h)
  w, h = w or 15, h or 15
  -- side wrapping.
  for x = 3, w do 
    old[h+2][x] = old[ 2 ][x]
    old[ 1 ][x] = old[h+1][x]
  end
  for y = 3, h do 
    old[y][w+2] = old[y][ 2 ]
    old[y][ 1 ] = old[y][w+1]
  end
  -- .. and corner wrapping, obviously I am too stupid.
  local tl, tr, bl, br = old[2][2], old[2][w+1], old[h+1][2], old[h+1][w+1]
  old[2][w+2], old[h+2][2], old[h+2][w+2] = tl, tl, tl
  old[2][1],   old[h+2][1], old[h+2][w+1] = tr, tr, tr
  old[1][2],   old[1][w+2], old[h+1][w+2] = bl, bl, bl
  old[1][1],   old[1][w+1], old[h+1][1]   = br, br, br
end

local function grid_iteration(old_grid, new_grid, w, h)
  w, h = w or 15, h or 15
  wrap_padding(old_grid)
  for y = 2, h+1 do
    for x = 2, w+1 do
      new_grid[y][x] = ruleset( old_grid[y][x], neighbor_count(old_grid, y, x, h, w) )
    end
  end
  for y = 1, h+2 do 
    for x = 1, w+2 do 
      old_grid[y][x] = new_grid[y][x] -- grid data copy
      new_grid[y][x] = 0              -- clean new grid data
    end
  end
end
----------------

local game = {}

game.WIDTH        = 1200
game.HEIGHT       = 900
game.INIT_OPTION  = 0x0000FFFF -- SDL_INIT_EVERYTHING
game.VIDEO_OPTION = -- 0x01 + 0x40000000
                    bit.bor(bit.bor(0x01, SDL.SDL_GL_DOUBLEBUFFER), 0x02)
                    -- SDL_HWSURFACE | SDL_GL_DOUBLEBUFFER | SDL_OPENGL
game.t            = os.clock()
game.csize        = 2
game.model_w      = game.WIDTH / game.csize
game.model_h      = game.HEIGHT/ game.csize

function game:init()
 
  randomseed(os.time())

  SDL.SDL_Init(self.INIT_OPTION)
  SDL.SDL_WM_SetCaption("SDL + OpenGL Game of Life", "SDL")
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_RED_SIZE,        8);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_GREEN_SIZE,      8);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_BLUE_SIZE,       8);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_ALPHA_SIZE,      8);

  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_DEPTH_SIZE,      16);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_BUFFER_SIZE,     32);

  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_ACCUM_RED_SIZE,  8);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_ACCUM_GREEN_SIZE,8);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_ACCUM_BLUE_SIZE, 8);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_ACCUM_ALPHA_SIZE,8);

  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_MULTISAMPLEBUFFERS,  1);
  SDL.SDL_GL_SetAttribute(SDL.SDL_GL_MULTISAMPLESAMPLES,  2);  
  
  self.screen = SDL.SDL_SetVideoMode(self.WIDTH, self.HEIGHT, 32, self.VIDEO_OPTION)
  
  GL.glClearColor(0, 0, 0, 0);
  GL.glViewport(0, 0, self.WIDTH, self.HEIGHT);
  GL.glMatrixMode(GL.GL_PROJECTION);
  GL.glLoadIdentity();
  GL.glOrtho(0, self.WIDTH, self.HEIGHT, 0, 1, -1);
  GL.glMatrixMode(GL.GL_MODELVIEW);
  GL.glEnable(GL.GL_TEXTURE_2D);
  GL.glLoadIdentity();
  
  self.old = new_grid(self.model_w, self.model_h)
  self.new = new_grid(self.model_w, self.model_h)
  for i = 1, self.model_w*self.model_h / 9 do 
    self.old[random(self.model_h)+1][random(self.model_w)+1] = 1 
  end
end

function game:run()
  local event = ffi.new("SDL_Event")
  if SDL.SDL_PollEvent(event) == 1 then
    local etype = event.type
    if etype == SDL.SDL_QUIT then
      return false
    elseif etype == SDL.SDL_KEYDOWN then
      sym = event.key.keysym.sym
      if sym == SDL.SDLK_q or sym == SDL.SDLK_ESCAPE then
        return false
      end
    end
  end
  return true
end

function game:update(t)
  --print(t - self.t)
  --if t - self.t > 0.033 then
    grid_iteration(self.old, self.new, self.model_w, self.model_h)
    self.t = t
  --end
end

function game:render()
  GL.glClear( bit.bor(GL.GL_COLOR_BUFFER_BIT, GL.GL_DEPTH_BUFFER_BIT) );
  GL.glLoadIdentity();
  local csizep = self.csize
  local csize  = csizep-1
  for y = 0, self.model_h-1 do
    for x = 0, self.model_w-1 do
      if self.old[y+1][x+1] == 1 then
        GL.glBegin(GL.GL_QUADS);
          GL.glColor3f(1, 1, 1); GL.glVertex3f(x*csizep        , y*csizep        , 0);
          GL.glColor3f(1, 1, 1); GL.glVertex3f(x*csizep + csize, y*csizep        , 0);
          GL.glColor3f(1, 1, 1); GL.glVertex3f(x*csizep + csize, y*csizep + csize, 0);
          GL.glColor3f(1, 1, 1); GL.glVertex3f(x*csizep        , y*csizep + csize, 0);
        GL.glEnd();
      end
    end
  end
  SDL.SDL_GL_SwapBuffers();
end

function game:destroy()
  SDL.SDL_FreeSurface(self.screen)
  SDL.SDL_Quit()
end

local function main()
  game:init()
  while game:run() do
    game:update(os.clock())
    game:render()
  end
  game:destroy()
end

main()