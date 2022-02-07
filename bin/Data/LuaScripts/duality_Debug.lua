local DualityGlobalEvents = require "LuaScripts/duality_GlobalEvents"

--    - Handle Esc key down to hide Console or exit application


local DualityDebug = {}

DualityDebug.drawDebug = false -- Draw debug geometry flag

local function DualityDebugHandleKeyUp(eventType, eventData)
    local key = eventData["Key"]:GetInt()
    -- Close console (if open) or exit when ESC is pressed
    if key == KEY_ESCAPE then
        if console:IsVisible() then
            console:SetVisible(false)
        else
            if GetPlatform() ~= "Web" then
                engine:Exit()
            end
        end
    end
end

local function DualityDebugHandleKeyDown(eventType, eventData)
    local key = eventData["Key"]:GetInt()

    local uiManager = require("LuaScripts/ui/UI_Manager")

    if key == KEY_F1 then
        console:Toggle()
        -- uiManager.ShowUI("Loading")
    elseif key == KEY_F2 then
        debugHud:ToggleAll()

        -- ---@type EndGameScreenData
        -- local endgameData = {}
        -- endgameData.hasWon = true

        -- uiManager.ShowUI("Endgame", endgameData)
    elseif key == KEY_F3 then
        DualityDebug.drawDebug = not DualityDebug.drawDebug
        -- uiManager.ShowUI("MainMenu")
    elseif key == KEY_F5 then
        Scene_:SaveXML(fileSystem:GetProgramDir().."Data/Scenes/duality.xml")
        ui.root:SaveXML(fileSystem:GetProgramDir().."Data/duality.xml")
    end

end

function DualityDebug.DebugSetup()

    -- Create console and debug HUD
    DualityDebug.CreateConsoleAndDebugHud()

    -- Subscribe key down event
    DualityGlobalEvents:SubscribeToEvent("KeyDown", DualityDebugHandleKeyDown)

    -- Subscribe key up event
    DualityGlobalEvents:SubscribeToEvent("KeyUp", DualityDebugHandleKeyUp)
end

function DualityDebug.CreateConsoleAndDebugHud()
    -- Get default style
    local uiStyle = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
    if uiStyle == nil then
        return
    end

    -- Create console
    engine:CreateConsole()
    console.defaultStyle = uiStyle
    console.background.opacity = 0.8

    -- Create debug HUD
    engine:CreateDebugHud()
    debugHud.defaultStyle = uiStyle
end



return DualityDebug
