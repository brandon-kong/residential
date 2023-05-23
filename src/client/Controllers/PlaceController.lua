local rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local placeUtil = require(script.Parent.Parent.Modules.PlaceUtil)
local mouseModule = require(script.Parent.Parent.Modules.Mouse)
local knit = require(rs.Packages.knit)

local PlaceController = knit.CreateController {
    Name = "PlaceController",
}

function PlaceController:KnitInit()
    self._mouse = mouseModule.new()
    
    self.state = {
        selectedObject = nil,
        selectedTile = nil,
        rotation = 0,
        movingObjectRotation = 0,
        formattedObjectTree = "",
        plot = nil,

        isMovingObject = false,
    }

    RunService:BindToRenderStep("PlaceController", Enum.RenderPriority.First.Value, function(dt)
        self:Render(dt)
    end)
end

function PlaceController:Render(dt)
    if (not self.state.isMovingObject) then
        return
    end

    local mouse = self._mouse
    local selectedObject = self.state.selectedObject


    local hit = mouse:GetTarget()
    local hitParent = hit and hit.Parent

    local tile = nil

    if (not hitParent or not hitParent:IsA("Folder") or not hit:IsDescendantOf(self.state.plot.Tiles)) then
        tile = placeUtil.GetNearestTileFromMousePosition(mouse, self.state.plot.Tiles:GetChildren())
        if (tile == self.state.selectedTile) then
            return
        else
            hit = tile
        end
    else
        tile = hit
    end

    if (not tile or not tile:IsA("BasePart")) then
        return
    end

    if (tile == self.state.selectedTile) then
        --return
    end

    self.state.selectedTile = tile

    local tilePosition = tile.Position
    local tileCFrame = tile.CFrame
    local tileSize = tile.Size

    local tileY = tilePosition.Y
    local tileHeight = tileSize.Y

    local tileTop = tileY + (tileHeight / 2)
    
    local tileCenter = tileCFrame.Position

    local objectSize = selectedObject.PrimaryPart.Size
    local objectHeight = objectSize.Y

    local objectTop = tileTop + (objectHeight / 2)

    local objectCenter = Vector3.new(
        tileCenter.X,
        objectTop,
        tileCenter.Z
    )

    local objectCFrame = CFrame.new(objectCenter)

    self.state.cframe = objectCFrame

    --selectedObject:SetPrimaryPartCFrame(objectCFrame)
    TweenService:Create(selectedObject.PrimaryPart, TweenInfo.new(0.2), {
        CFrame = self.state.cframe * CFrame.Angles(0, math.rad(self.state.rotation*90), 0)
    }):Play()
end

function PlaceController:KnitStart()

    local objToPlace = 'Residential/House/StarterHouse'
    ContextActionService:BindAction("PlaceObject", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:PlaceObject(objToPlace)
        end
    end, false, Enum.KeyCode.E)

    ContextActionService:BindAction("CancelPlace", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:CancelPlace()
        end
    end, true, Enum.KeyCode.C)

    ContextActionService:BindAction("RotateObject", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:RotateObject()
        end
    end, false, Enum.KeyCode.R)

    ContextActionService:BindAction("ConfirmPlacement", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:ConfirmPlacement()
        end
    end, false, Enum.UserInputType.MouseButton1)

    ContextActionService:BindAction("ShuffleObjects", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            if (objToPlace == 'Road/Basic Road') then
                objToPlace = 'Road/Raised Road'
            else
                objToPlace = 'Road/Basic Road'
            end
        end
    end, false, Enum.KeyCode.T)


    local PlotService = knit.GetService("PlotService")
    
    PlotService:GetPlayersPlot(game.Players.LocalPlayer):andThen(function(plot)
        self.state.plot = plot
        self._mouse:SetTargetFilter({plot.Models, plot.Debris})
        --self._mouse:SetFilterType(Enum.RaycastFilterType.Include)
    end)

    print("PlaceController started")
end

function PlaceController:PlaceObject(treePath: string)
    if (self.state.isMovingObject) then
        -- cannot place object while another object is being placed
        return
    end

    if (not self.state.plot) then return end

    local ObjectService = knit.GetService("ObjectService")
    local status, foundObj = ObjectService:GetObjectFromTreePath(treePath):await()

    if (not status) then
        warn("Error getting object from tree path")
        return
    end
    
    if (not foundObj) then
        warn("Object not found")
        return
    end

    self.state.selectedObject = foundObj:Clone()

    self.state.selectedObject.Parent = self.state.plot.Debris
    self.state.selectedObject:SetPrimaryPartCFrame(CFrame.new(0, 0, 0))
    self.state.selectedObject.PrimaryPart.Anchored = true

    self.state.formattedObjectTree = treePath
    self.state.isMovingObject = true

    for _, part in ipairs(self.state.selectedObject:GetDescendants()) do
        if (part:IsA("BasePart")) then
            part.CanCollide = false
            part.Transparency = 0.5
        end
    end
end

function PlaceController:CancelPlace()
    if (not self.state.isMovingObject) then
        return
    end

    self.state.selectedObject:Destroy()
    self.state.selectedObject = nil
    self.state.selectedTile = nil
    self.state.formattedObjectTree = ""
    self.state.isMovingObject = false
end

function PlaceController:RotateObject()
    if (not self.state.isMovingObject) then
        return
    end
    
    self.state.rotation = (self.state.rotation + 1) % 4
    TweenService:Create(self.state.selectedObject.PrimaryPart, TweenInfo.new(0.2), {
        CFrame = self.state.cframe * CFrame.Angles(0, math.rad(self.state.rotation*90), 0)
    }):Play()
end

function PlaceController:ConfirmPlacement()
    if (not self.state.isMovingObject) then
        return
    end

    if (not self.state.selectedTile) then
        return
    end

    local PlotService = knit.GetService("PlotService")

    local playersPlot = PlotService:GetPlayersPlot(game.Players.LocalPlayer)

    if (not playersPlot) then
        return
    end

    PlotService:PlaceObject(self.state.formattedObjectTree, {
        tile = self.state.selectedTile,
        rotation = self.state.rotation,
    })

    --self:CancelPlace()

end

return PlaceController