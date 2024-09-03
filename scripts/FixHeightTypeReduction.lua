
--[[local mapNumChannels = 0

DensityMapHeightManager.addDensityMapHeightType = Utils.prependedFunction(DensityMapHeightManager.addDensityMapHeightType, function(manager, typeName, _, _, _, _, _, _, isBaseType)
    if manager.heightTypeNumChannels > mapNumChannels then
        print(("Height Type Limit Debug: Height Types were increased from %d to %d"):format(mapNumChannels, 2^manager.heightTypeNumChannels))
        mapNumChannels = manager.heightTypeNumChannels
    elseif manager.heightTypeNumChannels < mapNumChannels then
        Logging.warning(("Height Type Debug: Prevented the reduction of height types while registering type '%s'"):format(typeName))
        printCallstack()
        manager.heightTypeNumChannels = mapNumChannels
    end
end)]]