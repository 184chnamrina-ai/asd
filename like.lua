-- ============================================================================
-- W-SKINSHOWCASE BYPASS — /home [skinname] | /home off | /home
-- ดึงจาก Config.WeaponSkinsData ของ w-skinshowcase เท่านั้น
-- รองรับทุกไม้ variant ในเซิฟ (POOLCUE0-5, BOTTLE0-5, KNIFE, COUNCIL ฯลฯ)
-- ============================================================================

print("^2[W-SKIN] >>> โหลดสำเร็จ! พิมพ์ /home เพื่อดูรายชื่อสกิน <<<^7")

local activeSkin = nil
local activeWeaponHash = nil
local autoEquipRunning = false
local handFxRunning = false
local dmgRegistered = false
local lastKillTime = 0

local origHas = HasPedGotWeaponComponent
local origRemove = RemoveWeaponComponentFromPed

-- ============================================================================
-- 1. WEAPON VARIANT MAP — ทุกไม้ในเซิฟ map กลับไปหา weaponKey ของ w-skinshowcase
-- ============================================================================
local WEAPON_VARIANTS = {}
local function reg(baseKey, names)
    for _, n in ipairs(names) do
        WEAPON_VARIANTS[GetHashKey(n)] = baseKey
    end
end

reg('WEAPON_POOLCUE', {
    'WEAPON_POOLCUE','WEAPON_POOLCUE0','WEAPON_POOLCUE1','WEAPON_POOLCUE2',
    'WEAPON_POOLCUE3','WEAPON_POOLCUE4','WEAPON_POOLCUE5',
    'WEAPON_POOLCUE14DAY','WEAPON_POOLCUEWAR','WEAPON_POOLCUE_COUNCIL',
    'WEAPON_POOLCUE_0','WEAPON_POOLCUE_1','WEAPON_POOLCUE_2','WEAPON_POOLCUE_3',
    'WEAPON_POOLCUE_4','WEAPON_POOLCUE_5','WEAPON_POOLCUE_6','WEAPON_POOLCUE_7',
    'WEAPON_POOLCUE_8','WEAPON_POOLCUE_9','WEAPON_POOLCUE_10',
})
reg('WEAPON_KNIFE', {
    'WEAPON_KNIFE','WEAPON_KNIFE0','WEAPON_KNIFE1','WEAPON_KNIFE2',
    'WEAPON_KNIFE3','WEAPON_KNIFE4','WEAPON_KNIFE5',
    'WEAPON_KNIFE_0','WEAPON_KNIFE_1','WEAPON_KNIFE_2','WEAPON_KNIFE_3',
    'WEAPON_KNIFE_4','WEAPON_KNIFE_5',
})
reg('WEAPON_BOTTLE', {
    'WEAPON_BOTTLE','WEAPON_BOTTLE0','WEAPON_BOTTLE1','WEAPON_BOTTLE2',
    'WEAPON_BOTTLE3','WEAPON_BOTTLE4','WEAPON_BOTTLE5',
    'WEAPON_BOTTLE_0','WEAPON_BOTTLE_1','WEAPON_BOTTLE_2','WEAPON_BOTTLE_3',
    'WEAPON_BOTTLE_4','WEAPON_BOTTLE_5','WEAPON_BOTTLE_COUNCIL',
})
reg('WEAPON_DAGGER', {
    'WEAPON_DAGGER','WEAPON_DAGGER0','WEAPON_DAGGER1','WEAPON_DAGGER2',
    'WEAPON_DAGGER3','WEAPON_DAGGER4','WEAPON_DAGGER5',
    'WEAPON_DAGGER_0','WEAPON_DAGGER_1','WEAPON_DAGGER_2',
})
reg('WEAPON_MACHETE', {
    'WEAPON_MACHETE','WEAPON_MACHETE0','WEAPON_MACHETE1','WEAPON_MACHETE2',
    'WEAPON_MACHETE3','WEAPON_MACHETE4','WEAPON_MACHETE5',
    'WEAPON_MACHETE_0','WEAPON_MACHETE_1','WEAPON_MACHETE_2',
})
reg('WEAPON_KNUCKLE', {
    'WEAPON_KNUCKLE','WEAPON_KNUCKLEDUSTER',
    'WEAPON_KNUCKLE0','WEAPON_KNUCKLE1','WEAPON_KNUCKLE2',
    'WEAPON_KNUCKLE3','WEAPON_KNUCKLE4','WEAPON_KNUCKLE5',
    'WEAPON_KNUCKLE_0','WEAPON_KNUCKLE_1','WEAPON_KNUCKLE_2','WEAPON_KNUCKLE_3',
})
reg('WEAPON_REVOLVER', {
    'WEAPON_REVOLVER','WEAPON_REVOLVER0','WEAPON_REVOLVER1','WEAPON_REVOLVER2',
    'WEAPON_REVOLVER3','WEAPON_REVOLVER4','WEAPON_REVOLVER5',
    'WEAPON_REVOLVER_0','WEAPON_REVOLVER_1','WEAPON_REVOLVER_2',
    'WEAPON_REVOLVER_MK2',
})
reg('WEAPON_BAT', {
    'WEAPON_BAT','WEAPON_BAT0','WEAPON_BAT1','WEAPON_BAT2',
    'WEAPON_BAT3','WEAPON_BAT4','WEAPON_BAT5',
    'WEAPON_BAT_0','WEAPON_BAT_1','WEAPON_BAT_2',
})

