local DualityGlobalEvents = require("LuaScripts/duality_GlobalEvents")
local uiManager = require("LuaScripts/ui/UI_Manager")

---@class UiEndgame : UiScreen
local Ui = {}

Ui.screenName = "Endgame"

local leaveViaKeysEnabled = false


--- links actions to buttons and etc. Usually, should be run only once
---@param instanceRoot UIElement
Ui.Setup = function (instanceRoot)

    DualityGlobalEvents:SubscribeToEvent("KeyUp", EndGameAnyKeyToContinue)

    local buttonPlay = instanceRoot:GetChild("ButtonPlay", true)
    SubscribeToEvent(buttonPlay, "Released", function ()
        instanceRoot:SetVisible(false)
        uiManager.ShowUI("MainMenu")
        leaveViaKeysEnabled = false
    end)

end

---@param instanceRoot UIElement
---@param dataPassed EndGameScreenData
Ui.Show = function (instanceRoot, dataPassed)

    if dataPassed.hasWon then
        uiManager.ShowUI("Loading")
        return
    end

    instanceRoot:SetVisible(true)

    local pointsText = instanceRoot:GetChild("pointsText", true)
    pointsText.text = TimesWon

    ---@type BorderImage
    local parkDeathBg = instanceRoot:GetChild("bg_parkdeath", true)
    parkDeathBg:SetVisible(not WorldIsFlipped)

    TimesWon = 0
    StopMusic()

    coroutine.start(function ()
        coroutine.sleep(1.75)
        if instanceRoot:IsVisible() then
            leaveViaKeysEnabled = true
        end
    end)

end

function EndGameAnyKeyToContinue()

    if leaveViaKeysEnabled then
        leaveViaKeysEnabled = false
        uiManager.HideUI("Endgame")
        uiManager.ShowUI("MainMenu")
    end
    
end

return Ui