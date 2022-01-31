local uiManager = require("LuaScripts/ui/UI_Manager")

---@class UiScreen
local Ui = {}

Ui.screenName = "Credits"

--- links actions to buttons and etc. Usually, should be run only once
---@param instanceRoot UIElement
Ui.Setup = function (instanceRoot)

    local buttonMenu = instanceRoot:GetChild("ButtonMenu", true)

    SubscribeToEvent(buttonMenu, "Released", function ()
        instanceRoot:SetVisible(false)
        uiManager.ShowUI("MainMenu")
    end)

end

---@param instanceRoot UIElement
---@param dataPassed table
Ui.Show = function (instanceRoot, dataPassed)
    instanceRoot:SetVisible(true)
end

return Ui