local function getWeaponKey(wHash)
    if not wHash or wHash == 0 or wHash == GetHashKey('WEAPON_UNARMED') then return nil end
    local r = WEAPON_VARIANTS[wHash]
    if r then return r end
    -- FiveM hash อาจ signed/unsigned ต่างกัน
    if wHash < 0 then
        r = WEAPON_VARIANTS[wHash + 0x100000000]
        if r then return r end
    else
        r = WEAPON_VARIANTS[wHash - 0x100000000]
        if r then return r end
    end
    -- fallback: ลองเช็คจากชื่อ weapon ที่รู้จัก
    local weaponGroups = {
        { key='WEAPON_POOLCUE', patterns={'poolcue','pool_cue'} },
        { key='WEAPON_KNIFE',   patterns={'knife'} },
        { key='WEAPON_BOTTLE',  patterns={'bottle'} },
        { key='WEAPON_DAGGER',  patterns={'dagger'} },
        { key='WEAPON_MACHETE', patterns={'machete'} },
        { key='WEAPON_KNUCKLE', patterns={'knuckle'} },
        { key='WEAPON_REVOLVER',patterns={'revolver'} },
        { key='WEAPON_BAT',     patterns={'bat'} },
    }
    for _, g in ipairs(weaponGroups) do
        for _, p in ipairs(g.patterns) do
            if wHash == GetHashKey('WEAPON_'..string.upper(p)) then return g.key end
        end
    end
    return nil
end

