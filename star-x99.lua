-- ============================================================================
-- AQUA SERVER - ESX_RP-WEAPON-SKIN BYPASS (Poolcue Only)
-- /home <skin>  |  /homeoff  |  /homelist
-- ============================================================================
print("^2[AQUA-SKIN] Bypass loaded. /home <skin> | /homeoff | /homelist^7")

local active = false
local skinId = nil
local skinModel = nil
local propEntity = nil
local propModelName = nil
local loopRunning = false
local dmgReady = false
local lastKill = 0
local RES = "esx_rp-weapon-skin"

-- ── Poolcue weapon hashes ──
local POOLCUE_HASHES = {}
for _, name in ipairs({
    "WEAPON_POOLCUE","WEAPON_POOLCUE_V1","WEAPON_POOLCUE_V2",
    "WEAPON_POOLCUE_V3","WEAPON_POOLCUE_V4","WEAPON_POOLCUE_V5",
    "WEAPON_POOLCUE_0","WEAPON_POOLCUE_1","WEAPON_POOLCUE_2",
    "WEAPON_POOLCUE_3","WEAPON_POOLCUE_4","WEAPON_POOLCUE_5",
    "WEAPON_POOLCUE0","WEAPON_POOLCUE1","WEAPON_POOLCUE2",
    "WEAPON_POOLCUE3","WEAPON_POOLCUE4","WEAPON_POOLCUE5",
    "WEAPON_POOLCUE_RENT","WEAPON_POOLCUE14DAY","WEAPON_POOLCUEWAR",
}) do
    POOLCUE_HASHES[GetHashKey(name)] = true
end

local function isPoolcue(wHash)
    return POOLCUE_HASHES[wHash] == true
end

-- ── Attach offset (จาก cfg.weapon_offset_helper["WEAPON_POOLCUE"]) ──
local PX, PY, PZ = 0.0800, -0.0250, -0.0200
local RX, RY, RZ = -85.0, -16.0, -23.0
local BONE = 57005

-- ── Skin Database: skin_id → { model, name, ptfx, kill } ──
local SKINS = {
    ["aqua_skin_1"] = {
        model = "weapon_promote_1",
        name = "Aqua Skin Di wa",
        ptfx = { dict = "weapon_event_effect", eff = "weapon_event_b1", freq = 1500, bone = 28422, scale = 0.3 },
        kill = { dict = "weapon_event_particle", eff = "weapon_event_particleb1", scale = 1.5 },
    },
    ["weapon_lz_halloween_pool_lv1"] = {
        model = "lz_halloween_pool",
        name = "HW Poolcue (NT) Lv1",
    },
    ["weapon_lz_halloween_pool_lv2"] = {
        model = "lz_halloween_pool",
        name = "HW Poolcue (NT) Lv2",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx", freq = 1500, bone = 28422, scale = 0.7 },
    },
    ["weapon_lz_halloween_pool_lv3"] = {
        model = "lz_halloween_pool",
        name = "HW Poolcue (NT) Lv3",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx", freq = 1500, bone = 28422, scale = 0.7 },
        kill = { dict = "lz_halloween_fx", eff = "halloween_hit", scale = 1.0 },
    },
    ["weapon_lz_halloween_pool_pink_lv1"] = {
        model = "lz_halloween_pool_pink",
        name = "HW Pink Poolcue (NT) Lv1",
    },
    ["weapon_lz_halloween_pool_pink_lv2"] = {
        model = "lz_halloween_pool_pink",
        name = "HW Pink Poolcue (NT) Lv2",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx_pink", freq = 1500, bone = 28422, scale = 0.7 },
    },
    ["weapon_lz_halloween_pool_pink_lv3"] = {
        model = "lz_halloween_pool_pink",
        name = "HW Pink Poolcue (NT) Lv3",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx_pink", freq = 1500, bone = 28422, scale = 0.7 },
        kill = { dict = "lz_halloween_fx", eff = "halloween_hit_pink", scale = 1.0 },
    },
}

-- ── Search ──
local function findSkin(q)
    if not q or q == '' then return nil end
    q = string.lower(q)
    for id in pairs(SKINS) do
        if string.lower(id) == q then return id end
    end
    for id in pairs(SKINS) do
        if string.find(string.lower(id), q, 1, true) then return id end
    end
    for id, d in pairs(SKINS) do
        if string.find(string.lower(d.name), q, 1, true) then return id end
    end
    return nil
