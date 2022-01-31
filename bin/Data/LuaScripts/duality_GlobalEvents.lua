local DualityGlobalEvents = {}

local subscribedEvents = {}

local function HandleEvent(eventName, eventType, eventData)
    for _, subFunction in pairs(subscribedEvents[eventName]) do
        subFunction(eventType, eventData)
    end
end

---@param targetEventName string
---@param functionToCall function
function DualityGlobalEvents:SubscribeToEvent(targetEventName, functionToCall)
    if subscribedEvents[targetEventName] == nil then
        subscribedEvents[targetEventName] = {}
        SubscribeToEvent(targetEventName, function (eventType, eventData)
            HandleEvent(targetEventName, eventType, eventData)
        end)
    end

    for _, subFunction in pairs(subscribedEvents[targetEventName]) do
        if subFunction == functionToCall then return end
    end

    log:Write(LOG_DEBUG, "subscribed function to event " .. targetEventName)
    table.insert(subscribedEvents[targetEventName], functionToCall)
end


return DualityGlobalEvents