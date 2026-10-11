-- =====================================================================
-- BYPASS Ex_Weaponeffects + nc_inventory Weapon Skin Unlocker
-- /skin [ชื่อ] = ใส่สกิน | /skin off = ถอด | /skinlist = ดูรายชื่อ
-- /skindebug = debug อาวุธที่ถืออยู่
-- =====================================================================

print("^2[SKIN-BYPASS] >>> โหลดสำเร็จ! พิมพ์ /skinlist ดูสกินทั้งหมด | /skin [ชื่อ] ใส่สกิน ^7")
pcall(function()
    TriggerEvent('chat:addMessage', { args = { "^2[SKIN]", "^2โหลดสำเร็จ! /skinlist ดูสกิน | /skin [ชื่อ] ใส่สกิน | /skin off ถอด^0" } })
end)

local active = false
local currentSkinKey = nil
local equippedWeaponHash = nil
local autoEquipRunning = false
local holdFxRunning = false
local damageHandlerRegistered = false
local lastEffectTime = 0
local RES = "Ex_Weaponeffects"

-- ========== WEAPON TYPE DETECTION ==========
local POOLCUE_NAMES = {
    'WEAPON_POOLCUE', 'WEAPON_POOLCUE0', 'WEAPON_POOLCUE1', 'WEAPON_POOLCUE2',
    'WEAPON_POOLCUE3', 'WEAPON_POOLCUE4', 'WEAPON_POOLCUE5',
    'WEAPON_POOLCUE6', 'WEAPON_POOLCUE7', 'WEAPON_POOLCUE8', 'WEAPON_POOLCUE9',
    'WEAPON_POOLCUE10', 'WEAPON_POOLCUE14DAY', 'WEAPON_POOLCUEWAR',
}

local BOTTLE_NAMES = {
    'WEAPON_BOTTLE', 'WEAPON_BOTTLE0', 'WEAPON_BOTTLE1', 'WEAPON_BOTTLE2',
    'WEAPON_BOTTLE3', 'WEAPON_BOTTLE4', 'WEAPON_BOTTLE5',
    'WEAPON_BOTTLE6', 'WEAPON_BOTTLE7', 'WEAPON_BOTTLE8', 'WEAPON_BOTTLE9',
    'WEAPON_KNIFE', 'WEAPON_DAGGER', 'WEAPON_SWITCHBLADE',
}

local KNUCKLE_NAMES = {
    'WEAPON_KNUCKLEDUSTER', 'WEAPON_KNUCKLE', 'WEAPON_KNUCKLE0', 'WEAPON_KNUCKLE1',
    'WEAPON_KNUCKLE2', 'WEAPON_KNUCKLE3',
}

local MACHETE_NAMES = {
    'WEAPON_MACHETE', 'WEAPON_MACHETE0', 'WEAPON_MACHETE1', 'WEAPON_MACHETE2',
    'WEAPON_MACHETE3',
}

local weaponHashCache = {}

local function BuildHashCache()
    for _, name in ipairs(POOLCUE_NAMES) do
        weaponHashCache[GetHashKey(name)] = 'poolcue'
    end
    for _, name in ipairs(BOTTLE_NAMES) do
        weaponHashCache[GetHashKey(name)] = 'bottle'
    end
    for _, name in ipairs(KNUCKLE_NAMES) do
        weaponHashCache[GetHashKey(name)] = 'knuckle'
    end
    for _, name in ipairs(MACHETE_NAMES) do
        weaponHashCache[GetHashKey(name)] = 'machete'
    end
end

local function GetWeaponType(wHash)
    if not wHash or wHash == 0 then return nil end
    if wHash == GetHashKey('WEAPON_UNARMED') then return nil end
    local t = weaponHashCache[wHash]
    if t then return t end
    if wHash < 0 then
        t = weaponHashCache[wHash + 0x100000000]
        if t then weaponHashCache[wHash] = t return t end
    else
        t = weaponHashCache[wHash - 0x100000000]
        if t then weaponHashCache[wHash] = t return t end
    end
    return nil
