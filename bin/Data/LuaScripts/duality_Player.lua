local uiManager = require "LuaScripts/ui/UI_Manager"
---@class DualityPlayer : LuaScriptObject


-- Character2D script object class
---@type DualityPlayer
DualityPlayer = ScriptObject()

local bigHeadAnimTime = 0.75

---@type Vector2
local bigHeadBigScaleFactor = 300

function DualityPlayer:Start()

    self.isFlipped = false
    self.canCountTime = false
    self.canMove = true
    self.hasAnkh = false

    self.flipImmunityTime = 0.0
    self.bigHeadAnimTimePassed = 0.0

    ---@type ProgressBar
    self.timeBar = nil

    local spriteNode = self.node:CreateChild("sprite")

    ---@type AnimatedSprite2D
    self.animatedSprite = spriteNode:CreateComponent("AnimatedSprite2D")
    self.animatedSprite.animationSet = cache:GetResource("AnimationSet2D", "Urho2D/duality/player.scml")
    self.animatedSprite.animation = "idle"
    self.animatedSprite:SetLayer(4)

    spriteNode:SetScale2D(Vector2.ONE * 2.5)

    ---@type RigidBody2D
    self.body = self.node:CreateComponent("RigidBody2D")
    self.body:SetGravityScale(0.0)
    self.body.bodyType = BT_DYNAMIC
    self.body.allowSleep = false

    ---@type CollisionCircle2D
    self.colshape = self.node:CreateComponent("CollisionCircle2D")
    self.colshape.radius = 1.1 -- Set shape size
    self.colshape.friction = 0.0 -- Set friction
    self.colshape.restitution = 0.1 -- Slight bounce
    self.colshape:SetCategoryBits(COLMASK_PLAYER)

    self.ankhVisualNode = self.node:CreateChild("ankhVisualNode")
    self.ankhVisualNode.position2D = Vector2(0.0, 2.0)

    ---@type StaticSprite2D
    local ankhSprite = self.ankhVisualNode:CreateComponent("StaticSprite2D")
    ankhSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/ankh/ankh_static.png")
    ankhSprite:SetLayer(4)

    self.ankhVisualNode:SetScale2D(1.5, 1.0)

    -- hide ankh visual until the plyr gets the ankh
    self.ankhVisualNode:SetEnabled(false)


    self.introHeadNode = self.node:CreateChild("introHeadNode")
    self.introHeadNode.position2D = Vector2.UP * 0.5

    ---@type StaticSprite2D
    self.introHeadSprite = self.introHeadNode:CreateComponent("StaticSprite2D")
    self.introHeadSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/cabecaEsqueleto.png")
    self.introHeadSprite:SetLayer(6)

    self.sparkNode = self.node:CreateChild("endSpark")

    ---@type AnimatedSprite2D
    self.sparkSprite = self.sparkNode:CreateComponent("AnimatedSprite2D")
    self.sparkSprite.animationSet = cache:GetResource("AnimationSet2D", "Urho2D/duality/brilho.scml")
    self.sparkSprite.animation = "idle"
    self.sparkSprite:SetLoopMode(LM_FORCE_CLAMPED)
    self.sparkSprite:SetLayer(5) -- Put character over tile map (which is on layer 0)

    self.sparkNode:SetScale2D(Vector2.ONE * 10.0)
    self.sparkNode:SetEnabled(false)

    self:Flip(self.isFlipped)

    self:SubscribeToEvent(self.node, "NodeBeginContact2D", "DualityPlayer:HandleCollisionStart")

    DualityPlayerNode:SetScale(0.2)
end

