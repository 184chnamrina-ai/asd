-- ====================================================================================
-- PEPE WEAPONSKIN - F8: /home <skinname> | /homelist | /homeoff
-- Pulls skins from SkinPool + Config.Weapons of this server only
-- ====================================================================================

print('^2[PEPE-SKIN]^7 Loaded! /home <skinname> | /homelist | /homeoff')

local active = false
local selectedLabel = nil
local selectedItem = nil
local selectedComponent = nil
local selectedUpgrade = nil
local selectedModel = nil
local selectedModelPos = nil
local selectedModelRot = nil
local equippedOnWeapon = nil
local autoEquipActive = false
local handFxActive = false
local damageRegistered = false
local lastEffectTime = 0
local activeProp = nil

local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComponent = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

-- ========== BUILD SKIN DB FROM SERVER CONFIG ==========
local SKIN_DB = {}

local function BuildSkinDB()
    if not Config or not Config.Weapons then
        print('^1[PEPE-SKIN]^7 Config.Weapons not found!')
        return
    end
    for weaponName, weaponData in pairs(Config.Weapons) do
        local wHash = GetHashKey(weaponName)
        if weaponData.skins then
            for _, skin in ipairs(weaponData.skins) do
                local key = string.lower(skin.label)
                if not SKIN_DB[key] then
                    SKIN_DB[key] = {}
                end
                table.insert(SKIN_DB[key], {
                    weaponName = weaponName,
                    weaponHash = wHash,
                    category = weaponData.category,
                    label = skin.label,
                    item = skin.item,
                    component = skin.component,
                    upgrade = skin.upgrade,
                    model = skin.model,
                    pos = skin.pos,
                    rot = skin.rot,
                })
            end
        end
    end
    local count = 0
    for _ in pairs(SKIN_DB) do count = count + 1 end
    print('^2[PEPE-SKIN]^7 Loaded ' .. count .. ' unique skin labels from Config')
end

-- ========== UTILITY ==========
local function ForceLoadPtfx(dict)
    if not dict then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local t = 0
    while not HasNamedPtfxAssetLoaded(dict) and t < 60 do Wait(10) t = t + 1 end
    return HasNamedPtfxAssetLoaded(dict)
end

local function SafeDeleteProp(prop)
    if not prop or not DoesEntityExist(prop) then return end
    DetachEntity(prop, true, true)
    SetEntityAsMissionEntity(prop, true, true)
    DeleteEntity(prop)
end

local function RemoveProp()
    if activeProp then SafeDeleteProp(activeProp) activeProp = nil end
end

local function GetCurrentWeaponName(weaponHash)
    if not Config or not Config.Weapons then return nil end
    for weaponName, _ in pairs(Config.Weapons) do
        if GetHashKey(weaponName) == weaponHash then return weaponName end
    end
    return nil
end

local function FindSkinForWeapon(label, weaponHash)
    local key = string.lower(label)
    local entries = SKIN_DB[key]
    if not entries then return nil end
    for _, entry in ipairs(entries) do
        if entry.weaponHash == weaponHash then return entry end
    end
    return nil
end

-- ========== APPLY / REMOVE COMPONENT ==========
local function ApplyComponent(ped, weaponHash, componentName)
    if not componentName then return end
    local compHash = GetHashKey(componentName)
    GiveWeaponComponentToPed(ped, weaponHash, compHash)
end

local function RemoveCurrentSkin()
    if selectedComponent and equippedOnWeapon then
        local ped = PlayerPedId()
        local compHash = GetHashKey(selectedComponent)
        origRemoveComponent(ped, equippedOnWeapon, compHash)
    end
    RemoveProp()
    equippedOnWeapon = nil
end

