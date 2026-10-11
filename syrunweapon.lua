-- =====================================================================
-- BYPASS Ex_Weaponeffects + Weapon Skin Unlocker (PROP ATTACH v3)
-- /skin [ชื่อ] = ใส่สกิน | /skin off = ถอด | /skinlist = ดูรายชื่อ
-- วิธี: สร้าง 3D Object ของสกิน Attach ไปที่มือ + ซ่อนอาวุธเดิม
-- =====================================================================

print("^2[SKIN] >>> โหลดสำเร็จ! /skinlist ดูสกิน | /skin [ชื่อ] ใส่สกิน ^7")
pcall(function()
    TriggerEvent('chat:addMessage', { args = { "^2[SKIN]", "^2โหลดสำเร็จ! /skinlist ดูสกิน | /skin [ชื่อ] ใส่ | /skin off ถอด^0" } })
end)

local active = false
local currentSkinKey = nil
local currentSkinData = nil
local activePropEntity = nil
local holdFxToken = 0
local damageHandlerRegistered = false
local lastEffectTime = 0
local lastHiddenWeaponEntity = nil

local ATTACH_CONFIG = {
    Bone = 28422,
    Pos = { x = 0.055, y = 0.045, z = 0.01 },
    Rot = { x = -77.0, y = -23.0, z = -16.0 },
    RotOrder = 0
}

-- ========== WEAPON TYPE DETECTION ==========
local ALL_WEAPON_NAMES = {
    'WEAPON_POOLCUE', 'WEAPON_POOLCUE0', 'WEAPON_POOLCUE1', 'WEAPON_POOLCUE2',
    'WEAPON_POOLCUE3', 'WEAPON_POOLCUE4', 'WEAPON_POOLCUE5', 'WEAPON_POOLCUE6',
    'WEAPON_POOLCUE7', 'WEAPON_POOLCUE8', 'WEAPON_POOLCUE9', 'WEAPON_POOLCUE10',
    'WEAPON_POOLCUE14DAY', 'WEAPON_POOLCUEWAR',
    'WEAPON_BOTTLE', 'WEAPON_BOTTLE0', 'WEAPON_BOTTLE1', 'WEAPON_BOTTLE2',
    'WEAPON_BOTTLE3', 'WEAPON_BOTTLE4', 'WEAPON_BOTTLE5', 'WEAPON_BOTTLE6',
    'WEAPON_BOTTLE7', 'WEAPON_BOTTLE8', 'WEAPON_BOTTLE9',
    'WEAPON_KNIFE', 'WEAPON_DAGGER', 'WEAPON_SWITCHBLADE',
}

local WEAPON_TYPE_MAP = {
    WEAPON_POOLCUE='poolcue', WEAPON_POOLCUE0='poolcue', WEAPON_POOLCUE1='poolcue',
    WEAPON_POOLCUE2='poolcue', WEAPON_POOLCUE3='poolcue', WEAPON_POOLCUE4='poolcue',
    WEAPON_POOLCUE5='poolcue', WEAPON_POOLCUE6='poolcue', WEAPON_POOLCUE7='poolcue',
    WEAPON_POOLCUE8='poolcue', WEAPON_POOLCUE9='poolcue', WEAPON_POOLCUE10='poolcue',
    WEAPON_POOLCUE14DAY='poolcue', WEAPON_POOLCUEWAR='poolcue',
    WEAPON_BOTTLE='bottle', WEAPON_BOTTLE0='bottle', WEAPON_BOTTLE1='bottle',
    WEAPON_BOTTLE2='bottle', WEAPON_BOTTLE3='bottle', WEAPON_BOTTLE4='bottle',
    WEAPON_BOTTLE5='bottle', WEAPON_BOTTLE6='bottle', WEAPON_BOTTLE7='bottle',
    WEAPON_BOTTLE8='bottle', WEAPON_BOTTLE9='bottle',
    WEAPON_KNIFE='bottle', WEAPON_DAGGER='bottle', WEAPON_SWITCHBLADE='bottle',
}

local hashToType = {}

local function BuildHashCache()
    for _, name in ipairs(ALL_WEAPON_NAMES) do
        local h = GetHashKey(name)
        hashToType[h] = WEAPON_TYPE_MAP[name]
    end
end

local function GetWeaponType(wHash)
    if not wHash or wHash == 0 then return nil end
    if wHash == GetHashKey('WEAPON_UNARMED') then return nil end
    local t = hashToType[wHash]
    if t then return t end
    for _, name in ipairs(ALL_WEAPON_NAMES) do
        local h = GetHashKey(name)
        if (wHash < 0 and wHash + 0x100000000 == h) or (wHash > 0 and wHash - 0x100000000 == h) then
            hashToType[wHash] = WEAPON_TYPE_MAP[name]
            return WEAPON_TYPE_MAP[name]
        end
    end
    return nil
