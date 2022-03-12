local uiManager = require "LuaScripts/ui/UI_Manager"

CAMERA_MIN_DIST = 0.1
CAMERA_MAX_DIST = 6

MOVE_SPEED_X = 4.5 -- Movement speed for isometric maps
MOVE_SPEED_SCALE = 1 -- Scaling factor based on tiles' aspect ratio

MAX_TIME_PER_LEVEL = 15.0
MIN_TIME_PER_LEVEL = 5.0

MIN_TIME_LEVEL = 40

SHOW_CRAVEI_LEVEL_INTERVAL = 10 -- every x levels we show the "cravei" screen

PLAYER_FLIP_IMMUNE_INTERVAL = 0.2


COLMASK_WORLD = 1
COLMASK_WORLD_FLIPPED = 2
COLMASK_PLAYER = 4
COLMASK_PLAYER_FLIPPED = 8
COLMASK_OBJS = 16
COLMASK_OBJS_FLIPPED = 32

VIEWMASK_UNFLIPPED = 1
VIEWMASK_FLIPPED = 2

TAG_PLAYER = "player"
TAG_ENEMY = "enemy"
TAG_PORTAL = "portal"
TAG_ANKH = "ankh"
TAG_WIN_OBJ = "winnerobj"

SCALE_WORLD = Vector2(1.23, 1.35)


-- assuming world is a square
WORLD_BOUNDS_UNSCALED = Vector2(5.0, 2.3)

CurCameraZoom = 1.12 -- Speed is scaled according to zoom
DemoFilename = "duality"

DoneSettingUp = false

---@type Node
DualityPlayerNode = nil

---@type DualityPlayer
DualityPlayerScript = nil

---@type Node
local ankhNode = nil

---@type Node
local altarNode = nil

---@type StaticSprite2D
local altarSprite = nil

---@type StaticSprite2D
local altarShadowSprite = nil

LevelTimeLeft = 0

TimeForCurrentLevel = 15.0

TimesWon = 0


GAMESTATE_ENDED = 1
GAMESTATE_STARTING = 2
GAMESTATE_PLAYING = 4
GAMESTATE_ENDING = 8

---@type "GAMESTATE_ENDED"|"GAMESTATE_STARTING"|"GAMESTATE_PLAYING"|"GAMESTATE_ENDING"
CurGameState = GAMESTATE_ENDED

WorldIsFlipped = false

---@type Node
DynamicContentParent = nil

---@type Node
UnflippedScenarioContentParent = nil

---@type Node
FlippedScenarioContentParent = nil

---@type Node
local craveiContent = nil


local flippedElements = {}
local unflippedElements = {}

---@class portalData
---@field isAnimated boolean
---@field filePath string


---@type portalData[]
local unflippedPortalDatas = {
    {isAnimated = false, filePath = "Urho2D/duality/buraco.png"},
    {isAnimated = true, filePath = "Urho2D/duality/enemies/coco.scml"},
}

---@type portalData[]
local flippedPortalDatas = {
    {isAnimated = true, filePath = "Urho2D/duality/enemies/fogoAzul.scml"},
    {isAnimated = false, filePath = "Urho2D/duality/buraco.png"},
    {isAnimated = false, filePath = "Urho2D/duality/espinhos.png"},
}


local unflippedObstacleDatas = {
    "Urho2D/duality/static_obstacles/unflip/3arvorezinhas.png",
    "Urho2D/duality/static_obstacles/unflip/4arvorezinhas.png",
    "Urho2D/duality/static_obstacles/unflip/arvores.png",
    "Urho2D/duality/static_obstacles/unflip/arvorezinha.png",
    "Urho2D/duality/static_obstacles/unflip/banco.png",
}

local flippedObstacleDatas = {
    "Urho2D/duality/static_obstacles/flip/arvores_mortas.png",
    "Urho2D/duality/static_obstacles/flip/cruzElapides.png",
    "Urho2D/duality/static_obstacles/flip/tumulosPretos.png"
}


function SetupCraveiContent()
    ---@type Node
    craveiContent = Scene_:InstantiateXML("Data/Objects/duality/cravei_content.xml", Vector3.ZERO, Quaternion.IDENTITY)
    craveiContent:SetScale(0)
end

