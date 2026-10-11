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

local menuOpen = false
local menuTab = 1
local menuIndex = 1
local menuItems = {}
local menuTabs = { "POOLCUE", "BOTTLE" }
local menuInputCD = 0
local menuAnim = 0.0
local menuSelAnim = 0
local menuNotify = nil
local menuNotifyEnd = 0

local MX = 0.82
local MY = 0.08
local MW = 0.24
local ITEM_H = 0.036
local GAP = 0.002
local MAX_SHOW = 10

local function C(r, g, b, a) return { r = r, g = g, b = b, a = a or 255 } end

local THEME = {
    bg        = C(8, 8, 14, 235),
    header    = C(0, 0, 0, 0),
    grad_top  = C(0, 170, 255, 255),
    grad_bot  = C(0, 100, 220, 255),
    tab       = C(30, 30, 45, 220),
    tab_sel   = C(0, 140, 220, 255),
    tab_line  = C(0, 200, 255, 255),
    item      = C(18, 18, 28, 210),
    item_alt  = C(22, 22, 34, 210),
    sel       = C(0, 110, 200, 240),
    sel_glow  = C(0, 140, 255, 60),
    active    = C(0, 180, 90, 240),
    active_sel= C(0, 220, 120, 250),
    txt       = C(240, 240, 245),
    txt_dim   = C(140, 145, 160),
    txt_acc   = C(80, 200, 255),
    badge_fx  = C(60, 160, 255),
    badge_kill= C(255, 70, 70),
    badge_on  = C(80, 230, 120),
    footer    = C(12, 12, 20, 230),
    divider   = C(50, 50, 70, 120),
    notify_bg = C(0, 180, 100, 230),
    shadow    = C(0, 0, 0, 100),
}

local function dR(x, y, w, h, c)
    DrawRect(x, y, w, h, c.r, c.g, c.b, c.a)
end

local function dT(text, x, y, scale, c, font, align)
    SetTextFont(font or 4)
    SetTextScale(scale, scale)
    SetTextColour(c.r, c.g, c.b, c.a)
    if align == 'r' then
        SetTextJustification(2)
        SetTextWrap(0.0, x)
    elseif align == 'c' then
        SetTextJustification(0)
        SetTextWrap(0.0, 1.0)
    end
    SetTextDropShadow(1, 0, 0, 0, 200)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText((align == 'r') and 0.0 or x, y)
end

local function lerp(a, b, t)
    return a + (b - a) * math.min(math.max(t, 0), 1)
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
    menuNotify = "~g~Equipped: ~w~" .. sk.name
    menuNotifyEnd = GetGameTimer() + 1500
end

local function removeMenuSkin(wType)
    activeSkins[wType] = nil
    saveKVP(wType, '')
    destroyProp()
    menuNotify = "~r~Removed ~w~" .. wType .. " skin"
    menuNotifyEnd = GetGameTimer() + 1500
end

local function openMenu()
    menuOpen = true
    menuTab = 1
    menuIndex = 1
    menuAnim = 0.0
    buildMenuItems()
end

local function closeMenu()
    menuOpen = false
end

local function menuInput()
    local now = GetGameTimer()
    if now < menuInputCD then return end
    local cd = 150

    if IsControlJustPressed(0, 172) then
        menuIndex = menuIndex - 1
        if menuIndex < 1 then menuIndex = #menuItems end
        menuInputCD = now + cd
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 173) then
        menuIndex = menuIndex + 1
        if menuIndex > #menuItems then menuIndex = 1 end
        menuInputCD = now + cd
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 174) then
        menuTab = menuTab - 1
        if menuTab < 1 then menuTab = #menuTabs end
        menuIndex = 1
        buildMenuItems()
        menuInputCD = now + cd
        PlaySoundFrontend(-1, "NAV_LEFT_RIGHT", "HUD_FREEMODE_SOUNDSET", true)
    elseif IsControlJustPressed(0, 175) then
        menuTab = menuTab + 1
        if menuTab > #menuTabs then menuTab = 1 end
        menuIndex = 1
        buildMenuItems()
        menuInputCD = now + cd
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
        menuInputCD = now + 250
        PlaySoundFrontend(-1, "BACK", "HUD_FREEMODE_SOUNDSET", true)
    end
end

