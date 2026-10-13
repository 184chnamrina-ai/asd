-- ═══════════════════════════════════════════════════════════════════════════════
-- 1nfx_weaponskin — Weapon Skin Unlocker (Config-only)
-- ดึง Config จาก 1nfx_weaponskin เท่านั้น ใช้ได้ทุกไม้
-- Commands: /home <skinname> | /homelist | /homeoff
-- ═══════════════════════════════════════════════════════════════════════════════

local RES = "1nfx_weaponskin"
local active = false
local selectedSkin = nil
local selectedSkinCfg = nil
local equippedOnWeapon = nil
local autoEquipActive = false
local handFxLoopActive = false
local damageRegistered = false
local lastEffectTime = 0
local currentPropEntity = nil
local currentPropModel = nil

-- ═══════════════════════════════════════════════════════════════════════════════
-- WEAPON MAP — ครอบคลุมทุกไม้/อาวุธ
-- ═══════════════════════════════════════════════════════════════════════════════
local WEAPON_MAP = {
    poolcue = {
        GetHashKey('WEAPON_POOLCUE'), GetHashKey('WEAPON_POOLCUE_0'), GetHashKey('WEAPON_POOLCUE_1'),
        GetHashKey('WEAPON_POOLCUE_2'), GetHashKey('WEAPON_POOLCUE_3'), GetHashKey('WEAPON_POOLCUE_4'),
        GetHashKey('WEAPON_POOLCUE_5'), GetHashKey('WEAPON_POOLCUE0'), GetHashKey('WEAPON_POOLCUE1'),
        GetHashKey('WEAPON_POOLCUE2'), GetHashKey('WEAPON_POOLCUE3'), GetHashKey('WEAPON_POOLCUE4'),
        GetHashKey('WEAPON_POOLCUE5'), GetHashKey('WEAPON_POOLCUE_RENT'), GetHashKey('WEAPON_POOLCUE14DAY'),
        GetHashKey('WEAPON_POOLCUEWAR'),
    },
    bottle = {
        GetHashKey('WEAPON_BOTTLE'), GetHashKey('WEAPON_BOTTLE_0'), GetHashKey('WEAPON_BOTTLE_1'),
        GetHashKey('WEAPON_BOTTLE_2'), GetHashKey('WEAPON_BOTTLE_3'), GetHashKey('WEAPON_BOTTLE_4'),
        GetHashKey('WEAPON_BOTTLE_5'), GetHashKey('WEAPON_BOTTLE0'), GetHashKey('WEAPON_BOTTLE1'),
        GetHashKey('WEAPON_BOTTLE2'), GetHashKey('WEAPON_BOTTLE3'), GetHashKey('WEAPON_BOTTLE4'),
        GetHashKey('WEAPON_BOTTLE5'),
    },
    knife = {
        GetHashKey('WEAPON_KNIFE'), GetHashKey('WEAPON_KNIFE_1'), GetHashKey('WEAPON_KNIFE_2'),
        GetHashKey('WEAPON_KNIFE_3'), GetHashKey('WEAPON_KNIFE_4'),
        GetHashKey('WEAPON_SWITCHBLADE'),
    },
    dagger = {
        GetHashKey('WEAPON_DAGGER'), GetHashKey('WEAPON_DAGGER_0'), GetHashKey('WEAPON_DAGGER_1'),
        GetHashKey('WEAPON_DAGGER_2'),
    },
    knuckle = {
        GetHashKey('WEAPON_KNUCKLEDUSTER'), GetHashKey('WEAPON_KNUCKLE'),
        GetHashKey('WEAPON_KNUCKLE_0'), GetHashKey('WEAPON_KNUCKLE_1'),
        GetHashKey('WEAPON_KNUCKLE_2'), GetHashKey('WEAPON_KNUCKLE_3'),
    },
    machete = {
        GetHashKey('WEAPON_MACHETE'), GetHashKey('WEAPON_MACHETE_0'),
        GetHashKey('WEAPON_MACHETE_1'), GetHashKey('WEAPON_MACHETE_2'),
        GetHashKey('WEAPON_MACHETE_3'), GetHashKey('WEAPON_MACHETTE_0'),
        GetHashKey('WEAPON_MACHETTE_1'), GetHashKey('WEAPON_MACHETTE_2'),
        GetHashKey('WEAPON_MACHETTE_3'),
    },
    bat = {
        GetHashKey('WEAPON_BAT'), GetHashKey('WEAPON_BAT_0'), GetHashKey('WEAPON_BAT_1'),
        GetHashKey('WEAPON_BAT_2'), GetHashKey('WEAPON_BAT_3'),
    },
    revolver = {
        GetHashKey('WEAPON_REVOLVER'), GetHashKey('WEAPON_REVOLVER_0'),
        GetHashKey('WEAPON_REVOLVER_1'), GetHashKey('WEAPON_REVOLVER_2'),
        GetHashKey('WEAPON_REVOLVER_3'),
    },
}

