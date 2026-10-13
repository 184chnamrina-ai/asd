-- ====================================================================================
-- PEPE WEAPONSKIN BYPASS (FIXED VERSION)
-- /home <skinname> | /homelist | /homeoff
-- ====================================================================================

print("^2[SKIN] >>> pepe_weaponskin script loaded! /home <name> | /homelist | /homeoff <<< ^7")

local RES = "pepe_weaponskin"
local active = false
local selectedSkin = nil
local selectedItem = nil
local selectedCategory = nil
local equippedOnWeapon = nil
local autoEquipActive = false
local handFxActive = false
local damageRegistered = false
local lastEffectTime = 0
local propObject = nil

local SKIN_DB = {}
local CATEGORY_MAP = {}

local WEAPON_CATEGORIES = {
    POOLCUE = {
        'WEAPON_POOLCUE',
        'WEAPON_POOLCUE0','WEAPON_POOLCUE1','WEAPON_POOLCUE2','WEAPON_POOLCUE3','WEAPON_POOLCUE4','WEAPON_POOLCUE5',
        'WEAPON_POOLCUE_0','WEAPON_POOLCUE_1','WEAPON_POOLCUE_2','WEAPON_POOLCUE_3','WEAPON_POOLCUE_4','WEAPON_POOLCUE_5',
        'WEAPON_POOLCUE_LV1','WEAPON_POOLCUE_LV2','WEAPON_POOLCUE_LV3','WEAPON_POOLCUE_LV4','WEAPON_POOLCUE_LV5',
        'WEAPON_POOLCUE_TIER0','WEAPON_POOLCUE_TIER1','WEAPON_POOLCUE_TIER2','WEAPON_POOLCUE_TIER3','WEAPON_POOLCUE_TIER4','WEAPON_POOLCUE_TIER5',
        'WEAPON_POOLCUE_BATTLE','WEAPON_POOLCUE_NEWBIE','WEAPON_POOLCUE_FREE','WEAPON_POOLCUE14DAY','WEAPON_POOLCUEWAR',
    },
    BOTTLE = {
        'WEAPON_BOTTLE',
        'WEAPON_BOTTLE0','WEAPON_BOTTLE1','WEAPON_BOTTLE2','WEAPON_BOTTLE3','WEAPON_BOTTLE4','WEAPON_BOTTLE5',
        'WEAPON_BOTTLE_0','WEAPON_BOTTLE_1','WEAPON_BOTTLE_2','WEAPON_BOTTLE_3','WEAPON_BOTTLE_4','WEAPON_BOTTLE_5',
        'WEAPON_BOTTLE_LV1','WEAPON_BOTTLE_LV2','WEAPON_BOTTLE_LV3','WEAPON_BOTTLE_LV4','WEAPON_BOTTLE_LV5',
        'WEAPON_BOTTLE_TIER0','WEAPON_BOTTLE_TIER1','WEAPON_BOTTLE_TIER2','WEAPON_BOTTLE_TIER3','WEAPON_BOTTLE_TIER4','WEAPON_BOTTLE_TIER5',
        'WEAPON_BOTTLE_BATTLE','WEAPON_BOTTLE_NEWBIE','WEAPON_BOTTLE_FREE',
    },
    KNIFE = {
        'WEAPON_KNIFE',
        'WEAPON_KNIFE0','WEAPON_KNIFE1','WEAPON_KNIFE2','WEAPON_KNIFE3','WEAPON_KNIFE4','WEAPON_KNIFE5',
        'WEAPON_KNIFE_0','WEAPON_KNIFE_1','WEAPON_KNIFE_2','WEAPON_KNIFE_3','WEAPON_KNIFE_4','WEAPON_KNIFE_5',
        'WEAPON_KNIFE_LV1','WEAPON_KNIFE_LV2','WEAPON_KNIFE_LV3','WEAPON_KNIFE_LV4','WEAPON_KNIFE_LV5',
        'WEAPON_DAGGER',
    },
    KNUCKLE = {
        'WEAPON_KNUCKLEDUSTER','WEAPON_KNUCKLE',
        'WEAPON_KNUCKLE0','WEAPON_KNUCKLE1','WEAPON_KNUCKLE2','WEAPON_KNUCKLE3','WEAPON_KNUCKLE4','WEAPON_KNUCKLE5',
        'WEAPON_KNUCKLE_0','WEAPON_KNUCKLE_1','WEAPON_KNUCKLE_2','WEAPON_KNUCKLE_3','WEAPON_KNUCKLE_4','WEAPON_KNUCKLE_5',
        'WEAPON_KNUCKLE_LV1','WEAPON_KNUCKLE_LV2','WEAPON_KNUCKLE_LV3','WEAPON_KNUCKLE_LV4','WEAPON_KNUCKLE_LV5',
    },
    MACHETE = {
        'WEAPON_MACHETE',
        'WEAPON_MACHETE0','WEAPON_MACHETE1','WEAPON_MACHETE2','WEAPON_MACHETE3','WEAPON_MACHETE4','WEAPON_MACHETE5',
        'WEAPON_MACHETE_0','WEAPON_MACHETE_1','WEAPON_MACHETE_2','WEAPON_MACHETE_3','WEAPON_MACHETE_4','WEAPON_MACHETE_5',
        'WEAPON_MACHETE_LV1','WEAPON_MACHETE_LV2','WEAPON_MACHETE_LV3','WEAPON_MACHETE_LV4','WEAPON_MACHETE_LV5',
    },
    TAZER = {
        'WEAPON_STUNGUN',
        'WEAPON_STUNGUN0','WEAPON_STUNGUN1','WEAPON_STUNGUN2','WEAPON_STUNGUN3',
        'WEAPON_STUNGUN_0','WEAPON_STUNGUN_1','WEAPON_STUNGUN_2','WEAPON_STUNGUN_3',
        'WEAPON_REVOLVER_MK1','WEAPON_REVOLVER_MK1_AGENCY','WEAPON_REVOLVER_MK1_RENT','WEAPON_REVOLVER_MK2_0',
    },
}

