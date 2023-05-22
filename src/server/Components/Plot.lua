local Component = require(game:GetService("ReplicatedStorage").Packages.component)
local Maid = require(game:GetService("ReplicatedStorage").Packages.maid)

local Plot = Component.new({
    Tag = 'Plot',
    Ancestors = {workspace.Plots},
})

function Plot:Construct()
    self._maid = Maid.new()
    self._owner = nil
    self.tiles = {}
end

function Plot:Stop()
    self._maid:destroy()
end


function Plot:setOwner(player)
    self._owner = player
end


function Plot:getOwner()
    return self._owner
end


function Plot:isOwned()
    return self._owner ~= nil
end


function Plot:isOwnedBy(player)
    return self._owner == player
end


function Plot:PlaceObject(object: Instance, configs: table)
    local tile = configs.tile
    local tileNum = tonumber(tile.Name)

    if (not tileNum) then
        return
    end

    if (self.tiles[tileNum]) then
        return
    end

    self.tiles[tileNum] = {object}

    object.Parent = self.Instance.Models

    configs.rotation = configs.rotation or 0
    local objCFrame = (tile.CFrame + Vector3.new(0, object.PrimaryPart.Size.Y / 2, 0)) * CFrame.Angles(0, math.rad(configs.rotation*90), 0)
    object:SetPrimaryPartCFrame(objCFrame)
end

return Plot