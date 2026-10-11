-- ============================================================================
-- AQUA SERVER - ESX_RP-WEAPON-SKIN BYPASS (Poolcue & Bottle)
-- /home <skin>  |  /homeoff  |  /homelist
-- ============================================================================

local activeSkins = {
    ["POOLCUE"] = nil,
    ["BOTTLE"]  = nil,
}

local propEntity = nil
local propModelName = nil
local currentPropType = nil
local loopRunning = false
local dmgReady = false
local lastKill = 0
local RES = "esx_rp-weapon-skin"

-- ── Weapon Hashes & Mapping ──
local WEAPON_CONFIG = {
    ["POOLCUE"] = {
        names = {
            "WEAPON_POOLCUE", "WEAPON_POOLCUE_V1", "WEAPON_POOLCUE_V2",
            "WEAPON_POOLCUE_V3", "WEAPON_POOLCUE_V4", "WEAPON_POOLCUE_V5",
            "WEAPON_POOLCUE_0", "WEAPON_POOLCUE_1", "WEAPON_POOLCUE_2",
            "WEAPON_POOLCUE_3", "WEAPON_POOLCUE_4", "WEAPON_POOLCUE_5",
            "WEAPON_POOLCUE0", "WEAPON_POOLCUE1", "WEAPON_POOLCUE2",
            "WEAPON_POOLCUE3", "WEAPON_POOLCUE4", "WEAPON_POOLCUE5",
            "WEAPON_POOLCUE_RENT", "WEAPON_POOLCUE14DAY", "WEAPON_POOLCUEWAR",
            "WEAPON_POOLCUE_FREE", "WEAPON_POOLCUE_LV1", "WEAPON_POOLCUE_LV2",
            "WEAPON_POOLCUE_LV3", "WEAPON_POOLCUE_LV4", "WEAPON_POOLCUE_LV5",
            "WEAPON_POOLCUE_TIER0", "WEAPON_POOLCUE_TIER1", "WEAPON_POOLCUE_TIER2",
            "WEAPON_POOLCUE_TIER3", "WEAPON_POOLCUE_BATTLE", "WEAPON_POOLCUE_NEWBIE",
        },
        offset = {
            pos = { x = 0.0800, y = -0.0250, z = -0.0200 },
            rot = { x = -85.0,  y = -16.0,   z = -23.0 },
            bone = 57005,
        },
    },
    ["BOTTLE"] = {
        names = {
            "WEAPON_BOTTLE", "WEAPON_BOTTLE_V1", "WEAPON_BOTTLE_V2",
            "WEAPON_BOTTLE_V3", "WEAPON_BOTTLE_V4", "WEAPON_BOTTLE_V5",
            "WEAPON_BOTTLE_0", "WEAPON_BOTTLE_1", "WEAPON_BOTTLE_2",
            "WEAPON_BOTTLE_3", "WEAPON_BOTTLE_4", "WEAPON_BOTTLE_5",
            "WEAPON_BOTTLE0", "WEAPON_BOTTLE1", "WEAPON_BOTTLE2",
            "WEAPON_BOTTLE3", "WEAPON_BOTTLE4", "WEAPON_BOTTLE5",
            "WEAPON_BOTTLE_RENT", "WEAPON_BOTTLE14DAY", "WEAPON_BOTTLEWAR",
            "WEAPON_BOTTLE_NEWBIE", "WEAPON_BOTTLE_LV1", "WEAPON_BOTTLE_LV2",
            "WEAPON_BOTTLE_LV3", "WEAPON_BOTTLE_LV4", "WEAPON_BOTTLE_LV5",
            "WEAPON_BOTTLE_REAL",
        },
        offset = {
            pos = { x = 0.0850, y = 0.0000,  z = -0.0150 },
            rot = { x = -86.0,  y = 9.0,     z = -20.0 },
            bone = 57005,
        },
    },
}

local WEAPON_HASH_MAP = {}
for wType, conf in pairs(WEAPON_CONFIG) do
    for _, name in ipairs(conf.names) do
        WEAPON_HASH_MAP[GetHashKey(name)] = wType
    end
end

local function getWeaponType(wHash)
    return WEAPON_HASH_MAP[wHash]
end