local function drawMenu()
    menuAnim = lerp(menuAnim, 1.0, 0.12)
    local alpha = menuAnim
    local offsetX = (1.0 - alpha) * 0.03
    local cx = MX + offsetX
    local y = MY

    -- Shadow behind entire menu
    dR(cx + 0.003, y + 0.20, MW + 0.006, 0.42, C(0, 0, 0, math.floor(80 * alpha)))

    -- ══════ HEADER ══════
    local headH = 0.050
    -- Gradient header (2 strips)
    dR(cx, y + headH * 0.25, MW, headH * 0.5, C(0, 140, 240, math.floor(255 * alpha)))
    dR(cx, y + headH * 0.75, MW, headH * 0.5, C(0, 100, 200, math.floor(255 * alpha)))

    dT("AQUA", cx - 0.035, y + 0.008, 0.50, C(255, 255, 255, math.floor(255 * alpha)), 1, 'c')
    dT("SKINS", cx + 0.030, y + 0.008, 0.50, C(180, 230, 255, math.floor(255 * alpha)), 1, 'c')

    -- Accent line under header
    dR(cx, y + headH + 0.001, MW, 0.003, C(0, 220, 255, math.floor(200 * alpha)))

    y = y + headH + 0.006

    -- ══════ TAB BAR ══════
    local tabH = 0.030
    dR(cx, y + tabH / 2, MW, tabH, C(THEME.bg.r, THEME.bg.g, THEME.bg.b, math.floor(THEME.bg.a * alpha)))

    local tabW = MW / #menuTabs
    for i, name in ipairs(menuTabs) do
        local tx = cx - MW / 2 + tabW * (i - 0.5)
        local isSel = (i == menuTab)
        local hasActive = activeSkins[name] ~= nil

        if isSel then
            dR(tx, y + tabH / 2, tabW - 0.004, tabH - 0.004, C(THEME.tab_sel.r, THEME.tab_sel.g, THEME.tab_sel.b, math.floor(THEME.tab_sel.a * alpha)))
            dR(tx, y + tabH - 0.001, tabW - 0.004, 0.003, C(THEME.tab_line.r, THEME.tab_line.g, THEME.tab_line.b, math.floor(255 * alpha)))
        else
            dR(tx, y + tabH / 2, tabW - 0.004, tabH - 0.004, C(THEME.tab.r, THEME.tab.g, THEME.tab.b, math.floor(THEME.tab.a * alpha)))
        end

        local label = name
        if hasActive then label = name .. "  ~g~●" end
        local tc = isSel and THEME.txt or THEME.txt_dim
        dT(label, tx, y + 0.005, 0.28, C(tc.r, tc.g, tc.b, math.floor(tc.a * alpha)), 4, 'c')
    end

    y = y + tabH + 0.004

    -- ══════ SKIN LIST ══════
    local listBgH = (#menuItems == 0 and 1 or math.min(#menuItems, MAX_SHOW)) * (ITEM_H + GAP) + 0.008
    dR(cx, y + listBgH / 2, MW, listBgH, C(THEME.bg.r, THEME.bg.g, THEME.bg.b, math.floor(THEME.bg.a * alpha)))

    y = y + 0.004

    if #menuItems == 0 then
        dT("No skins available", cx, y + 0.006, 0.30, C(THEME.txt_dim.r, THEME.txt_dim.g, THEME.txt_dim.b, math.floor(200 * alpha)), 4, 'c')
        y = y + ITEM_H
    else
        local scrollOff = 0
        if #menuItems > MAX_SHOW then
            scrollOff = math.max(0, math.min(menuIndex - math.floor(MAX_SHOW / 2), #menuItems - MAX_SHOW))
        end

        -- scroll indicator top
        if scrollOff > 0 then
            dT("~b~▲", cx, y - 0.002, 0.22, C(THEME.txt_acc.r, THEME.txt_acc.g, THEME.txt_acc.b, math.floor(200 * alpha)), 4, 'c')
        end

        for i = scrollOff + 1, math.min(scrollOff + MAX_SHOW, #menuItems) do
            local item = menuItems[i]
            local wType = menuTabs[menuTab]
            local isActive = (activeSkins[wType] == item.id)
            local isSel = (i == menuIndex)
            local iy = y + (ITEM_H + GAP) / 2

            -- item background
            local bgc
            if isSel and isActive then bgc = THEME.active_sel
            elseif isSel then bgc = THEME.sel
            elseif isActive then bgc = THEME.active
            elseif (i % 2 == 0) then bgc = THEME.item_alt
            else bgc = THEME.item end

            dR(cx, iy, MW - 0.008, ITEM_H, C(bgc.r, bgc.g, bgc.b, math.floor(bgc.a * alpha)))

            -- selection indicator bar
            if isSel then
                dR(cx - MW / 2 + 0.006, iy, 0.003, ITEM_H - 0.006, C(THEME.tab_line.r, THEME.tab_line.g, THEME.tab_line.b, math.floor(255 * alpha)))
            end

            -- skin name
            local nameX = cx - MW / 2 + 0.014
            local nameCol = isSel and THEME.txt or (isActive and THEME.txt or THEME.txt_dim)
            dT(item.skin.name, nameX, y + 0.007, 0.26, C(nameCol.r, nameCol.g, nameCol.b, math.floor(nameCol.a * alpha)), 4)

            -- badges on right
            local bx = cx + MW / 2 - 0.012
            if isActive then
                dT("~g~ON", bx, y + 0.007, 0.23, C(THEME.badge_on.r, THEME.badge_on.g, THEME.badge_on.b, math.floor(255 * alpha)), 4, 'r')
                bx = bx - 0.025
            end
            if item.skin.kill then
                dT("~r~K", bx, y + 0.007, 0.23, C(THEME.badge_kill.r, THEME.badge_kill.g, THEME.badge_kill.b, math.floor(255 * alpha)), 4, 'r')
                bx = bx - 0.016
            end
            if item.skin.ptfx then
                dT("~b~F", bx, y + 0.007, 0.23, C(THEME.badge_fx.r, THEME.badge_fx.g, THEME.badge_fx.b, math.floor(255 * alpha)), 4, 'r')
            end

            y = y + ITEM_H + GAP
        end

        -- scroll indicator bottom
        if scrollOff + MAX_SHOW < #menuItems then
            dT("~b~▼", cx, y + 0.001, 0.22, C(THEME.txt_acc.r, THEME.txt_acc.g, THEME.txt_acc.b, math.floor(200 * alpha)), 4, 'c')
            y = y + 0.012
        end

        -- counter
        if #menuItems > 1 then
            dT(menuIndex .. " / " .. #menuItems, cx, y + 0.001, 0.20, C(THEME.txt_dim.r, THEME.txt_dim.g, THEME.txt_dim.b, math.floor(180 * alpha)), 4, 'c')
            y = y + 0.016
        end
    end

    -- ══════ SELECTED SKIN INFO ══════
    if menuItems[menuIndex] then
        local sk = menuItems[menuIndex].skin
        local infoH = 0.045
        y = y + 0.002
        dR(cx, y + infoH / 2, MW, infoH, C(15, 15, 25, math.floor(220 * alpha)))
        dR(cx, y + 0.001, MW, 0.002, C(THEME.divider.r, THEME.divider.g, THEME.divider.b, math.floor(THEME.divider.a * alpha)))

        dT("Model: ~b~" .. sk.model, cx - MW / 2 + 0.010, y + 0.006, 0.22, C(THEME.txt_dim.r, THEME.txt_dim.g, THEME.txt_dim.b, math.floor(220 * alpha)), 4)

        local features = {}
        if sk.ptfx then features[#features+1] = "~b~Hand FX" end
        if sk.kill then features[#features+1] = "~r~Kill FX" end
        if #features == 0 then features[#features+1] = "~w~Basic" end
        dT(table.concat(features, " ~w~| "), cx - MW / 2 + 0.010, y + 0.024, 0.20, C(THEME.txt_dim.r, THEME.txt_dim.g, THEME.txt_dim.b, math.floor(200 * alpha)), 4)

        y = y + infoH
    end

    -- ══════ FOOTER ══════
    y = y + 0.004
    local footH = 0.028
    dR(cx, y + footH / 2, MW, footH, C(THEME.footer.r, THEME.footer.g, THEME.footer.b, math.floor(THEME.footer.a * alpha)))
    dT("~b~< > ~w~Tab   ~b~Enter ~w~Select   ~b~Bksp ~w~Close", cx, y + 0.004, 0.20, C(THEME.txt_dim.r, THEME.txt_dim.g, THEME.txt_dim.b, math.floor(220 * alpha)), 4, 'c')

    -- ══════ NOTIFICATION ══════
    if menuNotify and GetGameTimer() < menuNotifyEnd then
        local ny = MY - 0.035
        local na = math.floor(lerp(255, 0, (GetGameTimer() - (menuNotifyEnd - 1500)) / 1500) + 255)
        if na > 255 then na = 255 end
        dR(cx, ny, MW, 0.026, C(THEME.notify_bg.r, THEME.notify_bg.g, THEME.notify_bg.b, math.floor(math.min(na, 230))))
        dT(menuNotify, cx, ny - 0.008, 0.25, C(255, 255, 255, math.min(na, 255)), 4, 'c')
    elseif menuNotify then
        menuNotify = nil
    end
end

CreateThread(function()
    while true do
        if menuOpen then
            menuInput()
            drawMenu()
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            Wait(0)
        else
            Wait(200)
        end
    end
end)

RegisterCommand('homemenu', function()
    if menuOpen then closeMenu() else openMenu() end
end, false)

RegisterKeyMapping('homemenu', 'Open Skin Menu', 'keyboard', 'HOME')
