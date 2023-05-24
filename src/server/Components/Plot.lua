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
    self.objects = {}
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
        return nil
    end

    local function getTileInstance(tile)
        if (not tile) then
            return nil
        end
        return tile
    end

    local function getDictionaryLength(dictionary)
        local count = 0
        for _, _ in pairs(dictionary) do
            count = count + 1
        end
        return count
    end

    local tile = props.Tile
    local rotation = props.Rotation
    local stacked = props.Stacked

    local id = os.time()

    if (stacked == nil) then
        stacked = {
            is = false,
            id = nil,
            obj = nil,
        }
    end

    local tileObject = self.tiles[tile]

    local objCFrame = CFrame.new()
    local objOrientation, objSize = object:GetBoundingBox()

    local y = object.PrimaryPart.Size.Y

    local stackedItems = {}

    if (not stacked.is) then
        if (tileObject) then
            -- check if the tile is already occupied
            return nil
        else
        tileObject = {object}
        self.tiles[tile] = tileObject
        objCFrame = (getTileInstance(tile).CFrame + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
        end
    else
        -- handle stacked objects

            -- check if the object is already stacked
            if (stacked.id == object:GetAttribute("Id")) then
                return nil
            end

            local stackedObject = self.objects[stacked.obj]

            if (not stackedObject) then
                return nil
            end

            local objectToStackIndexEntry = ObjectService:GetIndexEntryFromPath(stackedObject.Path)

            if (not objectToStackIndexEntry) then return nil end
            if (not objectToStackIndexEntry.special.stacking) then return nil end

            local stacking = objectToStackIndexEntry.special.stacking

            if (not stacking.allowed) then return nil end
            if (not stacking.allowedModels[path]) then return nil end

            -- get the length of stacked items with the same class
            local a = 0
            for _, b in pairs(stackedObject.StackedItems) do
                if (b.Path == path) then
                    a = a + 1
                end
            end

            local max = stacking.allowedModels[path].max or 1
            if (a >= max) then return nil end

            -- check if connection points are taken
            for _, connectionPoint in ipairs(stackedObject.StackedItems) do
                if (connectionPoint.ConnectionPoint == stacked.connectionPoint) then
                    return nil
                end
            end

            local connectionPoint  = stacked.connectionPoint
            local connectionPointCFrame = connectionPoint.CFrame

            objCFrame = (connectionPointCFrame * CFrame.Angles(0, math.rad(rotation), 0))

            self.objects[stacked.obj].StackedItems[id] = {
                Path = path,
                Rotation = rotation,
                Tile = tile,
                Stacked = stacked,
                Instance = object,
                ConnectionPoint = tonumber(connectionPoint.Name),
                StackedItems = {}
            }
    end

    self.objects[object] = {
        Path = path,
        Rotation = rotation,
        Tile = tile,
        Stacked = stacked,
        Instance = object,
        StackedItems = {}
    }

    object.Parent = self.Instance.Models
    object:SetAttribute("Id", id)
    object:PivotTo(objCFrame)

    return object
end

return Plot