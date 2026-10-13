-- ═══════════════════════════════════════════════════════════════════════════════
-- 1nfx_weaponskin — Weapon Skin Unlocker (No Config Needed)
-- ใช้ได้ทุกไม้ ไม่ต้องพึ่ง Config จาก resource
-- Commands: /home <skinname> | /homelist | /homeoff
-- ═══════════════════════════════════════════════════════════════════════════════

print("^2[1nfx] Loading weapon skin script...^7")

local active = false
local selectedSkin = nil
local equippedOnWeapon = nil
local autoEquipActive = false
local handFxLoopActive = false
local damageRegistered = false
local lastEffectTime = 0
local currentPropEntity = nil
local currentPropModel = nil

local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComponent = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

-- ═══════════════════════════════════════════════════════════════════════════════
-- WEAPON MAP — ครอบคลุมทุกไม้
-- ═══════════════════════════════════════════════════════════════════════════════
local WEAPON_HASHES = {}
local weaponNames = {
    'WEAPON_POOLCUE','WEAPON_POOLCUE_0','WEAPON_POOLCUE_1','WEAPON_POOLCUE_2',
    'WEAPON_POOLCUE_3','WEAPON_POOLCUE_4','WEAPON_POOLCUE_5',
    'WEAPON_POOLCUE0','WEAPON_POOLCUE1','WEAPON_POOLCUE2','WEAPON_POOLCUE3',
    'WEAPON_POOLCUE4','WEAPON_POOLCUE5','WEAPON_POOLCUE_RENT','WEAPON_POOLCUE14DAY','WEAPON_POOLCUEWAR',
    'WEAPON_BOTTLE','WEAPON_BOTTLE_0','WEAPON_BOTTLE_1','WEAPON_BOTTLE_2',
    'WEAPON_BOTTLE_3','WEAPON_BOTTLE_4','WEAPON_BOTTLE_5',
    'WEAPON_BOTTLE0','WEAPON_BOTTLE1','WEAPON_BOTTLE2','WEAPON_BOTTLE3',
    'WEAPON_BOTTLE4','WEAPON_BOTTLE5',
    'WEAPON_KNIFE','WEAPON_KNIFE_1','WEAPON_KNIFE_2','WEAPON_KNIFE_3','WEAPON_KNIFE_4',
    'WEAPON_SWITCHBLADE',
    'WEAPON_DAGGER','WEAPON_DAGGER_0','WEAPON_DAGGER_1','WEAPON_DAGGER_2',
    'WEAPON_KNUCKLEDUSTER','WEAPON_KNUCKLE','WEAPON_KNUCKLE_0','WEAPON_KNUCKLE_1',
    'WEAPON_KNUCKLE_2','WEAPON_KNUCKLE_3',
    'WEAPON_MACHETE','WEAPON_MACHETE_0','WEAPON_MACHETE_1','WEAPON_MACHETE_2','WEAPON_MACHETE_3',
    'WEAPON_MACHETTE_0','WEAPON_MACHETTE_1','WEAPON_MACHETTE_2','WEAPON_MACHETTE_3',
    'WEAPON_BAT','WEAPON_BAT_0','WEAPON_BAT_1','WEAPON_BAT_2','WEAPON_BAT_3',
    'WEAPON_REVOLVER','WEAPON_REVOLVER_0','WEAPON_REVOLVER_1','WEAPON_REVOLVER_2','WEAPON_REVOLVER_3',
}
for _, name in ipairs(weaponNames) do
    WEAPON_HASHES[GetHashKey(name)] = true
end

local function IsWeaponSupported(hash)
    return WEAPON_HASHES[hash] or false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SKIN DATABASE — scan จาก resource โดยตรง + built-in list
-- ═══════════════════════════════════════════════════════════════════════════════
local SKIN_DB = {}