end

local function IsHoldingWeapon()
    local ped = PlayerPedId()
    local cur = GetSelectedPedWeapon(ped)
    if cur == GetHashKey('WEAPON_UNARMED') then return false, nil end
    return true, cur
end

-- ========== SKIN DATABASE ==========
local SKIN_DB = {
    bunny_pool    = { label="BUNNY",       weaponType="poolcue", skinModel="things_freebunny_poolcue",      component="COMPONENT_POOL_SKIN_01" },
    syrus_pool    = { label="SYRUS",       weaponType="poolcue", skinModel="w_me_poolsyrus",                component="COMPONENT_POOL_SKIN_02" },
    spark_pool    = { label="SPARK OVER",  weaponType="poolcue", skinModel="lazy_sparkover_poolcue",        component="COMPONENT_POOL_SKIN_03" },
    sleepy_pool   = { label="SLEEPY",      weaponType="poolcue", skinModel="bbg_wp26_poolcue",              component="COMPONENT_POOL_SKIN_04" },
    tiger_pool    = { label="WHITE TIGER", weaponType="poolcue", skinModel="sharkz_poolcue_white_tiger",    component="COMPONENT_POOL_SKIN_05" },
    syrus_bottle  = { label="SYRUS",       weaponType="bottle",  skinModel="w_me_knife_syrus",              component="COMPONENT_BOTTLE_SKIN_01" },
    spark_bottle  = { label="SPARK OVER",  weaponType="bottle",  skinModel="lazy_sparkover_bottle",         component="COMPONENT_BOTTLE_SKIN_02" },
    sleepy_bottle = { label="SLEEPY",      weaponType="bottle",  skinModel="bbg_wp26_dagger",               component="COMPONENT_BOTTLE_SKIN_03" },
    tiger_bottle  = { label="WHITE TIGER", weaponType="bottle",  skinModel="sharkz_bottle_white_tiger",     component="COMPONENT_BOTTLE_SKIN_04" },
}

-- ========== PROP MANAGEMENT ==========
local function RestoreWeaponVisibility()
    if lastHiddenWeaponEntity and DoesEntityExist(lastHiddenWeaponEntity) then
        SetEntityVisible(lastHiddenWeaponEntity, true, false)
        ResetEntityAlpha(lastHiddenWeaponEntity)
    end
    lastHiddenWeaponEntity = nil
end

local function SafeDeleteProp()
    if activePropEntity then
        pcall(function()
            if DoesEntityExist(activePropEntity) then
                DetachEntity(activePropEntity, true, true)
                SetEntityAsMissionEntity(activePropEntity, true, true)
                DeleteEntity(activePropEntity)
            end
        end)
        activePropEntity = nil
    end
    RestoreWeaponVisibility()
end

local function CreateSkinProp(ped, modelName)
    SafeDeleteProp()

    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) then return false end

    RequestModel(modelHash)
    local tries = 0
    while not HasModelLoaded(modelHash) and tries < 50 do Wait(10) tries = tries + 1 end
    if not HasModelLoaded(modelHash) then return false end

    local coords = GetEntityCoords(ped)
    activePropEntity = CreateObject(modelHash, coords.x, coords.y, coords.z - 50.0, true, true, false)
    if not activePropEntity or not DoesEntityExist(activePropEntity) then return false end

    SetEntityCollision(activePropEntity, false, false)
    pcall(SetEntityCompletelyDisableCollision, activePropEntity, false, true)
    pcall(DisableCamCollisionForObject, activePropEntity)

    local att = ATTACH_CONFIG
    local boneIndex = GetPedBoneIndex(ped, att.Bone)
    if boneIndex == -1 then boneIndex = GetPedBoneIndex(ped, 28422) end

    AttachEntityToEntity(
        activePropEntity, ped, boneIndex,
        att.Pos.x, att.Pos.y, att.Pos.z,
        att.Rot.x, att.Rot.y, att.Rot.z,
        true, true, false, false, att.RotOrder, true
    )

    SetModelAsNoLongerNeeded(modelHash)
    return true
end

-- ========== PTFX ==========
local loadedPtfx = {}

local function EnsurePtfx(asset)
    if not asset then return false end
    if loadedPtfx[asset] then return true end
    RequestNamedPtfxAsset(asset)
    local t = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(asset) and GetGameTimer() < t do Wait(10) end
    if HasNamedPtfxAssetLoaded(asset) then loadedPtfx[asset] = true return true end
    return false