-- ========== PROP ATTACH (model-based skins: THUNDERX, RYX, PIRATE) ==========
local function AttachPropSkin(ped, modelName, pos, rot)
    RemoveProp()
    if not modelName then return end
    local modelHash = GetHashKey(modelName)
    if not IsModelInCdimage(modelHash) then return end
    RequestModel(modelHash)
    local t = 0
    while not HasModelLoaded(modelHash) and t < 30 do Wait(10) t = t + 1 end
    if not HasModelLoaded(modelHash) then return end
    local coords = GetEntityCoords(ped)
    activeProp = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    SetEntityCollision(activeProp, false, false)
    DisableCamCollisionForObject(activeProp)
    local boneIndex = GetPedBoneIndex(ped, 28422)
    local px, py, pz = 0.055, 0.045, 0.01
    local rx, ry, rz = -77.0, -23.0, -16.0
    if pos then px, py, pz = pos.x or px, pos.y or py, pos.z or pz end
    if rot then rx, ry, rz = rot.x or rx, rot.y or ry, rot.z or rz end
    AttachEntityToEntity(activeProp, ped, boneIndex, px, py, pz, rx, ry, rz, true, true, false, false, 0, true)
    SetModelAsNoLongerNeeded(modelHash)
end

-- ========== HAND FX ==========
local function StopHandFx()
    handFxActive = false
end

local function StartHandFx()
    if handFxActive then return end
    local itemKey = selectedUpgrade or selectedItem
    if not itemKey or not Config or not Config.BoneEffects then return end
    local boneData = Config.BoneEffects[itemKey]
    if not boneData or not boneData.fx or #boneData.fx == 0 then return end
    handFxActive = true
    for _, fx in ipairs(boneData.fx) do
        CreateThread(function()
            while handFxActive and active do
                local ped = PlayerPedId()
                local curWep = GetSelectedPedWeapon(ped)
                if GetCurrentWeaponName(curWep) then
                    if ForceLoadPtfx(fx.dict) then
                        UseParticleFxAssetNextCall(fx.dict)
                        StartParticleFxNonLoopedOnPedBone(
                            fx.name, ped,
                            fx.x or 0.0, fx.y or 0.0, fx.z or 0.0,
                            fx.rx or 0.0, fx.ry or 0.0, fx.rz or 0.0,
                            fx.bone or 57005,
                            fx.size or 1.0,
                            false, false, false
                        )
                    end
                    Wait(fx.interval or 1000)
                else
                    Wait(500)
                end
            end
        end)
    end
end

-- ========== HIT/KILL EFFECTS ==========
local function PlayHitEffects(victimPed, isDead)
    if not selectedItem or not Config or not Config.HitEffects then return end
    local effects = Config.HitEffects[selectedItem]
    if not effects then return end
    local now = GetGameTimer()
    if now - lastEffectTime < 1500 then return end
    lastEffectTime = now

    for _, eff in ipairs(effects) do
        if isDead then
            if eff.type == "EffectHeadshot" or eff.type == "EffectKill" then
                CreateThread(function()
                    if ForceLoadPtfx(eff.dict) then
                        UseParticleFxAssetNextCall(eff.dict)
                        if eff.bone then
                            StartNetworkedParticleFxNonLoopedOnPedBone(
                                eff.name, victimPed,
                                eff.x or 0.0, eff.y or 0.0, eff.z or 0.0,
                                eff.rx or 0.0, eff.ry or 0.0, eff.rz or 0.0,
                                eff.bone, eff.size or 1.0,
                                false, false, false
                            )
                        else
                            local c = GetEntityCoords(victimPed)
                            StartNetworkedParticleFxNonLoopedAtCoord(
                                eff.name, c.x, c.y, c.z + 0.6,
                                0.0, 0.0, 0.0, eff.size or 1.0,
                                false, false, false
                            )
                        end
                    end
                end)
            elseif eff.type == "ScreenKill" then
                SendNUIMessage({ action = "showScreen", url = eff.url, duration = eff.duration or 2500 })
            elseif eff.type == "SoundKill" then
                SendNUIMessage({ action = "playSound", url = eff.url, volume = eff.volume or 0.5 })
            end
        else
            if eff.type == "EffectHit" then
                CreateThread(function()
                    if ForceLoadPtfx(eff.dict) then
                        UseParticleFxAssetNextCall(eff.dict)
                        if eff.bone then
                            StartNetworkedParticleFxNonLoopedOnPedBone(
                                eff.name, victimPed,
                                eff.x or 0.0, eff.y or 0.0, eff.z or 0.0,
                                eff.rx or 0.0, eff.ry or 0.0, eff.rz or 0.0,
                                eff.bone, eff.size or 1.0,
                                false, false, false
                            )
                        end
                    end
                end)
            elseif eff.type == "ScreenHit" then
                SendNUIMessage({ action = "showScreen", url = eff.url, duration = eff.duration or 1500 })
            elseif eff.type == "SoundHit" then
                SendNUIMessage({ action = "playSound", url = eff.url, volume = eff.volume or 0.5 })
            end
        end
    end
