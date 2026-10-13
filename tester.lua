-- ═══════════════════════════════════════════════════════════════════════════════
-- 1nfx_weaponskin — Weapon Skin Unlocker
-- อ่าน Config จาก resource files โดยตรง ใช้ได้ทุกไม้
-- /home <skinname> | /homelist | /homeoff
-- ═══════════════════════════════════════════════════════════════════════════════

print("^2[1nfx] Loading...^7")

local RES = "1nfx_weaponskin"
local active = false
local selectedSkin = nil
local equippedOnWeapon = nil
local autoEquipActive = false
local handFxLoopActive = false
local damageRegistered = false
local lastEffectTime = 0

local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComponent = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

-- ═══════════════════════════════════════════════════════════════════════════════
-- LOAD CONFIG — อ่านจากไฟล์ resource โดยตรง
-- ═══════════════════════════════════════════════════════════════════════════════
local Cfg = nil

local function LoadConfig()
    if Cfg then return true end

    local env = { Config = { General = {
        weapons = {}, weaponTextures = {}, itemSkins = {},
        itemSkinAliases = {}, skinLabels = {}, weaponEffects = {},
    }}, GetHashKey = GetHashKey, sec = 1000, min = 60000 }
    setmetatable(env, { __index = _G })

    local files = {
        'config/config.lua',
        'config/config.mixing.lua',
        'config/weapons/poolcue.lua',
        'config/weapons/bottle.lua',
        'config/weapons/knuckle.lua',
        'config/weapons/machete.lua',
        'config/weapons/revolver.lua',
        'config/weapons/dagger.lua',
    }

    local skinFiles = {
        'bearxblack','bearxwhite','boom','bubblegum','candy','carbon','chromium',
        'crybaby','cutestar','darkchocolate','eightbit','endlesslove','goldx',
        'greendragon','jangwatrade','kradikjuu','lava','lazy_thunderx',
        'lightningstrike','lookprajaotak','maidaidi','monchhichi','morning',
        'onelove','poker','puppy','qoqo','rabbit','rainbow','rich','royalblood',
        'splashrod','stepfiaw','stl_green','whiterabbit','winterfrostblack','winterfrostwhite',
    }
    for _, name in ipairs(skinFiles) do
        files[#files+1] = 'config/skins/' .. name .. '.lua'
    end

    local loaded = 0
    for _, f in ipairs(files) do
        local raw = LoadResourceFile(RES, f)
        if raw and raw ~= '' then
            local fn = load(raw, '@' .. RES .. '/' .. f, 't', env)
            if fn then
                local ok = pcall(fn)
                if ok then loaded = loaded + 1 end
            end
        end
    end

    if loaded > 0 and env.Config and env.Config.General and env.Config.General.weaponTextures then
        local hasAnySkin = false
        for _, wt in pairs(env.Config.General.weaponTextures) do
            if wt.skins and next(wt.skins) then hasAnySkin = true break end
        end
        if hasAnySkin then
            Cfg = env.Config
            print(("^2[1nfx] Config loaded! (%d files)^7"):format(loaded))
            return true
        end
    end

    print(("^1[1nfx] Config load failed (loaded %d files but no skins found)^7"):format(loaded))
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- SKIN DB — สร้างจาก Config.General.weaponTextures
-- ═══════════════════════════════════════════════════════════════════════════════

-- SKIN_DB[skinName] = { label, components = { [weaponType] = componentName } }
local SKIN_DB = {}
local WEAPON_MAP = {} -- WEAPON_MAP[weaponHash] = weaponType ("Poolcue", "Bottle", etc)
local allComponentHashes = {}

local function BuildDB()
    SKIN_DB = {}
    WEAPON_MAP = {}
    allComponentHashes = {}
    if not Cfg or not Cfg.General then return end

    for weaponType, hashMap in pairs(Cfg.General.weapons or {}) do
        for hash, _ in pairs(hashMap) do
            WEAPON_MAP[hash] = weaponType
        end
    end

    for weaponType, texData in pairs(Cfg.General.weaponTextures or {}) do
        if texData.skins then
            for skinName, componentName in pairs(texData.skins) do
                if not SKIN_DB[skinName] then
                    SKIN_DB[skinName] = {
                        label = (Cfg.General.skinLabels and Cfg.General.skinLabels[skinName]) or skinName,
                        components = {},
                    }
                end
                SKIN_DB[skinName].components[weaponType] = componentName
                local h = GetHashKey(componentName)
                allComponentHashes[h] = true
            end
        end
    end

    local count = 0
    for _ in pairs(SKIN_DB) do count = count + 1 end
    print(("^2[1nfx] %d skins built for all weapon types^7"):format(count))
end

local function GetWeaponType(weaponHash)
    return WEAPON_MAP[weaponHash]
end

local function FindSkin(query)
    if not query or query == '' then return nil end
    local q = string.lower(query)
    for k in pairs(SKIN_DB) do
        if string.lower(k) == q then return k end
    end
    for k, v in pairs(SKIN_DB) do
        if v.label and string.lower(v.label) == q then return k end
    end
    for k in pairs(SKIN_DB) do
        if string.find(string.lower(k), q, 1, true) then return k end
    end
    return nil
end

local function GetEffects(skinName)
    if Cfg and Cfg.General and Cfg.General.weaponEffects then
        return Cfg.General.weaponEffects[skinName]
    end
    return nil
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- APPLY / REMOVE — GiveWeaponComponent ตรงจาก component name
-- ═══════════════════════════════════════════════════════════════════════════════
local appliedHash = 0

local function RemoveAllSkins(ped, weaponHash)
    for h in pairs(allComponentHashes) do
        if origHasPedGot(ped, weaponHash, h) then
            origRemoveComponent(ped, weaponHash, h)
        end
    end
end

local function ApplySkin(skinName)
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    if curWeapon == GetHashKey('WEAPON_UNARMED') or curWeapon == 0 then return false end

    local weaponType = GetWeaponType(curWeapon)
    if not weaponType then return false end

    local skinData = SKIN_DB[skinName]
    if not skinData then return false end

    local componentName = skinData.components[weaponType]
    if not componentName then return false end

    RemoveAllSkins(ped, curWeapon)

    local compHash = GetHashKey(componentName)
    GiveWeaponComponentToPed(ped, curWeapon, compHash)
    appliedHash = compHash
    equippedOnWeapon = curWeapon
    return true
end

local function RemoveSkin()
    if equippedOnWeapon then
        local ped = PlayerPedId()
        RemoveAllSkins(ped, equippedOnWeapon)
    end
    equippedOnWeapon = nil
    appliedHash = 0
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PTFX
-- ═══════════════════════════════════════════════════════════════════════════════
local function EnsurePtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local dl = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < dl do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function StopHandFx() handFxLoopActive = false end

-- ค้นหา FX list: ลอง weaponType ก่อน ถ้าไม่มีก็ fallback ไป entry อื่น
local function FindFxList(effectBlock, weaponType)
    if not effectBlock then return nil end
    local fxList = effectBlock[weaponType]
    if fxList and #fxList > 0 then return fxList end
    for _, list in pairs(effectBlock) do
        if type(list) == 'table' and #list > 0 then return list end
    end
    return nil
end

-- ค้นหา FX จาก Kill หรือ Hit — fallback ข้าม category
local function FindAnyFx(effects, weaponType)
    if not effects then return nil, nil end
    local fxList = nil
    local screen = nil
    if effects.Kill then
        fxList = FindFxList(effects.Kill.Effect, weaponType)
        screen = effects.Kill.Screen
    end
    if not fxList and effects.Hit then
        fxList = FindFxList(effects.Hit.Effect, weaponType)
        screen = screen or effects.Hit.Screen
    end
    return fxList, screen
end

local function StartHandFx(skinName, weaponType)
    StopHandFx()
    local effects = GetEffects(skinName)
    if not effects then return end

    local fxList = FindAnyFx(effects, weaponType)
    if not fxList or #fxList == 0 then return end

    handFxLoopActive = true
    for _, fx in ipairs(fxList) do
        CreateThread(function()
            while handFxLoopActive and active do
                local ped = PlayerPedId()
                if GetSelectedPedWeapon(ped) == GetHashKey('WEAPON_UNARMED') then
                    Wait(500)
                else
                    local dict = fx.particleDictionary
                    local eff = fx.particleName
                    local bone = fx.bone or 57005
                    local scale = (fx.scale or 1.0) * 0.5
                    local off = fx.offset or {}
                    local rot = fx.rot or {}
                    if dict and eff and EnsurePtfx(dict) then
                        UseParticleFxAsset(dict)
                        StartParticleFxNonLoopedOnPedBone(
                            eff, ped,
                            off.x or 0.0, off.y or 0.0, off.z or 0.0,
                            rot.x or 0.0, rot.y or 0.0, rot.z or 0.0,
                            bone, scale, false, false, false
                        )
                    end
                    Wait(fx.loop or fx.Time or 800)
                end
            end
        end)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- KILL / HIT EFFECTS — ใช้ได้ทุกไม้ fallback Kill↔Hit
-- ═══════════════════════════════════════════════════════════════════════════════
local function PlayScreenEffect(screen)
    if not screen then return end
    if screen.image and screen.image ~= '' then
        SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = screen.image, time = screen.duration or 3000 })
    end
    if screen.sound and screen.sound ~= '' then
        SendNUIMessage({ action = 'PLAY_SOUND', sound = screen.sound, volume = screen.volume or 0.3 })
    end
