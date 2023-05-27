local rs = game:GetService("ReplicatedStorage")
local knit = require(rs.Packages.knit)

local Plot = require(script.Parent.Parent.Components.Plot)
local CollectionService = game:GetService("CollectionService")

local PlotService = knit.CreateService {
    Name = "PlotService",
    Client = {},
}

function PlotService:KnitInit()
    self._plots = {}
    self._plotCount = 0

    print("PlotService initialized")
end

function PlotService:KnitStart()
    for _, plot in ipairs(workspace.Plots:GetChildren()) do
         CollectionService:AddTag(plot, "Plot")

         Plot:WaitForInstance(plot):andThen(function(plotInstance)
            self._plots[#self._plots + 1] = plotInstance
            self._plotCount = self._plotCount + 1
         end)
    end

    print("PlotService started")
end

function PlotService:AssignPlotToPlayer(player)
    local index = 1
    local plot = self._plots[index]

    while (plot) do
        if (not plot:isOwned()) then
            plot:setOwner(player)
            return plot
        end

        index = index + 1
        plot = self._plots[index]
    end

    return nil
end

function PlotService:GetPlot(player)
    for _, plot in ipairs(self._plots) do
        if (plot:isOwnedBy(player)) then
            return plot
        end
    end

    return nil
end

function PlotService.Client:GetPlot(player)
    return self.Server:GetPlot(player)
end

function PlotService.Client:GetPlotInstance(player)
    local plot = self.Server:GetPlot(player)
    if (not plot) then return nil end

    return plot.Instance
end


function PlotService:ConfirmPlacement(player, path, props)
    local plot = self:GetPlot(player)
    if (not plot) then return end

    local ObjectService = knit.GetService("ObjectService")

    local gottenObj = ObjectService:GetObjectFromPath(path)

    if (not gottenObj) then
        warn("Object not found")
        return
    end

    local clonedObj = gottenObj:Clone()

    local object = plot:PlaceObject(clonedObj, props, path)
    if (not object) then clonedObj:Destroy() return end

    return object
end


function PlotService.Client:ConfirmPlacement(player, path, props)
    return self.Server:ConfirmPlacement(player, path, props)
end


-- just an alias
function PlotService.Client:PlaceObject(player, path, props)
    return self:ConfirmPlacement(player, path, props)
end


function PlotService:MoveObject(player, object, props)
    if (not object) then return end

    local id = object:GetAttribute("Id")
    local plot = self:GetPlot(player)
    local path = object:GetAttribute("Path")

    local b = object:Clone()

    if (not path) then return end
    if (not plot) then return end
    if (not id) then return end

    local movedObj = plot:MoveObject(object, props, path)

    if (not movedObj) then
        local currentObj = plot:GetObjectFromId(id)

        if (not currentObj) then return end

        -- return the object to its original position
        local newProps = {
            Rotation = currentObj.Rotation,
            Tile = currentObj.Tile,
            Stacked = currentObj.Stacked,
            Id = currentObj.Id,
        }

        plot:PlaceObject(b, newProps, path)
    else
        b:Destroy()
    end
    return movedObj
end


function PlotService.Client:MoveObject(player, object, props)
    return self.Server:MoveObject(player, object, props)
end


function PlotService:GetRotation(player, object)
    if (not object) then return end

    local id = object:GetAttribute("Id")
    local plot = self:GetPlot(player)
    local path = object:GetAttribute("Path")

    if (not path) then return end
    if (not plot) then return end
    if (not id) then return end

    local currentObj = plot:GetObjectFromId(id)

    if (not currentObj) then return end

    return currentObj.Rotation
end

function PlotService.Client:GetRotation(player, object)
    return self.Server:GetRotation(player, object)
end

return PlotService