end

local function GetEffectConfig(skinData)
    if not skinData then return nil end
    local h = GetHashKey(skinData.skinModel)
    local cfg = nil
    pcall(function() if Config and Config.Weapon then cfg = Config.Weapon[h] end end)
    return cfg
end

-- ========== HOLD FX ==========
local function PlayHoldEffect(ped, skinData)
    local cfg = GetEffectConfig(skinData)
    if not cfg or not cfg.EffectCarry or not cfg.EffectCarry.Effect then return end
    local we = GetCurrentPedWeaponEntityIndex(ped)
    local useEnt = we ~= nil and we ~= 0 and DoesEntityExist(we)

    for _, ef in ipairs(cfg.EffectCarry.Effect) do
        if ef.enabled ~= false and ef.Asset and ef.Name and EnsurePtfx(ef.Asset) then
            local p = ef.position or {}
            UseParticleFxAssetNextCall(ef.Asset)
            if useEnt then
                StartParticleFxNonLoopedOnEntity(ef.Name, we,
                    p.posx or 0.0, p.posy or 0.0, p.posz or 0.0,
                    p.rotx or 0.0, p.roty or 0.0, p.rotz or 0.0,
                    p.scale or 1.0, false, false, false)
            else
                StartParticleFxNonLoopedOnPedBone(ef.Name, ped,
                    p.posx or 0.0, p.posy or 0.0, p.posz or 0.0,
                    p.rotx or 0.0, p.roty or 0.0, p.rotz or 0.0,
                    57005, p.scale or 1.0, false, false, false)
            end
        end
    end
end

local function StartHoldFxLoop(skinData)
    holdFxToken = holdFxToken + 1
    local myToken = holdFxToken
    CreateThread(function()
        while myToken == holdFxToken and active do
            local ped = PlayerPedId()
            local ok, cur = IsHoldingWeapon()
            if ok then
                local wt = GetWeaponType(cur)
                if wt == skinData.weaponType or wt == nil then
                    PlayHoldEffect(ped, skinData)
                end
            end
            local iv = 1000
            local cfg = GetEffectConfig(skinData)
            if cfg and cfg.EffectCarry and cfg.EffectCarry.interval then iv = cfg.EffectCarry.interval end
            Wait(iv)
        end
    end)
end

-- ========== HIT/KILL ==========
local function PlayHitEffect(skinData, victimPed, isDead)
    local cfg = GetEffectConfig(skinData)
    if not cfg then return end
    local now = GetGameTimer()
    if now - lastEffectTime < 3000 then return end
    lastEffectTime = now

    local ew = cfg.EffectWeapon
    if not ew then return end
    local play = (ew.CriticalEffect == 'kill' and isDead)
        or (ew.CriticalEffect == 'cri' and isDead)
        or (ew.CriticalEffect ~= 'kill' and ew.CriticalEffect ~= 'cri')
    if not play then return end

    local entries = type(ew.ParticleEffect) == 'table' and ew.ParticleEffect or (ew.NameParticleEffect and {ew} or {})
    for _, ef in ipairs(entries) do
        local np = ef.NameParticleEffect
        if np and np[1] and np[2] then
            CreateThread(function()
                if EnsurePtfx(np[1]) then
                    UseParticleFxAssetNextCall(np[1])
                    StartParticleFxNonLoopedOnPedBone(np[2], victimPed,
                        ef.offsetX or ew.offsetX or 0.0, ef.offsetY or ew.offsetY or 0.0,
                        ef.offsetZ or ew.offsetZ or 0.05, ef.rotationX or ew.rotationX or 0.0,
                        ef.rotationY or ew.rotationY or 90.0, ef.rotationZ or ew.rotationZ or 0.0,
                        31086, ef.Scale or ew.Scale or 1.0, false, false, false)
                end
            end)
        end
    end
    if cfg.EffectImg then
        pcall(function()
            SendNUIMessage({ action='Effect', image=cfg.EffectImg.ImageShow,
                time=cfg.EffectImg.TimeImage or 3, SoundName=cfg.EffectImg.SoundName,
                SoundValue=cfg.EffectImg.SoundValue or 0.4 })
        end)
    end
end

local function RegisterDamageHandler()
    if damageHandlerRegistered then return end
    damageHandlerRegistered = true
    AddEventHandler("gameEventTriggered", function(ev, ed)
        if not active or not currentSkinKey or ev ~= "CEventNetworkEntityDamage" then return end
        local victim, attacker = ed[1], ed[2]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped then return end
        local sd = SKIN_DB[currentSkinKey]
        if sd then PlayHitEffect(sd, victim, ed[4] == 1 or IsEntityDead(victim)) end
    end)