-- ── Skin Database: skin_id → { weapon, model, name, ptfx, kill } ──
local SKINS = {
    -- ── POOLCUE SKINS ──
    ["aqua_skin_1"] = {
        weapon = "POOLCUE",
        model = "weapon_promote_1",
        name = "Aqua Skin Di wa",
        ptfx = { dict = "weapon_event_effect", eff = "weapon_event_b1", freq = 1500, bone = 28422, scale = 0.3 },
        kill = { dict = "weapon_event_particle", eff = "weapon_event_particleb1", scale = 1.5 },
    },
    ["weapon_lz_halloween_pool_lv1"] = {
        weapon = "POOLCUE",
        model = "lz_halloween_pool",
        name = "HW Poolcue (NT) Lv1",
    },
    ["weapon_lz_halloween_pool_lv2"] = {
        weapon = "POOLCUE",
        model = "lz_halloween_pool",
        name = "HW Poolcue (NT) Lv2",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx", freq = 1500, bone = 28422, scale = 0.7 },
    },
    ["weapon_lz_halloween_pool_lv3"] = {
        weapon = "POOLCUE",
        model = "lz_halloween_pool",
        name = "HW Poolcue (NT) Lv3",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx", freq = 1500, bone = 28422, scale = 0.7 },
        kill = { dict = "lz_halloween_fx", eff = "halloween_hit", scale = 1.0 },
    },
    ["weapon_lz_halloween_pool_pink_lv1"] = {
        weapon = "POOLCUE",
        model = "lz_halloween_pool_pink",
        name = "HW Pink Poolcue (NT) Lv1",
    },
    ["weapon_lz_halloween_pool_pink_lv2"] = {
        weapon = "POOLCUE",
        model = "lz_halloween_pool_pink",
        name = "HW Pink Poolcue (NT) Lv2",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx_pink", freq = 1500, bone = 28422, scale = 0.7 },
    },
    ["weapon_lz_halloween_pool_pink_lv3"] = {
        weapon = "POOLCUE",
        model = "lz_halloween_pool_pink",
        name = "HW Pink Poolcue (NT) Lv3",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx_pink", freq = 1500, bone = 28422, scale = 0.7 },
        kill = { dict = "lz_halloween_fx", eff = "halloween_hit_pink", scale = 1.0 },
    },

    -- ── BOTTLE SKINS ──
    ["weapon_lz_halloween_knife_lv1"] = {
        weapon = "BOTTLE",
        model = "lz_halloween_knife",
        name = "HW Bottle (NT) Lv1",
    },
    ["weapon_lz_halloween_knife_lv2"] = {
        weapon = "BOTTLE",
        model = "lz_halloween_knife",
        name = "HW Bottle (NT) Lv2",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx", freq = 1500, bone = 28422, scale = 0.7 },
    },
    ["weapon_lz_halloween_knife_lv3"] = {
        weapon = "BOTTLE",
        model = "lz_halloween_knife",
        name = "HW Bottle (NT) Lv3",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx", freq = 1500, bone = 28422, scale = 0.7 },
        kill = { dict = "lz_halloween_fx", eff = "halloween_hit", scale = 1.0 },
    },
    ["weapon_lz_halloween_knife_pink_lv1"] = {
        weapon = "BOTTLE",
        model = "lz_halloween_knife_pink",
        name = "HW Pink Bottle (NT) Lv1",
    },
    ["weapon_lz_halloween_knife_pink_lv2"] = {
        weapon = "BOTTLE",
        model = "lz_halloween_knife_pink",
        name = "HW Pink Bottle (NT) Lv2",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx_pink", freq = 1500, bone = 28422, scale = 0.7 },
    },
    ["weapon_lz_halloween_knife_pink_lv3"] = {
        weapon = "BOTTLE",
        model = "lz_halloween_knife_pink",
        name = "HW Pink Bottle (NT) Lv3",
        ptfx = { dict = "lz_halloween_fx", eff = "halloween_hfx_pink", freq = 1500, bone = 28422, scale = 0.7 },
        kill = { dict = "lz_halloween_fx", eff = "halloween_hit_pink", scale = 1.0 },
    },
}

