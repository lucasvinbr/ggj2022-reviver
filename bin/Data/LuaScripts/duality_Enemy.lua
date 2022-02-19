---@class DualityEnemy : LuaScriptObject

---@type DualityEnemy
DualityEnemy = ScriptObject()

DualityEnemy.__index = DualityEnemy

---@class EnemyData
---@field isNoClip boolean
---@field looksPath string

---@type EnemyData[]
local flippedEnemyDatas = {
    { isNoClip = true, looksPath = "Urho2D/duality/enemies/fantasma.scml"}
}

---@type EnemyData[]
local unflippedEnemyDatas = {
    { isNoClip = false, looksPath = "Urho2D/duality/enemies/gato.scml"},
    { isNoClip = true, looksPath = "Urho2D/duality/enemies/abelhas.scml"}
}

function DualityEnemy:Start()
    log:Write(LOG_DEBUG, "Enemy start!")

    self.node:SetScale2D(Vector2.ONE * 0.45)

    self.moveSpeed = MOVE_SPEED_X / 2
    self.alwaysChargesAtPlayer = false
    self.chargingAtPlayer = false
    self.moveTarget = self.node.position2D
    self.chargeDistance = 2.0

    self.moveDir = Vector3.ZERO

    ---@type AnimatedSprite2D
    self.animatedSprite = self.node:CreateComponent("AnimatedSprite2D")
    self.animatedSprite:SetLayer(3)

    ---@type RigidBody2D
    self.rigidbody = self.node:CreateComponent("RigidBody2D")
    self.rigidbody.bodyType = BT_KINEMATIC
    self.rigidbody.allowSleep = false
    self.rigidbody:SetGravityScale(0.0)

    coroutine.start(function ()
        while self.node ~= nil do
            coroutine.sleep(1.0)
            if DistanceBetween(self.node.position2D, DualityPlayerNode.position2D) < self.chargeDistance then
                self.chargingAtPlayer = true
            else
                if not self.alwaysChargesAtPlayer then
                    self.chargingAtPlayer = false
                end
            end
        end
    end)
end

--- sets up some of the enemy's data (like its looks and collider) based on whether it's in the flipped world or not
function DualityEnemy:SetupFlipDependentData(isFlipped)
    ---@type CollisionCircle2D
    self.collisionShape = self.node:CreateComponent("CollisionCircle2D")
    self.collisionShape:SetRadius(0.5)
    self.collisionShape:SetFriction(0.8)

    ---@type EnemyData
    local enemyData = nil

    if isFlipped then
        enemyData = flippedEnemyDatas[RandomInt(1, #flippedEnemyDatas + 1)]
        self.collisionShape:SetCategoryBits(COLMASK_OBJS_FLIPPED)

        if enemyData.isNoClip then
            self.collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED)
        else
            self.rigidbody.bodyType = BT_DYNAMIC
            self.collisionShape:SetMaskBits(COLMASK_PLAYER_FLIPPED + COLMASK_OBJS_FLIPPED)
        end
    else
        enemyData = unflippedEnemyDatas[RandomInt(1, #unflippedEnemyDatas + 1)]
        self.collisionShape:SetCategoryBits(COLMASK_OBJS)
        self.collisionShape:SetMaskBits(COLMASK_PLAYER)

        if enemyData.isNoClip then
            self.collisionShape:SetMaskBits(COLMASK_PLAYER)
        else
            self.rigidbody.bodyType = BT_DYNAMIC
            self.collisionShape:SetMaskBits(COLMASK_PLAYER + COLMASK_OBJS)
        end
    end

    self.collisionShape:SetTrigger(enemyData.isNoClip)

    self.animatedSprite.animationSet = cache:GetResource("AnimationSet2D", enemyData.looksPath)
    self.animatedSprite.animation = "idle"
    
    self.node:AddTag(TAG_ENEMY)
end

function DualityEnemy:Update(timeStep)

    if CurGameState ~= GAMESTATE_PLAYING then
        self.animatedSprite:SetAnimationEnabled(false)
        return
    else
        self.animatedSprite:SetAnimationEnabled(true)
    end

    local node = self.node
    local moveSpeed = self.moveSpeed

    if not self.chargingAtPlayer then
        -- walk slower when not in combat
        moveSpeed = moveSpeed / 2
        self.moveTarget = self.node.position2D
    else
        self.moveTarget = DualityPlayerNode.position2D
    end

    ---@type Vector2
    local moveDir = (self.moveTarget - node.position2D):Normalized()
    local distanceToTarget = DistanceBetween(node.position2D, self.moveTarget)

    if distanceToTarget > 0.1 then
        node:Translate(Vector3(moveDir.x, moveDir.y, 0) * moveSpeed * timeStep)
        self.animatedSprite.flipX = moveDir.x > 0
    end

end