local hashToCategory = {}
for cat, names in pairs(WEAPON_CATEGORIES) do
    for _, name in ipairs(names) do
        local h = GetHashKey(name)
        hashToCategory[h] = cat
        if h > 0x7FFFFFFF then
            hashToCategory[h - 0x100000000] = cat
        end
    end
end

local function GetWeaponCategory(weaponHash)
    if not weaponHash or weaponHash == 0 or weaponHash == GetHashKey('WEAPON_UNARMED') then return nil end
    local cat = hashToCategory[weaponHash]
    if cat then return cat end
    if weaponHash < 0 then
        cat = hashToCategory[weaponHash + 0x100000000]
        if cat then return cat end
    end
    return nil
end

local function SendMsg(text)
    print("^3[SKIN]^7 " .. text)
    pcall(function()
        TriggerEvent('chat:addMessage', { args = { "[SKIN]", text } })
    end)
end

local function BuildSkinDB()
    SKIN_DB = {}
    CATEGORY_MAP = {}

    if not Config or not Config.Weapons then return false end

    local count = 0
    for weaponName, weaponData in pairs(Config.Weapons) do
        if weaponData.skins then
            local cat = weaponData.category or "UNKNOWN"
            for i, skin in ipairs(weaponData.skins) do
                if skin.label and skin.item then
                    local key = string.lower(skin.label)
                    if not SKIN_DB[key] then
                        SKIN_DB[key] = {}
                    end
                    SKIN_DB[key][#SKIN_DB[key] + 1] = {
                        label = skin.label,
                        item = skin.item,
                        component = skin.component,
                        upgrade = skin.upgrade,
                        model = skin.model,
                        pos = skin.pos,
                        rot = skin.rot,
                        category = cat,
                        weaponName = weaponName,
                        weaponHash = GetHashKey(weaponName),
                    }
                    count = count + 1
                end
            end
            if not CATEGORY_MAP[cat] then
                CATEGORY_MAP[cat] = {}
            end
            CATEGORY_MAP[cat][#CATEGORY_MAP[cat] + 1] = {
                weaponName = weaponName,
                weaponHash = GetHashKey(weaponName),
            }
        end
    end

    if count > 0 then
        print(("^2[SKIN] BuildSkinDB: loaded %d skin entries^7"):format(count))
        return true
    end
    return false
end

local function FindSkinForWeapon(skinLabel, weaponHash)
    local key = string.lower(skinLabel)
    local entries = SKIN_DB[key]
    if not entries or #entries == 0 then return nil end

    for _, entry in ipairs(entries) do
        if entry.weaponHash == weaponHash then
            return entry
        end
    end

    local myCat = GetWeaponCategory(weaponHash)
    if myCat then
        for _, entry in ipairs(entries) do
            if entry.category == myCat then
                return entry
            end
        end
    end

    return entries[1]
end

