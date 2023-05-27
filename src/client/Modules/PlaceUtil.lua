local rs = game:GetService("ReplicatedStorage")
local container = rs.Container
local Items = require(rs.Shared.Modules.Items)

local PhysicsService = game:GetService("PhysicsService")

local PlaceUtil = {}

function PlaceUtil.GetNearestTileFromMousePosition(mouse, tiles)
    local _closestTile = nil
    for i, v in pairs(tiles) do
        if _closestTile == nil then
            _closestTile = v
        else
            local ray = mouse:CastRay()

            if _closestTile and ray and ray.Position and (ray.Position-v.Position).magnitude < (_closestTile.Position-ray.Position).magnitude then
                _closestTile = v
            end
        end
    end

    return _closestTile
end

function PlaceUtil.GetConnectionPoints(model: Instance, pathToOtherConnection: string)
    local connectionPoints = {}

    local connectionPoint = model.PrimaryPart['ConnectionPoints']:FindFirstChild(pathToOtherConnection)

    if (not connectionPoint) then
        return connectionPoints
    end

    for i, v in ipairs(connectionPoint:GetChildren()) do
        table.insert(connectionPoints, v)
    end

    return connectionPoints
end

function PlaceUtil.GetModelFromPart(part: Instance)
    if (not part) then
        return nil
    end

    if (part:IsA("Model")) then
        return part
    end

    if (part:IsA("BasePart")) then
        return part:FindFirstAncestorWhichIsA("Model")
    end

    return nil
end

function PlaceUtil.ModelIsInPlot(model: Model, plot: Instance)
    local plotModels = plot:FindFirstChild("Models")
    if (not plotModels) then
        return false
    end

    return model:IsDescendantOf(plotModels)
end

function PlaceUtil.PartIsInTiles(part: Instance, plot: Instance)

    if (not part) then
        return false
    end

    if (not plot) then
        return false
    end

    local tiles = plot:FindFirstChild("Tiles")
    if (not tiles) then
        return false
    end

    return part:IsDescendantOf(tiles)
end


function PlaceUtil.GetModelFromPath(path: string)
    local a = path:split('/')
    local model = container:FindFirstChild(a[1])

    if (not model) then
        return nil
    end

    for i = 2, #a do
        model = model:FindFirstChild(a[i])
        if (not model) then
            return nil
        end
    end

    return model
end

function PlaceUtil.CreateObject(path: string)
    local modelFromPath = PlaceUtil.GetModelFromPath(path)

    if (not modelFromPath) then
        return nil
    end

    local model = modelFromPath:Clone()
    return model
end


function PlaceUtil.SetTransparency(model: Model, transparency: number)
    for _, part in ipairs(model:GetDescendants()) do
        if (part:IsA("BasePart")) then
            if (part:IsDescendantOf(model.PrimaryPart)) then
                continue
            end
            part.Transparency = transparency
        end
    end

    if (model.PrimaryPart) then
        model.PrimaryPart.Transparency = 1
    end
end


function PlaceUtil.SetCollisionGroup(model: Model, collisionGroup: string)
    for _, part in ipairs(model:GetDescendants()) do
        if (part:IsA("BasePart")) then
            part.CollisionGroup = collisionGroup
        end
    end
end


function PlaceUtil.GetIndexEntryFromPath(path: string)
    local a = path:split('/')
    local indexEntry = Items

    for i = 1, #a do
        indexEntry = indexEntry[a[i]]
        if (not indexEntry) then
            return nil
        end
    end

    return indexEntry
end


function PlaceUtil.GetConnectionPointsClosestToMouse(mouse, model: Model, pathToOtherConnection: string)
    local connectionPoints = PlaceUtil.GetConnectionPoints(model, pathToOtherConnection)

    local closestConnectionPoint = nil
    local closestDistance = nil

    for i, connectionPoint in ipairs(connectionPoints) do
        local hit = mouse:CastRay()
        if (not hit) then
            return nil
        end
        
        local distance = (hit.Position - connectionPoint.Position).magnitude

        if (not closestDistance or distance < closestDistance) then
            closestConnectionPoint = connectionPoint
            closestDistance = distance
        end
    end

    return closestConnectionPoint
end

function PlaceUtil.RotationIsValid(path1, path2, object1, object2, connectionPoint)
    --1 is the model that is already placed
    --2 is the model that is being placed

    local indexEntry1 = PlaceUtil.GetIndexEntryFromPath(path1)
    local indexEntry2 = PlaceUtil.GetIndexEntryFromPath(path2)

    if (not indexEntry1) then
        return nil
    end

    if (not indexEntry2) then
        return nil
    end

    local allowedRotations = {}

    local b = object2:Clone()

    local allowedModel = indexEntry1.special.stacking.allowedModels[path2]

    if (not allowedModel) then
        return nil
    end

    local allowedSnapping1 = object1.PrimaryPart:FindFirstChild("AllowedSnapping")
    local allowedSnapping2 = b.PrimaryPart:FindFirstChild("AllowedSnapping")

    if (not allowedSnapping1) then
        return nil
    end

    if (not allowedSnapping2) then
        return nil
    end

    local snappingFolder1 = allowedSnapping1:FindFirstChild(path2)
    local snappingFolder2 = allowedSnapping2:FindFirstChild(path1)

    if (not snappingFolder1) then
        return nil
    end

    if (not snappingFolder2) then
        return nil
    end

    if (not allowedModel.orientationStrict) then
        return {0, 90, 180, 270}
    end

    local min = math.min(#snappingFolder1:GetChildren(), #snappingFolder2:GetChildren())

    for i = 0, 3 do
        local rotation = i * 90

        b:PivotTo(CFrame.new(connectionPoint.CFrame.Position) * CFrame.Angles(0, math.rad(rotation), 0))

        local c = 0

        for _, x in ipairs(snappingFolder2:GetChildren()) do
            for a, v in ipairs(snappingFolder1:GetChildren()) do
                if ((v.Position - x.Position).magnitude < 0.1) then
                    c += 1
                end
            end
        end

        if (c >= min) then
            
            table.insert(allowedRotations, rotation)
        end
    end

    return allowedRotations
end

return PlaceUtil