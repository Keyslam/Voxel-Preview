love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setBackgroundColor(0.1, 0.1, 0.1)
love.filesystem.mount("voxels", "items")

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

   scale       = 1,
   cameraScale = 1,
   autoRotate  = true,
   rotation    = 0,

   lastModified = nil,

   x = 0,
   y = 0,
   z = 0,
}

local function buildBatch()
   local extension = Viewer.selected:match("^.+(%..+)$")

   if extension == ".png" then
      Viewer.image = love.graphics.newImage("items/"..Viewer.selected)
   elseif extension == ".vox" then
      local file = love.filesystem.newFile("items/"..Viewer.selected)
      file:open("r")
		   local model = Vox_model.new(file:read())
      file:close()
      Viewer.image = Vox_texture.new(model)
   end

   Viewer.batch = Lovox.voxelBatch(Viewer.image, Viewer.layers, 1, "static")
   Viewer.batch:add(0, love.graphics.getWidth()/2 / Viewer.cameraScale, love.graphics.getHeight()/2 / Viewer.cameraScale, v, Viewer.scale)

   Viewer.lastModified = love.filesystem.getInfo("items/"..Viewer.selected).modtime
end

function love.load(arg)
end

function love.update(dt)
   if Viewer.autoRotate then
      Viewer.rotation = Viewer.rotation + dt % (2*math.pi)
   end

   if Viewer.batch then
      if Viewer.lastModified ~= love.filesystem.getInfo("items/"..Viewer.selected).modtime then
         love.timer.sleep(0.5)
         buildBatch()
      end

      Viewer.batch:set(1, (Viewer.x + love.graphics.getWidth()/2) / Viewer.cameraScale, (Viewer.y + love.graphics.getHeight()/2) / Viewer.cameraScale, Viewer.z, 1 - Viewer.rotation, Viewer.scale)
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
      local files = love.filesystem.getDirectoryItems("items")

      for i, fileName in ipairs(files) do
         if Imgui.Selectable(fileName, fileName == Viewer.selected) then
            Viewer.selected = fileName
            
            buildBatch()
         end
      end
   end; Imgui.End()

   if Imgui.Begin("Settings") then
      local status

      Viewer.x, Viewer.y, Viewer.z = Imgui.DragInt3("Position", Viewer.x, Viewer.y, Viewer.z)

      Viewer.scale, Viewer.cameraScale = Imgui.DragFloat2("Scale", Viewer.scale, Viewer.cameraScale, 0.1, 1, 100)

      Viewer.layers, status = Imgui.DragFloat("Layers", Viewer.layers, 1, 1, 8192)

      Viewer.rotation   = Imgui.DragFloat("Rotation", Viewer.rotation, 0.1) % (2*math.pi)
      Viewer.autoRotate = Imgui.Checkbox("Auto Rotate", Viewer.autoRotate)

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


function love.directorydropped(path)
   love.filesystem.mount(path, "items")
end