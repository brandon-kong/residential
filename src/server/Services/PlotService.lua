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


function PlotService:AssignPlotToPlayer(player: Player)
    local plot = self._plots[math.random(1, self._plotCount)]

    while (plot:isOwned()) do
        plot = self._plots[math.random(1, self._plotCount)]
    end

    plot:setOwner(player)
end


function PlotService:GetPlayersPlot(player: Player)
    for _, plot in ipairs(self._plots) do
        if (plot:isOwnedBy(player)) then
            return plot.Instance
        end
    end
    return nil
end

function PlotService:GetPlayersPlotComponent(player: Player)
    for _, plot in ipairs(self._plots) do
        if (plot:isOwnedBy(player)) then
            return plot
        end
    end
    return nil
end

function PlotService.Client:GetPlayersPlot(player: Player)
    return self.Server:GetPlayersPlot(player)
end

function PlotService:PlaceObject(player: Player, path: string, configs: table)
    local plot = self:GetPlayersPlotComponent(player)

    if (not plot) then
        warn("Player does not have a plot")
        return
    end

    if (not configs.tile) then
        warn("No tile provided")
        return
    end

    local ObjectService = knit.GetService("ObjectService")
    local foundObj = ObjectService:GetObjectFromTreePath(path)

    if (not foundObj) then
        warn("Object not found")
        return
    end

    local clonedObj = foundObj:Clone()

    plot:PlaceObject(clonedObj, configs)
end

function PlotService.Client:PlaceObject(player: Player, path: string, configs: table)
    self.Server:PlaceObject(player, path, configs)
end

return PlotService