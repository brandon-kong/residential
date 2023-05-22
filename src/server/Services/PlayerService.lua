local rs = game:GetService("ReplicatedStorage")
local knit = require(rs.Packages.knit)

local PlayerService = knit.CreateService {
    Name = "PlayerService",
    Client = {},
}

function PlayerService:KnitInit()
    print("PlayerService initialized")
end

function PlayerService:KnitStart()

    local PlotService = knit.GetService("PlotService")
    game.Players.PlayerAdded:Connect(function(player)
        PlotService:AssignPlotToPlayer(player)
    end)

    print("PlayerService started")
end



return PlayerService