-- ── Shortcut Aliases ──
local ALIASES = {
    ["aqua"]             = "aqua_skin_1",
    ["diwa"]             = "aqua_skin_1",
    ["pool1"]            = "weapon_lz_halloween_pool_lv1",
    ["pool2"]            = "weapon_lz_halloween_pool_lv2",
    ["pool3"]            = "weapon_lz_halloween_pool_lv3",
    ["pool_lv1"]         = "weapon_lz_halloween_pool_lv1",
    ["pool_lv2"]         = "weapon_lz_halloween_pool_lv2",
    ["pool_lv3"]         = "weapon_lz_halloween_pool_lv3",
    ["pool_pink1"]       = "weapon_lz_halloween_pool_pink_lv1",
    ["pool_pink2"]       = "weapon_lz_halloween_pool_pink_lv2",
    ["pool_pink3"]       = "weapon_lz_halloween_pool_pink_lv3",
    ["pool_pink_lv1"]    = "weapon_lz_halloween_pool_pink_lv1",
    ["pool_pink_lv2"]    = "weapon_lz_halloween_pool_pink_lv2",
    ["pool_pink_lv3"]    = "weapon_lz_halloween_pool_pink_lv3",

    ["bottle1"]          = "weapon_lz_halloween_knife_lv1",
    ["bottle2"]          = "weapon_lz_halloween_knife_lv2",
    ["bottle3"]          = "weapon_lz_halloween_knife_lv3",
    ["bottle_lv1"]       = "weapon_lz_halloween_knife_lv1",
    ["bottle_lv2"]       = "weapon_lz_halloween_knife_lv2",
    ["bottle_lv3"]       = "weapon_lz_halloween_knife_lv3",
    ["bottle_pink1"]     = "weapon_lz_halloween_knife_pink_lv1",
    ["bottle_pink2"]     = "weapon_lz_halloween_knife_pink_lv2",
    ["bottle_pink3"]     = "weapon_lz_halloween_knife_pink_lv3",
    ["bottle_pink_lv1"]  = "weapon_lz_halloween_knife_pink_lv1",
    ["bottle_pink_lv2"]  = "weapon_lz_halloween_knife_pink_lv2",
    ["bottle_pink_lv3"]  = "weapon_lz_halloween_knife_pink_lv3",

    ["knife1"]           = "weapon_lz_halloween_knife_lv1",
    ["knife2"]           = "weapon_lz_halloween_knife_lv2",
    ["knife3"]           = "weapon_lz_halloween_knife_lv3",
    ["knife_lv1"]        = "weapon_lz_halloween_knife_lv1",
    ["knife_lv2"]        = "weapon_lz_halloween_knife_lv2",
    ["knife_lv3"]        = "weapon_lz_halloween_knife_lv3",
    ["knife_pink1"]      = "weapon_lz_halloween_knife_pink_lv1",
    ["knife_pink2"]      = "weapon_lz_halloween_knife_pink_lv2",
    ["knife_pink3"]      = "weapon_lz_halloween_knife_pink_lv3",
    ["knife_pink_lv1"]   = "weapon_lz_halloween_knife_pink_lv1",
    ["knife_pink_lv2"]   = "weapon_lz_halloween_knife_pink_lv2",
    ["knife_pink_lv3"]   = "weapon_lz_halloween_knife_pink_lv3",
}

-- ── Search ──
local function findSkin(q)
    if not q or q == '' then return nil end
    q = string.lower(q)

    -- Check direct aliases
    if ALIASES[q] then return ALIASES[q] end

    -- Check exact match
    for id in pairs(SKINS) do
        if string.lower(id) == q then return id end
    end
    -- Check ID partial match
    for id in pairs(SKINS) do
        if string.find(string.lower(id), q, 1, true) then return id end
    end
    -- Check Name partial match
    for id, d in pairs(SKINS) do
        if string.find(string.lower(d.name), q, 1, true) then return id end
    end
    return nil
end

-- ── Prop Management ──
local function destroyProp()
    if propEntity and DoesEntityExist(propEntity) then
        SetEntityAsMissionEntity(propEntity, true, true)
        DetachEntity(propEntity, true, true)
        DeleteEntity(propEntity)
    end
    propEntity = nil
    propModelName = nil
    currentPropType = nil
end

local function createProp(ped, modelName, wType)
    if propEntity and DoesEntityExist(propEntity) and propModelName == modelName and currentPropType == wType then
        return true
    end
    destroyProp()

    local h = GetHashKey(modelName)
    if not IsModelValid(h) then h = GetHashKey(string.upper(modelName)) end
    if not IsModelValid(h) then h = GetHashKey(string.lower(modelName)) end
    if not IsModelValid(h) then
        return false
    end

    RequestModel(h)
    local deadline = GetGameTimer() + 3000
    while not HasModelLoaded(h) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(h) then
        return false
    end

    local c = GetEntityCoords(ped)
    local obj = CreateObject(h, c.x, c.y, c.z, true, true, false)
    if not DoesEntityExist(obj) then return false end

    SetEntityCollision(obj, false, false)
    SetEntityCompletelyDisableCollision(obj, false, false)

    if NetworkGetEntityIsNetworked(obj) then
        local netId = NetworkGetNetworkIdFromEntity(obj)
        SetNetworkIdCanMigrate(netId, true)
        SetNetworkIdExistsOnAllMachines(netId, true)
        NetworkSetEntityInvisibleToNetwork(obj, false)
    end

    local conf = WEAPON_CONFIG[wType] or WEAPON_CONFIG["POOLCUE"]
    local bi = GetPedBoneIndex(ped, conf.offset.bone)
    AttachEntityToEntity(
        obj, ped, bi,
        conf.offset.pos.x, conf.offset.pos.y, conf.offset.pos.z,
        conf.offset.rot.x, conf.offset.rot.y, conf.offset.rot.z,
        true, false, false, false, 0, true
    )

    propEntity = obj
    propModelName = modelName
    currentPropType = wType
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

