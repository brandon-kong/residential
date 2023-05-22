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

return PlaceUtil