end

-- ========== DAMAGE HANDLER ==========
local function RegisterDamageHandler()
    if damageRegistered then return end
    damageRegistered = true
    AddEventHandler("gameEventTriggered", function(eventName, eventData)
        if not active or not selectedItem then return end
        if eventName ~= "CEventNetworkEntityDamage" then return end
        local victim = eventData[1]
        local attacker = eventData[2]
        local isFatalArg = eventData[4]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped then return end
        if not DoesEntityExist(victim) then return end
        local curWep = GetSelectedPedWeapon(ped)
        if not GetCurrentWeaponName(curWep) then return end
        local now = GetGameTimer()
        if now - lastEffectTime < 150 then return end
        CreateThread(function()
            Wait(10)
            local isDead = (isFatalArg == 1) or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or (GetEntityHealth(victim) <= 100)
            PlayHitEffects(victim, isDead)
        end)
    end)
end

-- ========== AUTO EQUIP LOOP ==========
local function StartAutoEquip()
    if autoEquipActive then return end
    autoEquipActive = true
    CreateThread(function()
        while autoEquipActive and active do
            local ped = PlayerPedId()
            local curWep = GetSelectedPedWeapon(ped)
            if curWep ~= GetHashKey('WEAPON_UNARMED') and selectedLabel then
                local skinEntry = FindSkinForWeapon(selectedLabel, curWep)
                if skinEntry then
                    if skinEntry.component then
                        local compHash = GetHashKey(skinEntry.component)
                        if not origHasPedGot(ped, curWep, compHash) then
                            GiveWeaponComponentToPed(ped, curWep, compHash)
                        end
                    end
                    equippedOnWeapon = curWep
                    selectedItem = skinEntry.item
                    selectedComponent = skinEntry.component
                    selectedUpgrade = skinEntry.upgrade
                    selectedModel = skinEntry.model
                    selectedModelPos = skinEntry.pos
                    selectedModelRot = skinEntry.rot

                    if skinEntry.model then
                        if not activeProp or not DoesEntityExist(activeProp) then
                            AttachPropSkin(ped, skinEntry.model, skinEntry.pos, skinEntry.rot)
                        end
                        local wepEntity = GetCurrentPedWeaponEntityIndex(ped)
                        if wepEntity and wepEntity ~= 0 and DoesEntityExist(wepEntity) then
                            SetEntityVisible(wepEntity, false, false)
                            SetEntityAlpha(wepEntity, 0, false)
                        end
                    else
                        RemoveProp()
                    end
                else
                    RemoveProp()
                end
            end
            Wait(200)
        end
        autoEquipActive = false
    end)
end

-- ========== HOOKS ==========
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == "string" then
        local lower = string.lower(eventName)
        if lower:find("pepe_weapon") or lower:find("weaponskin") then
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
    if active and selectedComponent then
        local skinHash = GetHashKey(selectedComponent)
        if component == skinHash then return end
    end
    return origRemoveComponent(ped, weapon, component)
end

HasPedGotWeaponComponent = function(ped, weapon, component)
    if active and selectedComponent then
        local skinHash = GetHashKey(selectedComponent)
        if component == skinHash and ped == PlayerPedId() then return true end
    end
    return origHasPedGot(ped, weapon, component)
end

-- ========== INIT ==========
CreateThread(function()
    Wait(3000)
    BuildSkinDB()
end)

-- ========== COMMANDS ==========