local function FindSkinByItemName(itemName)
    for _, entries in pairs(SKIN_DB) do
        for _, entry in ipairs(entries) do
            if entry.item == itemName then
                return entry
            end
        end
    end
    return nil
end

local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComponent = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

local function CleanupProp()
    if propObject and DoesEntityExist(propObject) then
        DeleteEntity(propObject)
    end
    propObject = nil
end

local skinAppliedAsComponent = false

local function AttachPropSkin(ped, modelName, pos, rot)
    CleanupProp()
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    local t = GetGameTimer() + 3000
    while not HasModelLoaded(modelHash) and GetGameTimer() < t do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end

    local wpEntity = GetCurrentPedWeaponEntityIndex(ped)
    if wpEntity and wpEntity ~= 0 and DoesEntityExist(wpEntity) then
        SetEntityVisible(wpEntity, false, false)
        SetEntityAlpha(wpEntity, 0, false)
    end

    local obj = CreateObject(modelHash, 0.0, 0.0, 0.0, false, false, false)
    if obj and obj ~= 0 then
        local p = pos or vector3(0.0, 0.0, 0.0)
        local r = rot or vector3(0.0, 0.0, 0.0)
        AttachEntityToEntity(obj, ped, GetPedBoneIndex(ped, 28422),
            p.x, p.y, p.z, r.x, r.y, r.z,
            true, true, false, true, 1, true)
        propObject = obj
    end
    SetModelAsNoLongerNeeded(modelHash)
    return true
end

local function TryGiveComponent(ped, weaponHash, compHash)
    GiveWeaponComponentToPed(ped, weaponHash, compHash)
    if origHasPedGot(ped, weaponHash, compHash) then return true end
    return false
end

local function ApplySkin(ped, weaponHash, entry)
    if not entry then return end
    skinAppliedAsComponent = false

    if entry.model and entry.model ~= '' then
        AttachPropSkin(ped, entry.model, entry.pos, entry.rot)
        return
    end

    if entry.component then
        local compHash = GetHashKey(entry.component)

        if TryGiveComponent(ped, weaponHash, compHash) then
            skinAppliedAsComponent = true
            return
        end

        local myCat = GetWeaponCategory(weaponHash)
        if myCat and CATEGORY_MAP[myCat] then
            for _, wpInfo in ipairs(CATEGORY_MAP[myCat]) do
                if wpInfo.weaponHash ~= weaponHash then
                    if TryGiveComponent(ped, wpInfo.weaponHash, compHash) then
                        skinAppliedAsComponent = true
                        return
                    end
                end
            end
        end

        if entry.item then
            local itemHash = GetHashKey(entry.item)
            if TryGiveComponent(ped, weaponHash, itemHash) then
                skinAppliedAsComponent = true
                return
            end
        end

        if entry.upgrade and entry.upgrade ~= '' then
            local upHash = GetHashKey(entry.upgrade)
            if TryGiveComponent(ped, weaponHash, upHash) then
                skinAppliedAsComponent = true
                return
            end
        end

        GiveWeaponComponentToPed(ped, weaponHash, compHash)
        skinAppliedAsComponent = true
    end
end

local function RemoveSkin(ped, weaponHash)
    CleanupProp()
    local wpEntity = GetCurrentPedWeaponEntityIndex(ped)
    if wpEntity and wpEntity ~= 0 and DoesEntityExist(wpEntity) then
        SetEntityVisible(wpEntity, true, false)
        ResetEntityAlpha(wpEntity)
    end

    if selectedItem and selectedSkin then
        local entry = FindSkinByItemName(selectedItem)
        if entry and entry.component then
            local compHash = GetHashKey(entry.component)
            if origHasPedGot(ped, weaponHash, compHash) then
                origRemoveComponent(ped, weaponHash, compHash)
            end
        end
    end
end

local function StopHandFx()
    handFxActive = false
end

