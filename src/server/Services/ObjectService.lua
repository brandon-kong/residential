local rs = game:GetService("ReplicatedStorage")
local knit = require(rs.Packages.knit)
local CollectionService = game:GetService("CollectionService")

local ObjectService = knit.CreateService {
    Name = "ObjectService",
    Client = {},
}

function ObjectService:KnitInit()
    self._objects = {}

    print("Tagging objects...")

    self:TagAllModelsInTree(rs.Container, "Object")

    for _, object in pairs(CollectionService:GetTagged("Object")) do
        local objectTree = self:SerializeObjectTree(object)
        self._objects[objectTree] = object
    end

    print("Welding objects...")

    for _, object in pairs(CollectionService:GetTagged("Object")) do
        self:WeldObjectToPrimaryPart(object)
    end

    print("ObjectService initialized")
end

function ObjectService:SerializeObjectTree(object: Instance)
    -- Creates a formatted string that represents the object tree
    -- ex: Residential/House/StarterHouse

    local objectTree = object.Name

    if (object.Parent.Name == 'Container') then
        return objectTree
    end

    if (object.Parent) then
        objectTree = self:SerializeObjectTree(object.Parent) .. "/" .. objectTree
    end

    return objectTree
end

function ObjectService:TagAllModelsInTree(object: Instance, tag: string)
    -- Tags all models in the object tree with the Object tag
    -- ex: Residential/House/StarterHouse

    if (object:IsA("Model")) then
        CollectionService:AddTag(object, "Object")
        return
    end

    for _, child in pairs(object:GetChildren()) do
        self:TagAllModelsInTree(child)
    end
end

function ObjectService:GetObjectFromTreePath(treePath: string)
    return self._objects[treePath]
end

function ObjectService.Client:GetObjectFromTreePath(player: Instance, treePath: string)
    return self.Server:GetObjectFromTreePath(treePath)
end

function ObjectService:WeldObjectToPrimaryPart(object: Instance)
    -- Welds all parts in the object to the primary part
    -- ex: Residential/House/StarterHouse

    local primaryPart = object.PrimaryPart

    if (not primaryPart) then
        warn("Object does not have a primary part")
        return
    end

    for _, part in pairs(object:GetChildren()) do
        if (part:IsA("BasePart") and part ~= primaryPart) then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = primaryPart
            weld.Part1 = part
            weld.Parent = part
        end
    end
end

function ObjectService:KnitStart()
    print("ObjectService started")
end

return ObjectService