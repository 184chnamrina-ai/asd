-- ====================================================================================
-- W-SKINSHOWCASE BYPASS — LIKE TOWN OFFICIAL SKINS ONLY (POOLCUE & BOTTLE ONLY)
-- ดึงเฉพาะสกินของเซิร์ฟเวอร์ Like Town (Config.WeaponSkinsData) สำหรับ Poolcue และ Bottle เท่านั้น 100%
-- ระบบคำสั่ง: /home [ชื่อ] | /homeoff | /homelist
-- แก้บัคไม้ไม่หาย / ไม้ค้างหลุดมือ / ไม้บิดขวางเอว 100%
-- ====================================================================================

-- ====================================================================================
-- 1. ตารางอาวุธในเซิร์ฟเวอร์ LIKE TOWN (เฉพาะ POOLCUE และ BOTTLE ทุก Variant)
-- ====================================================================================
local SERVER_WEAPONS = {
    ['WEAPON_POOLCUE'] = {
        'WEAPON_POOLCUE', 'WEAPON_POOLCUE_FREE', 'WEAPON_POOLCUE_NEWPLAYER', 'WEAPON_POOLCUE_COUNCIL',
        'WEAPON_POOLCUEWARZONE', 'WEAPON_POOLCUE0', 'WEAPON_POOLCUE1', 'WEAPON_POOLCUE2', 'WEAPON_POOLCUE3',
        'WEAPON_POOLCUE4', 'WEAPON_POOLCUE5', 'WEAPON_POOLCUELV1', 'WEAPON_POOLCUELV2', 'WEAPON_POOLCUELV3',
        'WEAPON_POOLCUELV4', 'WEAPON_POOLCUE_LV1', 'WEAPON_POOLCUE_LV2', 'WEAPON_POOLCUE_LV3',
        'WEAPON_POOLCUENEWBIE', 'WEAPON_POOLCUE_NEWBIE', 'WEAPON_POOLCUE_14D', 'WEAPON_POOLCUE14DAY',
        'WEAPON_POOLCUE_WELFARE', 'WEAPON_POOLWARZONE', 'WEAPON_POOLAVENGER', 'WEAPON_RABBIT_POOLCUE',
        'WEAPON_RYX_POOLCUE', 'WEAPON_THINGS_CHROMEACE_POOLCUE_PINK', 'WEAPON_THINGS_CHROMEACE_POOLCUE_SILVER',
        'WEAPON_WM_VIREX_POOL', 'WEAPON_POOLCUEWAR', 'WEAPON_POOLCUE_TIER0', 'WEAPON_POOLCUE_TIER1',
        'WEAPON_POOLCUE_TIER2', 'WEAPON_POOLCUE_TIER3', 'WEAPON_POOLCUE_BATTLE'
    },
    ['WEAPON_BOTTLE'] = {
        'WEAPON_BOTTLE', 'WEAPON_BOTTLE_NEWPLAYER', 'WEAPON_BOTTLE_COUNCIL', 'WEAPON_BOTTLEWARZONE',
        'WEAPON_BOTTLE0', 'WEAPON_BOTTLE1', 'WEAPON_BOTTLE2', 'WEAPON_BOTTLE3', 'WEAPON_BOTTLE4',
        'WEAPON_BOTTLE5', 'WEAPON_BOTTLELV1', 'WEAPON_BOTTLELV2', 'WEAPON_BOTTLELV3', 'WEAPON_BOTTLELV4',
        'WEAPON_BOTTLE_LV1', 'WEAPON_BOTTLE_LV2', 'WEAPON_BOTTLE_LV3', 'WEAPON_BOTTLENEWBIE',
        'WEAPON_BOTTLE_NEWBIE', 'WEAPON_BOTTLE_WELFARE', 'WEAPON_BOTTLEAVENGER', 'WEAPON_RABBIT_BOTTLE',
        'WEAPON_WIP_SNOW_BOTTLE', 'WEAPON_THINGS_CHROMEACE_BOTTLE_PINK', 'WEAPON_THINGS_CHROMEACE_BOTTLE_SILVER',
        'WEAPON_BOTTLE_TIER1', 'WEAPON_BOTTLE_TIER2', 'WEAPON_BOTTLE_TIER3', 'WEAPON_BOTTLE_BATTLE'
    }
}

