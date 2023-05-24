local rs = game:GetService("ReplicatedStorage")
local knit = require(rs.Packages.knit)
local CollectionService = game:GetService("CollectionService")
local container = rs.Container

local Items = require(rs.Shared.Modules.Items)

local ObjectService = knit.CreateService {
    Name = "ObjectService",
    Client = {},
}


function ObjectService:KnitInit()

    self.objects = {}

    local function initCallback(action, callback)
        print('Initializing callback for action: ' .. action)
        callback()
        print('Callback initialized for action: ' .. action)
    end

    initCallback('Welding', function()
        for _, model in ipairs(container:GetDescendants()) do
            if (model:IsA("Model")) then
                self:WeldModelToPrimaryPart(model)
            end
        end
    end)

    initCallback('Paths', function()
        self:InitializePathsInContainer()
    end)

    print("ObjectService initialized")
end


function ObjectService:KnitStart()
    print("ObjectService started")
end


function ObjectService:WeldModelToPrimaryPart(model: Model)
    local primaryPart = model.PrimaryPart
    if (not primaryPart) then return end

    for _, part in ipairs(model:GetDescendants()) do
        if (part:IsA("BasePart")) then
            part.Anchored = false
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = primaryPart
            weld.Part1 = part
            weld.Parent = part
        end
    end

    primaryPart.Anchored = true
end


function ObjectService:GeneratePath(object: Instance)
    --[[
        Recursive function that generates a path to an object in the container.
    ]]

    if (object == container) then
        return
    end

    if (not object) then
        return
    end

    local path = object.Name

    if (object.Parent == container) then
        return path
    end

    return self:GeneratePath(object.Parent) .. '/' .. path
end


function ObjectService:InitializePathsInContainer()
    for _, object in ipairs(container:GetDescendants()) do
        if (object:IsA("Model") and object.PrimaryPart) then
            local path = self:GeneratePath(object)
            if (not self:ItemIsInIndex(path)) then
                warn('Item not in index: ' .. path)
                continue
            end

            self.objects[path] = object
            object:SetAttribute("Path", path)
        end
    end
end


function ObjectService:ItemIsInIndex(path: string)
    local a = path:split('/')
    local b = Items

    for _, v in ipairs(a) do
        if (not b[v]) then
            return false
        end

        b = b[v]
    end

    return true
end


function ObjectService:GetIndexEntryFromPath(path: string)
    local a = path:split('/')
    local b = Items

    for _, v in ipairs(a) do
        if (not b[v]) then
            return nil
        end

        b = b[v]
    end

    return b
end


function ObjectService:GetObjectFromPath(path: string)
    return self.objects[path]
end

return ObjectService