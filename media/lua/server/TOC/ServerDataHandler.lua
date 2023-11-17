if isClient() then return end       -- The event makes this necessary to prevent clients from running this file

local ServerDataHandler = {}
ServerDataHandler.modData = {}

---Get the server mod data table containing that player TOC data
---@param key string
---@return tocModData
function ServerDataHandler.GetTable(key)
    return ServerDataHandler.modData[key]
end

---Add table to the ModData and a local table
---@param key string
---@param table tocModData
function ServerDataHandler.AddTable(key, table)
    print("TOC: received ModData => " .. key)
    
    TOC_DEBUG.printTable(table)
    --TOC_DEBUG.print("Adding table with key: " .. tostring(key))
    ModData.add(key, table)     -- Add it to the server mod data
    ServerDataHandler.modData[key] = table
end

Events.OnReceiveGlobalModData.Add(ServerDataHandler.AddTable)


return ServerDataHandler
