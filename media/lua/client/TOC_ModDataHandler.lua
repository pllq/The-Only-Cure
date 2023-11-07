local StaticData = require("TOC_StaticData")

----------------
---@alias partData { isCut : boolean?, isInfected : boolean?, isOperated : boolean?, isCicatrized : boolean?, isCauterized : boolean?, isDependant : boolean?, cicatrizationTime : number }
---@alias tocModData {Hand_L : partData, ForeArm_L : partData, UpperArm_L : partData, Hand_R : partData, ForeArm_R : partData, UpperArm_R : partData, isIgnoredPartInfected : boolean}
----------------
-- TODO This class should handle all the stuff related to the mod data

---@class ModDataHandler
---@field playerObj IsoPlayer
---@field tocData tocModData 
local ModDataHandler = {}

---@param playerObj IsoPlayer
---@return ModDataHandler
function ModDataHandler:new(playerObj)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.playerObj = playerObj
    o.tocData = playerObj:getModData()[StaticData.MOD_NAME]

    ModDataHandler.instance = o

    return o
end

---Setup a newly instanced ModDataHandler
---@param force boolean?
function ModDataHandler:setup(force)
    local tocData = self.playerObj:getModData()[StaticData.MOD_NAME]
    if force or tocData == nil or tocData.Hand_L == nil or tocData.Hand_L.isCut == nil then
        self:createData()
    end
    -- TODO Check compatibility or do we just skip it at this point?

end

function ModDataHandler:createData()
    print("TOC: createData")

    local modData = self.playerObj:getModData()
    modData[StaticData.MOD_NAME] = {

        -- Generic stuff that does not belong anywhere else
        isIgnoredPartInfected = false
    }

    ---@type partData
    local defaultParams = {isCut = false, isInfected = false, isOperated = false, isCicatrized = false, isCauterized = false, isDependant = false}


    -- Initialize limbs
    for i=1, #StaticData.LIMBS_STRINGS do
        local limbName = StaticData.LIMBS_STRINGS[i]
        modData[StaticData.MOD_NAME][limbName] = {}
        self:setLimbParams(StaticData.LIMBS_STRINGS[i], defaultParams, 0)
    end

    self.tocData = self.playerObj:getModData()[StaticData.MOD_NAME]
end


-----------------
--* Setters *--

---Set isCut
---@param limbName string
---@param isCut boolean
function ModDataHandler:setIsCut(limbName, isCut)
    self.tocData[limbName].isCut = isCut
end

---Set isInfected
---@param limbName string
---@param isInfected boolean
function ModDataHandler:setIsInfected(limbName, isInfected)
    self.tocData[limbName].isInfected = isInfected
end

---Set isIgnoredPartInfected
---@param isIgnoredPartInfected boolean
function ModDataHandler:setIsIgnoredPartInfected(isIgnoredPartInfected)
    self.tocData.isIgnoredPartInfected = isIgnoredPartInfected
end

-----------------
--* Getters *--
---Get isCut
---@param limbName string
---@return boolean
function ModDataHandler:getIsCut(limbName)
    return self.tocData[limbName].isCut
end

---Get isIgnoredPartInfected
---@return boolean
function ModDataHandler:getIsIgnoredPartInfected()
    return self.tocData.isIgnoredPartInfected
end




--* Limbs data handling *--

---Set a limb and its dependend limbs as cut
---@param limbName string
---@param isOperated boolean
---@param isCicatrized boolean
---@param isCauterized boolean
---@param surgeonFactor number?
function ModDataHandler:setCutLimb(limbName, isOperated, isCicatrized, isCauterized, surgeonFactor)
    local cicatrizationTime = 0
    if isCicatrized == false or isCauterized == false then
        cicatrizationTime = StaticData.LIMBS_CICATRIZATION_TIME[limbName] - surgeonFactor
    end

    ---@type partData
    local params = {isCut = true, isInfected = false, isOperated = isOperated, isCicatrized = isCicatrized, isCauterized = isCauterized, isDependant = false}
    self:setLimbParams(limbName, params, cicatrizationTime)

    for i=1, #StaticData.LIMBS_DEPENDENCIES[limbName] do
        local dependedLimbName = StaticData.LIMBS_DEPENDENCIES[limbName][i]

        -- We don't care about isOperated, isCicatrized, isCauterized since this is depending on another limb
        -- Same story for cicatrizationTime, which will be 0
        self:setLimbParams(dependedLimbName, {isCut = true, isInfected = false, isDependant = true}, 0)
    end

    -- Set the highest amputation and caches them.
    ISHealthPanel.GetHighestAmputation()
end


---Internal use only, set a limb data
---@param limbName string
---@param ampStatus partData {isCut, isInfected, isOperated, isCicatrized, isCauterized, isDependant}
---@param cicatrizationTime integer?
---@private
function ModDataHandler:setLimbParams(limbName, ampStatus, cicatrizationTime)
    local limbData = self.tocData[limbName]
    if ampStatus.isCut ~= nil then limbData.isCut = ampStatus.isCut end
    if ampStatus.isInfected ~= nil then limbData.isInfected = ampStatus.isInfected end
    if ampStatus.isOperated ~= nil then limbData.isOperated = ampStatus.isOperated end
    if ampStatus.isCicatrized ~= nil then limbData.isCicatrized = ampStatus.isCicatrized end
    if ampStatus.isCauterized ~= nil then limbData.isCauterized = ampStatus.isCauterized end
    if ampStatus.isDependant ~= nil then limbData.isDependant = ampStatus.isDependant end

    if cicatrizationTime ~= nil then limbData.cicatrizationTime = cicatrizationTime end
end



return ModDataHandler