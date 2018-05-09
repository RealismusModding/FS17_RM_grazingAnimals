----------------------------------------------------------------------------------------------------
-- GRAZING AREA
----------------------------------------------------------------------------------------------------
-- Purpose: To limit the area for the getDensity funcs
-- Author:  reallogger
--
-- Copyright (c) Realismus Modding, 2018
----------------------------------------------------------------------------------------------------

grazingArea = {}
local grazingArea_mt = Class(grazingArea)

function onCreate(self, id)
    g_currentMission:addNonUpdateable(grazingArea:new(id))
end

function grazingArea.onCreate(id)
    g_currentMission:addNonUpdateable(grazingArea:new(id))
end

function grazingArea:new(id)

    local self = {}
    setmetatable(self, grazingArea_mt)

    grazingArea.areas = {}

    for i = 1, getNumOfChildren(id) do
        local areaId = getChildAt(id,i-1)        
        local animalType = Utils.getNoNil(getName(areaId), "default")

        if areaName ~= "default" then
            local corner1Id = getChildAt(areaId,0)
            local corner2Id = getChildAt(corner1Id,0)
            local corner3Id = getChildAt(corner1Id,1)
            
            grazingArea.areas[animalType] = {}

            local x0, _, z0 = getWorldTranslation(corner2Id)
            local x1, _ ,z1 = getWorldTranslation(corner1Id)
            local x2, _ ,z2 = getWorldTranslation(corner3Id)

            grazingArea.areas[animalType].x,
            grazingArea.areas[animalType].z,
            grazingArea.areas[animalType].widthX,
            grazingArea.areas[animalType].widthZ,
            grazingArea.areas[animalType].heightX,
            grazingArea.areas[animalType].heightZ = Utils.getXZWidthAndHeight(nil, x0,z0, x1,z1, x2,z2)
        end
    end

    return self
end

function grazingArea:delete()
end

g_onCreateUtil.addOnCreateFunction("grazingArea", grazingArea.onCreate)