
---@class UiDefinition
---@field uiFilePath string
---@field attachedInstance UIElement
local MainMenu = { 
    uiFilePath = "UI/duality/duality_screen_title.xml",
    handlerFile = require("LuaScripts/ui/screens/duality_UI_MainMenu")
 }

---@type UiDefinition[]
local definitions = {
    MainMenu = MainMenu,
    PopupGeneric = { uiFilePath = "UI/duality/duality_overlay_popup.xml" },
    PopupInput = {
        uiFilePath = "UI/duality/duality_generic_input_overlay.xml",
        handlerFile = require("LuaScripts/ui/screens/duality_UI_Popup_Input")
    },
    Endgame = { 
        uiFilePath = "UI/duality/duality_screen_endgame.xml",
        handlerFile = require("LuaScripts/ui/screens/duality_UI_Endgame")
    },
    Credits = { 
        uiFilePath = "UI/duality/duality_screen_credits.xml",
        handlerFile = require("LuaScripts/ui/screens/duality_UI_Credits")
    },
    HowTo = { 
        uiFilePath = "UI/duality/duality_screen_howto.xml",
        handlerFile = require("LuaScripts/ui/screens/duality_UI_Credits")
    },
    Loading = { 
        uiFilePath = "UI/duality/duality_screen_loading.xml",
        handlerFile = require("LuaScripts/ui/screens/duality_UI_Loading")
    },
    Game = { 
        uiFilePath = "UI/duality/duality_screen_game.xml",
        handlerFile = require("LuaScripts/ui/screens/duality_UI_Game")
    },
}


-- extra emmylua ui-related definitions...

---@class PopupDisplayData
---@field title string
---@field prompt string
---@field buttonInfos PopupButtonInfo[]
local popupDisplayData = {}

---@class InputPopupDisplayData : PopupDisplayData
---@field inputFieldInitialValue string
local inputPopupDisplayData = {}

---@class PopupButtonInfo
---@field buttonText string
---@field buttonAction function
---@field closePopupOnClick boolean
local popupButtonInfo = {}

---@class EndGameScreenData
---@field hasWon boolean
local endGameScreenData = {}


return definitions