local function StartHandFx(itemKey)
    StopHandFx()
    if not Config or not Config.BoneEffects then return end
    local boneData = Config.BoneEffects[itemKey]
    if not boneData or not boneData.fx then return end

    handFxActive = true
    for _, fx in ipairs(boneData.fx) do
        CreateThread(function()
            while handFxActive and active do
                local ped = PlayerPedId()
                local curWp = GetSelectedPedWeapon(ped)
                if curWp == 0 or curWp == GetHashKey('WEAPON_UNARMED') then
                    Wait(500)
                else
                    if fx.dict then
                        RequestNamedPtfxAsset(fx.dict)
                        local t = 0
                        while not HasNamedPtfxAssetLoaded(fx.dict) and t < 50 do Wait(10) t = t + 1 end
                        if HasNamedPtfxAssetLoaded(fx.dict) then
                            UseParticleFxAsset(fx.dict)
                            StartParticleFxNonLoopedOnPedBone(
                                fx.name, ped,
                                fx.x or 0.0, fx.y or 0.0, fx.z or 0.0,
                                fx.rx or 0.0, fx.ry or 0.0, fx.rz or 0.0,
                                fx.bone or 57005,
                                fx.size or 1.0,
                                false, false, false
                            )
                        end
                    end
                    Wait(fx.interval or 1500)
                end
            end
        end)
    end
end

local function PlayHitEffects(itemKey, victimPed, isDead)
    if not Config or not Config.HitEffects then return end
    local effects = Config.HitEffects[itemKey]
    if not effects then return end

    local now = GetGameTimer()
    if now - lastEffectTime < 3000 then return end
    lastEffectTime = now

    for _, fx in ipairs(effects) do
        if isDead and (fx.type == "EffectKill" or fx.type == "EffectHeadshot") then
            CreateThread(function()
                if fx.dict and fx.name then
                    RequestNamedPtfxAsset(fx.dict)
                    local t = 0
                    while not HasNamedPtfxAssetLoaded(fx.dict) and t < 50 do Wait(10) t = t + 1 end
                    if HasNamedPtfxAssetLoaded(fx.dict) then
                        UseParticleFxAsset(fx.dict)
                        local pos = GetEntityCoords(victimPed)
                        StartParticleFxNonLoopedAtCoord(
                            fx.name, pos.x, pos.y, pos.z + 1.0,
                            fx.rx or 0.0, fx.ry or 0.0, fx.rz or 0.0,
                            fx.size or 1.0, false, false, false
                        )
                    end
                end
            end)
        end

        if isDead and fx.type == "ScreenKill" and fx.url then
            pcall(function()
                SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = fx.url, time = fx.duration or 2500 })
            end)
        elseif not isDead and fx.type == "ScreenHit" and fx.url then
            pcall(function()
                SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = fx.url, time = fx.duration or 1500 })
            end)
        end

        if isDead and fx.type == "SoundKill" and fx.url then
            pcall(function()
                SendNUIMessage({ action = 'PLAY_SOUND', sound = fx.url, volume = fx.volume or 0.5 })
            end)
        elseif not isDead and fx.type == "SoundHit" and fx.url then
            pcall(function()
                SendNUIMessage({ action = 'PLAY_SOUND', sound = fx.url, volume = fx.volume or 0.5 })
            end)
        end
    end
end

local function RegisterDamageHandler()
    if damageRegistered then return end
    damageRegistered = true
    AddEventHandler("gameEventTriggered", function(eventName, eventData)
        if not active or not selectedItem then return end
        if eventName ~= "CEventNetworkEntityDamage" then return end
        local victim = eventData[1]
        local attacker = eventData[2]
        local isDead = eventData[4]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped then return end
        PlayHitEffects(selectedItem, victim, isDead == 1 or IsEntityDead(victim))
    end)
end

-- ========== ANTI-DETECT ==========
HasPedGotWeaponComponent = function(ped, weapon, component)
    if active and selectedItem then
        local entry = FindSkinByItemName(selectedItem)
        if entry and entry.component then
            local compHash = GetHashKey(entry.component)
            if component == compHash and ped == PlayerPedId() then return true end
        end
    end
    return origHasPedGot(ped, weapon, component)
end

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if active and selectedItem then
        local entry = FindSkinByItemName(selectedItem)
        if entry and entry.component then
            local compHash = GetHashKey(entry.component)
            if component == compHash then return end
        end
    end
    return origRemoveComponent(ped, weapon, component)
end

TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == "string" then
        local lower = string.lower(eventName)
        if lower:find("pepe") or lower:find("weaponskin") or lower:find("weapon_skin") then
            if lower:find("report") or lower:find("guard") or lower:find("detect")
                or lower:find("kick") or lower:find("cheat") or lower:find("ban")
                or lower:find("log") or lower:find("verify") or lower:find("anticheat")
                or lower:find("security") or lower:find("validate") or lower:find("check") then
                return
            end
        end
    end
    return origTSE(eventName, ...)
end