function DualityPlayer:Update(timeStep)

    -- round start/end transition anim
    if CurGameState ~= GAMESTATE_PLAYING then
        if self.introHeadNode:IsEnabledSelf() then
            self.bigHeadAnimTimePassed = self.bigHeadAnimTimePassed + timeStep

            if self.bigHeadAnimTimePassed >= bigHeadAnimTime then
                self.introHeadNode:SetEnabled(false)
                self.sparkNode:SetEnabled(false)

                if CurGameState == GAMESTATE_STARTING then
                    CurGameState = GAMESTATE_PLAYING
                else
                    EndGame(true)
                end

                return
            end

            if CurGameState == GAMESTATE_STARTING then
                self.introHeadNode:SetScale2D(Vector2.ONE * Lerp(bigHeadBigScaleFactor, 1.0, self.bigHeadAnimTimePassed / bigHeadAnimTime))
            else
                self.introHeadNode:SetScale2D(Vector2.ONE * Lerp(1.0, bigHeadBigScaleFactor, self.bigHeadAnimTimePassed / bigHeadAnimTime))
            end
        end
        return
    end

    if self.canCountTime and self.timeBar ~= nil then
        LevelTimeLeft = LevelTimeLeft - timeStep
        self.timeBar:SetValue(LevelTimeLeft/TimeForCurrentLevel)
        UpdateWorld()

        if self.flipImmunityTime > 0 then
            self.flipImmunityTime = self.flipImmunityTime - timeStep
        end

        if LevelTimeLeft <= 0 then
            EndGame(false)
        end
    end


    local node = self.node

    -- Set direction
    ---@type Vector3
    local moveDir = Vector3.ZERO -- Reset
    local speedX = Clamp(MOVE_SPEED_X / CurCameraZoom, 0.4, MOVE_SPEED_X)
    local speedY = speedX

    if input:GetKeyDown(KEY_LEFT) or input:GetKeyDown(KEY_A) then
        moveDir = moveDir + Vector3.LEFT * speedX
        self.animatedSprite.flipX = true -- Flip sprite (reset to default play on the X axis)
    end
    if input:GetKeyDown(KEY_RIGHT) or input:GetKeyDown(KEY_D) then
        moveDir = moveDir + Vector3.RIGHT * speedX
        self.animatedSprite.flipX = false -- Flip sprite (flip animation on the X axis)
    end

    if not moveDir:Equals(Vector3.ZERO) then
        speedY = speedX * MOVE_SPEED_SCALE
    end

    if input:GetKeyDown(KEY_UP) or input:GetKeyDown(KEY_W) then
        moveDir = moveDir + Vector3.UP * speedY
    end
    if input:GetKeyDown(KEY_DOWN) or input:GetKeyDown(KEY_S) then
        moveDir = moveDir + Vector3.DOWN * speedY
    end

    -- Move
    if not moveDir:Equals(Vector3.ZERO) and self.canMove then
        node:Translate(moveDir * timeStep)
    end

    -- ankh's "unflip on demand" power
    if self.hasAnkh and self.canMove and WorldIsFlipped and input:GetKeyPress(KEY_SPACE) then
        FlipWorld(true)
    end

    -- animation...
    if self.isFlipped then
        self.animatedSprite:SetAnimation("idle_flipped")
    else
        self.animatedSprite:SetAnimation("idle")
    end
    
end


function DualityPlayer:Flip(isFlipped)
    self.isFlipped = isFlipped

    self.flipImmunityTime = PLAYER_FLIP_IMMUNE_INTERVAL

    if self.isFlipped then
        self.colshape:SetCategoryBits(COLMASK_PLAYER_FLIPPED)
    else
        self.colshape:SetCategoryBits(COLMASK_PLAYER)
    end
end

function DualityPlayer:HandleCollisionStart(eventType, eventData)

    if CurGameState ~= GAMESTATE_PLAYING then return end

    --die if we touch an enemy
    ---@type Node
    local otherNode = eventData["OtherNode"]:GetPtr("Node")

    if otherNode:HasTag(TAG_PORTAL) or otherNode:HasTag(TAG_ENEMY) then
        if self.flipImmunityTime <= 0 then
            FlipWorld(true)
        end
    elseif otherNode:HasTag(TAG_ANKH) then
        -- take the ankh!
        PlayOneShotSound("Sounds/duality/gotAnkh.ogg", 0.45, 2000)
        self.hasAnkh = true
        self.ankhVisualNode:SetEnabled(true)
        otherNode:Remove()
    elseif otherNode:HasTag(TAG_WIN_OBJ) and self.hasAnkh then
        CurGameState = GAMESTATE_ENDING
        PlayOneShotSound("Sounds/duality/brilho.ogg", 0.75, 2000)
        self.sparkNode:SetEnabled(true)
        self.animatedSprite:SetAnimation("idle_flipped")
        coroutine.start(function ()
            coroutine.sleep(0.5)

            if (TimesWon + 1) % SHOW_CRAVEI_LEVEL_INTERVAL == 0 then
                -- do the cravei anim instead of the head anim!
                EndGame(true)
            else
                self:SetupBigHeadAnim()
            end

        end)
    end
end

--- sets up the animation responsible for transitioning rounds' start and end
function DualityPlayer:SetupBigHeadAnim()
    self.bigHeadAnimTimePassed = 0.0

    self.introHeadNode:SetEnabled(true)

    if CurGameState == GAMESTATE_STARTING then
        self.introHeadSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/cabecaEsqueleto.png")
        self.introHeadNode:SetScale2D(Vector2.ONE * bigHeadBigScaleFactor)
    else
        self.introHeadSprite.sprite = cache:GetResource("Sprite2D", "Urho2D/duality/cabecaChar.png")
        self.introHeadNode:SetScale2D(Vector2.ONE)
    end
end