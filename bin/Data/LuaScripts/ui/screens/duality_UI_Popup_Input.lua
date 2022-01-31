local uiManager = require("LuaScripts/ui/UI_Manager")

---@class PopupInputScreen : UiScreen
local ui = {}

ui.screenName = "PopupInput"

---@type LineEdit
local inputField = {}

--- links actions to buttons and etc. Usually, should be run only once
---@param instanceRoot UIElement
ui.Setup = function (instanceRoot)

    inputField = instanceRoot:GetChild("InputField", true)

end

---@param instanceRoot UIElement
---@param dataPassed InputPopupDisplayData
ui.Show = function (instanceRoot, dataPassed)
    
    instanceRoot:SetVisible(true)

    local inputTitle = instanceRoot:GetChild("InputTitleText", true)
    local inputDesc = instanceRoot:GetChild("InputDescText", true)
    -- cast to Text seems unnecessary in this case
    inputTitle.text = dataPassed.title
    inputDesc.text = dataPassed.prompt

    inputField:SetText(dataPassed.inputFieldInitialValue)

    local leftBtn = instanceRoot:GetChild("LeftBtn", true)

    UnsubscribeFromEvents(leftBtn)

    if dataPassed.buttonInfos[1] ~= nil then
        leftBtn:SetVisible(true)

        SubscribeToEvent(leftBtn, "Released", function ()
            
            -- Log:Write(LOG_INFO, "input popup left btn pressed!")

            if dataPassed.buttonInfos[1].buttonAction ~= nil then
                dataPassed.buttonInfos[1].buttonAction(inputField:GetText())
            end

            if dataPassed.buttonInfos[1].closePopupOnClick then
                instanceRoot:SetVisible(false)
            end

        end)

        local btnText = leftBtn:GetChild("Text")
        btnText.text = dataPassed.buttonInfos[1].buttonText

    else
        leftBtn:SetVisible(false)
    end

    local rightBtn = instanceRoot:GetChild("RightBtn", true)

    UnsubscribeFromEvents(rightBtn)

    if dataPassed.buttonInfos[2] ~= nil then

        rightBtn:SetVisible(true)

        SubscribeToEvent(rightBtn, "Released", function ()

            -- Log:Write(LOG_INFO, "input popup right btn pressed!")

            if dataPassed.buttonInfos[2].buttonAction ~= nil then
                dataPassed.buttonInfos[2].buttonAction(inputField:GetText())
            end

            if dataPassed.buttonInfos[2].closePopupOnClick then
                instanceRoot:SetVisible(false)
            end

        end)

        local btnText = rightBtn:GetChild("Text")
        btnText.text = dataPassed.buttonInfos[2].buttonText

    else
        rightBtn:SetVisible(false)
    end

end

return ui