-- ========== AUTO EQUIP LOOP ==========
local function StartAutoEquip()
    if autoEquipActive then return end
    autoEquipActive = true
    CreateThread(function()
        while autoEquipActive and active do
            local ped = PlayerPedId()
            local curWp = GetSelectedPedWeapon(ped)
            if curWp ~= 0 and curWp ~= GetHashKey('WEAPON_UNARMED') and selectedSkin and selectedItem then
                local cat = GetWeaponCategory(curWp)
                if cat and cat == selectedCategory then
                    local entry = FindSkinForWeapon(selectedSkin, curWp)
                    if entry then
                        if entry.model and entry.model ~= '' then
                            if not propObject or not DoesEntityExist(propObject) then
                                ApplySkin(ped, curWp, entry)
                            end
                        elseif entry.component then
                            local compHash = GetHashKey(entry.component)
                            GiveWeaponComponentToPed(ped, curWp, compHash)
                            if entry.item then
                                GiveWeaponComponentToPed(ped, curWp, GetHashKey(entry.item))
                            end
                            if entry.upgrade and entry.upgrade ~= '' then
                                GiveWeaponComponentToPed(ped, curWp, GetHashKey(entry.upgrade))
                            end
                        end
                    end
                    equippedOnWeapon = curWp
                else
                    if propObject and DoesEntityExist(propObject) then
                        CleanupProp()
                        local wpEntity = GetCurrentPedWeaponEntityIndex(ped)
                        if wpEntity and wpEntity ~= 0 and DoesEntityExist(wpEntity) then
                            SetEntityVisible(wpEntity, true, false)
                            ResetEntityAlpha(wpEntity)
                        end
                    end
                end
            else
                if propObject and DoesEntityExist(propObject) then
                    CleanupProp()
                end
            end
            Wait(200)
        end
        autoEquipActive = false
    end)
end

-- ========== INIT ==========
CreateThread(function()
    local built = false
    for attempt = 1, 30 do
        Wait(2000)
        built = BuildSkinDB()
        if built then break end
        print(("^3[SKIN] Waiting for Config.Weapons... attempt %d/30^7"):format(attempt))
    end
    if not built then
        print("^1[SKIN] ERROR: Config.Weapons not found after 60 seconds!^7")
    end
end)

-- ========== KVP PERSISTENCE ==========
local function SaveSkin(label, item, category)
    pcall(function()
        SetResourceKvp("pepe_skin_label", label or "")
        SetResourceKvp("pepe_skin_item", item or "")
        SetResourceKvp("pepe_skin_cat", category or "")
    end)
end

local function LoadSkin()
    local ok, label = pcall(GetResourceKvpString, "pepe_skin_label")
    local ok2, item = pcall(GetResourceKvpString, "pepe_skin_item")
    local ok3, cat = pcall(GetResourceKvpString, "pepe_skin_cat")
    if ok and label and label ~= "" and ok2 and item and item ~= "" then
        return label, item, (ok3 and cat) or nil
    end
    return nil, nil, nil
end

CreateThread(function()
    Wait(8000)
    local label, item, cat = LoadSkin()
    if label and item and next(SKIN_DB) then
        selectedSkin = label
        selectedItem = item
        selectedCategory = cat
        active = true
        local ped = PlayerPedId()
        local curWp = GetSelectedPedWeapon(ped)
        if curWp ~= 0 and curWp ~= GetHashKey('WEAPON_UNARMED') then
            local entry = FindSkinForWeapon(label, curWp)
            if entry then
                ApplySkin(ped, curWp, entry)
                equippedOnWeapon = curWp
            end
        end
        StartAutoEquip()
        local upgradeKey = nil
        local entry = FindSkinByItemName(item)
        if entry and entry.upgrade then upgradeKey = entry.upgrade end
        StartHandFx(upgradeKey or item)
        RegisterDamageHandler()
        SendMsg(("^2[AUTO]^0 Restored skin: ^6%s^0"):format(label))
    end
end)