end

local function IsHoldingWeapon()
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    if curWeapon == GetHashKey('WEAPON_UNARMED') then return false, nil, nil end
    local wpEntity = GetCurrentPedWeaponEntityIndex(ped)
    if wpEntity ~= 0 and DoesEntityExist(wpEntity) then
        return true, curWeapon, wpEntity
    end
    return curWeapon ~= 0, curWeapon, nil
end

-- ========== SKIN DATABASE ==========
local SKIN_DB = {
    -- POOLCUE
    bunny_pool = {
        label = "BUNNY",
        weaponType = "poolcue",
        component = "COMPONENT_POOL_SKIN_01",
        modelHash = "things_freebunny_poolcue",
    },
    syrus_pool = {
        label = "SYRUS",
        weaponType = "poolcue",
        component = "COMPONENT_POOL_SKIN_02",
        modelHash = "w_me_poolsyrus",
    },
    spark_pool = {
        label = "SPARK OVER",
        weaponType = "poolcue",
        component = "COMPONENT_POOL_SKIN_03",
        modelHash = "lazy_sparkover_poolcue",
    },
    sleepy_pool = {
        label = "SLEEPY",
        weaponType = "poolcue",
        component = "COMPONENT_POOL_SKIN_04",
        modelHash = "bbg_wp26_poolcue",
    },
    tiger_pool = {
        label = "WHITE TIGER",
        weaponType = "poolcue",
        component = "COMPONENT_POOL_SKIN_05",
        modelHash = "sharkz_poolcue_white_tiger",
    },

    -- BOTTLE / KNIFE
    syrus_bottle = {
        label = "SYRUS",
        weaponType = "bottle",
        component = "COMPONENT_BOTTLE_SKIN_01",
        modelHash = "w_me_knife_syrus",
    },
    spark_bottle = {
        label = "SPARK OVER",
        weaponType = "bottle",
        component = "COMPONENT_BOTTLE_SKIN_02",
        modelHash = "lazy_sparkover_bottle",
    },
    sleepy_bottle = {
        label = "SLEEPY",
        weaponType = "bottle",
        component = "COMPONENT_BOTTLE_SKIN_03",
        modelHash = "bbg_wp26_dagger",
    },
    tiger_bottle = {
        label = "WHITE TIGER",
        weaponType = "bottle",
        component = "COMPONENT_BOTTLE_SKIN_04",
        modelHash = "sharkz_bottle_white_tiger",
    },
}