local function TryLoadFromResource()
    local resNames = {
        '1nfx_weaponskin', 'gN_weaponskin', 'Secret_Weaponskin',
        'ar_weaponskinmenu', 'weaponskin', 'weapon_skin',
    }
    local configFiles = {
        'config.weaponskin.lua', 'config.lua', 'shared/config.lua',
        'core/config.lua', 'client/config.lua', 'data/config.lua',
        'config/weaponskin.lua', 'config/config.lua',
    }

    for _, resName in ipairs(resNames) do
        if GetResourceState(resName) ~= 'started' then goto nextRes end

        for _, fileName in ipairs(configFiles) do
            local raw = LoadResourceFile(resName, fileName)
            if raw and raw ~= '' and raw:find("WEAPON_SKIN") then
                local env = setmetatable({ Config = {} }, { __index = _G })
                local fn = load(raw, '@' .. resName .. '/' .. fileName, 't', env)
                if fn then
                    local ok = pcall(fn)
                    if ok and env.Config['WEAPON_SKIN'] and next(env.Config['WEAPON_SKIN']) then
                        print(("^2[1nfx] Loaded config from %s/%s^7"):format(resName, fileName))
                        return env.Config
                    end
                end
            end
        end

        local manifest = LoadResourceFile(resName, 'fxmanifest.lua') or ''
        for luaFile in manifest:gmatch("['\"]([^'\"]-%.lua)['\"]") do
            local raw = LoadResourceFile(resName, luaFile)
            if raw and raw ~= '' and raw:find("WEAPON_SKIN") then
                local env = setmetatable({ Config = {} }, { __index = _G })
                local fn = load(raw, '@' .. resName .. '/' .. luaFile, 't', env)
                if fn then
                    local ok = pcall(fn)
                    if ok and env.Config['WEAPON_SKIN'] and next(env.Config['WEAPON_SKIN']) then
                        print(("^2[1nfx] Loaded config from %s/%s^7"):format(resName, luaFile))
                        return env.Config
                    end
                end
            end
        end

        ::nextRes::
    end

    local numRes = GetNumResources()
    for i = 0, numRes - 1 do
        local resName = GetResourceByFindIndex(i)
        if resName and GetResourceState(resName) == 'started' then
            local l = resName:lower()
            if l:find('weapon') or l:find('skin') or l:find('1nfx') then
                for _, fileName in ipairs(configFiles) do
                    local raw = LoadResourceFile(resName, fileName)
                    if raw and raw ~= '' and raw:find("WEAPON_SKIN") then
                        local env = setmetatable({ Config = {} }, { __index = _G })
                        local fn = load(raw, '@' .. resName .. '/' .. fileName, 't', env)
                        if fn then
                            local ok = pcall(fn)
                            if ok and env.Config['WEAPON_SKIN'] and next(env.Config['WEAPON_SKIN']) then
                                print(("^2[1nfx] Loaded config from %s/%s^7"):format(resName, fileName))
                                return env.Config
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

local LoadedConfig = nil

local function GetSkinCfg(skinName)
    if LoadedConfig and LoadedConfig['WEAPON_SKIN'] and LoadedConfig['WEAPON_SKIN'][skinName] then
        return LoadedConfig['WEAPON_SKIN'][skinName]
    end
    return nil
end

local function BuildSkinDB()
    SKIN_DB = {}

    if not LoadedConfig then
        LoadedConfig = TryLoadFromResource()
    end

    if LoadedConfig and LoadedConfig['WEAPON_SKIN'] then
        for skinName, data in pairs(LoadedConfig['WEAPON_SKIN']) do
            if type(data) == 'table' then
                SKIN_DB[skinName] = {
                    model = data.MODEL or skinName,
                    label = data.SKIN_LABEL or skinName,
                }
            end
        end
    end
end

local function FindSkin(query)
    if not query or query == '' then return nil end
    local q = string.lower(query)
    for k, v in pairs(SKIN_DB) do
        if string.lower(k) == q then return k end
    end
    for k, v in pairs(SKIN_DB) do
        if v.label and string.lower(v.label) == q then return k end
    end
    for k, v in pairs(SKIN_DB) do
        if string.find(string.lower(k), q, 1, true) then return k end
        if v.label and string.find(string.lower(v.label), q, 1, true) then return k end
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PROP ATTACH
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
    local deadline = GetGameTimer() + 1500
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end

    local pCoords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
    if not DoesEntityExist(prop) then return false end

    SetEntityCollision(prop, false, false)
    SetEntityInvincible(prop, true)

    local boneIndex = GetPedBoneIndex(ped, 28422)
    AttachEntityToEntity(prop, ped, boneIndex,
        0.055, 0.045, 0.01,
        -77.0, -23.0, -16.0,
        true, true, false, true, 0, true
    )

    currentPropEntity = prop
    currentPropModel = modelName
    SetModelAsNoLongerNeeded(modelHash)
    SetPedCurrentWeaponVisible(ped, false, false, false, false)
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- APPLY / REMOVE — ใช้ชื่อตรงๆ ไม่ต้องมี Config
-- ═══════════════════════════════════════════════════════════════════════════════
local appliedHashes = {}

