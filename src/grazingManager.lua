----------------------------------------------------------------------------------------------------
-- GRAZING ANIMALS
----------------------------------------------------------------------------------------------------
-- Purpose: To automatically fill grass throughs when grass is available
-- Author:  reallogger
--
-- Copyright (c) Realismus Modding, 2018
----------------------------------------------------------------------------------------------------

grazingAnimals = {}

grazingAnimals.MASK_FIRST_CHANNEL = 0
grazingAnimals.MASK_NUM_CHANNELS = 1

-- add or remove animal types in the following tables
grazingAnimals.animalTypes = {"cow", "sheep"}
grazingAnimals.foliageTypes = {"grazingCows", "grazingSheep"}
grazingAnimals.consumedGrass = {}

grazingAnimals.GRASS_MULTIPLIER = 0.25 -- 0.25 gives approximately the same amount as if you would mow the grass area.

local modItem = ModsUtil.findModItemByModName(g_currentModName)
grazingAnimals.modDir = g_currentModDirectory

function grazingAnimals:loadMap()
    FSCareerMissionInfo.saveToXML = Utils.appendedFunction(FSCareerMissionInfo.saveToXML, grazingAnimals.saveToXML)

    g_currentMission.environment:addMinuteChangeListener(self)
    g_currentMission.environment:addHourChangeListener(self)

    self.enabled = true

    self.grassThroughCapacity = {}
    self.grassFillLevel = {}
    self.showPastureInfo = {}
    
    for _, animType in pairs(self.animalTypes) do
        self.grassThroughCapacity[animType] = 0
        self.grassFillLevel[animType] = 0
        self.showPastureInfo[animType] = false
    end

    self.grassAvailable = {}
    self.grassVolumeStage2 = {}
    self.grassVolumeStage3 = {}

    self.initMap = false

    self.lastUpdate = math.floor(g_currentMission.environment.dayTime / 1000) -- in seconds
end

function grazingAnimals:load()
end

function grazingAnimals:save()
end

function grazingAnimals:hourChanged()
    if self.preparedMap and g_currentMission:getIsServer() then
        -- update available grass if player has for instance mowed grass in the pasture
        for animI, animType in pairs(self.animalTypes) do
            self.grassVolumeStage2[animType], self.grassVolumeStage3[animType] = self:getGrassAmounts(animI, animType)
        end
    end
end

function grazingAnimals:minuteChanged()
    if self.preparedMap and g_currentMission:getIsServer() then
        for animI, animType in pairs(self.animalTypes) do
            if self.grassVolumeStage2[animType] ~= nil and self.grassVolumeStage3[animType]  ~= nil then
                self:manageGrazing(animI, animType)
            end
        end
    end
end

function grazingAnimals:manageGrazing(animI, animalType)
    local maxState = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].maxHarvestingGrowthState

    if g_currentMission.husbandries[animalType] == nil then
        return
    end

    if self.consumedGrass[animalType] == nil then
        self.consumedGrass[animalType] = 0
    end

    if self.grassVolumeStage3[animalType] > 0 then
        self.grassAvailable[animalType] = self.grassVolumeStage3[animalType] * 2 + self.grassVolumeStage2[animalType]
    elseif self.grassVolumeStage2[animalType] > 0 then
        self.grassAvailable[animalType] = self.grassVolumeStage2[animalType]
    else
        self.grassAvailable[animalType] = 0
    end

    local numAnimals = g_currentMission.husbandries[animalType].totalNumAnimals
    local grassCap = g_currentMission.husbandries[animalType]:getCapacity(FillUtil.FILLTYPE_GRASS_WINDROW)

    -- vanilla has same through capacity for less than 15 animals
    if numAnimals < 15 then
        self.grassThroughCapacity[animalType] = grassCap * numAnimals / 15
    else
        self.grassThroughCapacity[animalType] = grassCap
    end

    local foodPerDay = g_currentMission.husbandries[animalType].animalDesc.foodPerDay
    local weight = FillUtil.fillTypeToFoodGroup[g_currentMission.husbandries[animalType].animalDesc.index][FillUtil.FILLTYPE_GRASS_WINDROW].weight
    local grassPerDay = foodPerDay * numAnimals * weight

    -- finding how much can be filled
    self.grassFillLevel[animalType] = g_currentMission.husbandries[animalType]:getFillLevel(FillUtil.FILLTYPE_GRASS_WINDROW)

    -- make sure hay counts for sheep
    if animalType == "sheep" then
        self.grassFillLevel["sheep"] = self.grassFillLevel["sheep"] + g_currentMission.husbandries[animalType]:getFillLevel(FillUtil.FILLTYPE_DRYGRASS_WINDROW)
    end

    -- leave one day consumption
    local deltaFillLevel = math.min((self.grassThroughCapacity[animalType] - grassPerDay) -  self.grassFillLevel[animalType], self.grassAvailable[animalType] - self.consumedGrass[animalType])
    if numAnimals ~= 0 then
        deltaFillLevel = math.max(deltaFillLevel, 0)
    else
        deltaFillLevel = 0
    end

    if  self.grassAvailable[animalType] == 0 then
        deltaFillLevel = 0
        self.consumedGrass[animalType] = 0
    end

    -- setting new fill level
    if deltaFillLevel ~= 0 then
        g_currentMission.husbandries[animalType]:changeFillLevels(deltaFillLevel, FillUtil.FILLTYPE_GRASS_WINDROW)
    end
    self.consumedGrass[animalType] = self.consumedGrass[animalType] + deltaFillLevel

    -- internal grass storage depleted and have been used to fill the through
    if self.consumedGrass[animalType] > 0 then
        if self.consumedGrass[animalType] >= self.grassVolumeStage3[animalType] and self.grassVolumeStage3[animalType] > 0 then
            self.consumedGrass[animalType] = self.consumedGrass[animalType] - self.grassVolumeStage3[animalType]
            self:reduceGrassAmounts(animI, animalType, maxState + 1)

        elseif self.consumedGrass[animalType] >= self.grassVolumeStage2[animalType] and self.grassVolumeStage3[animalType] == 0 then
            self.consumedGrass[animalType] = self.consumedGrass[animalType] - self.grassVolumeStage2[animalType]
            self:reduceGrassAmounts(animI, animalType, maxState)
        end
    end
