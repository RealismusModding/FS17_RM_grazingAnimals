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
            grazingArea.areas[animalType].corner1X, _, grazingArea.areas[animalType].corner1Z = getWorldTranslation(corner1Id)
            grazingArea.areas[animalType].dX1, _ , _ = getTranslation(corner2Id)
            _, _ , grazingArea.areas[animalType].dZ2 = getTranslation(corner3Id)
        end
    end

    return self
end

function grazingArea:delete()
end

g_onCreateUtil.addOnCreateFunction("grazingArea", grazingArea.onCreate)