local heightTypeMapping = {}
local currentXMLFile = "unknown source"
local counter = 0
local currentIndex = 0


DensityMapHeightManager.addDensityMapHeightType = Utils.prependedFunction(DensityMapHeightManager.addDensityMapHeightType, function(manager, fillTypeName, ...)

    if currentXMLFile == nil then
        currentIndex = currentIndex + 1
        currentXMLFile = "unidentified (search log for \"UNID_HT_REG\")"
        Logging.error("UNID_HT_REG: A mod registered height types through script. The mod name should be visible in the following call stack:")
        printCallstack()
    end
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

local numChannelsBefore = 0

DensityMapHeightManager.loadDensityMapHeightTypes = Utils.prependedFunction(DensityMapHeightManager.loadDensityMapHeightTypes, function(manager, xmlFile, missionInfo, baseDirectory, isBaseType)

    local source = "unknown source"
    if xmlFile ~= nil then
        source = getXMLFilename(xmlFile)
    end

    -- Condense premium expansion into one entry
    if source == "data/foliage/carrot/carrot.xml" or source == "data/foliage/parsnip/parsnip.xml" then
        currentXMLFile = "data/foliage/beetRoot/beetRoot.xml"
    else
        currentXMLFile = source
        currentIndex = currentIndex + 1
    end

    print("Loading height types from " .. tostring(source))
    numChannelsBefore = g_densityMapHeightManager.heightTypeNumChannels or 0 -- will be nil before loading base game stuff
end)

local dummy = {}
function dummy.fakeCallback() end


local function getModName(path)
    if path == "data/maps/maps_densityMapHeightTypes.xml" then
        return g_i18n:getText("base_game")
    elseif path == "data/foliage/beetRoot/beetRoot.xml" then
        return g_i18n:getText("premium_expansion")
    elseif string.find(path, "pdlc/forestry") then
        return g_i18n:getText("platinum_expansion")
    elseif path:sub(1, #g_modsDirectory) == g_modsDirectory then
        local ret = path:sub(#g_modsDirectory + 1)
        return ret:sub(1, ret:find("/") - 1)
    else
        return path
    end
end

local incompatibleMods = {}
DensityMapHeightManager.loadDensityMapHeightTypes = Utils.appendedFunction(DensityMapHeightManager.loadDensityMapHeightTypes, function(...)

    if g_densityMapHeightManager.heightTypeNumChannels < numChannelsBefore then
        Logging.error("The number of density height types was decreased. You can identify the responsible mod in the call stack:")
        printCallstack()

        table.insert(incompatibleMods, getModName(currentXMLFile))

        -- Reset the number of channels so more mods like this one can be detected
        -- Note: This can not be used as a workaround for such mods since height type registration will have failed already
        g_densityMapHeightManager.heightTypeNumChannels = numChannelsBefore
    end
    currentXMLFile = nil
end)

DensityMapHeightManager.loadMapData = Utils.appendedFunction(DensityMapHeightManager.loadMapData, function(...)
    if #incompatibleMods > 0 then
        local modNames = ""
        for i = 1, #incompatibleMods, 1 do
            modNames = modNames .. incompatibleMods[i]
            if i ~= #incompatibleMods then
                modNames = modNames .. ", "
            end
        end
        g_gui:showYesNoDialog({
            title = g_i18n:getText("user_title_height_type_reduction"),
            text = g_i18n:getText("user_text_height_type_reduction"):format(modNames),
            callback = dummy.fakeCallback,
            yesText = g_i18n:getText("button_continue"),
            noText = g_i18n:getText("button_continue"),
            target = dummy
        })
    end
end)

Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function(screen)
    local maxTypes = 2^g_densityMapHeightManager.heightTypeNumChannels - 1
    print(">>>>>>> START HEIGHT TYPE DEBUG <<<<<<<")
    local userText = ""
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
    print(">>>>>>> END HEIGHT TYPE DEBUG <<<<<<<")

    local introText = ""
    if counter > maxTypes then
        introText = g_i18n:getText("user_text_intro")
    else
        introText = g_i18n:getText("user_text_intro_good")
    end
    userText = ( introText .. g_i18n:getText("user_text_intro_two") .. "\r\n\r\n"):format(counter, maxTypes + 1) .. userText
    if counter > maxTypes then
        userText = userText .. "\r\n" .. g_i18n:getText("user_text_outro"):format(counter - maxTypes - 1, (maxTypes + 1) * 2)
    end
    g_currentMission.hud:showInGameMessage("", userText, -1, nil, nil, nil)
end)