function CreateLevel()

    log:Write(LOG_DEBUG, TimesWon)

    CurGameState = GAMESTATE_STARTING

    TimeForCurrentLevel = Lerp(MAX_TIME_PER_LEVEL, MIN_TIME_PER_LEVEL, TimesWon / MIN_TIME_LEVEL)
    LevelTimeLeft = TimeForCurrentLevel

    DynamicContentParent = Scene_:CreateChild("DynamicContent")
    -- Create player character
    CreateCharacter(Vector3(-2, 0, 0))
    table.insert(unflippedElements, DualityPlayerNode)

    ---@type Node
    UnflippedScenarioContentParent = Scene_:CreateChild("ContentU")

    ---@type Node
    FlippedScenarioContentParent = Scene_:CreateChild("ContentF")

    local unflippedGround = UnflippedScenarioContentParent:CreateChild("GroundU")
    ---@type StaticSprite2D
    local unflippedGroundSprite = unflippedGround:CreateComponent("StaticSprite2D")
    unflippedGroundSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/parque.png")
    unflippedGroundSprite:SetLayer(1)
    unflippedGround:SetScale2D(SCALE_WORLD)

    local unflippedDecoParticlesNode = UnflippedScenarioContentParent:CreateChild("Emitter")
    unflippedDecoParticlesNode:SetScale2D(Vector2.ONE * 1.4)
    ---@type ParticleEmitter2D
    local unflippedDecoEmitter = unflippedDecoParticlesNode:CreateComponent("ParticleEmitter2D")
    unflippedDecoEmitter:SetLayer(5)
    unflippedDecoEmitter.effect = cache:GetResource("ParticleEffect2D", "Urho2D/duality/folhas.pex")
    unflippedDecoEmitter:SetBlendMode(BLEND_ALPHA)
    unflippedDecoEmitter:SetViewMask(VIEWMASK_UNFLIPPED)

    local flippedGround = FlippedScenarioContentParent:CreateChild("GroundF")
    ---@type StaticSprite2D
    local flippedGroundSprite = flippedGround:CreateComponent("StaticSprite2D")
    flippedGroundSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/cemiterio.png")
    flippedGroundSprite:SetLayer(1)
    flippedGround:SetScale2D(SCALE_WORLD)
  
    CreateAnkh(GetRandomPositionInWorld(), true)
    table.insert(flippedElements, ankhNode)
  
    CreateAltar(GetRandomPositionInWorld({DualityPlayerNode}), false)
    table.insert(unflippedElements, altarNode)
    table.insert(flippedElements, altarNode)
  
    for _ = 0, TimesWon, 1 do
        CreatePortal(GetRandomPositionInWorld(flippedElements), true)
        CreatePortal(GetRandomPositionInWorld(unflippedElements), false)
    end
    
    for _ = 3, TimesWon, 2 do
        CreateEnemy(GetRandomPositionInWorld(flippedElements), true)
    end

    for _ = 4, TimesWon, 2 do
        CreateEnemy(GetRandomPositionInWorld(unflippedElements), false)
    end

    for _ = 6, TimesWon, 2 do
        CreateObstacle(GetRandomPositionInWorld(unflippedElements), false)
    end

    for _ = 7, TimesWon, 2 do
        CreateObstacle(GetRandomPositionInWorld(flippedElements), true)
    end

    DualityPlayerScript:SetupBigHeadAnim()

end


function CreateCharacter(position)
    DualityPlayerNode = DynamicContentParent:CreateChild("Player")
    DualityPlayerNode.position = position

    ---@type DualityPlayer
    DualityPlayerScript = DualityPlayerNode:CreateScriptObject("DualityPlayer") -- Create a ScriptObject to handle character behavior

end

---@param position Vector2
---@param isInFlippedWorld boolean
function CreateWall(position, isInFlippedWorld)
    log:Write(LOG_DEBUG, "build wall at " .. position:ToString())
    local parent = nil

    if isInFlippedWorld then
        parent = FlippedScenarioContentParent
    else
        parent = UnflippedScenarioContentParent
    end

    local wallNode = parent:CreateChild("wall")

    wallNode.position2D = position

    ---@type StaticSprite2D
    local wallSprite = wallNode:CreateComponent("StaticSprite2D")
    wallSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/parede.png")
    wallSprite:SetLayer(2)

    ---@type RigidBody2D
    local rigidbody = wallNode:CreateComponent("RigidBody2D")
    rigidbody.bodyType = BT_STATIC
    rigidbody.allowSleep = false
    rigidbody:SetGravityScale(0.0)

    ---@type CollisionBox2D
    local collisionShape = wallNode:CreateComponent("CollisionBox2D")
    collisionShape:SetSize(Vector2.ONE * 0.5)
    collisionShape:SetFriction(0.8)
    if isInFlippedWorld then
        collisionShape:SetCategoryBits(COLMASK_OBJS_FLIPPED)
        --collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED)
    else
        collisionShape:SetCategoryBits(COLMASK_OBJS)
        --collisionShape:SetMaskBits(COLMASK_PLAYER)
    end

    wallNode:SetScale2D(Vector2.ONE * 0.8)
    
