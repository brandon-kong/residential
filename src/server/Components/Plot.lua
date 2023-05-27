local rs = game:GetService("ReplicatedStorage")
local Component = require(rs.Packages.component)
local Maid = require(rs.Packages.maid)

local knit = require(rs.Packages.knit)

local Items = require(rs.Shared.Modules.Items)

local Plot = Component.new({
    Tag = 'Plot',
    Ancestors = {workspace.Plots},
})

--[[

    Problems:
    Moving stacked item to tile destroys the stacked item
]]

--[[

    Constraints are added to the object that is stacking on top of the other object
]]

function getDictionaryLength(dict)
    local a = 0
    for _, _ in pairs(dict) do
        a = a + 1
    end
    return a
end

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

    local tile = props.Tile
    local rotation = props.Rotation
    local stacked = props.Stacked

    local id = props.id or self:GetNewUniqueId()

    if (stacked == nil) then
        stacked = {
            is = false,
            id = nil,
            obj = nil,
        }
    end

    local tileObject = self.tiles[tile]

    local objCFrame = CFrame.new()

    local y = object.PrimaryPart.Size.Y

    if (not stacked.is) then
        if (tileObject) then
            -- check if the tile is already occupied
            return nil
        else
        self.tiles[tile] = {}
        tileObject = {object}
        table.insert(self.tiles[tile], object)
        self.tiles[tile] = tileObject
        objCFrame = (getTileInstance(tile).CFrame + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(rotation), 0)
        end
    else
        -- handle stacked objects

            -- check if the object is already stacked
            if (stacked.id == object:GetAttribute("Id")) then
                return nil
            end

            local stackedObject = self.objects[stacked.id]

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

            -- We can stack the object now

            local connectionPoint  = stacked.connectionPoint
            local connectionPointCFrame = connectionPoint.CFrame

            objCFrame = CFrame.new(connectionPointCFrame.Position) * CFrame.Angles(0, math.rad(rotation), 0)

            self.objects[stacked.id].StackedItems[id] = {
                Path = path,
                Rotation = rotation,
                Tile = tile,
                Stacked = stacked,
                Instance = object,
                ConnectionPoint = tonumber(connectionPoint.Name),
                StackedItems = {}
            }

            tile = stackedObject.Tile
    end

    self.objects[id] = {
        Path = path,
        Rotation = rotation,
        Tile = tile,
        Stacked = stacked,
        Instance = object,
        Id = id,
        StackedItems = {}
    }

    object.Parent = self.Instance.Models
    object:SetAttribute("Id", id)
    object:SetAttribute("Path", path)
    object:PivotTo(objCFrame)

    if (stacked.is) then
        local weld = Instance.new("WeldConstraint")
        weld.Name = id
        weld.Part0 = object.PrimaryPart
        weld.Part1 = stacked.connectionPoint
        weld.Parent = object.PrimaryPart["StackedConstraints"]

        object.PrimaryPart.Anchored = false
    end

    return object
end


function Plot:RemoveObject(object: Instance)
    if (not object) then return end
    if (not self.objects[object]) then return end

    for _, stackedItem in ipairs(self.objects[object].StackedItems) do
        self:RemoveObject(stackedItem.Instance)
    end

    self.objects[object] = nil
    object:Destroy()
end


function Plot:MoveObject(object: Instance, props: table, path: string)
    if (not object) then return end
    if (not path) then return end

    -- delete the object from the plot

    local id = object:GetAttribute("Id")
    if (not id) then return end

    props.id = id
    props.moving = true

    local b = object:Clone()

    b:SetAttribute("Id", id)

    --self:RemoveObject(object)
    object:Destroy()

    -- place the object again
    self:MoveObjectHandler(b, props, path)
end