end

-- ========== MAIN LOOP: Prop Attach + ซ่อนอาวุธเดิม ==========
CreateThread(function()
    Wait(2000)
    BuildHashCache()

    while true do
        local ped = PlayerPedId()
        local shouldHaveProp = false

        if DoesEntityExist(ped) and not IsEntityDead(ped) and active and currentSkinData then
            local curWeapon = GetSelectedPedWeapon(ped)
            local isUnarmed = (curWeapon == GetHashKey('WEAPON_UNARMED') or curWeapon == 0)

            if not isUnarmed then
                local wt = GetWeaponType(curWeapon)
                if wt and wt == currentSkinData.weaponType then
                    local wepEntity = GetCurrentPedWeaponEntityIndex(ped)
                    local hasWeaponEntity = wepEntity and wepEntity ~= 0 and DoesEntityExist(wepEntity)

                    if hasWeaponEntity then
                        shouldHaveProp = true
                        if not activePropEntity or not DoesEntityExist(activePropEntity) then
                            CreateSkinProp(ped, currentSkinData.skinModel)
                        end
                        SetEntityVisible(wepEntity, false, false)
                        SetEntityAlpha(wepEntity, 0, false)
                        lastHiddenWeaponEntity = wepEntity
                    end
                end
            end
        end

        if not shouldHaveProp and activePropEntity then
            SafeDeleteProp()
        end

        Wait(0)
    end
end)

-- ========== ANTI-DETECT ==========
local origTSE = TriggerServerEvent
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == "string" then
        local lo = string.lower(eventName)
        if lo:find("weaponskin") or lo:find("weapon_skin") or lo:find("ex_weapon") then
            if lo:find("report") or lo:find("guard") or lo:find("detect") or lo:find("kick")
                or lo:find("cheat") or lo:find("check") or lo:find("log") or lo:find("ban")
                or lo:find("verify") or lo:find("anticheat") or lo:find("validate") or lo:find("security") then
                return
            end
        end
    end
    return origTSE(eventName, ...)
end

-- ========== HELPERS ==========
local function SendMsg(t)
    print("^3[SKIN]^7 " .. t)
    pcall(function() TriggerEvent('chat:addMessage', { args = {"[SKIN]", t} }) end)
end