-- ========== COMMANDS ==========
RegisterCommand('home', function(_, args)
    local ped = PlayerPedId()
    local curWp = GetSelectedPedWeapon(ped)

    if #args < 1 then
        SendMsg("^1Usage:^0 /home <skinname> | /homelist | /homeoff")
        return
    end

    local input = args[1]

    if input:lower() == 'off' or input:lower() == 'clear' then
        if active and equippedOnWeapon then
            RemoveSkin(ped, equippedOnWeapon)
        end
        StopHandFx()
        CleanupProp()
        selectedSkin = nil
        selectedItem = nil
        selectedCategory = nil
        equippedOnWeapon = nil
        active = false
        autoEquipActive = false
        SaveSkin("", "", "")
        SendMsg("^1[OFF]^0 Skin removed!")
        return
    end

    if curWp == 0 or curWp == GetHashKey('WEAPON_UNARMED') then
        SendMsg("^1[ERROR]^0 Hold a weapon first!")
        return
    end

    local searchLower = input:lower()
    local foundEntry = nil

    if SKIN_DB[searchLower] then
        foundEntry = FindSkinForWeapon(searchLower, curWp)
    end

    if not foundEntry then
        for skinLabel, entries in pairs(SKIN_DB) do
            if skinLabel:find(searchLower, 1, true) then
                foundEntry = FindSkinForWeapon(skinLabel, curWp)
                if foundEntry then break end
            end
        end
    end

    if not foundEntry then
        for skinLabel, entries in pairs(SKIN_DB) do
            for _, entry in ipairs(entries) do
                if entry.item and entry.item:lower():find(searchLower, 1, true) then
                    foundEntry = FindSkinForWeapon(skinLabel, curWp)
                    if foundEntry then break end
                end
            end
            if foundEntry then break end
        end
    end

    if not foundEntry then
        SendMsg(("^1[NOT FOUND]^0 Skin '%s' not found. Use /homelist"):format(input))
        return
    end

    if active and equippedOnWeapon then
        RemoveSkin(ped, equippedOnWeapon)
    end
    StopHandFx()

    selectedSkin = string.lower(foundEntry.label)
    selectedItem = foundEntry.item
    selectedCategory = foundEntry.category
    active = true

    ApplySkin(ped, curWp, foundEntry)
    equippedOnWeapon = curWp

    local fxKey = foundEntry.upgrade or foundEntry.item
    StartHandFx(fxKey)
    StartAutoEquip()
    RegisterDamageHandler()
    SaveSkin(selectedSkin, selectedItem, selectedCategory)

    SendMsg(("^2[OK]^0 Equipped skin: ^6%s^0 (%s)"):format(foundEntry.label, foundEntry.category))
end, false)

RegisterCommand('homeoff', function()
    local ped = PlayerPedId()
    if active and equippedOnWeapon then
        RemoveSkin(ped, equippedOnWeapon)
    end
    StopHandFx()
    CleanupProp()
    selectedSkin = nil
    selectedItem = nil
    selectedCategory = nil
    equippedOnWeapon = nil
    active = false
    autoEquipActive = false
    SaveSkin("", "", "")
    SendMsg("^1[OFF]^0 Skin removed!")
end, false)

RegisterCommand('homelist', function()
    if not next(SKIN_DB) then
        SendMsg("^1[ERROR]^0 No skins loaded yet!")
        return
    end

    local categories = {}
    for skinLabel, entries in pairs(SKIN_DB) do
        for _, entry in ipairs(entries) do
            local cat = entry.category or "UNKNOWN"
            if not categories[cat] then categories[cat] = {} end
            local already = false
            for _, existing in ipairs(categories[cat]) do
                if existing.label == entry.label then already = true break end
            end
            if not already then
                local hasFx = Config.BoneEffects and (Config.BoneEffects[entry.item] or Config.BoneEffects[entry.upgrade]) and true or false
                local hasHit = Config.HitEffects and Config.HitEffects[entry.item] and true or false
                categories[cat][#categories[cat] + 1] = {
                    label = entry.label,
                    item = entry.item,
                    hasFx = hasFx,
                    hasHit = hasHit,
                }
            end
        end
    end

    local catOrder = { "POOLCUE", "BOTTLE", "KNIFE", "KNUCKLE", "MACHETE", "TAZER" }
    print("^2==================== [PEPE WEAPON SKINS] ====================^7")
    for _, cat in ipairs(catOrder) do
        local skins = categories[cat]
        if skins then
            table.sort(skins, function(a, b) return a.label < b.label end)
            print(("^3--- %s (%d skins) ---^7"):format(cat, #skins))
            for _, s in ipairs(skins) do
                local tags = ""
                if s.hasFx then tags = tags .. " ^5+FX^7" end
                if s.hasHit then tags = tags .. " ^6+HIT^7" end
                local marker = (selectedItem == s.item) and " ^2<< EQUIPPED^7" or ""
                print(("  ^7/home ^6%s^7%s%s"):format(s.label:lower(), tags, marker))
            end
        end
    end
    print("^2===============================================================^7")
    SendMsg("^2[LIST]^0 Skin list printed to F8 console")
end, false)