end

local function PlayPtfxAtTarget(fxList, targetPos)
    if not fxList then return end
    for _, ptfx in ipairs(fxList) do
        local dict = ptfx.particleDictionary
        local eff = ptfx.particleName
        local scale = ptfx.scale or 1.0
        local off = ptfx.offset or {}
        if dict and eff and EnsurePtfx(dict) then
            UseParticleFxAsset(dict)
            StartParticleFxNonLoopedAtCoord(
                eff,
                targetPos.x + (off.x or 0), targetPos.y + (off.y or 0), targetPos.z + (off.z or 0),
                0.0, 0.0, 0.0, scale, false, false, false
            )
        end
    end
end

local function GetTargetPos(victimPed)
    local pos = GetEntityCoords(victimPed)
    local headBone = GetPedBoneIndex(victimPed, 31086)
    local targetPos = pos + vector3(0.0, 0.0, 1.0)
    if headBone ~= -1 then
        local bPos = GetWorldPositionOfEntityBone(victimPed, headBone)
        if bPos and #(bPos - pos) < 3.0 and bPos.z > 0.0 then targetPos = bPos end
    end
    return targetPos
end

local lastHitTime = 0

local function PlayKillEffect(victimPed, skinName, weaponType)
    local now = GetGameTimer()
    if now - lastEffectTime < 2000 then return end
    lastEffectTime = now

    local effects = GetEffects(skinName)
    if not effects then return end

    -- ลอง Kill ก่อน fallback Hit
    local fxList, screen = nil, nil
    if effects.Kill and effects.Kill.Effect then
        fxList = FindFxList(effects.Kill.Effect, weaponType)
        screen = effects.Kill.Screen
    end
    if not fxList and effects.Hit and effects.Hit.Effect then
        fxList = FindFxList(effects.Hit.Effect, weaponType)
        screen = screen or (effects.Hit and effects.Hit.Screen)
    end

    if fxList then
        PlayPtfxAtTarget(fxList, GetTargetPos(victimPed))
    end
    PlayScreenEffect(screen)
