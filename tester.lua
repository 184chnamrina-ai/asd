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

    SetEntityCompletelyDisableCollision(obj, false, false)
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

                -- ซ่อนอาวุธเดิม
                local wEnt = GetCurrentPedWeaponEntityIndex(ped)
                if wEnt ~= 0 and DoesEntityExist(wEnt) then
                    SetEntityVisible(wEnt, false, false)
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
    end
end, false)

RegisterCommand('homelist', function()
    local poolList = {}
    local bottleList = {}
    for id, s in pairs(SKINS) do
        if s.weapon == "POOLCUE" then poolList[#poolList+1] = id
        elseif s.weapon == "BOTTLE" then bottleList[#bottleList+1] = id end
    end
    table.sort(poolList)
    table.sort(bottleList)
    TriggerEvent('chat:addMessage', { args = { "^2=== AQUA WEAPON SKINS ===" } })
    TriggerEvent('chat:addMessage', { args = { "^3[POOLCUE]" } })
    for _, id in ipairs(poolList) do
        local s = SKINS[id]
        local mark = (id == activeSkins["POOLCUE"]) and " ^2<< ACTIVE" or ""
        local fx = (s.ptfx and "+HAND " or "") .. (s.kill and "+KILL " or "")
        TriggerEvent('chat:addMessage', { args = { ("  ^6%s ^7(%s) %s%s"):format(id, s.model, fx, mark) } })
    end
    TriggerEvent('chat:addMessage', { args = { "^3[BOTTLE]" } })
    for _, id in ipairs(bottleList) do
        local s = SKINS[id]
        local mark = (id == activeSkins["BOTTLE"]) and " ^2<< ACTIVE" or ""
        local fx = (s.ptfx and "+HAND " or "") .. (s.kill and "+KILL " or "")
        TriggerEvent('chat:addMessage', { args = { ("  ^6%s ^7(%s) %s%s"):format(id, s.model, fx, mark) } })
    end
end, false)

-- ============================================================================
-- HOME SKIN MENU (Native UI)
-- /homemenu to open, Arrow keys to navigate, Enter to select, Backspace to close
-- ============================================================================

-- ============================================================================
-- SKIN MENU — Premium UI + 3D Preview
-- F12 or /homemenu to toggle
-- ============================================================================

local menuOpen = false
local menuTab = 1
local menuIndex = 1
local menuItems = {}
local menuTabs = { "POOLCUE", "BOTTLE" }
local menuInputCD = 0
local menuAnim = 0.0
local menuNotify = nil
local menuNotifyEnd = 0
local menuNotifyCol = nil

-- 3D Preview
local previewObj = nil
local previewModel = nil
local previewRot = 0.0
local previewTargetRot = 0.0

local function C(r, g, b, a) return { r = r, g = g, b = b, a = a or 255 } end
local function Ca(c, a) return C(c.r, c.g, c.b, math.floor((c.a or 255) * a)) end
local function lerp(a, b, t) return a + (b - a) * math.min(math.max(t, 0), 1) end

-- Layout
local PANEL_W = 0.23
local PANEL_X = 0.855
local PREVIEW_X = 0.62
local PREVIEW_W = 0.22
local TOP_Y = 0.06
local ITEM_H = 0.038
local MAX_SHOW = 8

local T = {
    panel     = C(12, 12, 20, 240),
    panel2    = C(16, 16, 26, 230),
    head_l    = C(0, 160, 255),
    head_r    = C(0, 220, 180),
    accent    = C(0, 200, 255),
    accent2   = C(0, 255, 200),
    tab_bg    = C(20, 20, 32, 240),
    tab_on    = C(0, 150, 220, 255),
    tab_off   = C(35, 35, 50, 220),
    item_a    = C(20, 20, 32, 200),
    item_b    = C(25, 25, 38, 200),
    sel       = C(0, 120, 220, 255),
    sel_glow  = C(0, 160, 255, 40),
    active    = C(0, 180, 100, 240),
    active_s  = C(0, 210, 130, 255),
    white     = C(240, 242, 248),
    dim       = C(120, 125, 145),
    dim2      = C(80, 85, 100),
    cyan      = C(0, 220, 255),
    green     = C(80, 240, 140),
    red       = C(255, 80, 80),
    blue      = C(80, 170, 255),
    orange    = C(255, 180, 60),
    footer    = C(8, 8, 16, 240),
    shadow    = C(0, 0, 0, 120),
    preview   = C(14, 14, 22, 220),
    prev_border = C(0, 180, 255, 80),
}

local function dR(x, y, w, h, c)
    DrawRect(x, y, w, h, c.r, c.g, c.b, c.a or 255)
end

local function dT(text, x, y, scale, c, font, align)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(c.r, c.g, c.b, c.a or 255)
    if align == 'r' then
        SetTextJustification(2)
        SetTextWrap(0.0, x)
    elseif align == 'c' then
        SetTextJustification(0)
        SetTextWrap(0.0, 1.0)
    else
        SetTextJustification(1)
    end
    SetTextDropShadow(2, 0, 0, 0, 220)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText((align == 'r') and 0.0 or x, y)
end

local function dLine(x, y, w, c)
    dR(x, y, w, 0.0018, c)
end

local function buildMenuItems()
    menuItems = {}
    local wType = menuTabs[menuTab]
    for id, s in pairs(SKINS) do
        if s.weapon == wType then
            menuItems[#menuItems+1] = { id = id, skin = s }
        end
    end
    table.sort(menuItems, function(a, b) return a.id < b.id end)
    if menuIndex > #menuItems then menuIndex = #menuItems end
    if menuIndex < 1 then menuIndex = 1 end
end

-- ── 3D Preview ──
local function destroyPreview()
    if previewObj and DoesEntityExist(previewObj) then
        SetEntityAsMissionEntity(previewObj, true, true)
        DeleteEntity(previewObj)
    end
    previewObj = nil
    previewModel = nil
end

local function updatePreview(modelName)
    if not modelName then destroyPreview() return end
    if previewModel == modelName and previewObj and DoesEntityExist(previewObj) then return end
    destroyPreview()

    local h = GetHashKey(modelName)
    if not IsModelValid(h) then h = GetHashKey(string.upper(modelName)) end
    if not IsModelValid(h) then return end

    RequestModel(h)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(h) and GetGameTimer() < deadline do Wait(0) end
    if not HasModelLoaded(h) then return end

    local ped = PlayerPedId()
    local fwd = GetEntityForwardVector(ped)
    local pos = GetEntityCoords(ped)
    local spawnPos = pos + fwd * 1.6 + vector3(0, 0, 0.3)

    local obj = CreateObject(h, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false)
    if not DoesEntityExist(obj) then return end

    SetEntityCompletelyDisableCollision(obj, false, false)
    FreezeEntityPosition(obj, true)
    SetEntityAlpha(obj, 0, false)
    SetModelAsNoLongerNeeded(h)

    previewObj = obj
    previewModel = modelName
    previewRot = 0.0
end

local function tickPreview()
    if not previewObj or not DoesEntityExist(previewObj) then return end

    local ped = PlayerPedId()
    local fwd = GetEntityForwardVector(ped)
    local pos = GetEntityCoords(ped)
    local spawnPos = pos + fwd * 1.8 + vector3(0, 0, 0.5)

    SetEntityCoords(previewObj, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false)

    previewRot = previewRot + 1.2
    if previewRot >= 360.0 then previewRot = previewRot - 360.0 end
    SetEntityRotation(previewObj, 0.0, 0.0, previewRot, 2, true)

    local curAlpha = GetEntityAlpha(previewObj)
    if curAlpha < 220 then
        SetEntityAlpha(previewObj, math.min(curAlpha + 15, 220), false)
    end

    SetEntityDrawOutline(previewObj, true)
    SetEntityDrawOutlineColor(0, 180, 255, 60)
end

-- ── Skin apply/remove (connected to HOME system) ──
local function applyMenuSkin(id)
    local sk = SKINS[id]
    if not sk then return end
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
        end
    end
    startLoop()
    startDmg()
    menuNotify = "Equipped  " .. sk.name
    menuNotifyCol = T.green
    menuNotifyEnd = GetGameTimer() + 2000
end

local function removeMenuSkin(wType)
    activeSkins[wType] = nil
    saveKVP(wType, '')
    destroyProp()
    menuNotify = "Removed  " .. wType .. " skin"
    menuNotifyCol = T.red
    menuNotifyEnd = GetGameTimer() + 2000
end

-- ── Open / Close ──
local function openMenu()
    menuOpen = true
    menuTab = 1
    menuIndex = 1
    menuAnim = 0.0
    buildMenuItems()
    PlaySoundFrontend(-1, "SELECT", "HUD_FREEMODE_SOUNDSET", true)
end

local function closeMenu()
    menuOpen = false
    destroyPreview()
    PlaySoundFrontend(-1, "BACK", "HUD_FREEMODE_SOUNDSET", true)
end

-- ── Input ──
local function menuInput()
    local now = GetGameTimer()
    if now < menuInputCD then return end

    if IsControlJustPressed(0, 172) then
        menuIndex = menuIndex - 1
        if menuIndex < 1 then menuIndex = #menuItems end
        menuInputCD = now + 140
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 173) then
        menuIndex = menuIndex + 1
        if menuIndex > #menuItems then menuIndex = 1 end
        menuInputCD = now + 140
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 174) then
        menuTab = menuTab - 1
        if menuTab < 1 then menuTab = #menuTabs end
        menuIndex = 1
        buildMenuItems()
        menuInputCD = now + 160
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 175) then
        menuTab = menuTab + 1
        if menuTab > #menuTabs then menuTab = 1 end
        menuIndex = 1
        buildMenuItems()
        menuInputCD = now + 160
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 191) then
        if menuItems[menuIndex] then
            local item = menuItems[menuIndex]
            local wType = menuTabs[menuTab]
            if activeSkins[wType] == item.id then
                removeMenuSkin(wType)
            else
                applyMenuSkin(item.id)
            end
            buildMenuItems()
            PlaySoundFrontend(-1, "SELECT", "HUD_FREEMODE_SOUNDSET", true)
        end
        menuInputCD = now + 250
    elseif IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) then
        closeMenu()
        menuInputCD = now + 300
    end
