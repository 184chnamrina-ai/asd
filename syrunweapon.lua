-- =====================================================================
-- BYPASS Ex_Weaponeffects + Weapon Skin Unlocker (FINAL)
-- /skin [ชื่อ] = ใส่สกิน | /skin off = ถอด | /skinlist = ดูรายชื่อ
-- =====================================================================

print("^2[SKIN] >>> โหลดสำเร็จ! /skinlist ดูสกิน | /skin [ชื่อ] ใส่สกิน ^7")
pcall(function()
    TriggerEvent('chat:addMessage', { args = { "^2[SKIN]", "^2โหลดสำเร็จ! /skinlist ดูสกิน | /skin [ชื่อ] ใส่ | /skin off ถอด^0" } })
end)

local active = false
local currentSkinKey = nil
local equippedWeaponHash = nil
local holdFxToken = 0
local autoEquipToken = 0
local damageHandlerRegistered = false
local lastEffectTime = 0

-- ========== WEAPON NAME -> HASH MAP ==========
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
    WEAPON_POOLCUE = 'poolcue', WEAPON_POOLCUE0 = 'poolcue', WEAPON_POOLCUE1 = 'poolcue',
    WEAPON_POOLCUE2 = 'poolcue', WEAPON_POOLCUE3 = 'poolcue', WEAPON_POOLCUE4 = 'poolcue',
    WEAPON_POOLCUE5 = 'poolcue', WEAPON_POOLCUE6 = 'poolcue', WEAPON_POOLCUE7 = 'poolcue',
    WEAPON_POOLCUE8 = 'poolcue', WEAPON_POOLCUE9 = 'poolcue', WEAPON_POOLCUE10 = 'poolcue',
    WEAPON_POOLCUE14DAY = 'poolcue', WEAPON_POOLCUEWAR = 'poolcue',
    WEAPON_BOTTLE = 'bottle', WEAPON_BOTTLE0 = 'bottle', WEAPON_BOTTLE1 = 'bottle',
    WEAPON_BOTTLE2 = 'bottle', WEAPON_BOTTLE3 = 'bottle', WEAPON_BOTTLE4 = 'bottle',
    WEAPON_BOTTLE5 = 'bottle', WEAPON_BOTTLE6 = 'bottle', WEAPON_BOTTLE7 = 'bottle',
    WEAPON_BOTTLE8 = 'bottle', WEAPON_BOTTLE9 = 'bottle',
    WEAPON_KNIFE = 'bottle', WEAPON_DAGGER = 'bottle', WEAPON_SWITCHBLADE = 'bottle',
}

local hashToName = {}
local hashToType = {}

local function BuildHashCache()
    for _, name in ipairs(ALL_WEAPON_NAMES) do
        local h = GetHashKey(name)
        hashToName[h] = name
        hashToType[h] = WEAPON_TYPE_MAP[name]
    end
end

local function GetWeaponName(wHash)
    if not wHash or wHash == 0 then return nil end
    local n = hashToName[wHash]
    if n then return n end
    for _, name in ipairs(ALL_WEAPON_NAMES) do
        local h = GetHashKey(name)
        if wHash == h or (wHash < 0 and wHash + 0x100000000 == h) or (wHash > 0 and wHash - 0x100000000 == h) then
            hashToName[wHash] = name
            hashToType[wHash] = WEAPON_TYPE_MAP[name]
            return name
        end
    end
    return nil
end

local function GetWeaponType(wHash)
    if not wHash or wHash == 0 then return nil end
    if wHash == GetHashKey('WEAPON_UNARMED') then return nil end
    local t = hashToType[wHash]
    if t then return t end
    GetWeaponName(wHash)
    return hashToType[wHash]
end

local function IsHoldingWeapon()
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    if curWeapon == GetHashKey('WEAPON_UNARMED') then return false, nil end
    return true, curWeapon
end