local SKIN_DB = {}
local allKnownComponentHashes = {}

-- ═══════════════════════════════════════════════════════════════════════════════
-- DETECT WEAPON TYPE จากชื่อสกิน
-- ═══════════════════════════════════════════════════════════════════════════════
local function DetectWeaponType(skinName)
    local lower = string.lower(skinName)
    if lower:find("poolcue") or lower:find("pool") then return "poolcue" end
    if lower:find("bottle") then return "bottle" end
    if lower:find("dagger") then return "dagger" end
    if lower:find("knife") or lower:find("switchblade") then return "knife" end
    if lower:find("knuckle") then return "knuckle" end
    if lower:find("machete") or lower:find("machette") then return "machete" end
    if lower:find("bat") then return "bat" end
    if lower:find("revolver") or lower:find("gun") then return "revolver" end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- BUILD SKIN DB — ดึงจาก Config ของ 1nfx_weaponskin เท่านั้น
-- ═══════════════════════════════════════════════════════════════════════════════
local function BuildSkinDB()
    SKIN_DB = {}
    allKnownComponentHashes = {}

    local weaponSkinCfg = nil
    if Config and Config['WEAPON_SKIN'] then
        weaponSkinCfg = Config['WEAPON_SKIN']
    end

    if not weaponSkinCfg then
        pcall(function()
            local resCfg = exports[RES]:GetConfig()
            if resCfg and resCfg['WEAPON_SKIN'] then
                weaponSkinCfg = resCfg['WEAPON_SKIN']
            end
        end)
    end

    if not weaponSkinCfg then
        print("^1[1nfx] Config['WEAPON_SKIN'] not found — waiting...^7")
        return false
    end

    for skinName, data in pairs(weaponSkinCfg) do
        if type(data) == 'table' then
            local model = data.MODEL or skinName
            local weaponType = DetectWeaponType(skinName)
            if data.Category then
                weaponType = string.lower(data.Category)
                if weaponType == 'pool' then weaponType = 'poolcue' end
            end

            SKIN_DB[skinName] = {
                model = model,
                weaponType = weaponType,
                label = data.SKIN_LABEL or data.label or skinName,
            }

            allKnownComponentHashes[GetHashKey(model)] = true
            allKnownComponentHashes[GetHashKey(string.upper(model))] = true
            allKnownComponentHashes[GetHashKey(string.lower(model))] = true
            allKnownComponentHashes[GetHashKey("COMPONENT_" .. string.upper(model))] = true
        end
    end

    print(("^2[1nfx] Loaded %d skins from Config^7"):format(0 + (function() local c=0 for _ in pairs(SKIN_DB) do c=c+1 end return c end)()))
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ═══════════════════════════════════════════════════════════════════════════════
local function GetCurrentWeaponType(weaponHash)
    for wType, hashes in pairs(WEAPON_MAP) do
        for _, h in ipairs(hashes) do
            if h == weaponHash then return wType end
        end
    end
    return nil
end

local function GetAllWeaponHashes()
    local all = {}
    for _, hashes in pairs(WEAPON_MAP) do
        for _, h in ipairs(hashes) do
            all[h] = true
        end
    end
    return all
end