RegisterCommand('home', function(_, args)
    if #args < 1 then
        print('^1[PEPE-SKIN]^7 /home <skinname> | /homelist | /homeoff')
        if selectedLabel then print('^3[PEPE-SKIN]^7 Current: ' .. selectedLabel) end
        return
    end

    local skinInput = table.concat(args, ' ')
    local key = string.lower(skinInput)

    local entries = SKIN_DB[key]
    if not entries or #entries == 0 then
        for k, v in pairs(SKIN_DB) do
            if k:find(key, 1, true) then
                entries = v
                key = k
                break
            end
        end
    end

    if not entries or #entries == 0 then
        print('^1[PEPE-SKIN]^7 Not found: ' .. skinInput .. ' (/homelist)')
        return
    end

    RemoveCurrentSkin()
    StopHandFx()

    local first = entries[1]
    selectedLabel = first.label
    selectedItem = first.item
    selectedComponent = first.component
    selectedUpgrade = first.upgrade
    selectedModel = first.model
    selectedModelPos = first.pos
    selectedModelRot = first.rot
    active = true

    local ped = PlayerPedId()
    local curWep = GetSelectedPedWeapon(ped)
    if curWep ~= GetHashKey('WEAPON_UNARMED') then
        local skinForWep = FindSkinForWeapon(selectedLabel, curWep)
        if skinForWep then
            selectedItem = skinForWep.item
            selectedComponent = skinForWep.component
            selectedUpgrade = skinForWep.upgrade
            selectedModel = skinForWep.model
            selectedModelPos = skinForWep.pos
            selectedModelRot = skinForWep.rot
            if skinForWep.component then
                ApplyComponent(ped, curWep, skinForWep.component)
            end
            if skinForWep.model then
                AttachPropSkin(ped, skinForWep.model, skinForWep.pos, skinForWep.rot)
            end
            equippedOnWeapon = curWep
        end
    end

    StartAutoEquip()
    StartHandFx()
    RegisterDamageHandler()

    print('^2[PEPE-SKIN]^7 Equipped: ' .. selectedLabel .. ' (' .. (selectedComponent or selectedModel or '?') .. ')')
end, false)

RegisterCommand('homeoff', function()
    RemoveCurrentSkin()
    StopHandFx()
    selectedLabel = nil
    selectedItem = nil
    selectedComponent = nil
    selectedUpgrade = nil
    selectedModel = nil
    active = false
    autoEquipActive = false
    print('^3[PEPE-SKIN]^7 Removed skin')
end, false)

RegisterCommand('homelist', function()
    if not SKIN_DB or not next(SKIN_DB) then
        print('^1[PEPE-SKIN]^7 No skins loaded. Config not ready?')
        return
    end

    local categories = {}
    for key, entries in pairs(SKIN_DB) do
        local first = entries[1]
        local cat = first.category or 'OTHER'
        if not categories[cat] then categories[cat] = {} end
        local hasHand = false
        local hasKill = false
        if Config and Config.BoneEffects then
            local bk = first.upgrade or first.item
            if Config.BoneEffects[bk] then hasHand = true end
        end
        if Config and Config.HitEffects and Config.HitEffects[first.item] then hasKill = true end
        local marker = (selectedLabel and string.lower(selectedLabel) == key) and ' ^2<< EQUIPPED^7' or ''
        local hand = hasHand and '^3+HAND^7' or ''
        local kill = hasKill and '^1+KILL^7' or ''
        table.insert(categories[cat], {
            label = first.label,
            component = first.component,
            model = first.model,
            hand = hand,
            kill = kill,
            marker = marker,
        })
    end

    local catOrder = { 'POOLCUE', 'BOTTLE', 'KNIFE', 'KNUCKLE', 'MACHETE', 'TAZER' }
    local total = 0
    for _, cat in ipairs(catOrder) do
        local skins = categories[cat]
        if skins then
            table.sort(skins, function(a, b) return a.label < b.label end)
            print('^3===== ' .. cat .. ' (' .. #skins .. ') =====^7')
            for _, s in ipairs(skins) do
                local skinType = s.component and 'COMP' or 'PROP'
                print(('  ^6%-25s^7 [%s] %s %s%s'):format(s.label, skinType, s.hand, s.kill, s.marker))
                total = total + 1
            end
        end
    end
    print('^2===== TOTAL: ' .. total .. ' skins =====^7')
    print('^3[PEPE-SKIN]^7 /home <label> | /homeoff')
end, false)
