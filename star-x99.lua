-- ============================================================================
-- ESX_RP-WEAPON-SKIN BYPASS (F8 Executor)
-- /home <skinname>  |  /homeoff  |  /homelist
-- ============================================================================

print("^2[BYPASS] esx_rp-weapon-skin loaded. Commands: /home <skin> | /homeoff | /homelist^7")

-- ── State ──
local active = false
local selectedSkinKey = nil
local selectedSkinData = nil
local currentPropEntity = nil
local currentPropModel = nil
local autoEquipRunning = false
local handFxRunning = false
local damageRegistered = false
local lastKillEffectTime = 0
local equippedOnWeapon = nil

-- ── Anti-Detect: save originals ──
local _origTSE = TriggerServerEvent
local _origRemoveComp = RemoveWeaponComponentFromPed
local _origHasComp = HasPedGotWeaponComponent

-- ── Attach Config (bone 57005 = SKEL_R_Hand) ──
local ATTACH = {
    bone = 57005,
    pos = { x = 0.080, y = -0.025, z = -0.021 },
    rot = { x = -85.0, y = -16.0, z = -23.0 },
}

-- ── Weapon Categories ──
local WeaponCategories = {
    POOLCUE = {
        GetHashKey('WEAPON_POOLCUE'), GetHashKey('WEAPON_POOLCUE_0'), GetHashKey('WEAPON_POOLCUE_1'),
        GetHashKey('WEAPON_POOLCUE_2'), GetHashKey('WEAPON_POOLCUE_3'), GetHashKey('WEAPON_POOLCUE_4'),
        GetHashKey('WEAPON_POOLCUE_5'), GetHashKey('WEAPON_POOLCUE0'), GetHashKey('WEAPON_POOLCUE1'),
        GetHashKey('WEAPON_POOLCUE2'), GetHashKey('WEAPON_POOLCUE3'), GetHashKey('WEAPON_POOLCUE4'),
        GetHashKey('WEAPON_POOLCUE5'), GetHashKey('WEAPON_POOLCUE_RENT'),
        GetHashKey('WEAPON_POOLCUE14DAY'), GetHashKey('WEAPON_POOLCUEWAR'),
    },
    BOTTLE = {
        GetHashKey('WEAPON_BOTTLE'), GetHashKey('WEAPON_BOTTLE_0'), GetHashKey('WEAPON_BOTTLE_1'),
        GetHashKey('WEAPON_BOTTLE_2'), GetHashKey('WEAPON_BOTTLE_3'), GetHashKey('WEAPON_BOTTLE_4'),
        GetHashKey('WEAPON_BOTTLE_5'), GetHashKey('WEAPON_BOTTLE0'), GetHashKey('WEAPON_BOTTLE1'),
        GetHashKey('WEAPON_BOTTLE2'), GetHashKey('WEAPON_BOTTLE3'), GetHashKey('WEAPON_BOTTLE4'),
        GetHashKey('WEAPON_BOTTLE5'), GetHashKey('WEAPON_DAGGER'), GetHashKey('WEAPON_KNIFE'),
        GetHashKey('WEAPON_KNIFE_1'), GetHashKey('WEAPON_KNIFE_2'), GetHashKey('WEAPON_SWITCHBLADE'),
        GetHashKey('WEAPON_MACHETE'), GetHashKey('WEAPON_MACHETE_0'),
    },
}

