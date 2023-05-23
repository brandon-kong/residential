local rs = game:GetService("ReplicatedStorage")
local Component = require(rs.Packages.component)
local Maid = require(rs.Packages.maid)

local knit = require(rs.Packages.knit)

local Items = require(rs.Shared.Modules.Items)

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


function Plot:PlaceObject(object: Instance, props: table, path: string)

    local ObjectService = knit.GetService("ObjectService")

    if (not ObjectService) then
        warn("ObjectService not found")
        return false
    end
    
    local tile = props.tile
    local tileNum = tonumber(tile.Name)

    if (not tileNum) then
        return false
    end

    local objectFromPath = ObjectService:TreePathToItemObject(path)

    if (not objectFromPath) then
        warn('Object not found in index')
        return false
    end

    -- if the tile is already occupied, check if stacking is allowed

    if (self.tiles[tileNum]) then
        local stacking = objectFromPath.special.stacking

        if (stacking and stacking.allowed) then
            local allowedModels = stacking.allowedModels
            local max = stacking.max


            for _, stackedObject in pairs(self.tiles[tileNum]) do

                if (table.find(allowedModels, stackedObject.Name)) then
                    if (max and stackedObject.Stacked) then
                        return false
                    end
                else
                    return false
                end

                -- check if the connection points match


                local b = object:Clone()

                local yFactor = b.PrimaryPart.Size.Y/2 + tile.Size.Y/2

                if (b.PrimaryPart.Size.Y < 1) then
                    yFactor = b.PrimaryPart.Size.Y * 1.5
                end

                local objCFrame = (tile.CFrame + Vector3.new(0, yFactor, 0)) * CFrame.Angles(0, math.rad(props.rotation*90), 0)
                b:SetPrimaryPartCFrame(objCFrame)

                b.PrimaryPart.Anchored = true

                local stackedObjConnectionPoints = self.tiles[tileNum][1].Instance.PrimaryPart:FindFirstChild(path)
                local objectConnectionPoints = b.PrimaryPart:FindFirstChild(stackedObject.Name)

                if (not stackedObjConnectionPoints or not objectConnectionPoints) then
                    return false
                end

                local lenStack = #stackedObjConnectionPoints:GetChildren()
                local lenObj = #objectConnectionPoints:GetChildren()

                if (lenStack ~= lenObj) then
                    print(lenStack, lenObj)
                    return false
                end
                
                local connectionPoints = {}

                for i, v in ipairs(stackedObjConnectionPoints:GetChildren()) do
                    for i2, v2 in ipairs(objectConnectionPoints:GetChildren()) do
                        print((v.Position - v2.Position).Magnitude)
                        if ((v.Position - v2.Position).Magnitude < 0.25) then
                            table.insert(connectionPoints, v)
                        end
                    end
                end

                if (#connectionPoints ~= lenStack) then
                    return false
                end

            end

            -- if the object is allowed to be stacked, add it to the stack
        else
            return false
        end

        
    end

    local clonedObj = object:Clone()

    self.tiles[tileNum] = self.tiles[tileNum] or {}
    table.insert(self.tiles[tileNum], {Name = path, Instance = clonedObj, Stacked = self.tiles[tileNum][1]})

    

    clonedObj.Parent = self.Instance.Models

    props.rotation = props.rotation or 0

    local yFactor = clonedObj.PrimaryPart.Size.Y/2 + tile.Size.Y/2

    if (clonedObj.PrimaryPart.Size.Y < 1) then
        yFactor = clonedObj.PrimaryPart.Size.Y * 1.5
    end

    local objCFrame = (tile.CFrame + Vector3.new(0, yFactor , 0)) * CFrame.Angles(0, math.rad(props.rotation*90), 0)
    clonedObj:SetPrimaryPartCFrame(objCFrame)

    clonedObj.PrimaryPart.Anchored = true

    return true
end

return Plot