end

function CreatePortal(position, isInFlippedWorld)
    local parent = nil
    ---@type portalData
    local portalData = nil

    if isInFlippedWorld then
        parent = FlippedScenarioContentParent
        portalData = flippedPortalDatas[RandomInt(1, #flippedPortalDatas + 1)]
    else
        parent = UnflippedScenarioContentParent
        portalData = unflippedPortalDatas[RandomInt(1, #unflippedPortalDatas + 1)]
    end

    local portalNode = parent:CreateChild("portal")

    portalNode.position2D = position

    portalNode:AddTag(TAG_PORTAL)

    if portalData.isAnimated then
        ---@type AnimatedSprite2D
        local portalSprite = portalNode:CreateComponent("AnimatedSprite2D")
        portalSprite.animationSet = cache:GetResource("AnimationSet2D", portalData.filePath)
        portalSprite.animation = "idle"
        portalSprite:SetLayer(2)
    else
        ---@type StaticSprite2D
        local portalSprite = portalNode:CreateComponent("StaticSprite2D")
        portalSprite.sprite = cache:GetResource("Sprite2D", portalData.filePath)
        portalSprite:SetLayer(2)
    end
    

    ---@type RigidBody2D
    local rigidbody = portalNode:CreateComponent("RigidBody2D")
    rigidbody.bodyType = BT_STATIC
    rigidbody.allowSleep = false
    rigidbody:SetGravityScale(0.0)

    ---@type CollisionCircle2D
    local collisionShape = portalNode:CreateComponent("CollisionCircle2D")
    collisionShape:SetRadius(0.4)
    collisionShape:SetFriction(0.8)
    if isInFlippedWorld then
        collisionShape:SetCategoryBits(COLMASK_OBJS_FLIPPED)
        --collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED)
    else
        collisionShape:SetCategoryBits(COLMASK_OBJS)
        --collisionShape:SetMaskBits(COLMASK_PLAYER)
    end

    portalNode:SetScale2D(Vector2.ONE * 0.6)

    if isInFlippedWorld then
       table.insert(flippedElements, portalNode)
    else
        table.insert(unflippedElements, portalNode)
    end
    
end

function CreateObstacle(position, isInFlippedWorld)
    local parent = nil
    ---@type string
    local imagePath = nil

    if isInFlippedWorld then
        parent = FlippedScenarioContentParent
        imagePath = flippedObstacleDatas[RandomInt(1, #flippedObstacleDatas + 1)]
    else
        parent = UnflippedScenarioContentParent
        imagePath = unflippedObstacleDatas[RandomInt(1, #unflippedObstacleDatas + 1)]
    end

    local obstacleNode = parent:CreateChild("obstacle")

    obstacleNode.position2D = position

    ---@type StaticSprite2D
    local obstacleSprite = obstacleNode:CreateComponent("StaticSprite2D")
    obstacleSprite.sprite = cache:GetResource("Sprite2D", imagePath)
    obstacleSprite:SetLayer(2)


    ---@type RigidBody2D
    local rigidbody = obstacleNode:CreateComponent("RigidBody2D")
    rigidbody.bodyType = BT_STATIC
    rigidbody.allowSleep = false
    rigidbody:SetGravityScale(0.0)

    ---@type CollisionCircle2D
    local collisionShape = obstacleNode:CreateComponent("CollisionCircle2D")
    collisionShape:SetRadius(0.25)
    collisionShape:SetFriction(0.8)
    if isInFlippedWorld then
        collisionShape:SetCategoryBits(COLMASK_OBJS_FLIPPED)
        --collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED)
    else
        collisionShape:SetCategoryBits(COLMASK_OBJS)
        --collisionShape:SetMaskBits(COLMASK_PLAYER)
    end

    obstacleNode:SetScale2D(Vector2.ONE * 1.2)

    if isInFlippedWorld then
       table.insert(flippedElements, obstacleNode)
    else
        table.insert(unflippedElements, obstacleNode)
    end
    
end

function CreateAnkh(position, isInFlippedWorld)
    local parent = nil

    if isInFlippedWorld then
        parent = FlippedScenarioContentParent
    else
        parent = UnflippedScenarioContentParent
    end

    ankhNode = parent:CreateChild("ankh")

    ankhNode.position2D = position

    ankhNode:AddTag(TAG_ANKH)

    ---@type AnimatedSprite2D
    local animatedSprite = ankhNode:CreateComponent("AnimatedSprite2D")
    animatedSprite.animationSet = cache:GetResource("AnimationSet2D", "Urho2D/duality/ankh.scml")
    animatedSprite.animation = "idle"
    animatedSprite:SetLayer(4)

    ---@type RigidBody2D
    local rigidbody = ankhNode:CreateComponent("RigidBody2D")
    rigidbody.bodyType = BT_KINEMATIC
    rigidbody.allowSleep = false
    rigidbody:SetGravityScale(0.0)

    ---@type CollisionCircle2D
    local collisionShape = ankhNode:CreateComponent("CollisionCircle2D")
    collisionShape:SetRadius(0.5)
    collisionShape:SetFriction(0.8)
    if isInFlippedWorld then
        collisionShape:SetCategoryBits(COLMASK_OBJS_FLIPPED)
        collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED)
    else
        collisionShape:SetCategoryBits(COLMASK_OBJS)
        collisionShape:SetMaskBits(COLMASK_PLAYER)
    end

    ankhNode:SetScale2D(Vector2.ONE * 0.5)
    
end

function CreateAltar(position, isInFlippedWorld)

    local altarScaleFactor = 0.5
    -- the altar has a "shadow" in the other world, to help the player find it
    local parent = nil

    if isInFlippedWorld then
        parent = FlippedScenarioContentParent
    else
        parent = UnflippedScenarioContentParent
    end

    altarNode = parent:CreateChild("altar")

    altarNode.position2D = position

    altarNode:AddTag(TAG_WIN_OBJ)

    ---@type StaticSprite2D
    altarSprite = altarNode:CreateComponent("StaticSprite2D")
    altarSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/Altar.png")
    altarSprite:SetLayer(4)

    ---@type RigidBody2D
    local rigidbody = altarNode:CreateComponent("RigidBody2D")
    rigidbody.bodyType = BT_KINEMATIC
    rigidbody.allowSleep = false
    rigidbody:SetGravityScale(0.0)

    altarNode:SetScale2D(Vector2.ONE * altarScaleFactor)

    ---@type CollisionCircle2D
    local collisionShape = altarNode:CreateComponent("CollisionCircle2D")
    collisionShape:SetRadius(0.5)
    collisionShape:SetFriction(0.8)
    if isInFlippedWorld then
        collisionShape:SetCategoryBits(COLMASK_OBJS_FLIPPED)
        collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED)
    else
        collisionShape:SetCategoryBits(COLMASK_OBJS)
        collisionShape:SetMaskBits(COLMASK_PLAYER)
    end

    -- set up shadow in the world we're not in
    -- the altar has a "shadow" in the other world, to help the player find it
    local shadowParent = nil

    if isInFlippedWorld then
        shadowParent = UnflippedScenarioContentParent
    else
        shadowParent = FlippedScenarioContentParent
    end

    local altarShadowNode = shadowParent:CreateChild("altarShadow")
    altarShadowNode.position2D = altarNode.position2D
    ---@type StaticSprite2D
    altarShadowSprite = altarShadowNode:CreateComponent("StaticSprite2D")
    altarShadowSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/Altar.png")
    altarShadowSprite:SetLayer(4)

    altarShadowNode:SetScale2D(Vector2.ONE * altarScaleFactor)


    CirclePositionWithWalls(altarNode.position, isInFlippedWorld)
    
end

---@param spawnPos Vector2
---@param isInFlippedWorld boolean
function CreateEnemy(spawnPos, isInFlippedWorld)

    local parent = nil

    if isInFlippedWorld then
        parent = FlippedScenarioContentParent
    else
        parent = UnflippedScenarioContentParent
    end

    local node = parent:CreateChild("Enemy")
    node.position2D = spawnPos

    ---@type DualityEnemy
    local enemyScript = node:CreateScriptObject("DualityEnemy")

    enemyScript:SetupFlipDependentData(isInFlippedWorld)

    if isInFlippedWorld then
        table.insert(flippedElements, node)
    else
        table.insert(unflippedElements, node)
    end

    return node
end

--- spawns 9 walls around the target pos
---@param position Vector2
---@param isInFlippedWorld boolean
function CirclePositionWithWalls(position, isInFlippedWorld)

    local padding = 0.5

    ---@type boolean
    local mustBuildTop = position.y + padding < WORLD_BOUNDS_UNSCALED.y
    ---@type boolean
    local mustBuildBottom = (not mustBuildTop) or (position.y - padding > -WORLD_BOUNDS_UNSCALED.y)
    ---@type boolean
    local mustBuildRight = position.x + padding < WORLD_BOUNDS_UNSCALED.x
    ---@type boolean
    local mustBuildLeft = (not mustBuildRight) or (position.x - padding > -WORLD_BOUNDS_UNSCALED.x)

    local buildPos = Vector2(position.x, position.y)

    if mustBuildBottom then
        buildPos.y = position.y - padding
        CreateWall(buildPos, isInFlippedWorld)

        if mustBuildLeft then
            buildPos.x = position.x - padding
            CreateWall(buildPos, isInFlippedWorld)
        end
        if mustBuildRight then
            buildPos.x = position.x + padding
            CreateWall(buildPos, isInFlippedWorld)
        end
    end

    if mustBuildTop then
        buildPos.x = position.x
        buildPos.y = position.y + padding
        CreateWall(buildPos, isInFlippedWorld)

        if mustBuildLeft then
            buildPos.x = position.x - padding
            CreateWall(buildPos, isInFlippedWorld)
        end
        if mustBuildRight then
            buildPos.x = position.x + padding
            CreateWall(buildPos, isInFlippedWorld)
        end
    end

    if mustBuildLeft then
        buildPos.x = position.x - padding
        buildPos.y = position.y
        CreateWall(buildPos, isInFlippedWorld)
    end

    if mustBuildRight then
        buildPos.x = position.x + padding
        buildPos.y = position.y
        CreateWall(buildPos, isInFlippedWorld)
    end

end


function FlipWorld(playFlipSound)
    WorldIsFlipped = not WorldIsFlipped
    DualityPlayerScript:Flip(WorldIsFlipped)
    FlipMusic(WorldIsFlipped)

    if WorldIsFlipped then
        DualityCamera:SetViewMask(VIEWMASK_FLIPPED)
    else
        DualityCamera:SetViewMask(VIEWMASK_UNFLIPPED)
    end

    if playFlipSound then
        PlayOneShotSound("Sounds/duality/flip.ogg", 0.25, 2000)
    end

    UnflippedScenarioContentParent:SetEnabledRecursive(not WorldIsFlipped)
    FlippedScenarioContentParent:SetEnabledRecursive(WorldIsFlipped)
end


function UpdateWorld()
    -- altar and its shadow slowly fade out as the time runs out
    altarShadowSprite:SetColor(Color.TRANSPARENT_BLACK:Lerp(Color.BLACK, LevelTimeLeft / TimeForCurrentLevel))
    altarSprite:SetColor(Color.TRANSPARENT_BLACK:Lerp(Color.WHITE, LevelTimeLeft / TimeForCurrentLevel))
end

---@param victory boolean
function EndGame(victory)
    if CurGameState ~= GAMESTATE_ENDED then
        CurGameState = GAMESTATE_ENDED

        DualityPlayerScript.canCountTime = false
        DualityPlayerScript.canMove = false

        uiManager.HideUI("Game")

        ---@type EndGameScreenData
        local gameEndData = {
            hasWon = victory
        }

        if victory then
            TimesWon = TimesWon + 1
        else
            PlayOneShotSound("Music/duality/gameplaytransition.ogg", 0.65, 0)
        end

        if TimesWon % SHOW_CRAVEI_LEVEL_INTERVAL == 0 then
            DoCraveiProcedure()
        else
            uiManager.ShowUI("Endgame", gameEndData)
        end
        
    end
end


function DoCraveiProcedure()
    coroutine.start(function()
        local curTime = time:GetElapsedTime()
        local animStartTime = curTime
        local animEndTime = curTime + 2.5

        local transitionDuration = 0.75
        local dancingFlipInterval = 0.25
        local timeNextDancingFlip = curTime + dancingFlipInterval
        local craveiDancingGuyNode = craveiContent:GetChild("craveiDancingGuy")
        ---@type StaticSprite2D
        local craveiDancingGuySprite = craveiDancingGuyNode:GetComponent("StaticSprite2D")

        local craveiScoreTextNode = craveiContent:GetChild("craveiScoreText")
        ---@type Text3D
        local craveiScoreText = craveiScoreTextNode:GetComponent("Text3D")
        craveiScoreText:SetText(TimesWon)

        while curTime < animEndTime do
            coroutine.sleep(0.01)
            curTime = time:GetElapsedTime()

            local animTimeLeft = animEndTime - curTime
            local animTimeElapsed = curTime - animStartTime
            
            -- cravei transition in anim
            if animTimeElapsed < transitionDuration then
                craveiContent:SetScale(animTimeElapsed / transitionDuration)
            end

            -- cravei transition out anim
            if animTimeLeft < transitionDuration then
                craveiContent:SetScale(animTimeLeft / transitionDuration)
            end

            -- dancing guy's dance!
            if curTime > timeNextDancingFlip then
                craveiDancingGuySprite.flipX = not craveiDancingGuySprite.flipX
                timeNextDancingFlip = curTime + dancingFlipInterval
            end
        end

        craveiContent:SetScale(0.0)

        uiManager.ShowUI("Endgame", { hasWon = true })

    end)
end


function Cleanup()
    if DynamicContentParent ~= nil then
        DynamicContentParent:Remove()
        DynamicContentParent = nil

        UnflippedScenarioContentParent:Remove()
        UnflippedScenarioContentParent = nil

        FlippedScenarioContentParent:Remove()
        FlippedScenarioContentParent = nil

        flippedElements = {}
        unflippedElements = {}

        CurGameState = GAMESTATE_ENDED
    end
end

function SpawnEffect(node)
    local particleNode = Scene_:CreateChild("Emitter")
    particleNode:SetPosition2D(node.position)
    particleNode:SetScale(node.scale.x * 3)
    ---@type ParticleEmitter2D
    local particleEmitter = particleNode:CreateComponent("ParticleEmitter2D")
    particleEmitter:SetLayer(2)
    particleEmitter.effect = cache:GetResource("ParticleEffect2D", "Urho2D/duality/folhas.pex")
    
    coroutine.start(function()
        coroutine.sleep(1.5)
        particleNode:Remove()
    end)
end


---@param from Vector2
---@param to Vector2
---@return number
function DistanceBetween(from, to)

    ---@type Vector2
    local subtractedVec = to - from

    return subtractedVec:Length()

end

---@param repulsors table
---@param extraPaddingFromBounds number
---@return Vector2
function GetRandomPositionInWorld(repulsors, extraPaddingFromBounds)

    if extraPaddingFromBounds == nil then
        extraPaddingFromBounds = 0.0
    end

    local attempts = 0
    local padding = 0.1
    local pickedPos = Vector2(
        Random((-WORLD_BOUNDS_UNSCALED.x) + padding + extraPaddingFromBounds, (WORLD_BOUNDS_UNSCALED.x) - padding - extraPaddingFromBounds),
        Random((-WORLD_BOUNDS_UNSCALED.y) + padding + extraPaddingFromBounds, (WORLD_BOUNDS_UNSCALED.y) - padding - extraPaddingFromBounds)
    )
    local positionIsValid = true

    while attempts < 10 do
        
        positionIsValid = true

        if repulsors ~= nil then
            for _, repulsor in pairs(repulsors) do
                if DistanceBetween(repulsor.position2D, pickedPos) < 1.25 then
                    positionIsValid = false
                    break
                end
            end
        end

        if positionIsValid then
            break
        else
            pickedPos = Vector2(Random(-WORLD_BOUNDS_UNSCALED.x, WORLD_BOUNDS_UNSCALED.x), Random(-WORLD_BOUNDS_UNSCALED.y, WORLD_BOUNDS_UNSCALED.y))
            attempts = attempts + 1
        end

    end

    return pickedPos
end

function SaveScene(initial)
    local filename = DemoFilename
    if not initial then
        filename = DemoFilename .. "InGame"
    end

    Scene_:SaveXML(fileSystem:GetProgramDir() .. "Data/Scenes/" .. filename .. ".xml")
end