end

function grazingAnimals:getGrassAmounts(animI, animalType)
    local maskId = getTerrainDetailByName(g_currentMission.terrainRootNode, self.foliageTypes[animI])

    local fruitId = g_currentMission.fruits[FruitUtil.FRUITTYPE_GRASS].id
    local minState = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].minHarvestingGrowthState -- 2
    local maxState = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].maxHarvestingGrowthState -- 3

    local grassLitersPerSqm = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].literPerSqm
    local size = g_currentMission.terrainSize
    local pixelSize = size / getDensityMapSize(g_currentMission.terrainDetailId)

    self:fallbackGrazingAreas()
    local corners = grazingArea.areas[animalType]

    setDensityMaskParams(maskId, "equals", 1)
    setDensityCompareParams(fruitId, "equals", 4)

    local _, grassArea3 , _ = getDensityMaskedParallelogram(
        fruitId,
        corners.x, corners.z, corners.widthX, corners.widthZ, corners.heightX, corners.heightZ,
        0, g_currentMission.numFruitStateChannels,
        maskId,
        self.MASK_FIRST_CHANNEL,  self.MASK_NUM_CHANNELS)

    setDensityCompareParams(fruitId, "equals", 3)

    local _, grassArea2 , _ = getDensityMaskedParallelogram(
        fruitId,
        corners.x, corners.z, corners.widthX, corners.widthZ, corners.heightX, corners.heightZ,
        0, g_currentMission.numFruitStateChannels,
        maskId,
        self.MASK_FIRST_CHANNEL,  self.MASK_NUM_CHANNELS)

    setDensityMaskParams(maskId, "greater", -1)
    setDensityCompareParams(fruitId, "greater", -1)
   
    return grassArea2 * pixelSize * grassLitersPerSqm * self.GRASS_MULTIPLIER, grassArea3 * pixelSize * grassLitersPerSqm * self.GRASS_MULTIPLIER
end

-- In case erroneous definition of the grazing areas, scan the whole map instead to prevent game crash
function grazingAnimals:fallbackGrazingAreas()
    if grazingArea.areas == nil then
        print(g_i18n:getText("GA_GRAZINGAREAS_FAILED"))
        grazingArea.areas = {}
        local size = getDensityMapSize(g_currentMission.terrainDetailHeightId)
        for _, animType in pairs(grazingAnimals.animalTypes) do
            grazingArea.areas[animType] = {}
            grazingArea.areas[animType].x = -size/2
            grazingArea.areas[animType].z = -size/2
            grazingArea.areas[animType].widthX = size
            grazingArea.areas[animType].widthZ = 0
            grazingArea.areas[animType].heightX = 0
            grazingArea.areas[animType].heightZ = size
        end
    end
end