local function FindSkin(query)
    if not query or query == '' then return nil, nil end
    local q = string.lower(query)
    if SKIN_DB[query] then return query, SKIN_DB[query] end
    for k, v in pairs(SKIN_DB) do
        if string.lower(k) == q then return k, v end
    end
    for k, v in pairs(SKIN_DB) do
        if v.label and string.lower(v.label) == q then return k, v end
    end
    for k, v in pairs(SKIN_DB) do
        if string.find(string.lower(k), q, 1, true) then return k, v end
        if v.label and string.find(string.lower(v.label), q, 1, true) then return k, v end
    end
    return nil, nil
end

local function GetSkinCfg(skinName)
    if Config and Config['WEAPON_SKIN'] and Config['WEAPON_SKIN'][skinName] then
        return Config['WEAPON_SKIN'][skinName]
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROP ATTACH ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════
local function RemoveSkinProp()
    if currentPropEntity and DoesEntityExist(currentPropEntity) then
        SetEntityAsMissionEntity(currentPropEntity, true, true)
        DetachEntity(currentPropEntity, true, true)
        DeleteEntity(currentPropEntity)
    end
    currentPropEntity = nil
    currentPropModel = nil
    SetPedCurrentWeaponVisible(PlayerPedId(), true, false, false, false)
end

local function AttachSkinProp(ped, modelName)
    if currentPropEntity and DoesEntityExist(currentPropEntity) and currentPropModel == modelName then
        SetPedCurrentWeaponVisible(ped, false, false, false, false)
        return true
    end
    RemoveSkinProp()

    local modelHash = GetHashKey(modelName)
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.lower(modelName)) end
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.upper(modelName)) end
    if not IsModelValid(modelHash) then return false end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + 800
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end

    local pCoords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
    if not DoesEntityExist(prop) then return false end

    SetEntityCollision(prop, false, false)
    SetEntityInvincible(prop, true)

    local px, py, pz = 0.055, 0.045, 0.01
    local rx, ry, rz = -77.0, -23.0, -16.0
    local boneId = 28422

    if Config and Config.WeaponPosition then
        local posCfg = Config.WeaponPosition['POOL'] or Config.WeaponPosition['POOLCUE']
        if posCfg then
            px = (posCfg.Pos and posCfg.Pos.x) or px
            py = (posCfg.Pos and posCfg.Pos.y) or py
            pz = (posCfg.Pos and posCfg.Pos.z) or pz
            rx = (posCfg.Rot and posCfg.Rot.x) or rx
            ry = (posCfg.Rot and posCfg.Rot.y) or ry
            rz = (posCfg.Rot and posCfg.Rot.z) or rz
        end
    end

    local boneIndex = GetPedBoneIndex(ped, boneId)
    AttachEntityToEntity(prop, ped, boneIndex, px, py, pz, rx, ry, rz, true, true, false, true, 0, true)

    currentPropEntity = prop
    currentPropModel = modelName
    SetModelAsNoLongerNeeded(modelHash)
    SetPedCurrentWeaponVisible(ped, false, false, false, false)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- APPLY / REMOVE SKIN (Component + Prop hybrid) — ใช้ได้ทุกไม้
-- ═══════════════════════════════════════════════════════════════════════════════
local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComponent = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

local function RemoveAllSkinComponents(ped, weaponHash)
    if not ped or not DoesEntityExist(ped) or weaponHash == 0 then return end
    for compHash in pairs(allKnownComponentHashes) do
        if origHasPedGot(ped, weaponHash, compHash) then
            origRemoveComponent(ped, weaponHash, compHash)
        end
    end
end

local function ApplySkin(skinName)
    local ped = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon == GetHashKey('WEAPON_UNARMED') or currentWeapon == 0 then return false end

    local data = SKIN_DB[skinName]
    local modelName = (data and data.model) or skinName

    RemoveAllSkinComponents(ped, currentWeapon)

    local skinHash = GetHashKey(modelName)
    local upperHash = GetHashKey(string.upper(modelName))
    local compHash = GetHashKey("COMPONENT_" .. string.upper(modelName))

    GiveWeaponComponentToPed(ped, currentWeapon, skinHash)
    GiveWeaponComponentToPed(ped, currentWeapon, upperHash)
    GiveWeaponComponentToPed(ped, currentWeapon, compHash)

    local isComp = origHasPedGot(ped, currentWeapon, skinHash)
              or origHasPedGot(ped, currentWeapon, upperHash)
              or origHasPedGot(ped, currentWeapon, compHash)

    if isComp then
        RemoveSkinProp()
    else
        AttachSkinProp(ped, modelName)
    end

    equippedOnWeapon = currentWeapon
    return true
