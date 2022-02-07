local uiManager = require("LuaScripts/ui/UI_Manager")

---@class UiScreen
local Ui = {}

Ui.screenName = "MainMenu"

--- links actions to buttons and etc. Usually, should be run only once
---@param instanceRoot UIElement
Ui.Setup = function (instanceRoot)

    local buttonPlay = instanceRoot:GetChild("ButtonPlay", true)

    SubscribeToEvent(buttonPlay, "Released", function ()
        instanceRoot:SetVisible(false)
        uiManager.ShowUI("Loading")
    end)

    local buttonCreds = instanceRoot:GetChild("ButtonCredits", true)
    SubscribeToEvent(buttonCreds, "Released", function ()
        instanceRoot:SetVisible(false)
        uiManager.ShowUI("Credits")
    end)

    local buttonHowTo = instanceRoot:GetChild("ButtonHowTo", true)
    SubscribeToEvent(buttonHowTo, "Released", function ()
        instanceRoot:SetVisible(false)
        uiManager.ShowUI("HowTo")
    end)

    local buttonQuit = instanceRoot:GetChild("ButtonExit", true)
    SubscribeToEvent(buttonQuit, "Released", function ()
        engine:Exit()
    end)

    if GetPlatform() == "Web" then
        buttonQuit:SetVisible(false)
    end

end

---@param instanceRoot UIElement
---@param dataPassed table
Ui.Show = function (instanceRoot, dataPassed)
    instanceRoot:SetVisible(true)

    StartMusic()
end

return Ui