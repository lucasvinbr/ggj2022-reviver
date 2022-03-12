DualityDebug = require "LuaScripts/duality_Debug"
local uiManager = require "LuaScripts/ui/UI_Manager"
local dualityUiDefs = require "LuaScripts/ui/UI_Definitions"
local mouseConfig = require "LuaScripts/duality_Mouse"
require "LuaScripts/duality_World"
require "LuaScripts/duality_Audio"
require "LuaScripts/duality_Player"
require "LuaScripts/duality_Enemy"


---@type Scene
Scene_ = nil -- Scene

---@type Node
CameraNode = nil -- Camera scene node

---@type Camera
DualityCamera = nil

function Start()

  SetRandomSeed(os.time())
  -- Set custom window Title & Icon
  SetWindowTitleAndIcon()

  -- Execute debug stuff startup
  DualityDebug.DebugSetup()

-- Create the scene content
  CreateScene()

-- Hook up to relevant events
  SubscribeToEvents()

  SetupSound()

  SetupUI()

  mouseConfig.SetupMouseEvents()
  mouseConfig.SetMouseMode(MM_FREE)

end


function SetupUI()
  -- Set up global UI style into the root UI element
  local style = cache:GetResource("XMLFile", "UI/DefaultStyle.xml")
  ui.root.defaultStyle = style
  
  uiManager.AddUiDefinitions(dualityUiDefs)
  uiManager.ShowUI("MainMenu")
end

function SetWindowTitleAndIcon()
    local icon = cache:GetResource("Image", "Urho2D/duality/gameIcon.png")
    graphics:SetWindowIcon(icon)
    graphics.windowTitle = "Reviver"
end

function CreateScene()
    ---@type Scene
    Scene_ = Scene()

    -- Create the Octree, DebugRenderer and PhysicsWorld2D components to the scene
    Scene_:CreateComponent("Octree")
    Scene_:CreateComponent("DebugRenderer")
    local physicsWorld = Scene_:CreateComponent("PhysicsWorld2D")
    -- physicsWorld.gravity = Vector2.ZERO -- Neutralize gravity as the character will always be grounded

    -- Create camera
    CameraNode = Node()
    CameraNode:SetPosition(Vector3.BACK)
    ---@type Camera
    DualityCamera = CameraNode:CreateComponent("Camera")
    DualityCamera.orthographic = true
    DualityCamera.orthoSize = graphics.height * PIXEL_SIZE
    CurCameraZoom = CurCameraZoom * Min(graphics.width / 1280, graphics.height / 800) -- Set zoom according to user's resolution to ensure full visibility (initial zoom (2) is set for full visibility at 1280x800 resolution)
    DualityCamera:SetZoom(CurCameraZoom)

    -- Setup the viewport for displaying the scene
    renderer:SetViewport(0, Viewport:new(Scene_, DualityCamera))
    renderer.defaultZone.fogColor = Color(0.2, 0.2, 0.2) -- Set background color for the scene

    -- create level boundaries based on world bounds constants and scale
    local boundaryThickness = 10
    local rightBoundary = Scene_:CreateChild("levelBounds")
    ---@type RigidBody2D
    local boundaryRigid = rightBoundary:CreateComponent("RigidBody2D")
    boundaryRigid.bodyType = BT_STATIC

    ---@type CollisionBox2D
    local boundaryShape = rightBoundary:CreateComponent("CollisionBox2D")
    boundaryShape:SetCategoryBits(COLMASK_WORLD)
    boundaryShape:SetSize(2.0, 2.0)

    rightBoundary.position2D = Vector2(WORLD_BOUNDS_UNSCALED.x + boundaryThickness, 0)
    rightBoundary:SetScale2D(Vector2(boundaryThickness, WORLD_BOUNDS_UNSCALED.y))

    local leftBoundary = rightBoundary:Clone()
    leftBoundary.position2D = Vector2(-WORLD_BOUNDS_UNSCALED.x - boundaryThickness, 0)
    leftBoundary:SetScale2D(Vector2(boundaryThickness, WORLD_BOUNDS_UNSCALED.y))

    local topBoundary = rightBoundary:Clone()
    topBoundary.position2D = Vector2(0, WORLD_BOUNDS_UNSCALED.y + boundaryThickness)
    topBoundary:SetScale2D(Vector2(WORLD_BOUNDS_UNSCALED.x, boundaryThickness))

    local bottomBoundary = rightBoundary:Clone()
    bottomBoundary.position2D = Vector2(0, -WORLD_BOUNDS_UNSCALED.y - boundaryThickness)
    bottomBoundary:SetScale2D(Vector2(WORLD_BOUNDS_UNSCALED.x, boundaryThickness))

    SetupCraveiContent()

end

function SetupGameMatch()

  WorldIsFlipped = false

  Cleanup()

  CreateLevel()

  -- flip world twice to enable and disable all relevant stuff
  FlipWorld()
  FlipWorld(true)

  -- Check when scene is rendered; we pause until the player presses "play"
  SubscribeToEvent("EndRendering", HandleSceneReady)

end


function SetupViewport()
  -- Set up a viewport to the Renderer subsystem so that the 3D scene can be seen
  local viewport = Viewport:new(Scene_, CameraNode:GetComponent("Camera"))
  renderer:SetViewport(0, viewport)
end

function SubscribeToEvents()

  -- Subscribe HandlePostRenderUpdate() function for processing the post-render update event, during which we request
  -- debug geometry
  SubscribeToEvent("PostRenderUpdate", HandlePostRenderUpdate)

end


function HandlePostRenderUpdate(eventType, eventData)
  -- If draw debug mode is enabled, draw physics debug geometry. Use depth test to make the result easier to interpret
  if DualityDebug.drawDebug  then
    Scene_:GetComponent("PhysicsWorld2D"):DrawDebugGeometry(true)
  end
end

function HandleSceneReady()
  UnsubscribeFromEvent("EndRendering")
  if not DoneSettingUp then
    Scene_.updateEnabled = false -- Pause the scene if it's still being loaded
  end
end