local WEAPON_HASH_MAP = {}
local ALL_VALID_WEAPONS = {}

for baseKey, nameList in pairs(SERVER_WEAPONS) do
    for _, wName in ipairs(nameList) do
        local h = GetHashKey(wName)
        WEAPON_HASH_MAP[h] = baseKey
        ALL_VALID_WEAPONS[h] = true
        local s32 = (h >= 0x80000000) and (h - 0x100000000) or h
        WEAPON_HASH_MAP[s32] = baseKey
        ALL_VALID_WEAPONS[s32] = true
    end
end

local function GetWeaponBaseKey(wHash)
    if not wHash or wHash == 0 or wHash == GetHashKey('WEAPON_UNARMED') then return nil end
    return WEAPON_HASH_MAP[wHash]
end

-- ====================================================================================
-- 2. องศาการจับอาวุธ (ATTACHMENT PRESETS) ตรงตามมาตรฐาน FiveM ไม่บิดขวางเอว 100%
-- ====================================================================================
local ATTACH_CONFIG = {
    ['WEAPON_POOLCUE'] = {
        Bone = 28422, -- SKEL_R_Hand / PH_R_Hand
        Pos = { x = 0.055, y = 0.045, z = 0.01 },
        Rot = { x = -77.0, y = -23.0, z = -16.0 },
        RotOrder = 0  -- XYZ มาตรฐาน
    },
    ['WEAPON_BOTTLE'] = {
        Bone = 28422,
        Pos = { x = 0.08, y = 0.02, z = -0.02 },
        Rot = { x = -85.0, y = 0.0, z = 0.0 },
        RotOrder = 0
    }
}