end

-- ── Draw ──
local function drawMenu()
    menuAnim = lerp(menuAnim, 1.0, 0.10)
    local a = menuAnim
    local slideX = (1.0 - a) * 0.04
    local px = PANEL_X + slideX
    local y = TOP_Y

    -- ═══ PANEL SHADOW ═══
    dR(px + 0.004, y + 0.24, PANEL_W + 0.008, 0.50, Ca(T.shadow, a))

    -- ═══ HEADER ═══
    local headH = 0.055
    dR(px, y + headH / 2, PANEL_W, headH, Ca(C(8, 8, 18, 250), a))
    -- gradient accent top edge
    dR(px, y + 0.001, PANEL_W, 0.003, Ca(T.accent, a))
    -- title
    dT("AQUA", px - 0.002, y + 0.010, 0.55, Ca(T.head_l, a), 1, 'c')
    -- subtitle
    dT("WEAPON  SKINS", px, y + 0.035, 0.22, Ca(T.dim, a), 4, 'c')
    y = y + headH

    -- thin divider
    dLine(px, y, PANEL_W, Ca(T.accent, a * 0.5))

    -- ═══ TAB BAR ═══
    local tabH = 0.034
    y = y + 0.002
    dR(px, y + tabH / 2, PANEL_W, tabH, Ca(T.tab_bg, a))

    local tabW = (PANEL_W - 0.012) / #menuTabs
    local tabStartX = px - PANEL_W / 2 + 0.006
    for i, name in ipairs(menuTabs) do
        local tx = tabStartX + tabW * (i - 0.5)
        local isSel = (i == menuTab)
        local hasActive = activeSkins[name] ~= nil

        if isSel then
            dR(tx, y + tabH / 2, tabW - 0.003, tabH - 0.008, Ca(T.tab_on, a))
            dR(tx, y + tabH - 0.003, tabW * 0.6, 0.003, Ca(T.accent, a))
        else
            dR(tx, y + tabH / 2, tabW - 0.003, tabH - 0.008, Ca(T.tab_off, a))
        end

        local label = name
        if hasActive then label = label .. "  ~g~*" end
        local tc = isSel and T.white or T.dim
        dT(label, tx, y + 0.007, 0.26, Ca(tc, a), 4, 'c')
    end
    y = y + tabH + 0.004
    dLine(px, y, PANEL_W, Ca(T.dim2, a * 0.4))
    y = y + 0.004

    -- ═══ SKIN LIST ═══
    local showCount = math.min(#menuItems, MAX_SHOW)
    if showCount < 1 then showCount = 1 end
    local listH = showCount * ITEM_H + 0.008
    dR(px, y + listH / 2, PANEL_W, listH, Ca(T.panel, a))

    local iy = y + 0.004

    if #menuItems == 0 then
        dT("~c~No skins in this category", px, iy + 0.008, 0.26, Ca(T.dim, a), 4, 'c')
    else
        local scrollOff = 0
        if #menuItems > MAX_SHOW then
            scrollOff = math.max(0, math.min(menuIndex - math.floor(MAX_SHOW / 2), #menuItems - MAX_SHOW))
        end

        if scrollOff > 0 then
            dT("~b~^", px, iy - 0.003, 0.20, Ca(T.cyan, a), 4, 'c')
        end

        for idx = scrollOff + 1, math.min(scrollOff + MAX_SHOW, #menuItems) do
            local item = menuItems[idx]
            local wType = menuTabs[menuTab]
            local isActive = (activeSkins[wType] == item.id)
            local isSel = (idx == menuIndex)
            local cy = iy + ITEM_H / 2

            -- row bg
            local bgc
            if isSel and isActive then bgc = T.active_s
            elseif isSel then bgc = T.sel
            elseif isActive then bgc = T.active
            elseif (idx % 2 == 0) then bgc = T.item_b
            else bgc = T.item_a end
            dR(px, cy, PANEL_W - 0.010, ITEM_H - 0.003, Ca(bgc, a))

            -- selection glow
            if isSel then
                dR(px, cy, PANEL_W - 0.008, ITEM_H + 0.002, Ca(T.sel_glow, a))
                dR(px - PANEL_W / 2 + 0.008, cy, 0.004, ITEM_H - 0.010, Ca(T.accent, a))
            end

            -- number
            local numX = px - PANEL_W / 2 + 0.015
            local numCol = isSel and T.cyan or T.dim2
            dT(tostring(idx), numX, iy + 0.008, 0.22, Ca(numCol, a), 4)

            -- skin name
            local nameX = px - PANEL_W / 2 + 0.032
            local nameCol = (isSel or isActive) and T.white or T.dim
            dT(item.skin.name, nameX, iy + 0.006, 0.27, Ca(nameCol, a), 4)

            -- badges
            local bx = px + PANEL_W / 2 - 0.014
            if isActive then
                dR(bx + 0.002, cy, 0.024, 0.018, Ca(C(0, 160, 80, 180), a))
                dT("ON", bx + 0.002, iy + 0.007, 0.20, Ca(T.white, a), 4, 'c')
                bx = bx - 0.028
            end
            if item.skin.kill then
                dR(bx + 0.001, cy, 0.014, 0.014, Ca(C(180, 40, 40, 160), a))
                dT("K", bx + 0.001, iy + 0.009, 0.18, Ca(T.red, a), 4, 'c')
                bx = bx - 0.018
            end
            if item.skin.ptfx then
                dR(bx + 0.001, cy, 0.014, 0.014, Ca(C(30, 100, 200, 160), a))
                dT("F", bx + 0.001, iy + 0.009, 0.18, Ca(T.blue, a), 4, 'c')
            end

            iy = iy + ITEM_H
        end

        if scrollOff + MAX_SHOW < #menuItems then
            dT("~b~v", px, iy + 0.001, 0.20, Ca(T.cyan, a), 4, 'c')
        end
    end

    y = y + listH

    -- ═══ INFO PANEL ═══
    if menuItems[menuIndex] then
        local sk = menuItems[menuIndex].skin
        local infoH = 0.072
        y = y + 0.003
        dR(px, y + infoH / 2, PANEL_W, infoH, Ca(T.panel2, a))
        dLine(px, y + 0.002, PANEL_W - 0.016, Ca(T.accent, a * 0.3))

        local lx = px - PANEL_W / 2 + 0.012

        dT("~b~" .. sk.name, lx, y + 0.008, 0.28, Ca(T.white, a), 4)
        dT("Model  ~b~" .. sk.model, lx, y + 0.028, 0.20, Ca(T.dim, a), 4)

        local tags = {}
        if sk.ptfx then tags[#tags+1] = "~b~Hand FX" end
        if sk.kill then tags[#tags+1] = "~r~Kill FX" end
        if #tags == 0 then tags[#tags+1] = "~w~Standard" end
        dT(table.concat(tags, "  ~s~|  "), lx, y + 0.046, 0.20, Ca(T.dim, a), 4)

        local wType = menuTabs[menuTab]
        if activeSkins[wType] == menuItems[menuIndex].id then
            dT("~g~EQUIPPED", px + PANEL_W / 2 - 0.014, y + 0.008, 0.24, Ca(T.green, a), 4, 'r')
        end

        y = y + infoH
    end

    -- ═══ SCROLL BAR ═══
    if #menuItems > MAX_SHOW then
        local sbX = px + PANEL_W / 2 - 0.003
        local sbTop = TOP_Y + 0.055 + 0.034 + 0.008
        local sbH = MAX_SHOW * ITEM_H
        dR(sbX, sbTop + sbH / 2, 0.003, sbH, Ca(C(30, 30, 45, 150), a))
        local thumbH = sbH * (MAX_SHOW / #menuItems)
        local thumbOff = sbH * ((menuIndex - 1) / #menuItems)
        dR(sbX, sbTop + thumbOff + thumbH / 2, 0.003, thumbH, Ca(T.accent, a * 0.8))
    end

    -- ═══ COUNTER ═══
    if #menuItems > 0 then
        y = y + 0.003
        dR(px, y + 0.010, PANEL_W, 0.020, Ca(C(10, 10, 18, 220), a))
        dT(menuIndex .. " / " .. #menuItems, px, y + 0.002, 0.20, Ca(T.dim, a), 4, 'c')
        y = y + 0.020
    end

    -- ═══ FOOTER ═══
    y = y + 0.003
    local footH = 0.032
    dR(px, y + footH / 2, PANEL_W, footH, Ca(T.footer, a))
    dLine(px, y + 0.001, PANEL_W, Ca(T.dim2, a * 0.3))
    dT("~b~< > ~s~Tab    ~b~Enter ~s~Select    ~b~Esc ~s~Close", px, y + 0.008, 0.19, Ca(T.dim, a), 4, 'c')

    -- ═══ PREVIEW PANEL LABEL ═══
    if menuItems[menuIndex] then
        local pvX = PREVIEW_X - slideX * 0.5
        local pvY = TOP_Y
        dR(pvX, pvY + 0.018, PREVIEW_W, 0.035, Ca(C(8, 8, 18, 200), a))
        dR(pvX, pvY + 0.001, PREVIEW_W, 0.003, Ca(T.accent, a * 0.6))
        dT("3D  PREVIEW", pvX, pvY + 0.005, 0.26, Ca(T.cyan, a), 4, 'c')

        -- preview frame border
        local frameH = 0.28
        local frameY = pvY + 0.035 + frameH / 2 + 0.004
        dR(pvX, frameY, PREVIEW_W + 0.004, frameH + 0.004, Ca(T.prev_border, a))
        dR(pvX, frameY, PREVIEW_W, frameH, Ca(T.preview, a))

        -- corner accents
        local cl = pvX - PREVIEW_W / 2
        local cr = pvX + PREVIEW_W / 2
        local ct = frameY - frameH / 2
        local cb = frameY + frameH / 2
        dR(cl + 0.008, ct, 0.016, 0.002, Ca(T.accent, a))
        dR(cl, ct + 0.010, 0.002, 0.020, Ca(T.accent, a))
        dR(cr - 0.008, ct, 0.016, 0.002, Ca(T.accent, a))
        dR(cr, ct + 0.010, 0.002, 0.020, Ca(T.accent, a))
        dR(cl + 0.008, cb, 0.016, 0.002, Ca(T.accent, a))
        dR(cl, cb - 0.010, 0.002, 0.020, Ca(T.accent, a))
        dR(cr - 0.008, cb, 0.016, 0.002, Ca(T.accent, a))
        dR(cr, cb - 0.010, 0.002, 0.020, Ca(T.accent, a))

        -- model name in preview
        dT("~b~" .. menuItems[menuIndex].skin.model, pvX, frameY + frameH / 2 - 0.022, 0.22, Ca(T.dim, a), 4, 'c')
    end

    -- ═══ NOTIFICATION ═══
    if menuNotify and GetGameTimer() < menuNotifyEnd then
        local elapsed = GetGameTimer() - (menuNotifyEnd - 2000)
        local na = 1.0
        if elapsed > 1500 then na = 1.0 - (elapsed - 1500) / 500 end
        local nc = menuNotifyCol or T.green
        local ny = TOP_Y - 0.035

        dR(px, ny, PANEL_W + 0.02, 0.028, Ca(C(nc.r, nc.g, nc.b, 200), na))
        dT(menuNotify, px, ny - 0.009, 0.27, Ca(T.white, na), 4, 'c')
    elseif menuNotify and GetGameTimer() >= menuNotifyEnd then
        menuNotify = nil
    end
end

-- ── Main Thread ──
CreateThread(function()
    while true do
        if menuOpen then
            menuInput()
            drawMenu()

            -- Update 3D preview
            if menuItems[menuIndex] then
                updatePreview(menuItems[menuIndex].skin.model)
            else
                destroyPreview()
            end
            tickPreview()

            -- Disable controls while menu open
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 92, true)
            Wait(0)
        else
            Wait(200)
        end
    end
end)

RegisterCommand('homemenu', function()
    if menuOpen then closeMenu() else openMenu() end
end, false)

RegisterKeyMapping('homemenu', 'Skin Menu', 'keyboard', 'F12')