-- ========== COMPONENT MANAGEMENT ==========
local ALL_COMPONENTS = {}
for _, data in pairs(SKIN_DB) do
    ALL_COMPONENTS[#ALL_COMPONENTS + 1] = data.component
end

local function RemoveAllSkinComponents(ped, wHash)
    for _, comp in ipairs(ALL_COMPONENTS) do
        local compHash = GetHashKey(comp)
        pcall(function()
            if HasPedGotWeaponComponent(ped, wHash, compHash) then
                RemoveWeaponComponentFromPed(ped, wHash, compHash)
            end
        end)
    end
end

local function ApplySkinComponent(ped, wHash, skinData)
    if not skinData or not skinData.component then return false end
    RemoveAllSkinComponents(ped, wHash)
    local compHash = GetHashKey(skinData.component)
    GiveWeaponComponentToPed(ped, wHash, compHash)
    return true
end

-- ========== PTFX HOLD EFFECT ==========
local loadedPtfx = {}

local function EnsurePtfx(asset)
    if not asset then return false end
    if loadedPtfx[asset] then return true end
    RequestNamedPtfxAsset(asset)
    local t = GetGameTimer() + 3000
    while not HasNamedPtfxAssetLoaded(asset) and GetGameTimer() < t do Wait(10) end
    if HasNamedPtfxAssetLoaded(asset) then
        loadedPtfx[asset] = true
        return true
    end
    return false
end

local function GetEffectConfig(skinData)
    if not skinData or not skinData.modelHash then return nil end
    local modelH = GetHashKey(skinData.modelHash)
    local cfg = nil
    pcall(function()
        if Config and Config.Weapon then
            cfg = Config.Weapon[modelH]
        end
    end)
    return cfg
end

local function PlayHoldEffect(ped, skinData)
    local cfg = GetEffectConfig(skinData)
    if not cfg or not cfg.EffectCarry or not cfg.EffectCarry.Effect then return end

    local weaponEntity = GetCurrentPedWeaponEntityIndex(ped)
    local useEntity = weaponEntity ~= nil and weaponEntity ~= 0 and DoesEntityExist(weaponEntity)

    for _, ef in ipairs(cfg.EffectCarry.Effect) do
        if ef.enabled ~= false and ef.Asset and ef.Name and EnsurePtfx(ef.Asset) then
            local pos = ef.position or {}
            UseParticleFxAssetNextCall(ef.Asset)
            if useEntity then
                StartParticleFxNonLoopedOnEntity(
                    ef.Name, weaponEntity,
                    pos.posx or 0.0, pos.posy or 0.0, pos.posz or 0.0,
                    pos.rotx or 0.0, pos.roty or 0.0, pos.rotz or 0.0,
                    pos.scale or 1.0,
                    false, false, false
                )
            else
                StartParticleFxNonLoopedOnPedBone(
                    ef.Name, ped,
                    pos.posx or 0.0, pos.posy or 0.0, pos.posz or 0.0,
                    pos.rotx or 0.0, pos.roty or 0.0, pos.rotz or 0.0,
                    57005, pos.scale or 1.0,
                    false, false, false
                )
            end
        end
    end
end

local function StartHoldFxLoop(skinData)
    if holdFxRunning then return end
    holdFxRunning = true
    CreateThread(function()
        while holdFxRunning and active do
            local ped = PlayerPedId()
            local holding, curWeapon = IsHoldingWeapon()
            if holding then
                local wType = GetWeaponType(curWeapon)
                if wType == skinData.weaponType or wType == nil then
                    PlayHoldEffect(ped, skinData)
                end
            end
            local interval = 1000
            local cfg = GetEffectConfig(skinData)
            if cfg and cfg.EffectCarry and cfg.EffectCarry.interval then
                interval = cfg.EffectCarry.interval
            end
            Wait(interval)
        end
        holdFxRunning = false
    end)
end

-- ========== HIT/KILL EFFECTS (LOCAL) ==========
local function PlayHitEffect(skinData, victimPed, isDead)
    local cfg = GetEffectConfig(skinData)
    if not cfg then return end

    local now = GetGameTimer()
    if now - lastEffectTime < 3000 then return end
    lastEffectTime = now

    local effectWeapon = cfg.EffectWeapon
    if not effectWeapon then return end

    local shouldPlay = false
    if effectWeapon.CriticalEffect == 'kill' then
        shouldPlay = isDead
    elseif effectWeapon.CriticalEffect == 'cri' then
        shouldPlay = isDead
    else
        shouldPlay = true
    end
    if not shouldPlay then return end

    local entries = {}
    if type(effectWeapon.ParticleEffect) == 'table' then
        entries = effectWeapon.ParticleEffect
    elseif effectWeapon.NameParticleEffect then
        entries = { effectWeapon }
    end

    for _, ef in ipairs(entries) do
        local namePair = ef.NameParticleEffect
        if namePair and namePair[1] and namePair[2] then
            CreateThread(function()
                if EnsurePtfx(namePair[1]) then
                    UseParticleFxAssetNextCall(namePair[1])
                    StartParticleFxNonLoopedOnPedBone(
                        namePair[2], victimPed,
                        ef.offsetX or effectWeapon.offsetX or 0.0,
                        ef.offsetY or effectWeapon.offsetY or 0.0,
                        ef.offsetZ or effectWeapon.offsetZ or 0.05,
                        ef.rotationX or effectWeapon.rotationX or 0.0,
                        ef.rotationY or effectWeapon.rotationY or 90.0,
                        ef.rotationZ or effectWeapon.rotationZ or 0.0,
                        31086,
                        ef.Scale or effectWeapon.Scale or 1.0,
                        false, false, false
                    )
                end
            end)
        end
    end

    if cfg.EffectImg then
        pcall(function()
            SendNUIMessage({
                action = 'Effect',
                image = cfg.EffectImg.ImageShow,
                time = cfg.EffectImg.TimeImage or 3,
                SoundName = cfg.EffectImg.SoundName,
                SoundValue = cfg.EffectImg.SoundValue or 0.4,
            })
        end)
    end
end

local function RegisterDamageHandler()
    if damageHandlerRegistered then return end
    damageHandlerRegistered = true
    AddEventHandler("gameEventTriggered", function(eventName, eventData)
        if not active or not currentSkinKey then return end
        if eventName ~= "CEventNetworkEntityDamage" then return end
        local victim = eventData[1]
        local attacker = eventData[2]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped then return end

        local skinData = SKIN_DB[currentSkinKey]
        if not skinData then return end

        local isDead = eventData[4] == 1 or IsEntityDead(victim)
        PlayHitEffect(skinData, victim, isDead)
    end)
end

-- ========== AUTO EQUIP LOOP ==========
local function StartAutoEquip(skinData)
    if autoEquipRunning then return end
    autoEquipRunning = true
    CreateThread(function()
        while autoEquipRunning and active do
            local ped = PlayerPedId()
            local holding, curWeapon = IsHoldingWeapon()
            if holding then
                local wType = GetWeaponType(curWeapon)
                if wType == skinData.weaponType or wType == nil then
                    local compHash = GetHashKey(skinData.component)
                    if not HasPedGotWeaponComponent(ped, curWeapon, compHash) then
                        GiveWeaponComponentToPed(ped, curWeapon, compHash)
                    end
                    equippedWeaponHash = curWeapon
                end
            end
            Wait(300)
        end
        autoEquipRunning = false
    end)
end

-- ========== ANTI-DETECT ==========
local origTSE = TriggerServerEvent
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == "string" then
        local lower = string.lower(eventName)
        if lower:find("weaponskin") or lower:find("weapon_skin") or lower:find("ex_weapon") then
            if lower:find("report") or lower:find("guard") or lower:find("detect")
                or lower:find("kick") or lower:find("cheat") or lower:find("check")
                or lower:find("log") or lower:find("ban") or lower:find("verify")
                or lower:find("anticheat") or lower:find("validate") or lower:find("security") then
                return
            end
        end
    end
    return origTSE(eventName, ...)
end

-- ========== MSG HELPER ==========
local function SendMsg(text)
    print("^3[SKIN]^7 " .. text)
    pcall(function()
        TriggerEvent('chat:addMessage', { args = { "[SKIN]", text } })
    end)
end

-- ========== INIT ==========
CreateThread(function()
    Wait(2000)
    BuildHashCache()
    print("^2[SKIN-BYPASS] Hash cache built^7")
end)

-- ========== /skinlist ==========
RegisterCommand('skinlist', function()
    print("^2===================== [SKIN LIST] =====================^7")
    print("^3--- POOLCUE (ไม้พูล) ---^7")
    for key, data in pairs(SKIN_DB) do
        if data.weaponType == "poolcue" then
            local marker = (key == currentSkinKey) and " ^2<< EQUIPPED^7" or ""
            local hasFx = ""
            local cfg = GetEffectConfig(data)
            if cfg then
                local fx = (cfg.EffectWeapon) and "FX" or ""
                local hand = (cfg.EffectCarry and cfg.EffectCarry.Effect) and "+HAND" or ""
                local scr = (cfg.EffectImg and cfg.EffectImg.ImageShow) and "+SCR" or ""
                local snd = (cfg.EffectImg and cfg.EffectImg.SoundName) and "+SND" or ""
                hasFx = (" ^5[%s%s%s%s]^7"):format(fx, hand, scr, snd)
            end
            print(("  ^6/skin %-15s^7 = %s%s%s"):format(key, data.label, hasFx, marker))
        end
    end
    print("^3--- BOTTLE/KNIFE (ขวด/มีด) ---^7")
    for key, data in pairs(SKIN_DB) do
        if data.weaponType == "bottle" then
            local marker = (key == currentSkinKey) and " ^2<< EQUIPPED^7" or ""
            local hasFx = ""
            local cfg = GetEffectConfig(data)
            if cfg then
                local fx = (cfg.EffectWeapon) and "FX" or ""
                local hand = (cfg.EffectCarry and cfg.EffectCarry.Effect) and "+HAND" or ""
                local scr = (cfg.EffectImg and cfg.EffectImg.ImageShow) and "+SCR" or ""
                local snd = (cfg.EffectImg and cfg.EffectImg.SoundName) and "+SND" or ""
                hasFx = (" ^5[%s%s%s%s]^7"):format(fx, hand, scr, snd)
            end
            print(("  ^6/skin %-15s^7 = %s%s%s"):format(key, data.label, hasFx, marker))
        end
    end
    print("")
    print("^3วิธีใช้:^7 ถืออาวุธแล้วพิมพ์ ^6/skin [ชื่อ]^7 เช่น ^6/skin syrus_pool^7")
    print("^3ถอด:^7 ^1/skin off^7")
    print("^3Debug:^7 ^6/skindebug^7 (ดู hash อาวุธที่ถืออยู่)")
    print("^2========================================================^7")
    SendMsg("^2รายชื่อสกินขึ้นใน F8 แล้ว^0")
end, false)

-- ========== /skindebug ==========
RegisterCommand('skindebug', function()
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    local wpEntity = GetCurrentPedWeaponEntityIndex(ped)
    local wType = GetWeaponType(curWeapon)
    local modelHash = nil
    if wpEntity ~= 0 and DoesEntityExist(wpEntity) then
        modelHash = GetEntityModel(wpEntity)
    end

    print("^2========== [SKIN DEBUG] ==========^7")
    print(("  ^3Weapon Hash:^7 %s (%s)"):format(tostring(curWeapon), tostring(curWeapon and string.format("0x%X", curWeapon & 0xFFFFFFFF) or "nil")))
    print(("  ^3Weapon Entity:^7 %s (exists: %s)"):format(tostring(wpEntity), tostring(wpEntity ~= 0 and DoesEntityExist(wpEntity))))
    print(("  ^3Model Hash:^7 %s"):format(tostring(modelHash)))
    print(("  ^3Detected Type:^7 %s"):format(tostring(wType) or "UNKNOWN"))
    print(("  ^3Is Unarmed:^7 %s"):format(tostring(curWeapon == GetHashKey('WEAPON_UNARMED'))))

    print("  ^3Hash checks:^7")
    local testNames = {'WEAPON_POOLCUE','WEAPON_POOLCUE1','WEAPON_POOLCUE2','WEAPON_POOLCUE3','WEAPON_BOTTLE','WEAPON_BOTTLE1','WEAPON_BOTTLE2','WEAPON_BOTTLE3','WEAPON_KNIFE','WEAPON_DAGGER'}
    for _, name in ipairs(testNames) do
        local h = GetHashKey(name)
        local match = (h == curWeapon) and "^2 << MATCH!^7" or ""
        local matchNeg = ""
        if h ~= curWeapon then
            if curWeapon < 0 and (curWeapon + 0x100000000) == h then matchNeg = "^2 << MATCH (unsigned)!^7"
            elseif curWeapon > 0 and (curWeapon - 0x100000000) == h then matchNeg = "^2 << MATCH (signed)!^7"
            end
        end
        print(("    %s = %s%s%s"):format(name, tostring(h), match, matchNeg))
    end

    print(("  ^3Active skin:^7 %s"):format(tostring(currentSkinKey) or "none"))
    print(("  ^3Active:^7 %s"):format(tostring(active)))
    print("^2===================================^7")
    SendMsg("^2Debug info ขึ้นใน F8 แล้ว^0")
end, false)

-- ========== /skin ==========
RegisterCommand('skin', function(_, args)
    local input = args[1]
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)

    if not input or input == '' then
        SendMsg("^3พิมพ์ /skinlist ดูรายชื่อสกิน | /skin [ชื่อ] ใส่สกิน | /skin off ถอด^0")
        return
    end

    if input:lower() == 'list' then
        ExecuteCommand('skinlist')
        return
    end

    if input:lower() == 'off' or input:lower() == 'clear' or input:lower() == 'default' then
        if equippedWeaponHash and currentSkinKey then
            RemoveAllSkinComponents(ped, equippedWeaponHash)
        end
        if curWeapon and curWeapon ~= GetHashKey('WEAPON_UNARMED') then
            RemoveAllSkinComponents(ped, curWeapon)
        end
        currentSkinKey = nil
        equippedWeaponHash = nil
        active = false
        autoEquipRunning = false
        holdFxRunning = false
        SendMsg("^1[OFF]^0 ถอดสกินแล้ว")
        return
    end

    if input:lower() == 'debug' then
        ExecuteCommand('skindebug')
        return
    end

    local holding, heldWeapon = IsHoldingWeapon()
    if not holding then
        SendMsg("^1[ERROR]^0 ถืออาวุธก่อนแล้วค่อยใส่สกิน!")
        return
    end

    local wType = GetWeaponType(heldWeapon)

    local searchLower = input:lower()
    local foundKey, foundData = nil, nil

    -- exact match first
    if SKIN_DB[input] then
        foundKey, foundData = input, SKIN_DB[input]
    end

    -- exact key match (case insensitive)
    if not foundKey then
        for key, data in pairs(SKIN_DB) do
            if key:lower() == searchLower then
                foundKey, foundData = key, data
                break
            end
        end
    end

    -- partial match - prefer same weapon type, fallback to any
    if not foundKey then
        local fallbackKey, fallbackData = nil, nil
        for key, data in pairs(SKIN_DB) do
            if key:lower():find(searchLower, 1, true) or data.label:lower():find(searchLower, 1, true) then
                if wType and data.weaponType == wType then
                    foundKey, foundData = key, data
                    break
                elseif not fallbackKey then
                    fallbackKey, fallbackData = key, data
                end
            end
        end
        if not foundKey and fallbackKey then
            foundKey, foundData = fallbackKey, fallbackData
        end
    end

    if not foundKey or not foundData then
        SendMsg(("^1[NOT FOUND]^0 ไม่พบสกิน '%s' (พิมพ์ /skinlist ดูรายชื่อ)"):format(input))
        return
    end

    -- ถอดสกินเดิม
    if currentSkinKey and equippedWeaponHash then
        RemoveAllSkinComponents(ped, equippedWeaponHash)
    end
    if heldWeapon ~= equippedWeaponHash then
        RemoveAllSkinComponents(ped, heldWeapon)
    end
    holdFxRunning = false
    autoEquipRunning = false
    Wait(100)

    currentSkinKey = foundKey
    active = true

    ApplySkinComponent(ped, heldWeapon, foundData)
    equippedWeaponHash = heldWeapon

    StartAutoEquip(foundData)
    StartHoldFxLoop(foundData)
    RegisterDamageHandler()

    SendMsg(("^2[OK]^0 สวมสกิน ^6%s^0 (%s) สำเร็จ!"):format(foundData.label, foundKey))
end, false)