end

local function PlayHitEffect(victimPed, skinName, weaponType)
    local now = GetGameTimer()
    if now - lastHitTime < 1000 then return end
    lastHitTime = now

    local effects = GetEffects(skinName)
    if not effects then return end

    -- ลอง Hit ก่อน fallback Kill
    local fxList = nil
    if effects.Hit and effects.Hit.Effect then
        fxList = FindFxList(effects.Hit.Effect, weaponType)
    end
    if not fxList and effects.Kill and effects.Kill.Effect then
        fxList = FindFxList(effects.Kill.Effect, weaponType)
    end

    if fxList then
        PlayPtfxAtTarget(fxList, GetTargetPos(victimPed))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- DAMAGE HANDLER — ทั้ง Kill + Hit
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
        local wType = GetWeaponType(GetSelectedPedWeapon(ped))
        if isDead == 1 or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) then
            PlayKillEffect(victim, selectedSkin, wType)
        else
            PlayHitEffect(victim, selectedSkin, wType)
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTO EQUIP
-- ═══════════════════════════════════════════════════════════════════════════════
local function StartAutoEquip()
    if autoEquipActive then return end
    autoEquipActive = true
    CreateThread(function()
        while autoEquipActive and active do
            local ped = PlayerPedId()
            local curWeapon = GetSelectedPedWeapon(ped)
            if selectedSkin and curWeapon ~= GetHashKey('WEAPON_UNARMED') and curWeapon ~= 0 then
                local wType = GetWeaponType(curWeapon)
                if wType then
                    local skinData = SKIN_DB[selectedSkin]
                    local compName = skinData and skinData.components[wType]
                    if compName then
                        local compHash = GetHashKey(compName)
                        if not origHasPedGot(ped, curWeapon, compHash) then
                            GiveWeaponComponentToPed(ped, curWeapon, compHash)
                            appliedHash = compHash
                            equippedOnWeapon = curWeapon
                        end
                    end
                end
            end
            Wait(200)
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
        if lower:find("1nfx") or lower:find("weaponskin") then
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
    if active and appliedHash ~= 0 and component == appliedHash then return end
    return origRemoveComponent(ped, weapon, component)
end

HasPedGotWeaponComponent = function(ped, weapon, component)
    if active and appliedHash ~= 0 and ped == PlayerPedId() and component == appliedHash then
        return true
    end
    return origHasPedGot(ped, weapon, component)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- KVP
-- ═══════════════════════════════════════════════════════════════════════════════
local KVP = "1nfx_skin"
local function SaveKVP(s) if s then SetResourceKvp(KVP, s) else DeleteResourceKvp(KVP) end end
local function LoadKVP() local v = GetResourceKvpString(KVP) if v and v ~= '' then return v end return nil end

-- ═══════════════════════════════════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    Wait(3000)
    if not LoadConfig() then
        Wait(5000)
        LoadConfig()
    end
    if Cfg then
        BuildDB()
    end

    local saved = LoadKVP()
    if saved and SKIN_DB[saved] then
        selectedSkin = saved
        active = true
        StartAutoEquip()
        local ped = PlayerPedId()
        local wType = GetWeaponType(GetSelectedPedWeapon(ped))
        StartHandFx(saved, wType)
        RegisterDamageHandler()
        print(("^2[1nfx] Auto-loaded: %s^7"):format(saved))
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMANDS
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterCommand('home', function(_, args)
    if not Cfg then
        LoadConfig()
        if Cfg then BuildDB() end
    end

    if #args < 1 then
        print("^1[1nfx] /home <skinname>^7")
        return
    end

    RemoveSkin()
    StopHandFx()

    local skinKey = FindSkin(args[1])
    if not skinKey then
        print(("^1[1nfx] Skin '%s' not found — /homelist^7"):format(args[1]))
        return
    end

    selectedSkin = skinKey
    active = true

    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    local wType = GetWeaponType(curWeapon)

    if wType then
        ApplySkin(skinKey)
    end

    StartAutoEquip()
    StartHandFx(skinKey, wType)
    RegisterDamageHandler()
    SaveKVP(skinKey)

    local label = SKIN_DB[skinKey] and SKIN_DB[skinKey].label or skinKey
    print(("^2[1nfx] Equipped: %s^7"):format(label))
end, false)

RegisterCommand('homeoff', function()
    RemoveSkin()
    StopHandFx()
    selectedSkin = nil
    active = false
    autoEquipActive = false
    appliedHash = 0
    SaveKVP(nil)
    print("^1[1nfx] Skin removed.^7")
end, false)

RegisterCommand('homelist', function()
    if not Cfg then
        LoadConfig()
        if Cfg then BuildDB() end
    end

    if not next(SKIN_DB) then
        print("^1[1nfx] No skins loaded.^7")
        return
    end

    local weaponTypes = {}
    for skinName, data in pairs(SKIN_DB) do
        for wType in pairs(data.components) do
            if not weaponTypes[wType] then weaponTypes[wType] = {} end
            weaponTypes[wType][#weaponTypes[wType]+1] = { name = skinName, label = data.label }
        end
    end

    local order = { 'Poolcue', 'Bottle', 'Knuckle', 'Machete', 'Revolver', 'Dagger' }
    local total = 0
    for _ in pairs(SKIN_DB) do total = total + 1 end

    print(("^3═══════════ [1nfx SKINS] (%d) ═══════════^7"):format(total))
    for _, wType in ipairs(order) do
        local skins = weaponTypes[wType]
        if skins and #skins > 0 then
            table.sort(skins, function(a, b) return a.name < b.name end)
            print(("^3── %s (%d) ──^7"):format(wType, #skins))
            for _, s in ipairs(skins) do
                local marker = (s.name == selectedSkin) and " ^2<< EQUIPPED^7" or ""
                local fx = GetEffects(s.name) and "^6+FX^7 " or ""
                print(("  /home ^6%s^7  (%s) %s%s"):format(s.name, s.label, fx, marker))
            end
        end
    end
    print("^3═════════════════════════════════════════^7")
end, false)

print("^2[1nfx] Ready — /home <skin> | /homelist | /homeoff^7")