end

local function RemoveSkin()
    if selectedSkin and equippedOnWeapon then
        RemoveAllSkinComponents(PlayerPedId(), equippedOnWeapon)
    end
    RemoveSkinProp()
    equippedOnWeapon = nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PTFX
-- ═══════════════════════════════════════════════════════════════════════════════
local function EnsurePtfxLoaded(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local deadline = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function StopHandFx() handFxLoopActive = false end

local function StartHandFx(skinName)
    StopHandFx()
    local cfg = GetSkinCfg(skinName)
    if not cfg or not cfg.PTFX_ATTACH_BONE then return end

    local fxList = cfg.PTFX_ATTACH_BONE
    if not fxList or #fxList == 0 then return end

    handFxLoopActive = true
    for _, fx in ipairs(fxList) do
        CreateThread(function()
            while handFxLoopActive and active do
                local ped = PlayerPedId()
                if GetSelectedPedWeapon(ped) == GetHashKey('WEAPON_UNARMED') then
                    Wait(500)
                else
                    local dict = fx.Dict or fx.dict
                    local eff = fx.Eff or fx.eff
                    local bone = fx.Bone or fx.bone or 57005
                    local scale = fx.Scale or fx.scale or 1.0

                    if dict and eff and EnsurePtfxLoaded(dict) then
                        UseParticleFxAsset(dict)
                        StartParticleFxNonLoopedOnPedBone(
                            eff, ped,
                            fx.xPos or 0.12, fx.yPos or 0.0, fx.zPos or 0.0,
                            fx.xRot or 0.0, fx.yRot or 0.0, fx.zRot or 65.0,
                            bone, scale, false, false, false
                        )
                    end
                    Wait(fx.Time or fx.time or 800)
                end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- KILL / HIT EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════════
local function PlayKillEffect(victimPed, skinName)
    local now = GetGameTimer()
    local effDelay = (Config and Config['GENERAL'] and Config['GENERAL'].EFF_DELAY) or 3000
    if now - lastEffectTime < effDelay then return end
    lastEffectTime = now

    local cfg = GetSkinCfg(skinName)
    if not cfg then return end

    if cfg.EFF_CRITICAL_DEAD then
        local pos = GetEntityCoords(victimPed)
        local headBone = GetPedBoneIndex(victimPed, 31086)
        local targetPos = pos + vector3(0.0, 0.0, 0.65)
        if headBone ~= -1 then
            local bPos = GetWorldPositionOfEntityBone(victimPed, headBone)
            if bPos and #(bPos - pos) < 3.0 and bPos.z > 0.0 then targetPos = bPos end
        end

        for _, ptfx in ipairs(cfg.EFF_CRITICAL_DEAD) do
            local dict = ptfx.DICT or ptfx.dict
            local eff = ptfx.EFF or ptfx.eff
            local scale = ptfx.SCALE or ptfx.scale or 1.0
            if dict and eff and EnsurePtfxLoaded(dict) then
                UseParticleFxAsset(dict)
                StartParticleFxNonLoopedAtCoord(eff, targetPos.x, targetPos.y, targetPos.z, 0.0, 0.0, 0.0, scale, false, false, false)
                UseParticleFxAsset(dict)
                StartNetworkedParticleFxNonLoopedAtCoord(eff, targetPos.x, targetPos.y, targetPos.z, 0.0, 0.0, 0.0, scale, false, false, false)
            end
        end
    end

    if cfg.SCREEN and cfg.SCREEN.SCREEN_NAME and cfg.SCREEN.SCREEN_NAME ~= '' then
        local screenTime = (Config and Config['GENERAL'] and Config['GENERAL'].SCREEN_TIME) or 3000
        SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = cfg.SCREEN.SCREEN_NAME, time = screenTime })
    end

    local audioData = cfg.AUDIO_CRITICAL_DEAD
    if not audioData or not audioData.AUDIO_NAME or audioData.AUDIO_NAME == '' then
        audioData = cfg.AUDIO_HIT
    end
    if audioData and audioData.AUDIO_NAME and audioData.AUDIO_NAME ~= '' then
        SendNUIMessage({ action = 'PLAY_SOUND', sound = audioData.AUDIO_NAME, volume = tonumber(audioData.AUDIO_VOLUME) or 0.5 })
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DAMAGE HANDLER
-- ═══════════════════════════════════════════════════════════════════════════════
local function RegisterDamageHandler()
    if damageRegistered then return end
    damageRegistered = true

    AddEventHandler("gameEventTriggered", function(eventName, eventData)
        if not active or not selectedSkin then return end
        if eventName ~= "CEventNetworkEntityDamage" then return end

        local victim = eventData[1]
        local attacker = eventData[2]
        local isDead = eventData[4]
        local ped = PlayerPedId()

        if attacker ~= ped or victim == ped then return end

        if isDead == 1 or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) then
            PlayKillEffect(victim, selectedSkin)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTO EQUIP — ทำงานกับทุกไม้ที่ตรง weaponType