local function ApplySkin(skinName)
    local ped = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(ped)
    if currentWeapon == GetHashKey('WEAPON_UNARMED') or currentWeapon == 0 then return false end

    local modelName = skinName
    local dbEntry = SKIN_DB[skinName]
    if dbEntry then modelName = dbEntry.model or skinName end

    local h1 = GetHashKey(modelName)
    local h2 = GetHashKey(string.upper(modelName))
    local h3 = GetHashKey("COMPONENT_" .. string.upper(modelName))

    GiveWeaponComponentToPed(ped, currentWeapon, h1)
    GiveWeaponComponentToPed(ped, currentWeapon, h2)
    GiveWeaponComponentToPed(ped, currentWeapon, h3)

    local isComp = origHasPedGot(ped, currentWeapon, h1)
              or origHasPedGot(ped, currentWeapon, h2)
              or origHasPedGot(ped, currentWeapon, h3)

    if isComp then
        RemoveSkinProp()
        appliedHashes = { h1, h2, h3 }
    else
        local attached = AttachSkinProp(ped, modelName)
        if attached then
            appliedHashes = { h1, h2, h3 }
        else
            appliedHashes = { h1, h2, h3 }
        end
    end

    equippedOnWeapon = currentWeapon
    return true
end

local function RemoveSkin()
    if equippedOnWeapon then
        local ped = PlayerPedId()
        for _, h in ipairs(appliedHashes) do
            if origHasPedGot(ped, equippedOnWeapon, h) then
                origRemoveComponent(ped, equippedOnWeapon, h)
            end
        end
    end
    RemoveSkinProp()
    equippedOnWeapon = nil
    appliedHashes = {}
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PTFX HAND EFFECT
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

    handFxLoopActive = true
    for _, fx in ipairs(cfg.PTFX_ATTACH_BONE) do
        CreateThread(function()
            while handFxLoopActive and active do
                local ped = PlayerPedId()
                if GetSelectedPedWeapon(ped) == GetHashKey('WEAPON_UNARMED') then
                    Wait(500)
                else
                    local dict = fx.Dict or fx.dict
                    local eff = fx.Eff or fx.eff
                    if dict and eff and EnsurePtfxLoaded(dict) then
                        UseParticleFxAsset(dict)
                        StartParticleFxNonLoopedOnPedBone(
                            eff, ped,
                            fx.xPos or 0.12, fx.yPos or 0.0, fx.zPos or 0.0,
                            fx.xRot or 0.0, fx.yRot or 0.0, fx.zRot or 65.0,
                            fx.Bone or fx.bone or 57005,
                            fx.Scale or fx.scale or 1.0,
                            false, false, false
                        )
                    end
                    Wait(fx.Time or fx.time or 800)
                end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- KILL EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════════
local function PlayKillEffect(victimPed, skinName)
    local now = GetGameTimer()
    if now - lastEffectTime < 3000 then return end
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
            end
        end
    end

    if cfg.SCREEN and cfg.SCREEN.SCREEN_NAME and cfg.SCREEN.SCREEN_NAME ~= '' then
        SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = cfg.SCREEN.SCREEN_NAME, time = 3000 })
    end

    local audio = cfg.AUDIO_CRITICAL_DEAD or cfg.AUDIO_HIT
    if audio and audio.AUDIO_NAME and audio.AUDIO_NAME ~= '' then
        SendNUIMessage({ action = 'PLAY_SOUND', sound = audio.AUDIO_NAME, volume = tonumber(audio.AUDIO_VOLUME) or 0.5 })
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
-- AUTO EQUIP — ทำงานกับทุกไม้
-- ═══════════════════════════════════════════════════════════════════════════════
local function StartAutoEquip()
    if autoEquipActive then return end
    autoEquipActive = true
    CreateThread(function()
        while autoEquipActive and active do
            local ped = PlayerPedId()
            local curWeapon = GetSelectedPedWeapon(ped)
            if selectedSkin and curWeapon ~= GetHashKey('WEAPON_UNARMED') and curWeapon ~= 0 and IsWeaponSupported(curWeapon) then
                local modelName = selectedSkin
                local dbEntry = SKIN_DB[selectedSkin]
                if dbEntry then modelName = dbEntry.model or selectedSkin end

                local skinHash = GetHashKey(modelName)
                local needApply = not origHasPedGot(ped, curWeapon, skinHash)
                    and not (currentPropEntity and DoesEntityExist(currentPropEntity) and currentPropModel == modelName)

                if needApply then
                    equippedOnWeapon = curWeapon
                    ApplySkin(selectedSkin)
                end

                if currentPropEntity and DoesEntityExist(currentPropEntity) then
                    SetPedCurrentWeaponVisible(ped, false, false, false, false)
                end
            end
            Wait(150)
        end
        autoEquipActive = false
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANTI-DETECT
-- ═══════════════════════════════════════════════════════════════════════════════
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == "string" then
        local lower = string.lower(eventName)
        if lower:find("1nfx") or lower:find("weaponskin") or lower:find("gn_weapon") then
            if lower:find("report") or lower:find("guard") or lower:find("detect")
                or lower:find("kick") or lower:find("cheat") or lower:find("check")
                or lower:find("log") or lower:find("ban") or lower:find("verify")
                or lower:find("anticheat") or lower:find("security") then
                return
            end
        end
    end
    return origTSE(eventName, ...)
end

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if active and #appliedHashes > 0 then
        for _, h in ipairs(appliedHashes) do
            if component == h then return end
        end
    end
    return origRemoveComponent(ped, weapon, component)
end

HasPedGotWeaponComponent = function(ped, weapon, component)
    if active and #appliedHashes > 0 and ped == PlayerPedId() then
        for _, h in ipairs(appliedHashes) do
            if component == h then return true end
        end
    end
    return origHasPedGot(ped, weapon, component)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- KVP SAVE / LOAD
-- ═══════════════════════════════════════════════════════════════════════════════
local KVP_KEY = "1nfx_saved_skin"
local function SaveSkinKVP(s) if s and s ~= '' then SetResourceKvp(KVP_KEY, s) else DeleteResourceKvp(KVP_KEY) end end
local function LoadSkinKVP() local v = GetResourceKvpString(KVP_KEY) if v and v ~= '' then return v end return nil end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    Wait(3000)
    BuildSkinDB()
    local count = 0
    for _ in pairs(SKIN_DB) do count = count + 1 end
    if count > 0 then
        print(("^2[1nfx] Loaded %d skins from resource config^7"):format(count))
    else
        print("^3[1nfx] No config found — /home <modelname> ใช้ชื่อโมเดลตรงๆ ได้เลย^7")
    end

    local saved = LoadSkinKVP()
    if saved then
        selectedSkin = saved
        active = true
        StartAutoEquip()
        StartHandFx(saved)
        RegisterDamageHandler()
        print(("^2[1nfx] Auto-loaded: %s^7"):format(saved))
    end
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then RemoveSkinProp() end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterCommand('home', function(_, args)
    if #args < 1 then
        print("^1[1nfx] /home <skinname> — พิมพ์ชื่อสกินหรือชื่อโมเดลตรงๆ^7")
        return
    end

    RemoveSkin()
    StopHandFx()

    local input = args[1]
    local skinKey = FindSkin(input) or input

    selectedSkin = skinKey
    active = true

    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    if curWeapon ~= GetHashKey('WEAPON_UNARMED') and curWeapon ~= 0 then
        ApplySkin(skinKey)
    end

    StartAutoEquip()
    StartHandFx(skinKey)
    RegisterDamageHandler()
    SaveSkinKVP(skinKey)

    local label = skinKey
    if SKIN_DB[skinKey] then label = SKIN_DB[skinKey].label or skinKey end
    print(("^2[1nfx] Equipped: %s^7"):format(label))
end, false)

RegisterCommand('homeoff', function()
    RemoveSkin()
    StopHandFx()
    selectedSkin = nil
    active = false
    autoEquipActive = false
    appliedHashes = {}
    SaveSkinKVP(nil)
    print("^1[1nfx] Skin removed.^7")
end, false)

RegisterCommand('homelist', function()
    BuildSkinDB()

    local skins = {}
    for skinName, data in pairs(SKIN_DB) do
        skins[#skins + 1] = { name = skinName, label = data.label or skinName }
    end
    table.sort(skins, function(a, b) return a.name < b.name end)

    if #skins == 0 then
        print("^3[1nfx] ไม่พบ config — ใช้ /home <ชื่อโมเดล> ตรงๆ ได้เลย^7")
        print("^3[1nfx] เช่น: /home w_me_poolcueredfire^7")
        return
    end

    print(("^3═══════════ [1nfx WEAPON SKINS] (%d) ═══════════^7"):format(#skins))
    for _, s in ipairs(skins) do
        local marker = (s.name == selectedSkin) and " ^2<< EQUIPPED^7" or ""
        local cfg = GetSkinCfg(s.name)
        local fx = (cfg and cfg.PTFX_ATTACH_BONE) and "^6+FX^7 " or ""
        print(("  /home ^6%s^7  (%s) %s%s"):format(s.name, s.label, fx, marker))
    end
    print("^3═══════════════════════════════════════════════^7")
end, false)

print("^2[1nfx] Ready — /home <skin> | /homelist | /homeoff^7")