function Plot:MoveObjectHandler(object: Instance, props: table, path: string)
    
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

    local id = props.id
    local tile = props.Tile
    local rotation = props.Rotation
    local stacked = props.Stacked

    local isStacked = stacked.is

    local oldObject = self.objects[id]

    if (not oldObject) then return nil end

    -- delete the connections from the object
    for _, v in ipairs(object.PrimaryPart.StackedConstraints:GetChildren()) do
        v:Destroy()
    end

    if (not id) then return end

    local objCFrame = CFrame.new()
    local y = object.PrimaryPart.Size.Y

    if (oldObject.Stacked) then
        local oldStacked = oldObject.Stacked
        local oldStackedObject = self.objects[oldStacked.id]

        if (oldStackedObject) then
            oldStackedObject.StackedItems[id] = nil
        end

        if (not oldStacked.is) then
            -- get the tile that the object is stacked on
            local btile = oldObject.Tile
            self.tiles[btile] = nil
        end
    end

    local tileObject = self.tiles[tile]

    if (not isStacked) then
        if (tileObject) then
            -- check if the tile is already occupied
            return nil
        else
            tileObject = tileObject or {}
            self.tiles[tile] = {}
            table.insert(self.tiles[tile], object)
            objCFrame = (getTileInstance(tile).CFrame + Vector3.new(0, y, 0)) * CFrame.Angles(0, math.rad(rotation), 0)

            object.PrimaryPart.Anchored = true
        end
    else
        -- check if the object is already stacked
        if (stacked.id == object:GetAttribute("Id")) then
            return nil
        end

        local stackedObject = self.objects[stacked.id]

        if (not stackedObject) then
            return nil
        end

        local objectToStackIndexEntry = ObjectService:GetIndexEntryFromPath(stackedObject.Path)

        if (not objectToStackIndexEntry) then return nil end

        local stacking = objectToStackIndexEntry.special.stacking

        if (not stacking.allowed) then return nil end

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

        -- We can stack the object now

        local connectionPoint  = stacked.connectionPoint
        local connectionPointCFrame = connectionPoint.CFrame

        objCFrame = (CFrame.new(connectionPointCFrame.Position) * CFrame.Angles(0, math.rad(rotation), 0))

        self.objects[stacked.id].StackedItems[id] = {
            Path = path,
            Rotation = rotation,
            Tile = tile,
            Stacked = stacked,
            Instance = object,
            ConnectionPoint = tonumber(connectionPoint.Name),
            StackedItems = {}
        }

        tile = stackedObject.Tile
    end

    self.objects[id] = {
        Path = path,
        Rotation = rotation,
        Tile = tile,
        Stacked = stacked,
        Instance = object,
        Id = id,
        StackedItems = oldObject.StackedItems
    }

    object.Parent = self.Instance.Models
    object:SetAttribute("Id", id)
    object:SetAttribute("Path", path)
    object:PivotTo(objCFrame)

    if (stacked.is) then
        local weld = Instance.new("WeldConstraint")
        weld.Name = id
        weld.Part0 = object.PrimaryPart
        weld.Part1 = stacked.connectionPoint
        weld.Parent = object.PrimaryPart["StackedConstraints"]

        object.PrimaryPart.Anchored = false
    else
        object.PrimaryPart.Anchored = true
    end

    -- weld previous stacked items to the new object

    if (getDictionaryLength(self.objects[id].StackedItems) > 0) then
        local connectionPointsFolder = object.PrimaryPart["ConnectionPoints"]
        if (not connectionPointsFolder) then return end

        for i, v in pairs(self.objects[id].StackedItems) do
            local folderOfPath = connectionPointsFolder:FindFirstChild(tostring(v.Path))
            if (not folderOfPath) then continue end

            local connectionPointInstance = folderOfPath:FindFirstChild(tostring(v.ConnectionPoint))
            if (not connectionPointInstance) then continue end

            for x, z in ipairs(v.Instance.PrimaryPart.StackedConstraints:GetChildren()) do
                z:Destroy()
            end

            v.Instance:PivotTo(CFrame.new(connectionPointInstance.CFrame.Position) * CFrame.Angles(0, math.rad(v.Rotation), 0))
            self:WeldObjectToConnectionPoint(v.Instance, connectionPointInstance)
            --v.Instance.PrimaryPart.Anchored = false
            --self:RecursivelyWeldStack(v.Instance)
        end
    end

    -- TODO: recursively update the stacked items' tile
    self:UpdateItemInStack(object, {
        Tile = tile
    })