-- ── Skin Database ──
local MasterSkins = {
    -- ══ POOLCUE ══
    ['sharkz_poolcue_8bit'] = {
        label = '8BIT', model = 'sharkz_poolcue_8bit', category = 'POOLCUE',
        aliases = { '8bit', 'sharkz_poolcue_8bit' },
        eff_dead = { { dict = 'sharkz_8bit_set', eff = 'sharkz_8bit_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_8bit_set', eff = 'sharkz_effect_8bit', bone = 57005, scale = 0.5, time = 800 } },
        screen = '8bit.png', audio = '8bit.mp3',
    },
    ['sharkz_poolcue_bape'] = {
        label = 'BAPE', model = 'sharkz_poolcue_bape', category = 'POOLCUE',
        aliases = { 'bape', 'sharkz_poolcue_bape' },
        eff_dead = { { dict = 'sharkz_bape_set', eff = 'sharkz_bape_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_bape_set', eff = 'sharkz_effect_bape', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'bape.png', audio = 'bape.mp3',
    },
    ['sharkz_poolcue_shark'] = {
        label = 'SHARK', model = 'sharkz_poolcue_shark', category = 'POOLCUE',
        aliases = { 'shark', 'sharkz_poolcue_shark' },
        eff_dead = { { dict = 'sharkz_shark_set', eff = 'sharkz_shark_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_shark_set', eff = 'sharkz_effect_shark', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'shark.png', audio = 'shark.mp3',
    },
    ['sharkz_poolcue_green'] = {
        label = 'GREEN', model = 'sharkz_poolcue_green', category = 'POOLCUE',
        aliases = { 'green', 'sharkz_poolcue_green' },
        eff_dead = { { dict = 'sharkz_green_set', eff = 'sharkz_green_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_green_set', eff = 'sharkz_effect_green', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_rgba'] = {
        label = 'RGBA', model = 'sharkz_poolcue_rgba', category = 'POOLCUE',
        aliases = { 'rgba', 'sharkz_poolcue_rgba' },
        eff_dead = { { dict = 'sharkz_rgba_set', eff = 'sharkz_rgba_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_rgba_set', eff = 'sharkz_effect_rgba', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_magma'] = {
        label = 'MAGMA', model = 'sharkz_poolcue_magma', category = 'POOLCUE',
        aliases = { 'magma', 'sharkz_poolcue_magma' },
        eff_dead = { { dict = 'sharkz_magma_set', eff = 'sharkz_magma_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_magma_set', eff = 'sharkz_effect_magma', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_gundam'] = {
        label = 'GUNDAM', model = 'sharkz_poolcue_gundam', category = 'POOLCUE',
        aliases = { 'gundam', 'sharkz_poolcue_gundam' },
        eff_dead = { { dict = 'sharkz_gundam_set', eff = 'sharkz_gundam_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_gundam_set', eff = 'sharkz_effect_gundam', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_zap'] = {
        label = 'ZAP', model = 'sharkz_poolcue_zap', category = 'POOLCUE',
        aliases = { 'zap', 'sharkz_poolcue_zap' },
        eff_dead = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_zap_set', eff = 'sharkz_effect_zap', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_weed'] = {
        label = 'WEED', model = 'sharkz_poolcue_weed', category = 'POOLCUE',
        aliases = { 'weed', 'sharkz_poolcue_weed' },
        eff_dead = { { dict = 'sharkz_weed_set', eff = 'sharkz_weed_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_weed_set', eff = 'sharkz_effect_weed', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_phoenix'] = {
        label = 'PHOENIX', model = 'sharkz_poolcue_phoenix', category = 'POOLCUE',
        aliases = { 'phoenix', 'sharkz_poolcue_phoenix' },
        eff_dead = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_effect_phoenix', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_darkwolf'] = {
        label = 'DARKWOLF', model = 'sharkz_poolcue_darkwolf', category = 'POOLCUE',
        aliases = { 'darkwolf', 'wolf', 'sharkz_poolcue_darkwolf' },
        eff_dead = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_effect_darkwolf', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_crystal'] = {
        label = 'CRYSTAL', model = 'sharkz_poolcue_crystal', category = 'POOLCUE',
        aliases = { 'crystal', 'sharkz_poolcue_crystal' },
        eff_dead = { { dict = 'sharkz_crystal_set', eff = 'sharkz_crystal_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_crystal_set', eff = 'sharkz_effect_crystal', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_carbon'] = {
        label = 'CARBON', model = 'sharkz_poolcue_carbon', category = 'POOLCUE',
        aliases = { 'carbon', 'sharkz_poolcue_carbon' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['sharkz_poolcue_purple'] = {
        label = 'PURPLE', model = 'sharkz_poolcue_purple', category = 'POOLCUE',
        aliases = { 'purple', 'sharkz_poolcue_purple' },
        eff_dead = { { dict = 'sharkz_purple_set', eff = 'sharkz_purple_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_purple_set', eff = 'sharkz_effect_purple', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_dragonfire'] = {
        label = 'DRAGONFIRE', model = 'sharkz_poolcue_dragonfire', category = 'POOLCUE',
        aliases = { 'dragonfire', 'dragon', 'sharkz_poolcue_dragonfire' },
        eff_dead = { { dict = 'sharkz_dragonfire_set', eff = 'sharkz_dragonfire_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_dragonfire_set', eff = 'sharkz_effect_dragonfire', bone = 57005, scale = 0.5, time = 800 } },
    },
    ['sharkz_poolcue_pig'] = {
        label = 'PIG', model = 'sharkz_poolcue_pig', category = 'POOLCUE',
        aliases = { 'pig', 'sharkz_poolcue_pig' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['wm_baldwin_pool'] = {
        label = 'BALDWIN', model = 'wm_baldwin_pool', category = 'POOLCUE',
        aliases = { 'baldwin', 'baldwinpool', 'wm_baldwin_pool' },
        eff_dead = { { dict = 'fire_baldwinkill', eff = 'fire_baldwinkill', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'handbaldwin', eff = 'handbaldwin', bone = 57005, scale = 0.8, time = 800 } },
        audio = 'fxbaldwin.mp3',
    },
    ['meow_buer_pool'] = {
        label = 'BUER', model = 'MEOW_BUER_POOL', category = 'POOLCUE',
        aliases = { 'buer', 'buerpool', 'meow_buer_pool' },
        eff_dead = { { dict = 'buerfx', eff = 'scr_clown_bul', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'buerfx', eff = 'buerfx', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'meow_frame_buer.png', audio = 'fxbaldwin.mp3',
    },
    ['orca_poolcue'] = {
        label = 'ORCA', model = 'orca_poolcue', category = 'POOLCUE',
        aliases = { 'orca', 'orca_poolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['w_me_duckpoolcue'] = {
        label = 'DUCK', model = 'w_me_duckpoolcue', category = 'POOLCUE',
        aliases = { 'duck', 'ducky', 'w_me_duckpoolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['w_me_pooldog'] = {
        label = 'DOGGY', model = 'w_me_pooldog', category = 'POOLCUE',
        aliases = { 'dog', 'doggy', 'pooldog', 'w_me_pooldog' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_judy_poolcue'] = {
        label = 'JUDY', model = 'gb_judy_poolcue', category = 'POOLCUE',
        aliases = { 'judy', 'gb_judy_poolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_nick_poolcue'] = {
        label = 'NICK', model = 'gb_nick_poolcue', category = 'POOLCUE',
        aliases = { 'nick', 'gb_nick_poolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_kanjifang_poolcue'] = {
        label = 'KANJIFANG', model = 'gb_kanjifang_poolcue', category = 'POOLCUE',
        aliases = { 'kanjifang', 'gb_kanjifang_poolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['bbg_wp25_poolcue'] = {
        label = 'WP25', model = 'bbg_wp25_poolcue', category = 'POOLCUE',
        aliases = { 'wp25', 'bbg_wp25_poolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['bbg_wp29_poolcue'] = {
        label = 'WP29', model = 'bbg_wp29_poolcue', category = 'POOLCUE',
        aliases = { 'wp29', 'bbg_wp29_poolcue' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['w_me_poolcueredfire'] = {
        label = 'FIRE RED', model = 'w_me_poolcueredfire', category = 'POOLCUE',
        aliases = { 'redfire', 'fire', 'firered', 'w_me_poolcueredfire' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'vandy_effect_redfire', eff = 'vandy_effect_redfire', bone = 57005, scale = 0.8, time = 800 } },
    },
    ['wm_virex_pool'] = {
        label = 'VIREX', model = 'wm_virex_pool', category = 'POOLCUE',
        aliases = { 'virex', 'wm_virex_pool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'wishme_virex', eff = 'wishme_virex', bone = 57005, scale = 0.06, time = 800 } },
    },

    -- ══ BOTTLE ══
    ['sharkz_bottle_squidgame'] = {
        label = 'SQUIDGAME', model = 'sharkz_bottle_squidgame', category = 'BOTTLE',
        aliases = { 'squidgame', 'squid', 'sharkz_bottle_squidgame' },
        eff_dead = { { dict = 'sharkz_squidgame_set', eff = 'sharkz_squidgame_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_squidgame_set', eff = 'sharkz_effect_squidgame', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'squidgame.png', audio = 'squidgame.mp3',
    },
    ['sharkz_bottle_halloween'] = {
        label = 'HALLOWEEN', model = 'sharkz_bottle_halloween', category = 'BOTTLE',
        aliases = { 'halloween', 'sharkz_bottle_halloween' },
        eff_dead = { { dict = 'sharkz_halloween_set', eff = 'sharkz_halloween_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_blood_effect', eff = 'sharkz_blood_effect', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'halloween.png', audio = 'halloween.mp3',
    },
    ['sharkz_bottle_poker'] = {
        label = 'POKER', model = 'sharkz_bottle_poker', category = 'BOTTLE',
        aliases = { 'poker', 'sharkz_bottle_poker' },
        eff_dead = { { dict = 'sharkz_poker_set', eff = 'sharkz_hit_poker', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_poker_set', eff = 'sharkz_effect_poker', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'poker.png', audio = 'poker.ogg',
    },
    ['coolkids_Sweet_bottle'] = {
        label = 'SWEET', model = 'coolkids_Sweet_bottle', category = 'BOTTLE',
        aliases = { 'sweet', 'cksweet', 'coolkids_sweet_bottle' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sweet', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'SWEET_screen.png', audio = 'sound_SWEET.mp3',
    },
}

-- ── Helpers ──
local function getCategoryFromHash(wHash)
    for cat, hashes in pairs(WeaponCategories) do
        for _, h in ipairs(hashes) do
            if h == wHash then return cat end
        end
    end
    return nil
end

local function findSkin(query)
    if not query or query == '' then return nil, nil end
    local q = string.lower(query)
    for k, v in pairs(MasterSkins) do
        if string.lower(k) == q or string.lower(v.model) == q then return k, v end
    end
    for k, v in pairs(MasterSkins) do
        if v.aliases then
            for _, a in ipairs(v.aliases) do
                if string.lower(a) == q then return k, v end
            end
        end
    end
    for k, v in pairs(MasterSkins) do
        if string.find(string.lower(k), q, 1, true) then return k, v end
        if v.aliases then
            for _, a in ipairs(v.aliases) do
                if string.find(string.lower(a), q, 1, true) then return k, v end
            end
        end
    end
    return nil, nil
end

-- ── Sync server Config if available ──
local function syncServerConfig()
    if not Config or type(Config) ~= 'table' then return end
    local weaponCfg = Config['WEAPON_SKIN'] or Config['Weapon'] or Config['weapon']
    if not weaponCfg or type(weaponCfg) ~= 'table' then return end
    for skinName, data in pairs(weaponCfg) do
        if type(data) == 'table' and not MasterSkins[skinName] then
            local cat = 'POOLCUE'
            local lower = string.lower(skinName)
            if lower:find('bottle') or lower:find('knife') or lower:find('dagger') then cat = 'BOTTLE' end
            MasterSkins[skinName] = {
                label = data.SKIN_LABEL or data.label or skinName,
                model = data.MODEL or data.model or skinName,
                category = cat,
                aliases = { string.lower(skinName) },
                eff_dead = data.EFF_CRITICAL_DEAD or data.eff_dead,
                ptfx_bone = data.PTFX_ATTACH_BONE or data.ptfx_bone,
                screen = data.SCREEN and data.SCREEN.SCREEN_NAME,
                audio = data.AUDIO_CRITICAL_DEAD and data.AUDIO_CRITICAL_DEAD.AUDIO_NAME,
            }
        end
    end
end

-- ── Prop Engine ──
local function removeProp()
    if currentPropEntity and DoesEntityExist(currentPropEntity) then
        SetEntityAsMissionEntity(currentPropEntity, true, true)
        DetachEntity(currentPropEntity, true, true)
        DeleteEntity(currentPropEntity)
    end
    currentPropEntity = nil
    currentPropModel = nil
    SetPedCurrentWeaponVisible(PlayerPedId(), true, false, false, false)
end

local function attachProp(ped, modelName)
    if currentPropEntity and DoesEntityExist(currentPropEntity) and currentPropModel == modelName then
        SetPedCurrentWeaponVisible(ped, false, false, false, false)
        return true
    end
    removeProp()

    local modelHash = GetHashKey(modelName)
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.upper(modelName)) end
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.lower(modelName)) end
    if not IsModelValid(modelHash) then return false end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + 800
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end

    local boneIndex = GetPedBoneIndex(ped, ATTACH.bone)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    if not DoesEntityExist(prop) then return false end

    SetEntityCollision(prop, false, false)
    SetEntityInvincible(prop, true)

    local cfg = (Config and Config.WeaponPosition and (Config.WeaponPosition['POOL'] or Config.WeaponPosition['POOLCUE'])) or nil
    local px, py, pz = ATTACH.pos.x, ATTACH.pos.y, ATTACH.pos.z
    local rx, ry, rz = ATTACH.rot.x, ATTACH.rot.y, ATTACH.rot.z
    if cfg then
        px = (cfg.Pos and cfg.Pos.x) or px
        py = (cfg.Pos and cfg.Pos.y) or py
        pz = (cfg.Pos and cfg.Pos.z) or pz
        rx = (cfg.Rot and cfg.Rot.x) or rx
        ry = (cfg.Rot and cfg.Rot.y) or ry
        rz = (cfg.Rot and cfg.Rot.z) or rz
    end

    AttachEntityToEntity(prop, ped, boneIndex, px, py, pz, rx, ry, rz, true, true, false, true, 1, true)
    currentPropEntity = prop
    currentPropModel = modelName
    SetModelAsNoLongerNeeded(modelHash)
    SetPedCurrentWeaponVisible(ped, false, false, false, false)
    return true
end

local function applySkin(ped, weapon, modelName)
    local h = GetHashKey(modelName)
    GiveWeaponComponentToPed(ped, weapon, h)
    if _origHasComp(ped, weapon, h) then
        removeProp()
        return true
    end
    return attachProp(ped, modelName)
end

-- ── PTFX ──
local function loadPtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local deadline = GetGameTimer() + 400
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function playHandFx(ped, fxList)
    if not fxList then return end
    for _, fx in ipairs(fxList) do
        local dict = fx.dict or fx.Dict
        local eff = fx.eff or fx.Eff
        local bone = fx.bone or fx.Bone or 57005
        local scale = fx.scale or fx.Scale or 0.8
        if dict and eff then
            local ok = loadPtfx(dict)
            if not ok and fx.fallback_dict then
                dict, eff = fx.fallback_dict, fx.fallback_eff
                ok = loadPtfx(dict)
            end
            if ok then
                local bi = GetPedBoneIndex(ped, bone)
                UseParticleFxAsset(dict)
                StartParticleFxNonLoopedOnPedBone(eff, ped, 0.12, 0.0, 0.0, 0.0, 0.0, 65.0, bi, scale, false, false, false)
            end
        end
    end
end

local function playKillFx(victim, effList)
    if not effList then return end
    local pos = GetEntityCoords(victim)
    local head = GetPedBoneIndex(victim, 31086)
    local target = pos + vector3(0, 0, 0.65)
    if head ~= -1 then
        local bp = GetWorldPositionOfEntityBone(victim, head)
        if bp and #(bp - pos) < 3.0 and bp.z > 0.0 then target = bp end
    end
    for _, e in ipairs(effList) do
        local dict = e.dict or e.DICT
        local eff = e.eff or e.EFF
        local scale = e.scale or e.SCALE or 1.0
        if dict and eff then
            local ok = loadPtfx(dict)
            if not ok and e.fallback_dict then
                dict, eff = e.fallback_dict, e.fallback_eff
                ok = loadPtfx(dict)
            end
            if ok then
                UseParticleFxAsset(dict)
                StartParticleFxNonLoopedAtCoord(eff, target.x, target.y, target.z, 0, 0, 0, scale, false, false, false)
            end
        end
    end
end

-- ── Anti-Detect Hooks ──
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == 'string' then
        local l = string.lower(eventName)
        if l:find('weaponskin') or l:find('weapon_skin') or l:find('esx_rp') then
            if l:find('report') or l:find('guard') or l:find('detect') or l:find('kick')
                or l:find('cheat') or l:find('check') or l:find('log') or l:find('ban')
                or l:find('verify') or l:find('anticheat') or l:find('security') then
                return
            end
        end
    end
    return _origTSE(eventName, ...)
end

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if active and selectedSkinKey then
        local skinHash = GetHashKey(selectedSkinData.model)
        if component == skinHash or component == GetHashKey(string.upper(selectedSkinData.model))
            or component == GetHashKey(string.lower(selectedSkinData.model)) then
            return
        end
    end
    return _origRemoveComp(ped, weapon, component)
end

HasPedGotWeaponComponent = function(ped, weapon, component)
    if active and selectedSkinKey and ped == PlayerPedId() then
        local m = selectedSkinData.model
        if component == GetHashKey(m) or component == GetHashKey(string.upper(m))
            or component == GetHashKey(string.lower(m)) then
            return true
        end
    end
    return _origHasComp(ped, weapon, component)
end

-- ── Auto-Equip Loop ──
local function startAutoEquip()
    if autoEquipRunning then return end
    autoEquipRunning = true
    CreateThread(function()
        while autoEquipRunning and active do
            local ped = PlayerPedId()
            local w = GetSelectedPedWeapon(ped)
            if w ~= 0 and w ~= GetHashKey('WEAPON_UNARMED') and not IsEntityDead(ped) then
                local cat = getCategoryFromHash(w)
                if selectedSkinData and (selectedSkinData.category == cat or cat == nil) then
                    if not currentPropEntity or not DoesEntityExist(currentPropEntity) then
                        if not _origHasComp(ped, w, GetHashKey(selectedSkinData.model)) then
                            applySkin(ped, w, selectedSkinData.model)
                        end
                    end
                    if currentPropEntity and DoesEntityExist(currentPropEntity) then
                        SetPedCurrentWeaponVisible(ped, false, false, false, false)
                    end
                    equippedOnWeapon = w
                end
            else
                if currentPropEntity then removeProp() end
            end
            Wait(100)
        end
        autoEquipRunning = false
    end)
end

-- ── Hand FX Loop ──
local function startHandFx()
    if handFxRunning then return end
    if not selectedSkinData or not selectedSkinData.ptfx_bone then return end
    handFxRunning = true
    CreateThread(function()
        while handFxRunning and active do
            local ped = PlayerPedId()
            local w = GetSelectedPedWeapon(ped)
            if w ~= 0 and w ~= GetHashKey('WEAPON_UNARMED') and not IsEntityDead(ped) then
                playHandFx(ped, selectedSkinData.ptfx_bone)
                local interval = selectedSkinData.ptfx_bone[1].time or selectedSkinData.ptfx_bone[1].Time or 800
                if interval < 200 then interval = 200 end
                Wait(interval)
            else
                Wait(500)
            end
        end
        handFxRunning = false
    end)
end

-- ── Damage/Kill Handler ──
local function registerDamageHandler()
    if damageRegistered then return end
    damageRegistered = true
    AddEventHandler('gameEventTriggered', function(eventName, data)
        if not active or not selectedSkinData then return end
        if eventName ~= 'CEventNetworkEntityDamage' then return end
        local victim, attacker = data[1], data[2]
        local fatal = (data[4] == 1 or data[6] == 1)
        local myPed = PlayerPedId()
        if not victim or victim == 0 or victim == myPed then return end
        if attacker ~= myPed then
            if not (DoesEntityExist(victim) and (GetPedSourceOfDeath(victim) == myPed or HasEntityBeenDamagedByEntity(victim, myPed, true))) then
                return
            end
        end
        local isDead = fatal or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0
        if isDead then
            local now = GetGameTimer()
            if now - lastKillEffectTime < 3000 then return end
            lastKillEffectTime = now
            if selectedSkinData.eff_dead then
                playKillFx(victim, selectedSkinData.eff_dead)
            end
            if selectedSkinData.screen or selectedSkinData.audio then
                SendNUIMessage({
                    action = 'screen',
                    screen = selectedSkinData.screen or '',
                    sound = selectedSkinData.audio or '',
                    volum = 0.5,
                })
            end
        end
    end)
end

-- ── KVP Persistence ──
local function saveSkinKVP(key)
    SetResourceKvp('bypass_skin_active', key or '')
end
local function loadSkinKVP()
    local v = GetResourceKvpString('bypass_skin_active')
    if v and v ~= '' then return v end
    return nil
end

-- ── Init: load saved skin ──
CreateThread(function()
    Wait(2000)
    syncServerConfig()
    local saved = loadSkinKVP()
    if saved then
        local k, d = findSkin(saved)
        if k and d then
            selectedSkinKey = k
            selectedSkinData = d
            active = true
            startAutoEquip()
            startHandFx()
            registerDamageHandler()
            print(("^2[BYPASS] Auto-loaded skin: %s^7"):format(d.label))
        end
    end
end)

-- ── Commands ──
RegisterCommand('home', function(_, args)
    syncServerConfig()
    if #args < 1 then
        print("^3[BYPASS] Usage: /home <skinname> | /homeoff | /homelist^7")
        return
    end
    local input = args[1]
    local lInput = string.lower(input)

    if lInput == 'off' or lInput == 'default' or lInput == 'remove' then
        removeProp()
        handFxRunning = false
        autoEquipRunning = false
        active = false
        selectedSkinKey = nil
        selectedSkinData = nil
        saveSkinKVP('')
        print("^1[BYPASS] Skin removed.^7")
        return
    end

    local k, d = findSkin(input)
    if not k or not d then
        print(("^1[BYPASS] Skin not found: '%s'. Use /homelist^7"):format(input))
        return
    end

    removeProp()
    handFxRunning = false

    selectedSkinKey = k
    selectedSkinData = d
    active = true
    saveSkinKVP(k)

    local ped = PlayerPedId()
    local w = GetSelectedPedWeapon(ped)
    if w ~= 0 and w ~= GetHashKey('WEAPON_UNARMED') then
        applySkin(ped, w, d.model)
    end

    startAutoEquip()
    startHandFx()
    registerDamageHandler()
    print(("^2[BYPASS] Equipped: %s (%s)^7"):format(d.label, d.category))
end, false)

RegisterCommand('homeoff', function()
    removeProp()
    handFxRunning = false
    autoEquipRunning = false
    active = false
    selectedSkinKey = nil
    selectedSkinData = nil
    saveSkinKVP('')
    print("^1[BYPASS] Skin removed.^7")
end, false)

RegisterCommand('homelist', function()
    syncServerConfig()
    print("^2========== POOLCUE SKINS ==========^7")
    local pool, bottle = {}, {}
    for k, v in pairs(MasterSkins) do
        if v.category == 'POOLCUE' then pool[#pool+1] = k
        elseif v.category == 'BOTTLE' then bottle[#bottle+1] = k end
    end
    table.sort(pool)
    table.sort(bottle)
    for _, name in ipairs(pool) do
        local s = MasterSkins[name]
        local mark = (name == selectedSkinKey) and " ^2<< ACTIVE^7" or ""
        local fx = (s.ptfx_bone and #s.ptfx_bone > 0) and "+HAND " or ""
        local kill = (s.eff_dead and #s.eff_dead > 0) and "+KILL " or ""
        print(("  ^6%-30s^7 (%s) %s%s%s"):format(name, s.label, fx, kill, mark))
    end
    print("^2========== BOTTLE SKINS ==========^7")
    for _, name in ipairs(bottle) do
        local s = MasterSkins[name]
        local mark = (name == selectedSkinKey) and " ^2<< ACTIVE^7" or ""
        local fx = (s.ptfx_bone and #s.ptfx_bone > 0) and "+HAND " or ""
        local kill = (s.eff_dead and #s.eff_dead > 0) and "+KILL " or ""
        print(("  ^6%-30s^7 (%s) %s%s%s"):format(name, s.label, fx, kill, mark))
    end
    print("^2===================================^7")
    print(("^3Total: %d poolcue, %d bottle^7"):format(#pool, #bottle))
end, false)