end

-- ── Prop ──
local function destroyProp()
    if propEntity and DoesEntityExist(propEntity) then
        SetEntityAsMissionEntity(propEntity, true, true)
        DetachEntity(propEntity, true, true)
        DeleteEntity(propEntity)
    end
    propEntity = nil
    propModelName = nil
end

local function createProp(ped, modelName)
    if propEntity and DoesEntityExist(propEntity) and propModelName == modelName then
        return true
    end
    destroyProp()

    local h = GetHashKey(modelName)
    if not IsModelValid(h) then
        h = GetHashKey(string.upper(modelName))
    end
    if not IsModelValid(h) then
        h = GetHashKey(string.lower(modelName))
    end
    if not IsModelValid(h) then
        print(("^1[AQUA-SKIN] Model invalid: %s^7"):format(modelName))
        return false
    end

    RequestModel(h)
    local deadline = GetGameTimer() + 3000
    while not HasModelLoaded(h) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(h) then
        print(("^1[AQUA-SKIN] Model timeout: %s^7"):format(modelName))
        return false
    end

    local c = GetEntityCoords(ped)
    local obj = CreateObject(h, c.x, c.y, c.z, true, true, false)
    if not DoesEntityExist(obj) then return false end

    SetEntityCompletelyDisableCollision(obj, false, false)
    local bi = GetPedBoneIndex(ped, BONE)
    AttachEntityToEntity(obj, ped, bi, PX, PY, PZ, RX, RY, RZ, true, false, false, false, 0, true)

    propEntity = obj
    propModelName = modelName
    SetModelAsNoLongerNeeded(h)
    return true
end