end


function Plot:UpdateItemInStack(object, table)
    if (not object) then return end
    if (not table) then return end

    local id = object:GetAttribute("Id")

    if (not id) then return end

    if (not self.objects[id]) then return end

    for key, value in pairs(table) do
        self.objects[id][key] = value
    end

    for _, stackedItem in pairs(self.objects[id].StackedItems) do
        self:UpdateItemInStack(stackedItem.Instance, table)
    end
end

function Plot:GetStackedObjectsOnInstance(object: Instance)
    if (not object) then return {} end

    local stackedItems = {}

    for id, stackedItem in pairs(self.objects[object].StackedItems) do
        stackedItems[id] = stackedItem.Instance
    end

    return stackedItems
end


function Plot:WeldObjectToConnectionPoint(object: Instance, connectionPoint: Instance)
    if (not object) then return end
    if (not connectionPoint) then return end

    local weld = Instance.new("WeldConstraint")
    weld.Name = object:GetAttribute("Id")
    weld.Part0 = object.PrimaryPart
    weld.Part1 = connectionPoint
    weld.Parent = object.PrimaryPart["StackedConstraints"]
end


function Plot:RecursivelyWeldStack(object)
    if (not object) then return end

    local id = object:GetAttribute("Id")

    if (not id) then return end

    for objId, stackedItem in pairs(self.objects[id].StackedItems) do
        local connectionPointsFolder = object.PrimaryPart["ConnectionPoints"]
        if (not connectionPointsFolder) then continue end

        local folderOfPath = connectionPointsFolder:FindFirstChild(tostring(stackedItem.Path))
        if (not folderOfPath) then continue end

        local connectionPointInstance = folderOfPath:FindFirstChild(tostring(stackedItem.ConnectionPoint))
        if (not connectionPointInstance) then continue end

        self:WeldObjectToConnectionPoint(stackedItem.Instance, connectionPointInstance)
        stackedItem.Instance:PivotTo(CFrame.new(connectionPointInstance.CFrame.Position) * CFrame.Angles(0, math.rad(stackedItem.Rotation), 0))
        self:RecursivelyWeldStack(stackedItem.Instance)
    end
end


function Plot:RemoveConnectionsToObject(object: Instance)
    if (not object) then return end

    local id = object:GetAttribute("Id")

    if (not id) then return end

    for _, stackedItem in ipairs(self.objects[id].StackedItems) do
        local weld = stackedItem.Instance.PrimaryPart["StackedConstraints"]:FindFirstChild(id)
        if (weld) then
            weld:Destroy()
        end
    end
end

function Plot:GetModelThatObjectIsStackedOn(object: Instance)
    if (not object) then return nil end

    local id = object:GetAttribute("Id")

    if (not id) then return nil end

    local stackedItem = self.objects[id].Stacked

    if (not stackedItem.is) then return nil end

    return stackedItem.obj
end


function Plot:GetNewUniqueId()
    local id = os.time()
    while (self.objects[id]) do
        id = id + 1
    end

    return id
end


function Plot:GetObjectFromId(id: number)
    if (not id) then return nil end

    return self.objects[id]
end


function Plot:GetStackFromObject(object: Instance)
    if (not object) then return nil end

    local id = object:GetAttribute("Id")

    if (not id) then return nil end

    local a = {}

    while (object and self.objects[id]) do
        local object = self.objects[id].Instance
        table.insert(a, object)
        object = self.objects[id].Stacked.obj
        id = object:GetAttribute("Id")
    end

    return self.objects[id].Stacked
end

return Plot