-- ====================================================================================
-- 3. ฐานข้อมูลสกินเฉพาะเซิร์ฟเวอร์ LIKE TOWN (ครบทุกสกินของ POOLCUE และ BOTTLE)
-- ====================================================================================
local SERVER_SKINS_DB = {
    -- ─── 1. ไม้พูล (WEAPON_POOLCUE) — ครบทั้ง 15 สกิน ───
    { id='halloween', label='Halloween', weapon='WEAPON_POOLCUE', model='lz_halloween_pool', comp='COMPONENT_POOLCUE_HALLOWEEN',
      fx = { hold={dict='lz_halloween_fx', particle='halloween_hit', bone=57005, scale=0.2}, kill={dict='lz_halloween_fx', particle='halloween_hit', scale=1.0}, sound='lz_halloween_ovl.mp3', hud='lz_halloween_ovl' } },
    { id='halloween_pink', label='Halloween Pink', weapon='WEAPON_POOLCUE', model='lz_halloween_pool_pink', comp='COMPONENT_POOLCUE_HALLOWEEN_PINK',
      fx = { hold={dict='lz_halloween_fx', particle='halloween_hit_pink', bone=57005, scale=0.2}, kill={dict='lz_halloween_fx', particle='halloween_hit_pink', scale=1.0}, sound='lz_halloweenpink_ovl.mp3', hud='lz_halloweenpink_ovl' } },
    { id='brush', label='Brush', weapon='WEAPON_POOLCUE', model='drop_poolcue_brush', comp='COMPONENT_POOLCUE_BRUSH',
      fx = { kill={dict='drop_brush', particle='drop_particle_brush', scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', weapon='WEAPON_POOLCUE', model='drop_poolcue_greentea', comp='COMPONENT_POOLCUE_GREENTEA',
      fx = { kill={dict='drop_greentea', particle='drop_particle_greentea', scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', weapon='WEAPON_POOLCUE', model='dfx_poolcue_lava', comp='COMPONENT_POOLCUE_LAVA',
      fx = { kill={dict='dfx_lava', particle='dfx_particle_lava', scale=1.5}, hud='effect_lava' } },
    { id='betalike', label='Beta Like', weapon='WEAPON_POOLCUE', model='dfx_poolcue_betalike', comp='COMPONENT_POOLCUE_BETALIKE',
      fx = { kill={dict='dfx_ptfx_1', particle='dfx_particle_liketownbetax', scale=0.2}, hud='effect_liketownbetax' } },
    { id='streamer', label='Streamer', weapon='WEAPON_POOLCUE', model='dfx_poolcue_streamer', comp='COMPONENT_POOLCUE_STREAMER',
      fx = { kill={dict='dfx_ptfx_1', particle='dfx_particle_streamer', scale=0.1}, hud='effect_streamer' } },
    { id='carbon', label='Carbon', weapon='WEAPON_POOLCUE', model='dfx_poolcue_carbon', comp='COMPONENT_POOLCUE_CARBON',
      fx = { kill={dict='weapon_wishme', particle='wishme', scale=1.5}, sound='carbon_hit.ogg', hud='carbon_effect' } },
    { id='chromium', label='Chromium', weapon='WEAPON_POOLCUE', model='dfx_poolcue_chromium', comp='COMPONENT_POOLCUE_CHROMIUM',
      fx = { kill={dict='weapon_wishme', particle='wishme', scale=1.5}, sound='wishme_hit.ogg', hud='chromium_effect' } },
    { id='bape', label='Bape', weapon='WEAPON_POOLCUE', model='poolcue_bape', comp='COMPONENT_POOLCUE_BAPE',
      fx = { hold={dict='withme_bape', particle='withme_bape_hfx', bone=57005, scale=0.15}, kill={dict='withme_bape', particle='withme_bape_cri', scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='liketown', label='LikeTown', weapon='WEAPON_POOLCUE', model='liketown_poolcue', comp='COMPONENT_POOLCUE_LIKETOWN',
      fx = { kill={dict='dfx_ptfx_1', particle='dfx_particle_liketownbetax', scale=0.2}, hud='effect_liketownbetax' } },
    { id='virex', label='Virex', weapon='WEAPON_POOLCUE', model='wm_virex_pool', comp='COMPONENT_POOLCUE_VIREX',
      fx = { hold={dict='wishme_virex', particle='wishme_virex', bone=57005, scale=0.2}, kill={dict='wishme_virex', particle='wishme_virex', scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='chromeace_pink', label='ChromeAce Pink', weapon='WEAPON_POOLCUE', model='things_chromeace_pool_pink', comp='COMPONENT_POOLCUE_CHROMEACE_PINK',
      fx = { kill={dict='things_chromeace_pink', particle='things_chromeace_pink', scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', weapon='WEAPON_POOLCUE', model='things_chromeace_pool_sliver', comp='COMPONENT_POOLCUE_CHROMEACE_SILVER',
      fx = { kill={dict='things_chromeace_silver', particle='things_chromeace_silver', scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', weapon='WEAPON_POOLCUE', model='wm_baldwin_pool', comp='COMPONENT_POOLCUE_BALDWIN',
      fx = { hold={dict='handbaldwin', particle='handbaldwin', bone=57005, scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },

    -- ─── 2. ขวด (WEAPON_BOTTLE) — ครบทั้ง 12 สกิน ───
    { id='halloween', label='Halloween', weapon='WEAPON_BOTTLE', model='lz_halloween_knife', comp='COMPONENT_BOTTLE_HALLOWEEN',
      fx = { hold={dict='lz_halloween_fx', particle='halloween_hit', bone=57005, scale=0.2}, kill={dict='lz_halloween_fx', particle='halloween_hit', scale=1.0}, sound='lz_halloween_ovl.mp3', hud='lz_halloween_ovl' } },
    { id='halloween_pink', label='Halloween Pink', weapon='WEAPON_BOTTLE', model='lz_halloween_knife_pink', comp='COMPONENT_BOTTLE_HALLOWEEN_PINK',
      fx = { hold={dict='lz_halloween_fx', particle='halloween_hit_pink', bone=57005, scale=0.2}, kill={dict='lz_halloween_fx', particle='halloween_hit_pink', scale=1.0}, sound='lz_halloweenpink_ovl.mp3', hud='lz_halloweenpink_ovl' } },
    { id='brush', label='Brush', weapon='WEAPON_BOTTLE', model='drop_bottle_brush', comp='COMPONENT_BOTTLE_BRUSH',
      fx = { kill={dict='drop_brush', particle='drop_particle_brush', scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', weapon='WEAPON_BOTTLE', model='drop_bottle_greentea', comp='COMPONENT_BOTTLE_GREENTEA',
      fx = { kill={dict='drop_greentea', particle='drop_particle_greentea', scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', weapon='WEAPON_BOTTLE', model='dfx_bottle_lava', comp='COMPONENT_BOTTLE_LAVA',
      fx = { kill={dict='dfx_lava', particle='dfx_particle_lava', scale=1.5}, hud='effect_lava' } },
    { id='betalike', label='Beta Like', weapon='WEAPON_BOTTLE', model='dfx_bottle_betalike', comp='COMPONENT_BOTTLE_BETALIKE',
      fx = { kill={dict='dfx_ptfx_1', particle='dfx_particle_liketownbetax', scale=0.2}, hud='effect_liketownbetax' } },
    { id='streamer', label='Streamer', weapon='WEAPON_BOTTLE', model='dfx_bottle_streamer', comp='COMPONENT_BOTTLE_STREAMER',
      fx = { kill={dict='dfx_ptfx_1', particle='dfx_particle_streamer', scale=0.1}, hud='effect_streamer' } },
    { id='chromeace_pink', label='ChromeAce Pink', weapon='WEAPON_BOTTLE', model='things_chromeace_bottle_pink', comp='COMPONENT_BOTTLE_CHROMEACE_PINK',
      fx = { kill={dict='things_chromeace_pink', particle='things_chromeace_pink', scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', weapon='WEAPON_BOTTLE', model='things_chromeace_bottle_sliver', comp='COMPONENT_BOTTLE_CHROMEACE_SILVER',
      fx = { kill={dict='things_chromeace_silver', particle='things_chromeace_silver', scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', weapon='WEAPON_BOTTLE', model='wm_baldwin_knife', comp='COMPONENT_BOTTLE_BALDWIN',
      fx = { hold={dict='handbaldwin', particle='handbaldwin', bone=57005, scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },
    { id='virex', label='Virex', weapon='WEAPON_BOTTLE', model='wm_virex_knife', comp='COMPONENT_BOTTLE_VIREX',
      fx = { hold={dict='wishme_virex', particle='wishme_virex', bone=57005, scale=0.2}, kill={dict='wishme_virex', particle='wishme_virex', scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='bape', label='Bape', weapon='WEAPON_BOTTLE', model='knife_bape', comp='COMPONENT_BOTTLE_BAPE',
      fx = { hold={dict='withme_bape', particle='withme_bape_hfx', bone=57005, scale=0.15}, kill={dict='withme_bape', particle='withme_bape_cri', scale=0.2}, sound='bapebape.mp3', hud='bapee' } }
}

-- สร้างตาราง Model Hashes ทั้งหมดของเซิร์ฟเวอร์ เพื่อตรวจจับและกวาดล้างขยะ Entity
local SERVER_SKIN_MODELS = {}
for _, s in ipairs(SERVER_SKINS_DB) do
    if s.model then
        SERVER_SKIN_MODELS[GetHashKey(s.model)] = true
    end
end

-- ====================================================================================
-- 4. STATE & ENTITY LIFECYCLE MANAGEMENT (แก้บัคไม้ไม่หาย / หลุดมือ 100%)
-- ====================================================================================
local activeSkin = nil
local activePropEntity = nil
local activeHandThreads = {}
local lastHitTime = 0

local function ForceLoadPtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local t = GetGameTimer() + 800
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < t do
        Wait(10)
    end
    return HasNamedPtfxAssetLoaded(dict)
end

-- ฟังก์ชันทำลาย Entity Prop อย่างปลอดภัย ไร้ร่องรอย
local function SafeDeleteProp(entity)
    if not entity or not DoesEntityExist(entity) then return end
    pcall(function()
        DetachEntity(entity, true, true)
        SetEntityAsMissionEntity(entity, true, true)
        SetEntityCollision(entity, false, false)
        SetEntityVisible(entity, false, false)
        if type(DeleteObject) == 'function' then DeleteObject(entity) end
        if type(DeleteEntity) == 'function' then DeleteEntity(entity) end
        SetEntityAsNoLongerNeeded(entity)
    end)
end

-- ระบบ Garbage Collection สแกนตัวละคร กวาดล้างไม้หรือของที่ติดค้างอยู่
local function CleanupAttachedSkinProps(ped)
    if not ped or ped == 0 or not DoesEntityExist(ped) then return end
    if activePropEntity and DoesEntityExist(activePropEntity) then
        SafeDeleteProp(activePropEntity)
        activePropEntity = nil
    end

    pcall(function()
        local handle, obj = FindFirstObject()
        local success = true
        repeat
            if DoesEntityExist(obj) and IsEntityAttachedToEntity(obj, ped) then
                local model = GetEntityModel(obj)
                if SERVER_SKIN_MODELS[model] then
                    SafeDeleteProp(obj)
                end
            end
            success, obj = FindNextObject(handle)
        until not success
        EndFindObject(handle)
    end)
end

local function StopHandEffects()
    for _, t in ipairs(activeHandThreads) do
        t.isActive = false
    end
    activeHandThreads = {}
end

local function StartHandEffects()
    if not activeSkin or not activeSkin.fx or not activeSkin.fx.hold then return end
    if #activeHandThreads > 0 then return end

    local hFx = activeSkin.fx.hold
    local threadData = { isActive = true }
    table.insert(activeHandThreads, threadData)

    CreateThread(function()
        while threadData.isActive and activeSkin do
            local ped = PlayerPedId()
            local curWp = GetSelectedPedWeapon(ped)
            if ALL_VALID_WEAPONS[curWp] and not IsEntityDead(ped) then
                if ForceLoadPtfx(hFx.dict) then
                    UseParticleFxAssetNextCall(hFx.dict)
                    local boneId = (hFx.bone and hFx.bone ~= 0xDEAD) and hFx.bone or 57005
                    StartNetworkedParticleFxNonLoopedOnPedBone(
                        hFx.particle,
                        ped,
                        0.12, 0.0, 0.0,
                        0.0, 0.0, 65.0,
                        boneId,
                        hFx.scale or 0.2,
                        false, false, false
                    )
                end
                Wait(800)
            else
                Wait(300)
            end
        end
    end)
end

-- ====================================================================================
-- 5. RESOLVE SKIN & APPLY / REMOVE
-- ====================================================================================
local function FindSkin(query, baseKey)
    if not query or query == '' then return nil end
    local q = string.lower(query)

    -- ค้นหาตรงกับอาวุธที่ถืออยู่ก่อน
    if baseKey then
        for _, s in ipairs(SERVER_SKINS_DB) do
            if s.weapon == baseKey then
                if s.id == q or string.lower(s.label) == q then
                    return s
                end
            end
        end
        for _, s in ipairs(SERVER_SKINS_DB) do
            if s.weapon == baseKey then
                if string.find(s.id, q, 1, true) or string.find(string.lower(s.label), q, 1, true) then
                    return s
                end
            end
        end
    end

    -- ค้นหาจากฐานข้อมูลรวม
    for _, s in ipairs(SERVER_SKINS_DB) do
        if s.id == q or string.lower(s.label) == q then
            return s
        end
    end
    for _, s in ipairs(SERVER_SKINS_DB) do
        if string.find(s.id, q, 1, true) or string.find(string.lower(s.label), q, 1, true) then
            return s
        end
    end

    return nil
end

local function ApplyServerSkin(skinEntry)
    local ped = PlayerPedId()
    StopHandEffects()
    CleanupAttachedSkinProps(ped)

    if not skinEntry then
        activeSkin = nil
        pcall(function()
            LocalPlayer.state:set('Globalhand', nil, true)
            LocalPlayer.state:set('activePoolcueSkin', nil, true)
            TriggerServerEvent('w-skinshowcase:setHold', nil)
        end)
        -- คืนค่าไม้เดิมให้มองเห็นปกติ
        local wepEntity = GetCurrentPedWeaponEntityIndex(ped)
        if wepEntity and wepEntity ~= 0 and DoesEntityExist(wepEntity) then
            ResetEntityAlpha(wepEntity)
            SetEntityVisible(wepEntity, true, true)
        end
        return
    end

    activeSkin = skinEntry

    -- โหลด Ptfx ล่วงหน้า
    if activeSkin.fx then
        if activeSkin.fx.hold and activeSkin.fx.hold.dict then ForceLoadPtfx(activeSkin.fx.hold.dict) end
        if activeSkin.fx.kill and activeSkin.fx.kill.dict then ForceLoadPtfx(activeSkin.fx.kill.dict) end
    end

    -- Sync Statebag
    pcall(function()
        LocalPlayer.state:set('Globalhand', { weapon = activeSkin.weapon, object = activeSkin.model }, true)
        TriggerServerEvent('w-skinshowcase:setHold', activeSkin.fx and activeSkin.fx.hold and GetSelectedPedWeapon(ped) or nil)
    end)

    local curWp = GetSelectedPedWeapon(ped)
    if ALL_VALID_WEAPONS[curWp] then
        StartHandEffects()
    end
end

-- ====================================================================================
-- 6. MAIN ENGINE LOOP (0ms Fast Loop ซ่อนไม้เดิม + คุม Prop + ลบไม้ทันทีเมื่อเก็บอาวุธ)
-- ====================================================================================
CreateThread(function()
    while true do
        local sleep = 0
        local ped = PlayerPedId()

        if DoesEntityExist(ped) and not IsEntityDead(ped) and not IsPedDeadOrDying(ped, true) then
            local currentWeapon = GetSelectedPedWeapon(ped)
            local baseKey = GetWeaponBaseKey(currentWeapon)

            if baseKey and activeSkin and (activeSkin.weapon == baseKey) then
                local modelHash = GetHashKey(activeSkin.model)

                -- 1. บังคับซ่อนไม้เดิมทุกเฟรม 0ms ไร้การกระพริบ (ทำก่อนสร้าง prop เสมอ)
                local wepEntity = GetCurrentPedWeaponEntityIndex(ped)
                if wepEntity and wepEntity ~= 0 and DoesEntityExist(wepEntity) then
                    SetEntityVisible(wepEntity, false, false)
                    SetEntityAlpha(wepEntity, 0, false)
                end

                if IsModelInCdimage(modelHash) then
                    -- 2. สร้าง Prop สกิน (สร้างครั้งเดียว attach กับ weapon object)
                    if not activePropEntity or not DoesEntityExist(activePropEntity) then
                        RequestModel(modelHash)
                        local tries = 0
                        while not HasModelLoaded(modelHash) and tries < 25 do
                            Wait(10)
                            tries = tries + 1
                        end

                        if HasModelLoaded(modelHash) then
                            -- รอ weapon object พร้อม
                            local wObj = nil
                            for i = 1, 30 do
                                wObj = GetCurrentPedWeaponEntityIndex(ped)
                                if wObj and wObj ~= 0 and DoesEntityExist(wObj) then break end
                                Wait(50)
                            end

                            local coords = GetEntityCoords(ped)
                            activePropEntity = CreateObject(modelHash, coords.x, coords.y, coords.z - 50.0, false, false, false)
                            if activePropEntity and DoesEntityExist(activePropEntity) then
                                SetEntityCollision(activePropEntity, false, false)
                                pcall(DisableCamCollisionForObject, activePropEntity)

                                if wObj and wObj ~= 0 and DoesEntityExist(wObj) then
                                    AttachEntityToEntity(
                                        activePropEntity, wObj, 0,
                                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                                        false, true, false, true, 1, true
                                    )
                                else
                                    local att = ATTACH_CONFIG[baseKey] or ATTACH_CONFIG['WEAPON_POOLCUE']
                                    local boneIndex = GetPedBoneIndex(ped, att.Bone or 28422)
                                    if boneIndex == -1 then boneIndex = GetPedBoneIndex(ped, 28422) end
                                    AttachEntityToEntity(
                                        activePropEntity, ped, boneIndex,
                                        att.Pos.x, att.Pos.y, att.Pos.z,
                                        att.Rot.x, att.Rot.y, att.Rot.z,
                                        true, true, false, false,
                                        att.RotOrder or 0, true
                                    )
                                end
                                SetModelAsNoLongerNeeded(modelHash)
                            end
                        end
                    end
                else
                    if activePropEntity then
                        SafeDeleteProp(activePropEntity)
                        activePropEntity = nil
                    end
                end
            else
                -- ไม่ได้ถืออาวุธ หรือเก็บอาวุธเข้ากระเป๋า → ลบทันที 100%!
                if activePropEntity then
                    SafeDeleteProp(activePropEntity)
                    activePropEntity = nil
                end
                sleep = 120
            end
        else
            if activePropEntity then
                SafeDeleteProp(activePropEntity)
                activePropEntity = nil
            end
            sleep = 500
        end

        Wait(sleep)
    end
end)

-- ====================================================================================
-- 7. KILL & HIT EFFECTS (ตรงตามระบบ W-SKINSHOWCASE ของเซิร์ฟเวอร์ LIKE TOWN)
-- ====================================================================================
local function TriggerKillEffects(victimPed)
    if not activeSkin or not activeSkin.fx or not victimPed or not DoesEntityExist(victimPed) then return end
    local fx = activeSkin.fx

    -- 1. เล่นภาพ HUD หน้าจอ
    if fx.hud then
        pcall(function()
            SendNUIMessage({
                type = 'effect',
                name = fx.hud,
                time = 3000,
                fadein = 0, fadeout = 100, opacity = 100
            })
            SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = fx.hud, time = 3000 })
        end)
    end

    -- 2. เล่นเสียง Sound FX
    if fx.sound then
        pcall(function()
            SendNUIMessage({
                action = 'playSound',
                file = fx.sound,
                volume = 0.5
            })
            SendNUIMessage({ action = 'PLAY_SOUND', sound = fx.sound, volume = 0.5 })
        end)
    end

    -- 3. ยิง Particle แสงสังหารบนตัวเหยื่อ
    if fx.kill and fx.kill.dict and fx.kill.particle then
        CreateThread(function()
            if ForceLoadPtfx(fx.kill.dict) then
                UseParticleFxAssetNextCall(fx.kill.dict)
                local coords = GetEntityCoords(victimPed)
                StartNetworkedParticleFxNonLoopedAtCoord(
                    fx.kill.particle,
                    coords.x, coords.y, coords.z + 0.65,
                    0.0, 0.0, 0.0,
                    fx.kill.scale or 1.0,
                    false, false, false
                )
            end
        end)
    end
end

AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName == "CEventNetworkEntityDamage" then
        local victim = tonumber(args[1])
        local attacker = tonumber(args[2])
        local isFatal = tonumber(args[6]) == 1 or tonumber(args[4]) == 1
        local myPed = PlayerPedId()

        if attacker == myPed and victim ~= myPed and DoesEntityExist(victim) then
            local curWp = GetSelectedPedWeapon(myPed)
            if ALL_VALID_WEAPONS[curWp] and activeSkin then
                local now = GetGameTimer()
                if now - lastHitTime > 150 then
                    lastHitTime = now
                    CreateThread(function()
                        Wait(10)
                        local isDead = isFatal or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or (GetEntityHealth(victim) <= 100)
                        if isDead then
                            TriggerKillEffects(victim)
                        end
                    end)
                end
            end
        end
    end
end)

-- ====================================================================================
-- 8. HOOKS ป้องกันระบบตรวจสอบและเตะ (ANTI-CHEAT / ANTI-KICK BYPASS)
-- ====================================================================================
local rawHasPedGotWeaponComponent = HasPedGotWeaponComponent
HasPedGotWeaponComponent = function(ped, weaponHash, componentHash)
    if activeSkin and ped == PlayerPedId() and activeSkin.comp and componentHash == GetHashKey(activeSkin.comp) then
        return true
    end
    return rawHasPedGotWeaponComponent(ped, weaponHash, componentHash)
end

local rawRemoveWeaponComponentFromPed = RemoveWeaponComponentFromPed
RemoveWeaponComponentFromPed = function(ped, weaponHash, componentHash)
    if activeSkin and ped == PlayerPedId() and activeSkin.comp and componentHash == GetHashKey(activeSkin.comp) then
        return false
    end
    return rawRemoveWeaponComponentFromPed(ped, weaponHash, componentHash)
end

local rawTriggerServerEvent = TriggerServerEvent
TriggerServerEvent = function(eventName, ...)
    if type(eventName) == 'string' then
        local lo = string.lower(eventName)
        if lo:find('weaponskin') or lo:find('weapon_skin') or lo:find('skinguard') or lo:find('skinshowcase') then
            if lo:find('report') or lo:find('detect') or lo:find('kick') or lo:find('ban') or lo:find('cheat') or lo:find('verify') then
                return
            end
        end
    end
    return rawTriggerServerEvent(eventName, ...)
end

-- ====================================================================================
-- 9. USER COMMANDS: /home | /homeoff | /homelist
-- ====================================================================================

-- ── คำสั่ง /home [ชื่อสกิน] ──
RegisterCommand('home', function(_, args)
    local skinInput = args[1]
    if not skinInput or skinInput == '' then return end

    local q = string.lower(skinInput)
    if q == 'off' or q == 'none' or q == '0' or q == 'clear' then
        ExecuteCommand('homeoff')
        return
    end

    if q == 'list' or q == 'help' then
        ExecuteCommand('homelist')
        return
    end

    local ped = PlayerPedId()
    local curWp = GetSelectedPedWeapon(ped)
    local baseKey = GetWeaponBaseKey(curWp)
    if not baseKey then return end

    local skinEntry = FindSkin(q, baseKey)
    if skinEntry then
        ApplyServerSkin(skinEntry)
    end
end, false)

-- ── คำสั่ง /homeoff ──
RegisterCommand('homeoff', function()
    ApplyServerSkin(nil)
end, false)

-- ── คำสั่ง /homelist ──
RegisterCommand('homelist', function()
    local ped = PlayerPedId()
    local curWp = GetSelectedPedWeapon(ped)
    local curBaseKey = GetWeaponBaseKey(curWp)

    print('^2===================== [LIKE TOWN SKINS LIST] =====================^7')

    if curBaseKey then
        print(string.format('^3--- สกินที่ใช้ได้กับอาวุธที่ถืออยู่ (%s) ---^7', curBaseKey))
        for _, s in ipairs(SERVER_SKINS_DB) do
            if s.weapon == curBaseKey then
                local currentTag = (activeSkin and activeSkin.id == s.id and activeSkin.weapon == s.weapon) and ' ^2[กำลังใส่]^7' or ''
                print(string.format('  /home ^6%-18s^7 — %s%s', s.id, s.label, currentTag))
            end
        end
    else
        print('^3--- รายชื่อสกินทั้งหมด (Poolcue & Bottle เท่านั้น) ---^7')
        local grouped = {}
        for _, s in ipairs(SERVER_SKINS_DB) do
            grouped[s.weapon] = grouped[s.weapon] or {}
            table.insert(grouped[s.weapon], s)
        end
        local order = { 'WEAPON_POOLCUE', 'WEAPON_BOTTLE' }
        local labels = {
            ['WEAPON_POOLCUE'] = 'ไม้พูล (Pool Cue)',
            ['WEAPON_BOTTLE'] = 'ขวด (Bottle)'
        }
        for _, wKey in ipairs(order) do
            if grouped[wKey] then
                print(string.format('^3>> %s [%s]:^7', labels[wKey] or wKey, wKey))
                local line = '   '
                for idx, s in ipairs(grouped[wKey]) do
                    line = line .. string.format('^6%s^7, ', s.id)
                    if idx % 5 == 0 or idx == #grouped[wKey] then
                        print(line:sub(1, -3))
                        line = '   '
                    end
                end
            end
        end
    end

    print('^2=================================================================^7')
    print('^3วิธีใช้:^7 ถืออาวุธแล้วพิมพ์ ^2/home [ชื่อ]^7 | ถอด: ^1/homeoff^7')
end, false)

-- Cleanup เมื่อปิด Resource
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        local ped = PlayerPedId()
        StopHandEffects()
        CleanupAttachedSkinProps(ped)
        local wepEntity = GetCurrentPedWeaponEntityIndex(ped)
        if wepEntity and wepEntity ~= 0 and DoesEntityExist(wepEntity) then
            ResetEntityAlpha(wepEntity)
            SetEntityVisible(wepEntity, true, true)
        end
    end
end)
