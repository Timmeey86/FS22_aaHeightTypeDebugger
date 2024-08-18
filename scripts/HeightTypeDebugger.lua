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

Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, function(screen)
    local maxTypes = 2^g_densityMapHeightManager.heightTypeNumChannels - 1
    local userText = ("There are %d height types, but the map can only handle %d types.\r\nThe following files loaded height types:\r\n\r\n"):format(counter, maxTypes + 1)
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
        userText = ("%s%s: %d height types\r\n\r\n"):format(userText, xmlFileMapping.xmlFile, fileCounter)
    end
    print(">>>>>>> END HEIGHT TYPE DEBUG <<<<<<<")

    if counter > maxTypes then
        g_currentMission.hud:showInGameMessage("", userText, -1, nil, nil, nil)
    end
end)