-- ========== SKIN DATABASE ==========
local SKIN_DB = {
    bunny_pool    = { label = "BUNNY",       weaponType = "poolcue", skinModel = "things_freebunny_poolcue", component = "COMPONENT_POOL_SKIN_01" },
    syrus_pool    = { label = "SYRUS",       weaponType = "poolcue", skinModel = "w_me_poolsyrus",          component = "COMPONENT_POOL_SKIN_02" },
    spark_pool    = { label = "SPARK OVER",  weaponType = "poolcue", skinModel = "lazy_sparkover_poolcue",   component = "COMPONENT_POOL_SKIN_03" },
    sleepy_pool   = { label = "SLEEPY",      weaponType = "poolcue", skinModel = "bbg_wp26_poolcue",         component = "COMPONENT_POOL_SKIN_04" },
    tiger_pool    = { label = "WHITE TIGER", weaponType = "poolcue", skinModel = "sharkz_poolcue_white_tiger", component = "COMPONENT_POOL_SKIN_05" },
    syrus_bottle  = { label = "SYRUS",       weaponType = "bottle",  skinModel = "w_me_knife_syrus",         component = "COMPONENT_BOTTLE_SKIN_01" },
    spark_bottle  = { label = "SPARK OVER",  weaponType = "bottle",  skinModel = "lazy_sparkover_bottle",    component = "COMPONENT_BOTTLE_SKIN_02" },
    sleepy_bottle = { label = "SLEEPY",      weaponType = "bottle",  skinModel = "bbg_wp26_dagger",          component = "COMPONENT_BOTTLE_SKIN_03" },
    tiger_bottle  = { label = "WHITE TIGER", weaponType = "bottle",  skinModel = "sharkz_bottle_white_tiger", component = "COMPONENT_BOTTLE_SKIN_04" },
}

local ALL_SKIN_HASHES = {}
for _, data in pairs(SKIN_DB) do
    ALL_SKIN_HASHES[#ALL_SKIN_HASHES + 1] = data.skinModel
    ALL_SKIN_HASHES[#ALL_SKIN_HASHES + 1] = data.component
end

-- ========== COMPONENT ==========
local function RemoveAllSkins(ped, wHash)
    for _, name in ipairs(ALL_SKIN_HASHES) do
        local h = GetHashKey(name)
        pcall(function()
            if HasPedGotWeaponComponent(ped, wHash, h) then
                RemoveWeaponComponentFromPed(ped, wHash, h)
            end
        end)
    end
end

local function ForceApplySkin(ped, wHash, skinData)
    if not skinData then return end
    RemoveAllSkins(ped, wHash)
    GiveWeaponComponentToPed(ped, wHash, GetHashKey(skinData.skinModel))
    GiveWeaponComponentToPed(ped, wHash, GetHashKey(skinData.component))
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

-- ========== HOLD FX LOOP ==========
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
                    pos.scale or 1.0, false, false, false)
            else
                StartParticleFxNonLoopedOnPedBone(
                    ef.Name, ped,
                    pos.posx or 0.0, pos.posy or 0.0, pos.posz or 0.0,
                    pos.rotx or 0.0, pos.roty or 0.0, pos.rotz or 0.0,
                    57005, pos.scale or 1.0, false, false, false)
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
            local holding, curWeapon = IsHoldingWeapon()
            if holding then
                local wType = GetWeaponType(curWeapon)
                if wType == skinData.weaponType or wType == nil then
                    PlayHoldEffect(ped, skinData)
                end
            end
            local interval = 1000
            local cfg = GetEffectConfig(skinData)
            if cfg and cfg.EffectCarry and cfg.EffectCarry.interval then interval = cfg.EffectCarry.interval end
            Wait(interval)
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
    local shouldPlay = false
    if ew.CriticalEffect == 'kill' then shouldPlay = isDead
    elseif ew.CriticalEffect == 'cri' then shouldPlay = isDead
    else shouldPlay = true end
    if not shouldPlay then return end

    local entries = type(ew.ParticleEffect) == 'table' and ew.ParticleEffect or (ew.NameParticleEffect and { ew } or {})
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
            SendNUIMessage({ action = 'Effect', image = cfg.EffectImg.ImageShow,
                time = cfg.EffectImg.TimeImage or 3, SoundName = cfg.EffectImg.SoundName,
                SoundValue = cfg.EffectImg.SoundValue or 0.4 })
        end)
    end
end

