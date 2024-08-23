local heightTypeMapping = {}
local currentXMLFile = "unknown source"
local counter = 0
local currentIndex = 0


DensityMapHeightManager.addDensityMapHeightType = Utils.prependedFunction(DensityMapHeightManager.addDensityMapHeightType, function(manager, fillTypeName, ...)

    local alreadyExists = manager.fillTypeNameToHeightType[fillTypeName] ~= nil
    if not heightTypeMapping[currentIndex] then
        heightTypeMapping[currentIndex] = {
            xmlFile = currentXMLFile,
            data = {}
        }
    end
    local maxTypes = 2^g_densityMapHeightManager.heightTypeNumChannels - 1
    table.insert(heightTypeMapping[currentIndex].data, {
        alreadyExists = alreadyExists,
        index = counter,
        name = fillTypeName,
        failed = counter > maxTypes
    })
    if not alreadyExists then
        counter = counter + 1
    end
end)

DensityMapHeightManager.loadDensityMapHeightTypes = Utils.prependedFunction(DensityMapHeightManager.loadDensityMapHeightTypes, function(manager, xmlFile, missionInfo, baseDirectory, isBaseType)
    local source = "unknown source"
    if xmlFile ~= nil then
        source = getXMLFilename(xmlFile)
    end
    currentXMLFile = source
    currentIndex = currentIndex + 1
end)

local function getModName(path)
    if path == "data/maps/maps_densityMapHeightTypes.xml" then
        return g_i18n:getText("base_game")
    elseif path == "data/foliage/beetRoot/beetRoot.xml" then
        return g_i18n:getText("premium_expansion") .. "#1"
    elseif path == "data/foliage/carrot/carrot.xml" then
        return g_i18n:getText("premium_expansion") .. "#2"
    elseif path == "data/foliage/parsnip/parsnip.xml" then
        return g_i18n:getText("premium_expansion") .. "#3"
    elseif string.find(path, "pdlc/forestry") then
        return g_i18n:getText("platinum_expansion")
    elseif path:sub(1, #g_modsDirectory) == g_modsDirectory then
        local ret = path:sub(#g_modsDirectory + 1)
        return ret:sub(1, ret:find("/") - 1)
    else
        return path
    end
end


Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function(screen)
    local maxTypes = 2^g_densityMapHeightManager.heightTypeNumChannels - 1
    local userText = (g_i18n:getText("user_text_intro") .. g_i18n:getText("user_text_intro_two") .. "\r\n\r\n"):format(counter, maxTypes + 1)
    print(">>>>>>> START HEIGHT TYPE DEBUG <<<<<<<")
    for _, xmlFileMapping in pairs(heightTypeMapping) do
        print("> File: " .. xmlFileMapping.xmlFile)
        local fileCounter = 0
        for _, data in pairs(xmlFileMapping.data) do
            if data.alreadyExists then
                print((">>> %s: Ignored since it already exists"):format(data.name))
            elseif not data.failed then
                print((">>> %s: Added on index %d"):format(data.name, data.index))
                fileCounter = fileCounter + 1
            else
                print((">>> %s: Type exceeds maximum number of height types (index %d)"):format(data.name, data.index))
                fileCounter = fileCounter + 1
            end
        end
        local modName = getModName(xmlFileMapping.xmlFile)
        userText = ("%s%s: %s\r\n"):format(userText, modName, g_i18n:getText("user_text_height_types"):format(fileCounter))
    end
    userText = userText .. "\r\n" .. g_i18n:getText("user_text_outro"):format(counter - maxTypes - 1, (maxTypes + 1) * 2)
    print(">>>>>>> END HEIGHT TYPE DEBUG <<<<<<<")

    if counter > maxTypes then
        g_currentMission.hud:showInGameMessage("", userText, -1, nil, nil, nil)
    end
end)