function grazingAnimals:update(dt)
    -- for some reason the terrainRootNode does not exist until after loadMapFinished is done so making a stupid fix here to run once
    if not self.initMap then
        self.preparedMap = true
        for animI, _ in pairs(self.animalTypes) do  
            local maskId = getTerrainDetailByName(g_currentMission.terrainRootNode, self.foliageTypes[animI])
            if maskId == 0 then
                self.preparedMap = false
            end
        end
        self.initMap = true
    end

    -- only update every five seconds
    local currentSeconds = math.floor(g_currentMission.environment.dayTime / 1000)
    if currentSeconds > self.lastUpdate + 5 and self.preparedMap then
        self.lastUpdate = currentSeconds
        local x, _, z = getWorldTranslation(g_currentMission.player.rootNode)

        -- get initial amounts of grass in the pasture
        for animI, animType in pairs(self.animalTypes) do
            self:initGrass(animI, animType)

            local maskId = getTerrainDetailByName(g_currentMission.terrainRootNode, self.foliageTypes[animI])
            local a, _, _ = getDensityParallelogram(maskId, x - 2.5, z - 2.5, 5, 0, 0, 5, self.MASK_FIRST_CHANNEL,  self.MASK_NUM_CHANNELS)

            if a > 0 then
                self.showPastureInfo[animType] = true
            else
                self.showPastureInfo[animType] = false
            end
        end
    end

    for _, animType in pairs(self.animalTypes) do
        if self.showPastureInfo[animType] and self.preparedMap then
            local grassInField = math.max(math.floor(self.grassAvailable[animType] - self.consumedGrass[animType]), 0)
            g_currentMission:addExtraPrintText(g_i18n:getText("GA_" .. string.upper(animType) .."_PASTURE") .. tostring(grassInField) .. " " .. g_i18n:getText("unit_liter"))
        end
    end
end

function grazingAnimals:initGrass(animI, animalType)
    if self.grassAvailable[animalType] == nil then
        self.grassAvailable[animalType] = 0
        self.grassVolumeStage2[animalType], self.grassVolumeStage3[animalType] = self:getGrassAmounts(animI, animalType)
    end
end

function grazingAnimals:reduceGrassAmounts(animI, animalType, state)
    local maskId = getTerrainDetailByName(g_currentMission.terrainRootNode, self.foliageTypes[animI])

    local fruitId = g_currentMission.fruits[FruitUtil.FRUITTYPE_GRASS].id
    local minState = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].minHarvestingGrowthState
    local maxState = FruitUtil.fruitIndexToDesc[FruitUtil.FRUITTYPE_GRASS].maxHarvestingGrowthState
    local size = g_currentMission.terrainSize
    local corners = grazingArea.areas[animalType]

    setDensityMaskParams(maskId, "equals", 1)
    setDensityCompareParams(fruitId, "equals", state)

    addDensityMaskedParallelogram(
        fruitId,
        corners.x, corners.z, corners.widthX, corners.widthZ, corners.heightX, corners.heightZ,
        0, g_currentMission.numFruitStateChannels,
        maskId,
        self.MASK_FIRST_CHANNEL,  self.MASK_NUM_CHANNELS,
        -1)

    setDensityCompareParams(fruitId, "greater", -1)
    setDensityMaskParams(maskId, "greater", -1)

    self:getGrassAmounts(animI, animalType)
end

function grazingAnimals:deleteMap()
end

function grazingAnimals:keyEvent(unicode, sym, modifier, isDown)
end

function grazingAnimals:mouseEvent(posX, posY, isDown, isUp, button)
end

function grazingAnimals:draw()
end

function grazingAnimals.saveToXML(self)
    if grazingAnimals.enabled and self.isValid and self.xmlKey ~= nil and grazingAnimals.preparedMap then
        if self.xmlFile ~= nil then
            for _, animType in pairs(grazingAnimals.animalTypes) do
                setXMLFloat(self.xmlFile, self.xmlKey .. ".grazingAnimals.consumedGrass." .. animType,  grazingAnimals.consumedGrass[animType])
            end
        else
            g_currentMission.inGameMessage:showMessage("grazingAnimals", g_i18n:getText("GA_SAVE_FAILED"), 10000);
        end
    end
end

function grazingAnimals.loadFromXML()
    if g_currentMission == nil or not g_currentMission:getIsServer() then return end

    local xmlFile = nil
    if g_currentMission.missionInfo.isValid then
        xmlFile = g_currentMission.missionInfo.xmlFile
    end

    if xmlFile ~= nil then
        for _, animType in pairs(grazingAnimals.animalTypes) do
            local gmKey = g_currentMission.missionInfo.xmlKey .. ".grazingAnimals.consumedGrass." .. animType
            grazingAnimals.consumedGrass[animType] = Utils.getNoNil(getXMLFloat(xmlFile, gmKey), 0.0)
        end
    else
        for _, animType in pairs(grazingAnimals.animalTypes) do
            grazingAnimals.consumedGrass[animType] = 0
        end
    end
end

addModEventListener(grazingAnimals)

FSBaseMission.loadMapFinished = Utils.prependedFunction(FSBaseMission.loadMapFinished, grazingAnimals.loadFromXML)
