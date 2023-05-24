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
    self.mouse = mouseModule.new()

    self.state = {
        placing = false,
        moving = false,
        object = nil,
        props = nil,
        path = nil,
        plot = nil,
        tile = nil,
        stacked = {
            is = false,
            connectionPoint = nil,
        },
        rotation = 0,
    }

    local shuffle = {
        'Road/Basic Road',
        'Road/Streetlight',
        'Road/Raised Road',
    }

    local shuffleIndex = 1
    local b = shuffle[shuffleIndex]

    RunService:BindToRenderStep("PlaceController", Enum.RenderPriority.Camera.Value, function(dt)
        self:Render(dt)
    end)

    ContextActionService:BindAction("RotateObject", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:RotateObject()
        end
    end, false, Enum.KeyCode.R)

    ContextActionService:BindAction("PlaceObject", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:PlaceObject(b)
        end
    end, false, Enum.KeyCode.E)

    ContextActionService:BindAction("ConfirmPlacement", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:ConfirmPlacement()
        end
    end, false, Enum.UserInputType.MouseButton1)

    ContextActionService:BindAction("ShuffleObjects", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            shuffleIndex = shuffleIndex + 1
            if (shuffleIndex > #shuffle) then
                shuffleIndex = 1
            end
            b = shuffle[shuffleIndex]

            self:CancelPlacement()
            self:PlaceObject(b)

        end
    end, false, Enum.KeyCode.T)

    ContextActionService:BindAction("CancelPlacement", function(actionName, inputState, inputObject)
        if (inputState == Enum.UserInputState.Begin) then
            self:CancelPlacement()
        end
    end, false, Enum.KeyCode.Q)


end

function PlaceController:Render(dt)
    if (not self.state.placing) and (not self.state.moving) then return end
    if (not self.state.plot) then return end
    if (not self.state.object) then return end

    local mouse = self.mouse
    local state = self.state
    local path = state.path
    local plot = state.plot
    local object = state.object

    local target = mouse:GetTarget()
    local targetModel = placeUtil.GetModelFromPart(target)
    local partIsATile = placeUtil.PartIsInTiles(target, plot)

    --local targetModelIndexEntry = placeUtil.GetModelIndexEntryFromPath(targetModel)

    if (targetModel) then
        if (placeUtil.ModelIsInPlot(targetModel, plot)) then
            -- the target model is in the client's plot, so we can
            -- check if stacking is allowed
            local targetModelPath = targetModel:GetAttribute("Path")

            local targetModelIndexEntry = placeUtil.GetIndexEntryFromPath(targetModelPath)

            if (targetModelIndexEntry) then
                local targetModelStacking = targetModelIndexEntry.special.stacking

                if (targetModelStacking and targetModelStacking.allowed) then
                    -- stacking is allowed, so we can check if the object
                    -- is allowed to stack on the target model
                    
                    if (targetModelStacking.allowedModels[path]) then
                        local closestConnectionPoint = placeUtil.GetConnectionPointsClosestToMouse(mouse, targetModel, path)
                        
                        if (closestConnectionPoint) then
                            -- calculate rotation of object based on the closest connection point rotation
                            --object:PivotTo(closestConnectionPoint.CFrame * CFrame.Angles(0, math.rad(state.rotation), 0))

                            local objectPosition = closestConnectionPoint.CFrame

                            TweenService:Create(object.PrimaryPart, TweenInfo.new(0.1), {
                                CFrame = objectPosition * CFrame.Angles(0, math.rad(state.rotation), 0)
                            }):Play()

                            state.stacked = {
                                is = true,
                                id = targetModel:GetAttribute("Id"),
                                obj = targetModel,
                                connectionPoint = closestConnectionPoint,
                            }
                            return
                        end
                    end                        
                end
            end
        end
    end

    local targetTile = placeUtil.GetNearestTileFromMousePosition(mouse, plot.Tiles:GetChildren())

    if (targetTile) then

        state.stacked = {
            is = false,
        }

        self.state.tile = targetTile
        local targetTilePosition = targetTile.Position
        local targetTileSize = targetTile.Size

        local objectOrientation, objectSize = object:GetBoundingBox()

        local yFactor = objectSize.Y/targetTileSize.Y

        local objectPosition = targetTilePosition + Vector3.new(0, object.PrimaryPart.Size.Y, 0)

        TweenService:Create(object.PrimaryPart, TweenInfo.new(0.1), {
            CFrame = CFrame.new(objectPosition) * CFrame.Angles(0, math.rad(state.rotation), 0)
        }):Play()
        --object:PivotTo(CFrame.new(objectPosition) * CFrame.Angles(0, math.rad(state.rotation), 0))
    end
end

function PlaceController:KnitStart()
    print("PlaceController started")

    local PlotService = knit.GetService("PlotService")
    local ObjectService = knit.GetService("ObjectService")

    local status, plot = PlotService:GetPlotInstance():await()

    if (not status) then
        warn("Failed to get plot")
        return
    end

    if (not plot) then
        warn("No plot found")
        return
    end

    self.mouse:SetFilterType(Enum.RaycastFilterType.Exclude)
    self.mouse:SetTargetFilter({
        plot.Debris
    })

    self.state.plot = plot

    self:PlaceObject("Road/Raised Road")
end

function PlaceController:PlaceObject(path: string)
    if (self.state.placing) then return end
    if (not self.state.plot) then return end
    if (not path) then return end

    local state = self.state

    local plot = state.plot

    local object = placeUtil.CreateObject(path)
    state.object = object
    object.Parent = plot.Debris

    state.placing = true
    state.path = path

    placeUtil.SetTransparency(object, 0.5)
    placeUtil.SetCollisionGroup(object, "Plot")
end


function PlaceController:RotateObject()
    local state = self.state
    local object = state.object

    state.rotation = state.rotation + 90
    if (state.rotation >= 360) then
        state.rotation = 0
    end
end


function PlaceController:ConfirmPlacement()
    local state = self.state

    local object = state.object
    local plot = state.plot
    local path = state.path
    local rotation = state.rotation
    local tile = state.tile
    local stacked = state.stacked

    local PlotService = knit.GetService("PlotService")
    
    PlotService:PlaceObject(path, {
        Stacked = stacked,
        Path = path,
        Rotation = rotation,
        Tile = tile
    }, plot):andThen(function()
        --self:CancelPlacement()
    end)
end


function PlaceController:CancelPlacement()
    local state = self.state

    local object = state.object

    if (object) then
        object:Destroy()
    end

    state.placing = false
    state.object = nil
    state.path = nil
    state.props = nil
    state.stacked = {
        is = false,
        connectionPoint = nil,
    }
    state.tile = nil
    state.rotation = 0
end

return PlaceController