local function RegisterDamageHandler()
    if damageHandlerRegistered then return end
    damageHandlerRegistered = true
    AddEventHandler("gameEventTriggered", function(eventName, eventData)
        if not active or not currentSkinKey then return end
        if eventName ~= "CEventNetworkEntityDamage" then return end
        local victim, attacker = eventData[1], eventData[2]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped then return end
        local skinData = SKIN_DB[currentSkinKey]
        if not skinData then return end
        PlayHitEffect(skinData, victim, eventData[4] == 1 or IsEntityDead(victim))
    end)
end

-- ========== AUTO EQUIP ==========
local function StartAutoEquip(skinData)
    autoEquipToken = autoEquipToken + 1
    local myToken = autoEquipToken
    CreateThread(function()
        while myToken == autoEquipToken and active do
            local ped = PlayerPedId()
            local holding, curWeapon = IsHoldingWeapon()
            if holding then
                local wType = GetWeaponType(curWeapon)
                if wType == skinData.weaponType or wType == nil then
                    local h1 = GetHashKey(skinData.skinModel)
                    local h2 = GetHashKey(skinData.component)
                    if not HasPedGotWeaponComponent(ped, curWeapon, h1) and not HasPedGotWeaponComponent(ped, curWeapon, h2) then
                        ForceApplySkin(ped, curWeapon, skinData)
                    end
                    equippedWeaponHash = curWeapon
                end
            end
            Wait(300)
        end
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

-- ========== HELPERS ==========
local function SendMsg(text)
    print("^3[SKIN]^7 " .. text)
    pcall(function() TriggerEvent('chat:addMessage', { args = { "[SKIN]", text } }) end)
end

local function StopLoops()
    holdFxToken = holdFxToken + 1
    autoEquipToken = autoEquipToken + 1
end

-- ========== INIT ==========
CreateThread(function() Wait(2000) BuildHashCache() end)

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
                local p = {}
                if cfg.EffectWeapon then p[#p+1] = "FX" end
                if cfg.EffectCarry and cfg.EffectCarry.Effect then p[#p+1] = "HAND" end
                if cfg.EffectImg and cfg.EffectImg.ImageShow then p[#p+1] = "SCR" end
                if cfg.EffectImg and cfg.EffectImg.SoundName then p[#p+1] = "SND" end
                if #p > 0 then hasFx = (" ^5[%s]^7"):format(table.concat(p, "+")) end
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
                local p = {}
                if cfg.EffectWeapon then p[#p+1] = "FX" end
                if cfg.EffectCarry and cfg.EffectCarry.Effect then p[#p+1] = "HAND" end
                if cfg.EffectImg and cfg.EffectImg.ImageShow then p[#p+1] = "SCR" end
                if cfg.EffectImg and cfg.EffectImg.SoundName then p[#p+1] = "SND" end
                if #p > 0 then hasFx = (" ^5[%s]^7"):format(table.concat(p, "+")) end
            end
            print(("  ^6/skin %-15s^7 = %s%s%s"):format(key, data.label, hasFx, marker))
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
    local curWeapon = GetSelectedPedWeapon(ped)
    local wName = GetWeaponName(curWeapon)
    local wType = GetWeaponType(curWeapon)
    local wpEntity = GetCurrentPedWeaponEntityIndex(ped)
    local modelHash = (wpEntity ~= 0 and DoesEntityExist(wpEntity)) and GetEntityModel(wpEntity) or nil

    print("^2========== [SKIN DEBUG] ==========^7")
    print(("  ^3Weapon Hash:^7 %s (0x%X)"):format(curWeapon, curWeapon & 0xFFFFFFFF))
    print(("  ^3Matched Name:^7 %s"):format(tostring(wName or "NONE - อาวุธนี้ไม่อยู่ใน list!")))
    print(("  ^3Type:^7 %s"):format(tostring(wType or "UNKNOWN")))
    print(("  ^3Entity:^7 %s | Model: %s"):format(tostring(wpEntity), tostring(modelHash)))
    print(("  ^3Active:^7 %s | Skin: %s"):format(tostring(active), tostring(currentSkinKey or "none")))

    if currentSkinKey and SKIN_DB[currentSkinKey] then
        local sd = SKIN_DB[currentSkinKey]
        local h1 = GetHashKey(sd.skinModel)
        local h2 = GetHashKey(sd.component)
        print(("  ^3skinModel:^7 %s (hash:%s) has:%s"):format(sd.skinModel, h1, tostring(HasPedGotWeaponComponent(ped, curWeapon, h1))))
        print(("  ^3component:^7 %s (hash:%s) has:%s"):format(sd.component, h2, tostring(HasPedGotWeaponComponent(ped, curWeapon, h2))))
    end

    print("  ^3All weapon hashes:^7")
    for _, name in ipairs(ALL_WEAPON_NAMES) do
        local h = GetHashKey(name)
        local match = (h == curWeapon or (curWeapon < 0 and curWeapon + 0x100000000 == h) or (curWeapon > 0 and curWeapon - 0x100000000 == h))
        if match then print(("    ^2%s = %s << MATCH!^7"):format(name, h)) end
    end
    print("^2===================================^7")
    SendMsg("^2Debug ขึ้น F8 แล้ว^0")
end, false)

-- ========== /skin ==========
RegisterCommand('skin', function(_, args)
    local input = args[1]
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)

    if not input or input == '' then SendMsg("^3/skinlist ดูสกิน | /skin [ชื่อ] ใส่ | /skin off ถอด^0") return end
    if input:lower() == 'list' then ExecuteCommand('skinlist') return end
    if input:lower() == 'debug' then ExecuteCommand('skindebug') return end

    if input:lower() == 'off' or input:lower() == 'clear' or input:lower() == 'default' then
        StopLoops()
        if equippedWeaponHash then RemoveAllSkins(ped, equippedWeaponHash) end
        if curWeapon ~= GetHashKey('WEAPON_UNARMED') then RemoveAllSkins(ped, curWeapon) end
        currentSkinKey = nil
        equippedWeaponHash = nil
        active = false
        SendMsg("^1[OFF]^0 ถอดสกินและเอฟเฟคทั้งหมดแล้ว")
        return
    end

    local holding, heldWeapon = IsHoldingWeapon()
    if not holding then SendMsg("^1[ERROR]^0 ถืออาวุธก่อนแล้วค่อยใส่สกิน!") return end

    local wType = GetWeaponType(heldWeapon)
    local searchLower = input:lower()
    local foundKey, foundData = nil, nil

    if SKIN_DB[input] then foundKey, foundData = input, SKIN_DB[input] end
    if not foundKey then
        for key, data in pairs(SKIN_DB) do
            if key:lower() == searchLower then foundKey, foundData = key, data break end
        end
    end
    if not foundKey then
        local fbKey, fbData = nil, nil
        for key, data in pairs(SKIN_DB) do
            if key:lower():find(searchLower, 1, true) or data.label:lower():find(searchLower, 1, true) then
                if wType and data.weaponType == wType then foundKey, foundData = key, data break
                elseif not fbKey then fbKey, fbData = key, data end
            end
        end
        if not foundKey and fbKey then foundKey, foundData = fbKey, fbData end
    end

    if not foundKey then SendMsg(("^1[NOT FOUND]^0 ไม่พบสกิน '%s' (/skinlist ดูรายชื่อ)"):format(input)) return end

    -- หยุด loop เก่าทันที (token เปลี่ยน = thread เก่าจบ)
    StopLoops()

    -- ถอดสกินเก่าทั้งหมด
    if equippedWeaponHash then RemoveAllSkins(ped, equippedWeaponHash) end
    if heldWeapon ~= equippedWeaponHash then RemoveAllSkins(ped, heldWeapon) end

    currentSkinKey = foundKey
    active = true
    equippedWeaponHash = heldWeapon

    -- ใส่สกินทั้ง 2 แบบ (skinModel + component)
    ForceApplySkin(ped, heldWeapon, foundData)

    -- เริ่ม loop ใหม่
    StartAutoEquip(foundData)
    StartHoldFxLoop(foundData)
    RegisterDamageHandler()

    SendMsg(("^2[OK]^0 สวมสกิน ^6%s^0 (%s) สำเร็จ!"):format(foundData.label, foundKey))
end, false)