-- ── PTFX ──
local function loadDict(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local d = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < d do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function playHandFx(ped, fx)
    if not fx or not fx.dict or not fx.eff then return end
    if loadDict(fx.dict) then
        local bi = GetPedBoneIndex(ped, fx.bone or 28422)
        UseParticleFxAsset(fx.dict)
        StartParticleFxNonLoopedOnPedBone(
            fx.eff, ped,
            0.10, 0.0, 0.0,
            0.0, 0.0, 0.0,
            bi, fx.scale or 0.5,
            false, false, false
        )
    end
end

local function playKillFx(victim, kfx)
    if not kfx or not kfx.dict or not kfx.eff then return end
    if loadDict(kfx.dict) then
        local pos = GetEntityCoords(victim)
        local headBone = GetPedBoneIndex(victim, 31086)
        local tx, ty, tz = pos.x, pos.y, pos.z + 0.8
        if headBone ~= -1 then
            local bp = GetWorldPositionOfEntityBone(victim, headBone)
            if bp and bp.z > 0.0 then tx, ty, tz = bp.x, bp.y, bp.z end
        end
        UseParticleFxAsset(kfx.dict)
        StartParticleFxNonLoopedAtCoord(kfx.eff, tx, ty, tz, 0.0, 90.0, 0.0, kfx.scale or 1.0, false, false, false)
    end
end

-- ── Main Loop ──
local function startLoop()
    if loopRunning then return end
    loopRunning = true
    CreateThread(function()
        local lastW = 0
        local nextFx = 0
        while loopRunning and active do
            local ped = PlayerPedId()
            local w = GetSelectedPedWeapon(ped)

            if isPoolcue(w) and not IsEntityDead(ped) and skinModel then
                -- สร้าง prop เมื่อเปลี่ยนอาวุธ หรือ prop หาย
                if w ~= lastW or not propEntity or not DoesEntityExist(propEntity) then
                    createProp(ped, skinModel)
                    lastW = w
                end

                -- ซ่อนอาวุธเดิม (ใช้ SetEntityVisible เหมือนเซิฟจริง)
                local wEnt = GetCurrentPedWeaponEntityIndex(ped)
                if wEnt ~= 0 and DoesEntityExist(wEnt) then
                    SetEntityVisible(wEnt, false, false)
                end

                -- Hand PTFX
                local sk = SKINS[skinId]
                if sk and sk.ptfx then
                    local now = GetGameTimer()
                    if now >= nextFx then
                        playHandFx(ped, sk.ptfx)
                        nextFx = now + (sk.ptfx.freq or 1500)
                    end
                end
            else
                if lastW ~= 0 then
                    destroyProp()
                    -- คืนค่าอาวุธให้เห็น
                    local wEnt = GetCurrentPedWeaponEntityIndex(ped)
                    if wEnt ~= 0 and DoesEntityExist(wEnt) then
                        SetEntityVisible(wEnt, true, false)
                    end
                    lastW = 0
                end
            end
            Wait(0)
        end
        loopRunning = false
    end)
end

-- ── Damage Handler ──
local function startDmg()
    if dmgReady then return end
    dmgReady = true
    AddEventHandler('gameEventTriggered', function(ev, data)
        if not active or not skinId or ev ~= 'CEventNetworkEntityDamage' then return end
        local victim = data[1]
        local attacker = data[2]
        local myPed = PlayerPedId()
        if attacker ~= myPed or victim == myPed or not victim then return end
        if not (IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0) then return end
        local now = GetGameTimer()
        if now - lastKill < 3000 then return end
        lastKill = now
        local sk = SKINS[skinId]
        if sk and sk.kill then
            playKillFx(victim, sk.kill)
        end
    end)
end

-- ── KVP ──
local function saveKVP(id) SetResourceKvp('aqua_bypass_skin', id or '') end
local function loadKVP()
    local v = GetResourceKvpString('aqua_bypass_skin')
    if v and v ~= '' then return v end
    return nil
end

-- ── Init ──
CreateThread(function()
    Wait(3000)
    local saved = loadKVP()
    if saved and SKINS[saved] then
        skinId = saved
        skinModel = SKINS[saved].model
        active = true
        startLoop()
        startDmg()
        print(("^2[AQUA-SKIN] Auto-loaded: %s (%s)^7"):format(saved, SKINS[saved].name))
    end
end)

-- ── Commands ──
RegisterCommand('home', function(_, args)
    if #args < 1 then
        print("^3[AQUA-SKIN] /home <skin> | /homeoff | /homelist^7")
        if skinId then print(("^2  Active: %s^7"):format(skinId)) end
        return
    end

    local input = args[1]
    if string.lower(input) == 'off' or string.lower(input) == 'remove' then
        destroyProp()
        loopRunning = false
        active = false
        skinId = nil
        skinModel = nil
        saveKVP('')
        local ped = PlayerPedId()
        local wEnt = GetCurrentPedWeaponEntityIndex(ped)
        if wEnt ~= 0 and DoesEntityExist(wEnt) then
            SetEntityVisible(wEnt, true, false)
        end
        print("^1[AQUA-SKIN] Removed^7")
        return
    end

    local id = findSkin(input)
    if not id then
        print(("^1[AQUA-SKIN] Not found: '%s'. Use /homelist^7"):format(input))
        return
    end

    destroyProp()
    loopRunning = false

    skinId = id
    skinModel = SKINS[id].model
    active = true
    saveKVP(id)

    local ped = PlayerPedId()
    local w = GetSelectedPedWeapon(ped)
    if isPoolcue(w) then
        createProp(ped, skinModel)
        local wEnt = GetCurrentPedWeaponEntityIndex(ped)
        if wEnt ~= 0 and DoesEntityExist(wEnt) then
            SetEntityVisible(wEnt, false, false)
        end
    end

    startLoop()
    startDmg()
    print(("^2[AQUA-SKIN] Equipped: %s (%s)^7"):format(id, SKINS[id].name))
end, false)

RegisterCommand('homeoff', function()
    destroyProp()
    loopRunning = false
    active = false
    skinId = nil
    skinModel = nil
    saveKVP('')
    local ped = PlayerPedId()
    local wEnt = GetCurrentPedWeaponEntityIndex(ped)
    if wEnt ~= 0 and DoesEntityExist(wEnt) then
        SetEntityVisible(wEnt, true, false)
    end
    print("^1[AQUA-SKIN] Removed^7")
end, false)

RegisterCommand('homelist', function()
    print("^2========== AQUA POOLCUE SKINS ==========^7")
    local sorted = {}
    for id in pairs(SKINS) do sorted[#sorted+1] = id end
    table.sort(sorted)
    for _, id in ipairs(sorted) do
        local s = SKINS[id]
        local mark = (id == skinId) and " ^2<< ACTIVE^7" or ""
        local fx = s.ptfx and "+HAND " or ""
        local kfx = s.kill and "+KILL " or ""
        print(("  ^6%-40s^7 model:^3%-25s^7 %s%s%s"):format(id, s.model, fx, kfx, mark))
    end
    print(("^3Total: %d skins^7"):format(#sorted))
    print("^2=========================================^7")
end, false)