-- ═══════════════════════════════════════════════════════════════════════════════
local function StartAutoEquip()
    if autoEquipActive then return end
    autoEquipActive = true
    CreateThread(function()
        while autoEquipActive and active do
            local ped = PlayerPedId()
            local currentWeapon = GetSelectedPedWeapon(ped)
            if selectedSkin and currentWeapon ~= GetHashKey('WEAPON_UNARMED') and currentWeapon ~= 0 then
                local skinData = SKIN_DB[selectedSkin]
                if skinData then
                    local currentType = GetCurrentWeaponType(currentWeapon)
                    local skinType = skinData.weaponType
                    local match = (skinType == currentType)
                    if not match and not skinType then match = true end

                    if match then
                        local modelName = skinData.model or selectedSkin
                        local skinHash = GetHashKey(modelName)
                        if not origHasPedGot(ped, currentWeapon, skinHash) then
                            if not (currentPropEntity and DoesEntityExist(currentPropEntity) and currentPropModel == modelName) then
                                ApplySkin(selectedSkin)
                            end
                        end
                        if currentPropEntity and DoesEntityExist(currentPropEntity) then
                            SetPedCurrentWeaponVisible(ped, false, false, false, false)
                        end
                    end
                end
            end
            Wait(150)
        end
        autoEquipActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANTI-DETECT HOOKS
-- ═══════════════════════════════════════════════════════════════════════════════
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == "string" then
        local lower = string.lower(eventName)
        if lower:find("1nfx") or lower:find("weaponskin") then
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

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if active and selectedSkin then
        local modelName = (SKIN_DB[selectedSkin] and SKIN_DB[selectedSkin].model) or selectedSkin
        local h1 = GetHashKey(modelName)
        local h2 = GetHashKey(string.upper(modelName))
        local h3 = GetHashKey("COMPONENT_" .. string.upper(modelName))
        if component == h1 or component == h2 or component == h3 then return end
    end
    return origRemoveComponent(ped, weapon, component)
end

HasPedGotWeaponComponent = function(ped, weapon, component)
    if active and selectedSkin then
        local modelName = (SKIN_DB[selectedSkin] and SKIN_DB[selectedSkin].model) or selectedSkin
        local h1 = GetHashKey(modelName)
        local h2 = GetHashKey(string.upper(modelName))
        local h3 = GetHashKey("COMPONENT_" .. string.upper(modelName))
        if ped == PlayerPedId() and (component == h1 or component == h2 or component == h3) then
            return true
        end
    end
    return origHasPedGot(ped, weapon, component)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- KVP SAVE / LOAD
-- ═══════════════════════════════════════════════════════════════════════════════
local KVP_KEY = "1nfx_saved_skin"

local function SaveSkinKVP(skinName)
    if skinName and skinName ~= '' then
        SetResourceKvp(KVP_KEY, skinName)
    else
        DeleteResourceKvp(KVP_KEY)
    end
end

local function LoadSkinKVP()
    local val = GetResourceKvpString(KVP_KEY)
    if val and val ~= '' then return val end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INIT — รอ Config โหลดแล้วสร้าง DB
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    local attempts = 0
    while attempts < 30 do
        Wait(1000)
        attempts = attempts + 1
        if BuildSkinDB() then break end
    end

    if next(SKIN_DB) == nil then
        print("^1[1nfx] Could not load Config after 30s^7")
        return
    end

    local saved = LoadSkinKVP()
    if saved and SKIN_DB[saved] then
        selectedSkin = saved
        selectedSkinCfg = GetSkinCfg(saved)
        active = true
        StartAutoEquip()
        StartHandFx(saved)
        RegisterDamageHandler()
        print(("^2[1nfx] Auto-loaded saved skin: %s^7"):format(saved))
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        RemoveSkinProp()
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════

RegisterCommand('home', function(_, args)
    BuildSkinDB()

    if #args < 1 then
        print("^1[1nfx] Usage: /home <skinname>^7")
        return
    end

    RemoveSkin()
    StopHandFx()

    local skinKey, skinData = FindSkin(args[1])
    if not skinKey then
        print(("^1[1nfx] Skin not found: '%s' — use /homelist^7"):format(args[1]))
        return
    end

    selectedSkin = skinKey
    selectedSkinCfg = GetSkinCfg(skinKey)
    active = true

    ApplySkin(skinKey)
    StartAutoEquip()
    StartHandFx(skinKey)
    RegisterDamageHandler()
    SaveSkinKVP(skinKey)

    print(("^2[1nfx] Equipped: %s (%s)^7"):format(skinData.label or skinKey, skinKey))
end, false)

RegisterCommand('homeoff', function()
    RemoveSkin()
    StopHandFx()
    selectedSkin = nil
    selectedSkinCfg = nil
    active = false
    autoEquipActive = false
    SaveSkinKVP(nil)
    print("^1[1nfx] Skin removed.^7")
end, false)

RegisterCommand('homelist', function()
    BuildSkinDB()

    local categories = {}
    for skinName, data in pairs(SKIN_DB) do
        local cat = data.weaponType or 'other'
        if not categories[cat] then categories[cat] = {} end
        categories[cat][#categories[cat] + 1] = { name = skinName, label = data.label or skinName }
    end

    local order = { 'poolcue', 'bottle', 'knife', 'dagger', 'knuckle', 'machete', 'bat', 'revolver', 'other' }
    local catLabels = {
        poolcue = 'POOLCUE', bottle = 'BOTTLE', knife = 'KNIFE',
        dagger = 'DAGGER', knuckle = 'KNUCKLE', machete = 'MACHETE',
        bat = 'BAT', revolver = 'REVOLVER', other = 'OTHER',
    }

    local total = 0
    for _ in pairs(SKIN_DB) do total = total + 1 end

    print(("^3═══════════════ [1nfx WEAPON SKINS] (%d) ═══════════════^7"):format(total))
    for _, cat in ipairs(order) do
        local skins = categories[cat]
        if skins and #skins > 0 then
            table.sort(skins, function(a, b) return a.name < b.name end)
            print(("^3── %s (%d) ──^7"):format(catLabels[cat] or cat, #skins))
            for _, s in ipairs(skins) do
                local marker = (s.name == selectedSkin) and " ^2<< EQUIPPED^7" or ""
                local cfg = GetSkinCfg(s.name)
                local hasFx = (cfg and cfg.PTFX_ATTACH_BONE and #cfg.PTFX_ATTACH_BONE > 0) and "^6+HAND^7 " or ""
                local hasKill = (cfg and cfg.EFF_CRITICAL_DEAD and #cfg.EFF_CRITICAL_DEAD > 0) and "^1+KILL^7 " or ""
                print(("  ^7/home ^6%s^7  (%s) %s%s%s"):format(s.name, s.label, hasFx, hasKill, marker))
            end
        end
    end
    print("^3═══════════════════════════════════════════════════════^7")
    print("^2Usage: /home <skinname> | /homeoff | /homelist^7")
end, false)

print("^2[1nfx_weaponskin] Loaded — /home <skin> | /homelist | /homeoff^7")
