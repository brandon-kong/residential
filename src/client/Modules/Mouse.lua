local UserInputService = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Camera = workspace.Camera

local function onRenderStep(mouse, step)
	if (mouse.ticks % 2 == 0) then
		mouse.currentPosition = mouse:GetPosition()
	else
		mouse.previousPosition = mouse:GetPosition()
	end
	mouse.ticks = mouse.ticks % 10 + 1
end

local Mouse = {}
Mouse.__index = Mouse

function Mouse.new()
	local m = {}
	m.filterDescendants = {}
	m.filterType = Enum.RaycastFilterType.Exclude
	m.rayLength = 500
	m.currentPosition = Vector2.new(0, 0)
	m.previousPosition = Vector2.new(0, 0)
	m.ticks = 1
	
	RunService:BindToRenderStep('MeasureMouseMovement', Enum.RenderPriority.Input.Value, function(step)
		onRenderStep(m, step)
	end)

	setmetatable(m, Mouse)
	return m
end

function Mouse:GetViewSize()
	return Camera.ViewportSize
end

function Mouse:GetPosition()
	return UserInputService:GetMouseLocation()
end

function Mouse:GetUnitRay()
	local position = self:GetPosition()
	return Camera:ViewportPointToRay(position.x, position.y)
end

function Mouse:GetOrigin()
	return self:GetUnitRay().Origin
end

function Mouse:GetDelta()
	return (self.currentPosition - self.previousPosition)
end

function Mouse:ScreenPointToRay()
	local parameters = RaycastParams.new()
	parameters.FilterDescendantsInstances = self.filterDescendants
	parameters.FilterType = self.filterType
	return parameters
end

function Mouse:CastRay()
	local parameters = self:ScreenPointToRay()
	return workspace:Raycast(self:GetOrigin(), self:GetUnitRay().Direction * self.rayLength, parameters)
end

function Mouse:GetHit()
	local raycastResult = self:CastRay()
	return raycastResult and raycastResult.Position or nil
end

function Mouse:GetTarget()
	local raycastResult = self:CastRay()
	return raycastResult and raycastResult.Instance or nil
end

function Mouse:GetTargetFilter()
	return self.filterDescendants
end

function Mouse:SetTargetFilter(object)
	local dataType = typeof(object)
	if dataType == 'Instance' then
		self.filterDescendants = {object}
	elseif dataType == 'table' then
		self.filterDescendants = object
	else
		error('object expected an instance or a table of instances, received: '..dataType)
	end
end

function Mouse:GetRayLength()
	return self.rayLength
end

function Mouse:SetRayLength(length)
	local dataType = typeof(length)
	assert(dataType == 'number' and length >= 0, 'length expected a number, received: ' .. dataType)
	self.rayLength = length
end

function Mouse:GetFilterType()
	return self.filterType
end

function Mouse:SetFilterType(filterType)
	local filterTypes = Enum.RaycastFilterType:GetEnumItems()
	if table.find(filterTypes, filterType) then
		self.filterType = filterType
	else
		error('Invalid raycast filter type provided')
	end
end

function Mouse:EnableIcon()
	UserInputService.MouseIconEnabled = true
end

function Mouse:DisableIcon()
	UserInputService.MouseIconEnabled = false
end

return Mouse