-- ============================================================================
-- 2. SKIN DATABASE (จาก w-skinshowcase Config.WeaponSkinsData)
-- ============================================================================
local SkinDB = {
    -- ═══ WEAPON_POOLCUE ═══
    { id='halloween', label='Halloween', rarity='epic', weaponKey='WEAPON_POOLCUE', model='lz_halloween_pool', comp='COMPONENT_POOLCUE_HALLOWEEN',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit',bone=57005,scale=0.2}, kill={playOn='headshot',dict='lz_halloween_fx',particle='halloween_hit',scale=1.0}, sound='lz_halloween_ovl.mp3', hud='lz_halloween_ovl' } },
    { id='halloween_pink', label='Halloween Pink', rarity='epic', weaponKey='WEAPON_POOLCUE', model='lz_halloween_pool_pink', comp='COMPONENT_POOLCUE_HALLOWEEN_PINK',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit_pink',bone=57005,scale=0.2}, kill={playOn='headshot',dict='lz_halloween_fx',particle='halloween_hit_pink',scale=1.0}, sound='lz_halloweenpink_ovl.mp3', hud='lz_halloweenpink_ovl' } },
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_POOLCUE', model='drop_poolcue_brush', comp='COMPONENT_POOLCUE_BRUSH',
      fx = { kill={playOn='headshot',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_POOLCUE', model='drop_poolcue_greentea', comp='COMPONENT_POOLCUE_GREENTEA',
      fx = { kill={playOn='headshot',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', rarity='mythic', weaponKey='WEAPON_POOLCUE', model='dfx_poolcue_lava', comp='COMPONENT_POOLCUE_LAVA',
      fx = { kill={playOn='headshot',dict='dfx_lava',particle='dfx_particle_lava',scale=1.5}, hud='effect_lava' } },
    { id='betalike', label='Beta Like', rarity='legendary', weaponKey='WEAPON_POOLCUE', model='dfx_poolcue_betalike', comp='COMPONENT_POOLCUE_BETALIKE',
      fx = { kill={playOn='headshot',dict='dfx_ptfx_1',particle='dfx_particle_liketownbetax',scale=0.2}, hud='effect_liketownbetax' } },
    { id='streamer', label='Streamer', rarity='legendary', weaponKey='WEAPON_POOLCUE', model='dfx_poolcue_streamer', comp='COMPONENT_POOLCUE_STREAMER',
      fx = { kill={playOn='headshot',dict='dfx_ptfx_1',particle='dfx_particle_streamer',scale=0.1}, hud='effect_streamer' } },
    { id='carbon', label='Carbon', rarity='rare', weaponKey='WEAPON_POOLCUE', model='dfx_poolcue_carbon', comp='COMPONENT_POOLCUE_CARBON',
      fx = { kill={playOn='headshot',dict='weapon_wishme',particle='wishme',scale=1.5}, sound='carbon_hit.ogg', hud='carbon_effect' } },
    { id='chromium', label='Chromium', rarity='rare', weaponKey='WEAPON_POOLCUE', model='dfx_poolcue_chromium', comp='COMPONENT_POOLCUE_CHROMIUM',
      fx = { kill={playOn='headshot',dict='weapon_wishme',particle='wishme',scale=1.5}, sound='wishme_hit.ogg', hud='chromium_effect' } },
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_POOLCUE', model='poolcue_bape', comp='COMPONENT_POOLCUE_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='headshot',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_POOLCUE', model='wm_virex_pool', comp='COMPONENT_POOLCUE_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='headshot',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='chromeace_pink', label='ChromeAce Pink', rarity='rare', weaponKey='WEAPON_POOLCUE', model='things_chromeace_pool_pink', comp='COMPONENT_POOLCUE_CHROMEACE_PINK',
      fx = { kill={playOn='headshot',dict='things_chromeace_pink',particle='things_chromeace_pink',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', rarity='rare', weaponKey='WEAPON_POOLCUE', model='things_chromeace_pool_sliver', comp='COMPONENT_POOLCUE_CHROMEACE_SILVER',
      fx = { kill={playOn='headshot',dict='things_chromeace_silver',particle='things_chromeace_silver',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', rarity='rare', weaponKey='WEAPON_POOLCUE', model='wm_baldwin_pool', comp='COMPONENT_POOLCUE_BALDWIN',
      fx = { hold={dict='handbaldwin',particle='handbaldwin',bone=57005,scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },

    -- ═══ WEAPON_KNIFE ═══
    { id='halloween', label='Halloween', rarity='epic', weaponKey='WEAPON_KNIFE', model='lz_halloween_knife', comp='COMPONENT_KNIFE_HALLOWEEN',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit',bone=57005,scale=0.2}, kill={playOn='dead',dict='lz_halloween_fx',particle='halloween_hit',scale=1.0}, sound='lz_halloween_ovl.mp3', hud='lz_halloween_ovl' } },
    { id='halloween_pink', label='Halloween Pink', rarity='epic', weaponKey='WEAPON_KNIFE', model='lz_halloween_knife_pink', comp='COMPONENT_KNIFE_HALLOWEEN_PINK',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit_pink',bone=57005,scale=0.2}, kill={playOn='dead',dict='lz_halloween_fx',particle='halloween_hit_pink',scale=1.0}, sound='lz_halloweenpink_ovl.mp3', hud='lz_halloweenpink_ovl' } },
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_KNIFE', model='drop_knife_brush', comp='COMPONENT_KNIFE_BRUSH',
      fx = { kill={playOn='dead',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_KNIFE', model='drop_knife_greentea', comp='COMPONENT_KNIFE_GREENTEA',
      fx = { kill={playOn='dead',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', rarity='mythic', weaponKey='WEAPON_KNIFE', model='dfx_knife_lava', comp='COMPONENT_KNIFE_LAVA',
      fx = { kill={playOn='dead',dict='dfx_lava',particle='dfx_particle_lava',scale=1.5}, hud='effect_lava' } },
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_KNIFE', model='knife_bape', comp='COMPONENT_KNIFE_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='dead',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_KNIFE', model='wm_virex_knife', comp='COMPONENT_KNIFE_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='dead',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='chromeace_pink', label='ChromeAce Pink', rarity='rare', weaponKey='WEAPON_KNIFE', model='things_chromeace_knife_pink', comp='COMPONENT_KNIFE_CHROMEACE_PINK',
      fx = { kill={playOn='dead',dict='things_chromeace_pink',particle='things_chromeace_pink',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', rarity='rare', weaponKey='WEAPON_KNIFE', model='things_chromeace_knife_sliver', comp='COMPONENT_KNIFE_CHROMEACE_SILVER',
      fx = { kill={playOn='dead',dict='things_chromeace_silver',particle='things_chromeace_silver',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', rarity='rare', weaponKey='WEAPON_KNIFE', model='wm_baldwin_knife', comp='COMPONENT_KNIFE_BALDWIN',
      fx = { hold={dict='handbaldwin',particle='handbaldwin',bone=57005,scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },

    -- ═══ WEAPON_BOTTLE ═══
    { id='halloween', label='Halloween', rarity='epic', weaponKey='WEAPON_BOTTLE', model='lz_halloween_knife', comp='COMPONENT_BOTTLE_HALLOWEEN',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit',bone=57005,scale=0.2}, kill={playOn='dead',dict='lz_halloween_fx',particle='halloween_hit',scale=1.0}, sound='lz_halloween_ovl.mp3', hud='lz_halloween_ovl' } },
    { id='halloween_pink', label='Halloween Pink', rarity='epic', weaponKey='WEAPON_BOTTLE', model='lz_halloween_knife_pink', comp='COMPONENT_BOTTLE_HALLOWEEN_PINK',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit_pink',bone=57005,scale=0.2}, kill={playOn='dead',dict='lz_halloween_fx',particle='halloween_hit_pink',scale=1.0}, sound='lz_halloweenpink_ovl.mp3', hud='lz_halloweenpink_ovl' } },
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_BOTTLE', model='drop_bottle_brush', comp='COMPONENT_BOTTLE_BRUSH',
      fx = { kill={playOn='dead',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_BOTTLE', model='drop_bottle_greentea', comp='COMPONENT_BOTTLE_GREENTEA',
      fx = { kill={playOn='dead',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', rarity='mythic', weaponKey='WEAPON_BOTTLE', model='dfx_bottle_lava', comp='COMPONENT_BOTTLE_LAVA',
      fx = { kill={playOn='dead',dict='dfx_lava',particle='dfx_particle_lava',scale=1.5}, hud='effect_lava' } },
    { id='betalike', label='Beta Like', rarity='legendary', weaponKey='WEAPON_BOTTLE', model='dfx_bottle_betalike', comp='COMPONENT_BOTTLE_BETALIKE',
      fx = { kill={playOn='dead',dict='dfx_ptfx_1',particle='dfx_particle_liketownbetax',scale=0.2}, hud='effect_liketownbetax' } },
    { id='streamer', label='Streamer', rarity='legendary', weaponKey='WEAPON_BOTTLE', model='dfx_bottle_streamer', comp='COMPONENT_BOTTLE_STREAMER',
      fx = { kill={playOn='dead',dict='dfx_ptfx_1',particle='dfx_particle_streamer',scale=0.1}, hud='effect_streamer' } },
    { id='chromeace_pink', label='ChromeAce Pink', rarity='rare', weaponKey='WEAPON_BOTTLE', model='things_chromeace_bottle_pink', comp='COMPONENT_BOTTLE_CHROMEACE_PINK',
      fx = { kill={playOn='dead',dict='things_chromeace_pink',particle='things_chromeace_pink',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', rarity='rare', weaponKey='WEAPON_BOTTLE', model='things_chromeace_bottle_sliver', comp='COMPONENT_BOTTLE_CHROMEACE_SILVER',
      fx = { kill={playOn='dead',dict='things_chromeace_silver',particle='things_chromeace_silver',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', rarity='rare', weaponKey='WEAPON_BOTTLE', model='wm_baldwin_knife', comp='COMPONENT_BOTTLE_BALDWIN',
      fx = { hold={dict='handbaldwin',particle='handbaldwin',bone=57005,scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_BOTTLE', model='wm_virex_knife', comp='COMPONENT_BOTTLE_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='dead',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_BOTTLE', model='knife_bape', comp='COMPONENT_BOTTLE_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='dead',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },

    -- ═══ WEAPON_DAGGER ═══
    { id='halloween', label='Halloween', rarity='epic', weaponKey='WEAPON_DAGGER', model='lz_halloween_knife', comp='COMPONENT_DAGGER_HALLOWEEN',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit',bone=57005,scale=0.2}, kill={playOn='dead',dict='lz_halloween_fx',particle='halloween_hit',scale=1.0}, sound='lz_halloween_ovl.mp3', hud='lz_halloween_ovl' } },
    { id='halloween_pink', label='Halloween Pink', rarity='epic', weaponKey='WEAPON_DAGGER', model='lz_halloween_knife_pink', comp='COMPONENT_DAGGER_HALLOWEEN_PINK',
      fx = { hold={dict='lz_halloween_fx',particle='halloween_hit_pink',bone=57005,scale=0.2}, kill={playOn='dead',dict='lz_halloween_fx',particle='halloween_hit_pink',scale=1.0}, sound='lz_halloweenpink_ovl.mp3', hud='lz_halloweenpink_ovl' } },
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_DAGGER', model='drop_dagger_brush', comp='COMPONENT_DAGGER_BRUSH',
      fx = { hold={dict='drop_brush',particle='drop_particle_brush',bone=58870,scale=0.5}, kill={playOn='dead',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_DAGGER', model='drop_dagger_greentea', comp='COMPONENT_DAGGER_GREENTEA',
      fx = { hold={dict='drop_greentea',particle='drop_particle_greentea',bone=58870,scale=0.5}, kill={playOn='dead',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },

    -- ═══ WEAPON_MACHETE ═══
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_MACHETE', model='drop_machete_brush', comp='COMPONENT_MACHETE_BRUSH',
      fx = { kill={playOn='dead',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_MACHETE', model='drop_machete_greentea', comp='COMPONENT_MACHETE_GREENTEA',
      fx = { kill={playOn='dead',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', rarity='mythic', weaponKey='WEAPON_MACHETE', model='dfx_machete_lava', comp='COMPONENT_MACHETE_LAVA',
      fx = { kill={playOn='dead',dict='dfx_lava',particle='dfx_particle_lava',scale=1.5}, hud='effect_lava' } },
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_MACHETE', model='machette_bape', comp='COMPONENT_MACHETE_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='dead',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_MACHETE', model='wm_virex_machete', comp='COMPONENT_MACHETE_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='dead',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='chromeace_pink', label='ChromeAce Pink', rarity='rare', weaponKey='WEAPON_MACHETE', model='things_chromeace_machete_pink', comp='COMPONENT_MACHETE_CHROMEACE_PINK',
      fx = { kill={playOn='dead',dict='things_chromeace_pink',particle='things_chromeace_pink',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', rarity='rare', weaponKey='WEAPON_MACHETE', model='things_chromeace_machete_sliver', comp='COMPONENT_MACHETE_CHROMEACE_SILVER',
      fx = { kill={playOn='dead',dict='things_chromeace_silver',particle='things_chromeace_silver',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', rarity='rare', weaponKey='WEAPON_MACHETE', model='wm_baldwin_machete', comp='COMPONENT_MACHETE_BALDWIN',
      fx = { hold={dict='handbaldwin',particle='handbaldwin',bone=57005,scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },

    -- ═══ WEAPON_KNUCKLE ═══
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_KNUCKLE', model='drop_knuckle_brush', comp='COMPONENT_KNUCKLE_BRUSH',
      fx = { kill={playOn='dead',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_KNUCKLE', model='drop_knuckle_greentea', comp='COMPONENT_KNUCKLE_GREENTEA',
      fx = { kill={playOn='dead',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', rarity='mythic', weaponKey='WEAPON_KNUCKLE', model='dfx_knuckle_lava', comp='COMPONENT_KNUCKLE_LAVA',
      fx = { kill={playOn='dead',dict='dfx_lava',particle='dfx_particle_lava',scale=1.5}, hud='effect_lava' } },
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_KNUCKLE', model='knuckle_bape', comp='COMPONENT_KNUCKLE_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='dead',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_KNUCKLE', model='wm_virex_knuckle', comp='COMPONENT_KNUCKLE_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='dead',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='chromeace_pink', label='ChromeAce Pink', rarity='rare', weaponKey='WEAPON_KNUCKLE', model='things_chromeace_knuckle_pink', comp='COMPONENT_KNUCKLE_CHROMEACE_PINK',
      fx = { kill={playOn='dead',dict='things_chromeace_pink',particle='things_chromeace_pink',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', rarity='rare', weaponKey='WEAPON_KNUCKLE', model='things_chromeace_knuckle_sliver', comp='COMPONENT_KNUCKLE_CHROMEACE_SILVER',
      fx = { kill={playOn='dead',dict='things_chromeace_silver',particle='things_chromeace_silver',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', rarity='rare', weaponKey='WEAPON_KNUCKLE', model='wm_baldwin_knuckle', comp='COMPONENT_KNUCKLE_BALDWIN',
      fx = { hold={dict='handbaldwin',particle='handbaldwin',bone=57005,scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },

    -- ═══ WEAPON_REVOLVER ═══
    { id='brush', label='Brush', rarity='rare', weaponKey='WEAPON_REVOLVER', model='drop_revolver_brush', comp='COMPONENT_REVOLVER_BRUSH',
      fx = { kill={playOn='hit',dict='drop_brush',particle='drop_particle_brush',scale=1.5}, hud='effect_brush' } },
    { id='greentea', label='Green Tea', rarity='uncommon', weaponKey='WEAPON_REVOLVER', model='drop_revolver_greentea', comp='COMPONENT_REVOLVER_GREENTEA',
      fx = { kill={playOn='hit',dict='drop_greentea',particle='drop_particle_greentea',scale=1.5}, hud='effect_greentea' } },
    { id='lava', label='Lava', rarity='mythic', weaponKey='WEAPON_REVOLVER', model='dfx_revolver_lava', comp='COMPONENT_REVOLVER_LAVA',
      fx = { kill={playOn='hit',dict='dfx_lava',particle='dfx_particle_lava',scale=1.5}, hud='effect_lava' } },
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_REVOLVER', model='revolver_bape', comp='COMPONENT_REVOLVER_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='hit',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_REVOLVER', model='wm_virex_gun', comp='COMPONENT_REVOLVER_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='hit',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
    { id='chromeace_pink', label='ChromeAce Pink', rarity='rare', weaponKey='WEAPON_REVOLVER', model='things_chromeace_revolver_pink', comp='COMPONENT_REVOLVER_CHROMEACE_PINK',
      fx = { kill={playOn='hit',dict='things_chromeace_pink',particle='things_chromeace_pink',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_pink_screen' } },
    { id='chromeace_silver', label='ChromeAce Silver', rarity='rare', weaponKey='WEAPON_REVOLVER', model='things_chromeace_revolver_sliver', comp='COMPONENT_REVOLVER_CHROMEACE_SILVER',
      fx = { kill={playOn='hit',dict='things_chromeace_silver',particle='things_chromeace_silver',scale=0.2}, sound='things_chromeace_sound.mp3', hud='things_chromeace_silver_screen' } },
    { id='baldwin', label='Baldwin', rarity='rare', weaponKey='WEAPON_REVOLVER', model='wm_baldwin_gun', comp='COMPONENT_REVOLVER_BALDWIN',
      fx = { hold={dict='handbaldwin',particle='handbaldwin',bone=57005,scale=0.10}, sound='baldwin.mp3', hud='baldwin' } },

    -- ═══ WEAPON_BAT ═══
    { id='bape', label='Bape', rarity='rare', weaponKey='WEAPON_BAT', model='bat_bape', comp='COMPONENT_BAT_BAPE',
      fx = { hold={dict='withme_bape',particle='withme_bape_hfx',bone=57005,scale=0.15}, kill={playOn='dead',dict='withme_bape',particle='withme_bape_cri',scale=0.2}, sound='bapebape.mp3', hud='bapee' } },
    { id='virex', label='Virex', rarity='rare', weaponKey='WEAPON_BAT', model='wm_virex_bat', comp='COMPONENT_BAT_VIREX',
      fx = { hold={dict='wishme_virex',particle='wishme_virex',bone=57005,scale=0.2}, kill={playOn='dead',dict='wishme_virex',particle='wishme_virex',scale=1.5}, sound='virex.mp3', hud='virex' } },
}

-- ============================================================================
-- 3. HELPERS
-- ============================================================================
local allCompHashes = {}
for _, s in ipairs(SkinDB) do
    allCompHashes[GetHashKey(s.comp)] = true
end

local function findSkinEntry(query, weaponKey)
    if not query or query == '' then return nil end
    local q = string.lower(query)
    for _, s in ipairs(SkinDB) do
        if s.weaponKey == weaponKey and string.lower(s.id) == q then return s end
    end
    for _, s in ipairs(SkinDB) do
        if s.weaponKey == weaponKey and string.find(string.lower(s.label), q, 1, true) then return s end
    end
    for _, s in ipairs(SkinDB) do
        if string.lower(s.id) == q then return s end
    end
    return nil
end

local function removeAllComps(ped, wHash)
    for ch in pairs(allCompHashes) do
        if origHas(ped, wHash, ch) then origRemove(ped, wHash, ch) end
    end
end

-- ============================================================================
-- 4. ANTI-DETECT HOOKS
-- ============================================================================
HasPedGotWeaponComponent = function(ped, weapon, component)
    if activeSkin and ped == PlayerPedId() then
        if component == GetHashKey(activeSkin.comp) then return true end
    end
    return origHas(ped, weapon, component)
end

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if activeSkin and ped == PlayerPedId() then
        if component == GetHashKey(activeSkin.comp) then return end
    end
    return origRemove(ped, weapon, component)
end

local origTSE = TriggerServerEvent
TriggerServerEvent = function(eventName, ...)
    if activeSkin and type(eventName) == 'string' then
        local lo = string.lower(eventName)
        if lo:find('skinshowcase') or lo:find('weaponskin') then
            if lo:find('report') or lo:find('detect') or lo:find('kick') or lo:find('ban')
                or lo:find('cheat') or lo:find('guard') or lo:find('check') or lo:find('verify')
                or lo:find('log') or lo:find('anticheat') or lo:find('security') then
                return
            end
        end
    end
    return origTSE(eventName, ...)
end

-- ============================================================================
-- 5. PTFX ENGINE
-- ============================================================================
local function loadPtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local dl = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < dl do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function playHoldFx(ped, hold)
    if not hold or not hold.dict then return end
    if not loadPtfx(hold.dict) then return end
    local bi = GetPedBoneIndex(ped, hold.bone or 57005)
    if bi == -1 then return end
    UseParticleFxAsset(hold.dict)
    UseParticleFxAssetNextCall(hold.dict)
    StartParticleFxNonLoopedOnPedBone(hold.particle, ped, 0.12, 0.0, 0.0, 0.0, 0.0, 65.0, bi, hold.scale or 0.2, false, false, false)
end

local function playKillFx(victim, kill)
    if not kill or not kill.dict then return end
    if not loadPtfx(kill.dict) then return end
    local pos = GetEntityCoords(victim) + vector3(0.0, 0.0, 0.65)
    UseParticleFxAsset(kill.dict)
    UseParticleFxAssetNextCall(kill.dict)
    StartParticleFxNonLoopedAtCoord(kill.particle, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, kill.scale or 1.0, false, false, false)
    UseParticleFxAsset(kill.dict)
    UseParticleFxAssetNextCall(kill.dict)
    StartNetworkedParticleFxNonLoopedAtCoord(kill.particle, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, kill.scale or 1.0, false, false, false)
end

local function playHUD(hudName)
    if not hudName then return end
    pcall(function() SendNUIMessage({ action='SHOW_SCREEN_EFFECT', image=hudName, time=3000 }) end)
end

local function playSound(soundFile)
    if not soundFile then return end
    pcall(function() SendNUIMessage({ action='PLAY_SOUND', sound=soundFile, volume=0.5 }) end)
end

-- ============================================================================
-- 6. APPLY / REMOVE
-- ============================================================================
local function applySkin(entry)
    local ped = PlayerPedId()
    local cur = GetSelectedPedWeapon(ped)
    if cur == GetHashKey('WEAPON_UNARMED') or cur == 0 then return false end
    GiveWeaponComponentToPed(ped, cur, GetHashKey(entry.comp))
    activeWeaponHash = cur
    return true
end

local function removeSkin()
    if activeSkin and activeWeaponHash then
        origRemove(PlayerPedId(), activeWeaponHash, GetHashKey(activeSkin.comp))
    end
    activeSkin = nil
    activeWeaponHash = nil
    handFxRunning = false
    autoEquipRunning = false
end

-- ============================================================================
-- 7. AUTO-EQUIP LOOP
-- ============================================================================
local function startAutoEquip()
    if autoEquipRunning then return end
    autoEquipRunning = true
    CreateThread(function()
        while autoEquipRunning and activeSkin do
            local ped = PlayerPedId()
            local cur = GetSelectedPedWeapon(ped)
            if cur ~= GetHashKey('WEAPON_UNARMED') and cur ~= 0 and not IsEntityDead(ped) then
                local wKey = getWeaponKey(cur)
                if wKey and wKey == activeSkin.weaponKey then
                    local compHash = GetHashKey(activeSkin.comp)
                    if not origHas(ped, cur, compHash) then
                        GiveWeaponComponentToPed(ped, cur, compHash)
                    end
                    activeWeaponHash = cur
                end
            end
            Wait(200)
        end
        autoEquipRunning = false
    end)
end

-- ============================================================================
-- 8. HAND FX LOOP
-- ============================================================================
local function startHandFx()
    if handFxRunning then return end
    handFxRunning = true
    CreateThread(function()
        while handFxRunning and activeSkin do
            local ped = PlayerPedId()
            local cur = GetSelectedPedWeapon(ped)
            if cur ~= GetHashKey('WEAPON_UNARMED') and cur ~= 0 and not IsEntityDead(ped) then
                if activeSkin.fx and activeSkin.fx.hold then
                    playHoldFx(ped, activeSkin.fx.hold)
                end
            end
            Wait(800)
        end
        handFxRunning = false
    end)
end

-- ============================================================================
-- 9. KILL DETECT
-- ============================================================================
local function registerDmg()
    if dmgRegistered then return end
    dmgRegistered = true
    AddEventHandler('gameEventTriggered', function(ev, data)
        if not activeSkin or ev ~= 'CEventNetworkEntityDamage' then return end
        local victim, attacker = data[1], data[2]
        local fatal = (data[4] == 1 or data[6] == 1)
        local me = PlayerPedId()
        if not victim or victim == 0 or victim == me or attacker ~= me then return end

        local now = GetGameTimer()
        if now - lastKillTime < 2000 then return end

        local killFx = activeSkin.fx and activeSkin.fx.kill
        if not killFx then return end

        local isDead = fatal or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0

        local shouldPlay = false
        if killFx.playOn == 'hit' then shouldPlay = true
        elseif killFx.playOn == 'dead' then shouldPlay = isDead
        elseif killFx.playOn == 'headshot' then shouldPlay = isDead
        end

        if shouldPlay then
            lastKillTime = now
            playKillFx(victim, killFx)
            if activeSkin.fx then
                playHUD(activeSkin.fx.hud)
                playSound(activeSkin.fx.sound)
            end
        end
    end)
end

-- ============================================================================
-- 10. COMMAND: /home [skinname] | /home off | /home
-- ============================================================================
RegisterCommand('home', function(_, args)
    local ped = PlayerPedId()
    local cur = GetSelectedPedWeapon(ped)
    local wKey = getWeaponKey(cur)
    local input = args[1]

    if not input or input == '' then
        print("^2============ [W-SKINSHOWCASE SKINS] ============^7")
        local grouped = {}
        for _, s in ipairs(SkinDB) do
            if not grouped[s.weaponKey] then grouped[s.weaponKey] = {} end
            grouped[s.weaponKey][#grouped[s.weaponKey]+1] = s
        end
        local order = {'WEAPON_POOLCUE','WEAPON_KNIFE','WEAPON_BOTTLE','WEAPON_DAGGER','WEAPON_MACHETE','WEAPON_KNUCKLE','WEAPON_REVOLVER','WEAPON_BAT'}
        for _, wk in ipairs(order) do
            if grouped[wk] then
                print(("^3--- %s ---^7"):format(wk))
                for _, s in ipairs(grouped[wk]) do
                    local eq = (activeSkin and activeSkin.comp == s.comp) and " ^2<< EQUIPPED^7" or ""
                    print(("  /home ^6%s^7 — %s [%s]%s"):format(s.id, s.label, s.rarity, eq))
                end
            end
        end
        print("^2==================================================^7")
        print("^3[วิธีใช้] /home [id] | /home off^7")
        return
    end

    local lo = string.lower(input)
    if lo == 'off' or lo == 'default' or lo == 'remove' or lo == '0' then
        removeSkin()
        if cur ~= GetHashKey('WEAPON_UNARMED') and cur ~= 0 then
            removeAllComps(ped, cur)
        end
        print("^1[W-SKIN]^7 ถอดสกินเรียบร้อย")
        return
    end

    if not wKey then
        print("^1[W-SKIN]^7 ถืออาวุธที่รองรับก่อน (poolcue/knife/bottle/dagger/machete/knuckle/revolver/bat + ทุก variant)")
        return
    end

    local entry = findSkinEntry(input, wKey)
    if not entry then
        print(("^1[W-SKIN]^7 ไม่พบสกิน '%s' สำหรับ %s — พิมพ์ /home ดูรายชื่อ"):format(input, wKey))
        return
    end

    removeSkin()
    removeAllComps(ped, cur)

    activeSkin = entry
    local ok = applySkin(entry)
    if ok then
        print(("^2[W-SKIN]^7 ใส่สกิน ^6%s^7 (%s) [%s] สำเร็จ!"):format(entry.id, entry.label, entry.rarity))
    else
        print(("^2[W-SKIN]^7 บันทึก ^6%s^7 — ควักอาวุธมาสกินจะติดทันที"):format(entry.id))
    end

    startAutoEquip()
    startHandFx()
    registerDmg()
end, false)

print(("^2[W-SKIN]^7 พร้อมใช้งาน! สกินทั้งหมด %d ตัว | รองรับทุกไม้ variant ในเซิฟ"):format(#SkinDB))