-- ── Active Skin Check ──
local function hasAnyActiveSkin()
    return (activeSkins["POOLCUE"] ~= nil) or (activeSkins["BOTTLE"] ~= nil)
end

-- ── Main Loop ──
local function startLoop()
    if loopRunning then return end
    loopRunning = true
    CreateThread(function()
        local lastW = 0
        local nextFx = 0
        while loopRunning and hasAnyActiveSkin() do
            local ped = PlayerPedId()
            local w = GetSelectedPedWeapon(ped)
            local wType = getWeaponType(w)
            local curSkinId = wType and activeSkins[wType]
            local sk = curSkinId and SKINS[curSkinId]

            if sk and not IsEntityDead(ped) then
                -- สร้าง prop เมื่อเปลี่ยนอาวุธ หรือ prop หาย หรือ เปลี่ยน model
                if w ~= lastW or not propEntity or not DoesEntityExist(propEntity) or propModelName ~= sk.model or currentPropType ~= wType then
                    createProp(ped, sk.model, wType)
                    lastW = w
                end

                -- ซ่อนอาวุธเดิม (ใช้ Alpha 0 เพื่อให้ sync ทุกคนเห็น)
                local wEnt = GetCurrentPedWeaponEntityIndex(ped)
                if wEnt ~= 0 and DoesEntityExist(wEnt) then
                    SetEntityVisible(wEnt, false, false)
                    SetEntityAlpha(wEnt, 0, false)
                end

                -- Hand PTFX
                if sk.ptfx then
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
                        SetEntityAlpha(wEnt, 255, false)
                    end
                    lastW = 0
                end
            end
            Wait(0)
        end
        destroyProp()
        loopRunning = false
    end)
end

-- ── Damage Handler ──
local function startDmg()
    if dmgReady then return end
    dmgReady = true
    AddEventHandler('gameEventTriggered', function(ev, data)
        if ev ~= 'CEventNetworkEntityDamage' then return end
        local victim = data[1]
        local attacker = data[2]
        local myPed = PlayerPedId()
        if attacker ~= myPed or victim == myPed or not victim then return end
        if not (IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0) then return end

        local w = GetSelectedPedWeapon(myPed)
        local wType = getWeaponType(w)
        if not wType or not activeSkins[wType] then return end

        local sk = SKINS[activeSkins[wType]]
        if not sk or not sk.kill then return end

        local now = GetGameTimer()
        if now - lastKill < 3000 then return end
        lastKill = now
        playKillFx(victim, sk.kill)
    end)
end

-- ── KVP Storage ──
local function saveKVP(wType, id)
    SetResourceKvp(('aqua_bypass_skin_%s'):format(string.lower(wType)), id or '')
end

local function loadKVP(wType)
    local v = GetResourceKvpString(('aqua_bypass_skin_%s'):format(string.lower(wType)))
    if v and v ~= '' then return v end
    return nil
end

-- ── Init ──
CreateThread(function()
    Wait(3000)

    -- Auto-load Poolcue
    local savedPool = loadKVP("POOLCUE")
    if not savedPool then
        local legacy = GetResourceKvpString('aqua_bypass_skin')
        if legacy and legacy ~= '' and SKINS[legacy] and SKINS[legacy].weapon == "POOLCUE" then
            savedPool = legacy
        end
    end
    if savedPool and SKINS[savedPool] then
        activeSkins["POOLCUE"] = savedPool
    end

    -- Auto-load Bottle
    local savedBottle = loadKVP("BOTTLE")
    if not savedBottle then
        local legacy = GetResourceKvpString('aqua_bypass_skin')
        if legacy and legacy ~= '' and SKINS[legacy] and SKINS[legacy].weapon == "BOTTLE" then
            savedBottle = legacy
        end
    end
    if savedBottle and SKINS[savedBottle] then
        activeSkins["BOTTLE"] = savedBottle
    end

    if hasAnyActiveSkin() then
        startLoop()
        startDmg()
    end
end)

