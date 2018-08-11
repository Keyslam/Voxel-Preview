love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
love.filesystem.mount("voxels", "voxels")

local Imgui = require("imgui")

local Lovox = require("lovox")
local Vox_model = require("vox2png.vox_model")
local Vox_texture = require("vox2png.vox_texture")

local Viewer = {
   selected = nil,
   camera   = Lovox.camera(),
   
   image  = nil,
   layers = 1,
   batch  = nil,

   scale = 1,
   cameraScale = 1,

   lastModified = nil,
}

local function buildBatch()
   local extension = Viewer.selected:match("^.+(%..+)$")

   if extension == ".png" then
      Viewer.image = love.graphics.newImage("voxels/"..Viewer.selected)
   elseif extension == ".vox" then
      local file = love.filesystem.newFile("voxels/"..Viewer.selected)
      file:open("r")
		   local model = Vox_model.new(file:read())
      file:close()
      Viewer.image = Vox_texture.new(model)
   end

   Viewer.batch = Lovox.voxelBatch(Viewer.image, Viewer.layers, 1, "static")
   Viewer.batch:add(0, 360 / Viewer.cameraScale, 360 / Viewer.cameraScale, 0, Viewer.scale)

   Viewer.lastModified = love.filesystem.getInfo("voxels/"..Viewer.selected).modtime
end

function love.load(arg)
end

function love.update(dt)
   if Viewer.batch then
      if Viewer.lastModified ~= love.filesystem.getInfo("voxels/"..Viewer.selected).modtime then
         love.timer.sleep(0.5)
         buildBatch()
      end

      Viewer.batch:set(1, 360 / Viewer.cameraScale, 360 / Viewer.cameraScale, 0, 1 -love.timer.getTime(), Viewer.scale)
   end

   Imgui.NewFrame()
end

function love.draw()
   if Viewer.batch then
      Viewer.camera:attach()
      Viewer.batch:draw()
      Viewer.camera:detach()

      Viewer.camera:draw(nil, nil, nil, Viewer.cameraScale)
   end

   if Imgui.Begin("Open") then
      local files = love.filesystem.getDirectoryItems("voxels")

      for i, fileName in ipairs(files) do
         if Imgui.Selectable(fileName, fileName == Viewer.selected) then
            Viewer.selected = fileName
            
            buildBatch()
         end
      end
   end; Imgui.End()

   if Imgui.Begin("Settings") then
      local status

      Viewer.layers, status = Imgui.DragFloat("Layers", Viewer.layers, 1, 1, 8192)
      Viewer.scale = Imgui.DragFloat("Scale", Viewer.scale, 0.1, 1, 100)
      Viewer.cameraScale = Imgui.DragFloat("Camera scale", Viewer.cameraScale, 0.1, 1, 100)

      if status then
         buildBatch()
      end
   end; Imgui.End()

   Imgui.Render();
end

function love.quit()
   Imgui.ShutDown();
end

function love.textinput(t)
   Imgui.TextInput(t)
end

function love.keypressed(key)
   Imgui.KeyPressed(key)
end

function love.keyreleased(key)
   Imgui.KeyReleased(key)
end

function love.mousemoved(x, y)
   Imgui.MouseMoved(x, y)
end

function love.mousepressed(x, y, button)
   Imgui.MousePressed(button)
end

function love.mousereleased(x, y, button)
   Imgui.MouseReleased(button)
end

function love.wheelmoved(x, y)
   Imgui.WheelMoved(y)
   if not Imgui.GetWantCaptureMouse() then
      Viewer.scale = math.max(1, math.min(Viewer.scale + y/10, 100))
   end
end