-- ========== /skinlist ==========
RegisterCommand('skinlist', function()
    print("^2===================== [SKIN LIST] =====================^7")
    print("^3--- POOLCUE (ไม้พูล) ---^7")
    for key, data in pairs(SKIN_DB) do
        if data.weaponType == "poolcue" then
            local mk = (key == currentSkinKey) and " ^2<< EQUIPPED^7" or ""
            local fx = ""
            local cfg = GetEffectConfig(data)
            if cfg then
                local p = {}
                if cfg.EffectWeapon then p[#p+1]="FX" end
                if cfg.EffectCarry and cfg.EffectCarry.Effect then p[#p+1]="HAND" end
                if cfg.EffectImg and cfg.EffectImg.ImageShow then p[#p+1]="SCR" end
                if cfg.EffectImg and cfg.EffectImg.SoundName then p[#p+1]="SND" end
                if #p>0 then fx=(" ^5[%s]^7"):format(table.concat(p,"+")) end
            end
            print(("  ^6/skin %-15s^7 = %s%s%s"):format(key, data.label, fx, mk))
        end
    end
    print("^3--- BOTTLE/KNIFE (ขวด/มีด) ---^7")
    for key, data in pairs(SKIN_DB) do
        if data.weaponType == "bottle" then
            local mk = (key == currentSkinKey) and " ^2<< EQUIPPED^7" or ""
            local fx = ""
            local cfg = GetEffectConfig(data)
            if cfg then
                local p = {}
                if cfg.EffectWeapon then p[#p+1]="FX" end
                if cfg.EffectCarry and cfg.EffectCarry.Effect then p[#p+1]="HAND" end
                if cfg.EffectImg and cfg.EffectImg.ImageShow then p[#p+1]="SCR" end
                if cfg.EffectImg and cfg.EffectImg.SoundName then p[#p+1]="SND" end
                if #p>0 then fx=(" ^5[%s]^7"):format(table.concat(p,"+")) end
            end
            print(("  ^6/skin %-15s^7 = %s%s%s"):format(key, data.label, fx, mk))
        end
    end
    print("")
    print("^3วิธีใช้:^7 ถืออาวุธแล้วพิมพ์ ^6/skin [ชื่อ]^7 เช่น ^6/skin syrus^7")
    print("^3ถอด:^7 ^1/skin off^7 | ^3Debug:^7 ^6/skindebug^7")
    print("^2========================================================^7")
    SendMsg("^2รายชื่อสกินขึ้นใน F8 แล้ว^0")
end, false)

-- ========== /skindebug ==========
RegisterCommand('skindebug', function()
    local ped = PlayerPedId()
    local cur = GetSelectedPedWeapon(ped)
    local we = GetCurrentPedWeaponEntityIndex(ped)
    local wt = GetWeaponType(cur)

    print("^2========== [SKIN DEBUG] ==========^7")
    print(("  ^3Weapon Hash:^7 %s (0x%X)"):format(cur, cur & 0xFFFFFFFF))
    print(("  ^3Type:^7 %s | WeaponEntity: %s"):format(tostring(wt or "UNKNOWN"), tostring(we)))
    print(("  ^3Active:^7 %s | Skin: %s"):format(tostring(active), tostring(currentSkinKey or "none")))
    print(("  ^3Prop:^7 %s | Exists: %s"):format(
        tostring(activePropEntity),
        tostring(activePropEntity and DoesEntityExist(activePropEntity) or false)
    ))

    if currentSkinData then
        local modelHash = GetHashKey(currentSkinData.skinModel)
        print(("  ^3skinModel:^7 %s"):format(currentSkinData.skinModel))
        print(("  ^3modelHash:^7 %s | InCdimage: %s"):format(modelHash, tostring(IsModelInCdimage(modelHash))))
    end

    if we and we ~= 0 and DoesEntityExist(we) then
        print(("  ^3WeaponEntity visible:^7 %s | alpha: %s"):format(
            tostring(IsEntityVisible(we)),
            tostring(GetEntityAlpha(we))
        ))
    end

    print("^2===================================^7")
    SendMsg("^2Debug ขึ้น F8 แล้ว^0")
end, false)

-- ========== /skin ==========
RegisterCommand('skin', function(_, args)
    local input = args[1]
    local ped = PlayerPedId()

    if not input or input == '' then SendMsg("^3/skinlist ดูสกิน | /skin [ชื่อ] ใส่ | /skin off ถอด^0") return end
    if input:lower() == 'list' then ExecuteCommand('skinlist') return end
    if input:lower() == 'debug' then ExecuteCommand('skindebug') return end

    if input:lower() == 'off' or input:lower() == 'clear' or input:lower() == 'default' then
        holdFxToken = holdFxToken + 1
        SafeDeleteProp()
        currentSkinKey = nil
        currentSkinData = nil
        active = false
        local we = GetCurrentPedWeaponEntityIndex(ped)
        if we and we ~= 0 and DoesEntityExist(we) then
            SetEntityVisible(we, true, false)
            ResetEntityAlpha(we)
        end
        SendMsg("^1[OFF]^0 ถอดสกินและเอฟเฟคทั้งหมดแล้ว")
        return
    end

    local ok, held = IsHoldingWeapon()
    if not ok then SendMsg("^1[ERROR]^0 ถืออาวุธก่อนแล้วค่อยใส่สกิน!") return end

    local wt = GetWeaponType(held)
    local sl = input:lower()
    local fk, fd = nil, nil

    if SKIN_DB[input] then fk, fd = input, SKIN_DB[input] end
    if not fk then
        for k, d in pairs(SKIN_DB) do
            if k:lower() == sl then fk, fd = k, d break end
        end
    end
    if not fk then
        local bk, bd = nil, nil
        for k, d in pairs(SKIN_DB) do
            if k:lower():find(sl, 1, true) or d.label:lower():find(sl, 1, true) then
                if wt and d.weaponType == wt then fk, fd = k, d break
                elseif not bk then bk, bd = k, d end
            end
        end
        if not fk and bk then fk, fd = bk, bd end
    end
    if not fk then SendMsg(("^1[NOT FOUND]^0 ไม่พบสกิน '%s' (/skinlist ดูรายชื่อ)"):format(input)) return end

    holdFxToken = holdFxToken + 1
    SafeDeleteProp()

    currentSkinKey = fk
    currentSkinData = fd
    active = true

    CreateSkinProp(ped, fd.skinModel)
    StartHoldFxLoop(fd)
    RegisterDamageHandler()

    SendMsg(("^2[OK]^0 สวมสกิน ^6%s^0 (%s) สำเร็จ!"):format(fd.label, fk))
end, false)