-- ── Commands ──
RegisterCommand('home', function(_, args)
    if #args < 1 then
        return
    end

    local input = table.concat(args, " ")
    local lowerInput = string.lower(input)

    -- ถอดสกินทั้งหมด หรือ ถอดแยกอาวุธ
    if lowerInput == 'off' or lowerInput == 'remove' then
        destroyProp()
        activeSkins["POOLCUE"] = nil
        activeSkins["BOTTLE"] = nil
        saveKVP("POOLCUE", '')
        saveKVP("BOTTLE", '')
        SetResourceKvp('aqua_bypass_skin', '')
        local ped = PlayerPedId()
        local wEnt = GetCurrentPedWeaponEntityIndex(ped)
        if wEnt ~= 0 and DoesEntityExist(wEnt) then
            SetEntityVisible(wEnt, true, false)
            SetEntityAlpha(wEnt, 255, false)
        end
        return
    elseif lowerInput == 'off poolcue' or lowerInput == 'poolcue off' or lowerInput == 'off pool' or lowerInput == 'pool off' then
        activeSkins["POOLCUE"] = nil
        saveKVP("POOLCUE", '')
        destroyProp()
        return
    elseif lowerInput == 'off bottle' or lowerInput == 'bottle off' or lowerInput == 'off knife' or lowerInput == 'knife off' then
        activeSkins["BOTTLE"] = nil
        saveKVP("BOTTLE", '')
        destroyProp()
        return
    end

    local id = findSkin(input)
    if not id then
        return
    end

    local sk = SKINS[id]
    local wType = sk.weapon or "POOLCUE"

    activeSkins[wType] = id
    saveKVP(wType, id)
    SetResourceKvp('aqua_bypass_skin', id)

    local ped = PlayerPedId()
    local w = GetSelectedPedWeapon(ped)
    if getWeaponType(w) == wType then
        destroyProp()
        createProp(ped, sk.model, wType)
        local wEnt = GetCurrentPedWeaponEntityIndex(ped)
        if wEnt ~= 0 and DoesEntityExist(wEnt) then
            SetEntityVisible(wEnt, false, false)
            SetEntityAlpha(wEnt, 0, false)
        end
    end

    startLoop()
    startDmg()
end, false)

RegisterCommand('homeoff', function(_, args)
    local target = args[1] and string.lower(args[1])
    if target == 'poolcue' or target == 'pool' then
        activeSkins["POOLCUE"] = nil
        saveKVP("POOLCUE", '')
        destroyProp()
        return
    elseif target == 'bottle' or target == 'knife' then
        activeSkins["BOTTLE"] = nil
        saveKVP("BOTTLE", '')
        destroyProp()
        return
    end

    destroyProp()
    activeSkins["POOLCUE"] = nil
    activeSkins["BOTTLE"] = nil
    saveKVP("POOLCUE", '')
    saveKVP("BOTTLE", '')
    SetResourceKvp('aqua_bypass_skin', '')
    local ped = PlayerPedId()
    local wEnt = GetCurrentPedWeaponEntityIndex(ped)
    if wEnt ~= 0 and DoesEntityExist(wEnt) then
        SetEntityVisible(wEnt, true, false)
        SetEntityAlpha(wEnt, 255, false)
    end
end, false)

RegisterCommand('homelist', function()
    print("^2================== AQUA WEAPON SKINS ==================^7")

    print("^3[POOLCUE SKINS]^7")
    local poolList = {}
    local bottleList = {}
    for id, s in pairs(SKINS) do
        if s.weapon == "POOLCUE" then
            poolList[#poolList+1] = id
        elseif s.weapon == "BOTTLE" then
            bottleList[#bottleList+1] = id
        end
    end
    table.sort(poolList)
    table.sort(bottleList)

    for _, id in ipairs(poolList) do
        local s = SKINS[id]
        local mark = (id == activeSkins["POOLCUE"]) and " ^2<< ACTIVE^7" or ""
        local fx = s.ptfx and "+HAND " or ""
        local kfx = s.kill and "+KILL " or ""
        print(("  ^6%-35s^7 model:^3%-24s^7 %s%s%s"):format(id, s.model, fx, kfx, mark))
    end

    print("^3[BOTTLE SKINS]^7")
    for _, id in ipairs(bottleList) do
        local s = SKINS[id]
        local mark = (id == activeSkins["BOTTLE"]) and " ^2<< ACTIVE^7" or ""
        local fx = s.ptfx and "+HAND " or ""
        local kfx = s.kill and "+KILL " or ""
        print(("  ^6%-35s^7 model:^3%-24s^7 %s%s%s"):format(id, s.model, fx, kfx, mark))
    end

    print(("^3Total: %d Poolcue, %d Bottle skins^7"):format(#poolList, #bottleList))
    print("^2======================================================^7")
end, false)
