-- ============================================================================
-- WEAPON SKIN — ดึงสกินจาก Config['WEAPON_SKIN'] | เอฟเฟคมือ+ตีตาย hardcode
-- /home <skinname> = ใส่สกิน | /homeoff = ถอด | /homelist = ดูทั้งหมด
-- รองรับ: POOLCUE + BOTTLE (รวม knife/dagger/machete/knuckle)
-- ============================================================================

local SKIN_DB = {}
local equippedSkin = nil
local equippedHash = nil
local equippedOnWeapon = nil
local autoEquipActive = false
local handFxActive = false
local damageRegistered = false
local lastEffectTime = 0
local currentProp = nil
local currentPropModel = nil

-- ============================================================================
-- WEAPON HASHES — poolcue + bottle (รวม knife/dagger/machete/knuckle)
-- ============================================================================
local POOLCUE_HASHES = {}
local BOTTLE_HASHES = {}
local ALL_HASHES = {}

for _, name in ipairs({
    'WEAPON_POOLCUE','WEAPON_POOLCUE_0','WEAPON_POOLCUE_1','WEAPON_POOLCUE_2',
    'WEAPON_POOLCUE_3','WEAPON_POOLCUE_4','WEAPON_POOLCUE_5',
    'WEAPON_POOLCUE0','WEAPON_POOLCUE1','WEAPON_POOLCUE2','WEAPON_POOLCUE3',
    'WEAPON_POOLCUE4','WEAPON_POOLCUE5','WEAPON_POOLCUE_RENT',
    'WEAPON_POOLCUE14DAY','WEAPON_POOLCUEWAR',
}) do local h = GetHashKey(name); POOLCUE_HASHES[h] = true; ALL_HASHES[h] = true end

for _, name in ipairs({
    'WEAPON_BOTTLE','WEAPON_BOTTLE_0','WEAPON_BOTTLE_1','WEAPON_BOTTLE_2',
    'WEAPON_BOTTLE_3','WEAPON_BOTTLE_4','WEAPON_BOTTLE_5',
    'WEAPON_BOTTLE0','WEAPON_BOTTLE1','WEAPON_BOTTLE2','WEAPON_BOTTLE3',
    'WEAPON_BOTTLE4','WEAPON_BOTTLE5',
    'WEAPON_KNIFE','WEAPON_KNIFE_1','WEAPON_KNIFE_2','WEAPON_KNIFE_3','WEAPON_KNIFE_4',
    'WEAPON_DAGGER','WEAPON_SWITCHBLADE',
    'WEAPON_MACHETE','WEAPON_MACHETE_0','WEAPON_MACHETE_1','WEAPON_MACHETE_2','WEAPON_MACHETE_3',
    'WEAPON_MACHETTE_0','WEAPON_MACHETTE_1','WEAPON_MACHETTE_2','WEAPON_MACHETTE_3',
    'WEAPON_KNUCKLEDUSTER','WEAPON_KNUCKLE',
    'WEAPON_KNUCKLE_0','WEAPON_KNUCKLE_1','WEAPON_KNUCKLE_2','WEAPON_KNUCKLE_3',
}) do local h = GetHashKey(name); BOTTLE_HASHES[h] = true; ALL_HASHES[h] = true end

local function GetWeaponCat(wHash)
    if POOLCUE_HASHES[wHash] then return 'poolcue' end
    if BOTTLE_HASHES[wHash] then return 'bottle' end
    return nil
end

-- ============================================================================
-- HARDCODED EFFECTS — เอฟเฟคมือ + ตีตาย + screen + audio
-- ============================================================================
local SKIN_FX = {
    ['sharkz_poolcue_starhero']       = { hand = { dict='sharkz_starhero_set', eff='sharkz_starhero_effect', scale=0.3 }, dead = { dict='sharkz_starhero_set', eff='sharkz_starhero_hit', scale=1.5 }, screen='hero.png', audio='hero.mp3' },
    ['sharkz_bottle_starhero']        = { hand = { dict='sharkz_starhero_set', eff='sharkz_starhero_effect', scale=0.3 }, dead = { dict='sharkz_starhero_set', eff='sharkz_starhero_hit', scale=1.5 }, screen='hero.png', audio='hero.mp3' },
    ['sharkz_poolcue_8bit']           = { hand = { dict='sharkz_8bit_set', eff='sharkz_effect_8bit', scale=0.3 }, dead = { dict='sharkz_8bit_set', eff='sharkz_hit_8bit', scale=1.5 }, screen='8bit.png', audio='8bit.mp3' },
    ['sharkz_bottle_8bit']            = { hand = { dict='sharkz_8bit_set', eff='sharkz_effect_8bit', scale=0.3 }, dead = { dict='sharkz_8bit_set', eff='sharkz_hit_8bit', scale=1.5 }, screen='8bit.png', audio='8bit.mp3' },
    ['wishme_momo_poolcue']           = { hand = { dict='whitme_momo_efx', eff='scr_whitmemomo_beast_vanish', scale=0.1 }, dead = { dict='whitme_momo_efx', eff='scr_withme_firework_starburst', scale=1.5 }, screen='momo.png', audio='momo.mp3' },
    ['wishme_momo_1knife']            = { hand = { dict='whitme_momo_efx', eff='scr_whitmemomo_beast_vanish', scale=0.1 }, dead = { dict='whitme_momo_efx', eff='scr_withme_firework_starburst', scale=1.5 }, screen='momo.png', audio='momo.mp3' },
    ['rb_swagblack_poolcue']          = { hand = { dict='gb_efx_swag', eff='gb_efx_swaghand_1', scale=0.3 }, dead = { dict='gb_efx_swag', eff='gb_efx_swag_1', scale=0.5 }, screen='swag.png', audio='swag.mp3' },
    ['rb_swagblack_knife']            = { hand = { dict='gb_efx_swag', eff='gb_efx_swaghand_1', scale=0.3 }, dead = { dict='gb_efx_swag', eff='gb_efx_swag_1', scale=0.5 }, screen='swag.png', audio='swag.mp3' },
    ['rb_swagwhite_poolcue']          = { hand = { dict='gb_efx_swag', eff='gb_efx_swaghand_1', scale=0.3 }, dead = { dict='gb_efx_swag', eff='gb_efx_swag_1', scale=0.5 }, screen='swag.png', audio='swag.mp3' },
    ['rb_swagwhite_knife']            = { hand = { dict='gb_efx_swag', eff='gb_efx_swaghand_1', scale=0.3 }, dead = { dict='gb_efx_swag', eff='gb_efx_swag_1', scale=0.5 }, screen='swag.png', audio='swag.mp3' },
    ['sharkz_poolcue_phx_firestorm']  = { hand = { dict='sharkz_phoenix_set', eff='sharkz_phoenix_effect', scale=0.8 }, dead = { dict='sharkz_phoenix_set', eff='sharkz_phoenix_set', scale=1.0 }, screen='phoenix.png', audio='phoenix.mp3' },
    ['sharkz_knife_phx_firestorm']    = { hand = { dict='sharkz_phoenix_set', eff='sharkz_phoenix_effect', scale=0.8 }, dead = { dict='sharkz_phoenix_set', eff='sharkz_phoenix_set', scale=1.0 }, screen='phoenix.png', audio='phoenix.mp3' },
    ['x_me_poolcue_anubis']           = { hand = { dict='eff_anubis2', eff='eff_anubis2', scale=0.5 }, dead = { dict='eff_anubis', eff='eff_anubis', scale=0.5 }, screen='anubis.png', audio='anubis.mp3' },
    ['x_me_bottle_anubis']            = { hand = { dict='eff_anubis2', eff='eff_anubis2', scale=0.5 }, dead = { dict='eff_anubis', eff='eff_anubis', scale=0.5 }, screen='anubis.png', audio='anubis.mp3' },
    ['x_me_dagger_anubis']            = { hand = { dict='eff_anubis2', eff='eff_anubis2', scale=0.5 }, dead = { dict='eff_anubis', eff='eff_anubis', scale=0.5 }, screen='anubis.png', audio='anubis.mp3' },
    ['x_me_knife_anubis']             = { hand = { dict='eff_anubis2', eff='eff_anubis2', scale=0.5 }, dead = { dict='eff_anubis', eff='eff_anubis', scale=0.5 }, screen='anubis.png', audio='anubis.mp3' },
    ['w_me_poolcueks_dds']            = { hand = { dict='dds_ksn1v1_po', eff='dds_ksn1hxnd_po', scale=0.5 }, dead = { dict='dds_ksn1v1_po', eff='dds_ksn1v1_po', scale=0.2 }, screen='kitsune.png', audio='kitsune.mp3' },
    ['w_me_daggerks_dds']             = { hand = { dict='dds_ksn1v1_po', eff='dds_ksn1hxnd_po', scale=0.5 }, dead = { dict='dds_ksn1v1_po', eff='dds_ksn1v1_po', scale=0.2 }, screen='kitsune.png', audio='kitsune.mp3' },
    ['wm_elys_pool']                  = { hand = { dict='wm_ef_elys', eff='wm_ef_elys_hfx', scale=0.5 }, dead = { dict='wm_ef_elys', eff='wm_ef_elys', scale=0.5 }, screen='elys.png', audio='elys.mp3' },
    ['wm_elys_knife']                 = { hand = { dict='wm_ef_elys', eff='wm_ef_elys_hfx', scale=0.5 }, dead = { dict='wm_ef_elys', eff='wm_ef_elys', scale=0.5 }, screen='elys.png', audio='elys.mp3' },
    ['w_me_poolcue_eden']             = { hand = { dict='eden', eff='eden', scale=0.8 }, dead = { dict='eden', eff='eden', scale=2.0 }, screen='eden.png', audio='eden.mp3' },
    ['w_me_bottle_eden']              = { hand = { dict='eden', eff='eden', scale=0.8 }, dead = { dict='eden', eff='eden', scale=2.0 }, screen='eden.png', audio='eden.mp3' },
    ['sharkz_poolcue_darkwolf']       = { hand = { dict='sharkz_darkwolf_set', eff='sharkz_darkwolf_effect', scale=0.1 }, dead = { dict='sharkz_darkwolf_set', eff='sharkz_darkwolf_set', scale=1.0 }, screen='darkwolf.png', audio='darkwolf.mp3' },
    ['sharkz_knife_darkwolf']         = { hand = { dict='sharkz_darkwolf_set', eff='sharkz_darkwolf_effect', scale=0.1 }, dead = { dict='sharkz_darkwolf_set', eff='sharkz_darkwolf_set', scale=1.0 }, screen='darkwolf.png', audio='darkwolf.mp3' },
    ['sharkz_poolcue_zap']            = { hand = { dict='sharkz_zap_set', eff='sharkz_zap_effect', scale=0.8 }, dead = { dict='sharkz_zap_set', eff='sharkz_zap_set', scale=1.2 }, screen='zap.png', audio='zap.mp3' },
    ['sharkz_bottle_zap']             = { hand = { dict='sharkz_zap_set', eff='sharkz_zap_effect', scale=0.8 }, dead = { dict='sharkz_zap_set', eff='sharkz_zap_set', scale=1.2 }, screen='zap.png', audio='zap.mp3' },
    ['w_me_poolcueredfire']           = { hand = { dict='ar_effect', eff='redfire', scale=1.0 }, dead = { dict='ptfx_fireredsmoke', eff='ptfx_fireredsmoke', scale=0.5 }, screen='vdframefire.png', audio='vdfirered.mp3' },
    ['w_me_bottleredfire']            = { hand = { dict='ar_effect', eff='redfire', scale=1.0 }, dead = { dict='ptfx_fireredsmoke', eff='ptfx_fireredsmoke', scale=0.5 }, screen='vdframefire.png', audio='vdfirered.mp3' },
    ['w_me_poolcue_stl_green']        = { hand = { dict='ar_effect', eff='effect_energygreen', scale=0.5 }, dead = { dict='stl_green', eff='stl_green', scale=0.15 }, screen='green.png', audio='green.mp3' },
    ['w_me_bottle_stl_green']         = { hand = { dict='ar_effect', eff='effect_energygreen', scale=0.5 }, dead = { dict='stl_green', eff='stl_green', scale=0.15 }, screen='green.png', audio='green.mp3' },
    ['reawx_pool_fantacy']            = { hand = { dict='reaxw_effect_fantasy', eff='trail', scale=1.0 }, dead = { dict='reawx_particle_fantasy', eff='reawx_particle_fantasy', scale=2.0 }, screen='ZEPHYRON.png', audio='ZEPHYRON.mp3' },
    ['reawx_bottle_fantacy']          = { hand = { dict='reaxw_effect_fantasy', eff='trail', scale=1.0 }, dead = { dict='reawx_particle_fantasy', eff='reawx_particle_fantasy', scale=2.0 }, screen='ZEPHYRON.png', audio='ZEPHYRON.mp3' },
    ['bbg_wp26_poolcue']              = { hand = { dict='bbg_wp26_1', eff='bbg_effect_sleepy_star', scale=0.2 }, dead = { dict='bbg_wp26_1', eff='bbg_effect_sleepy', scale=3.5 }, screen='pinkpig.png', audio='pinkpig.ogg' },
    ['bbg_wp26_bottle']               = { hand = { dict='bbg_wp26_1', eff='bbg_effect_sleepy_star', scale=0.2 }, dead = { dict='bbg_wp26_1', eff='bbg_effect_sleepy', scale=3.5 }, screen='pinkpig.png', audio='pinkpig.ogg' },
    ['wishme_poolcue_chromium']       = { hand = { dict='weapon_wishme', eff='wishme', scale=1.0 }, dead = { dict='weapon_wishme', eff='wishme', scale=1.1 }, screen='wishme_kill.png', audio='wishme_kill.mp3' },
    ['bbg_wp28_poolcue']              = { hand = { dict='ar_bbg', eff='underthesea_bubble', scale=0.3 }, dead = { dict='ar_bbg', eff='underthesea_kill', scale=0.4 }, screen='sea.png', audio='sea.ogg' },
    ['bbg_wp28_bottle']               = { hand = { dict='ar_bbg', eff='underthesea_bubble', scale=0.3 }, dead = { dict='ar_bbg', eff='underthesea_kill', scale=0.4 }, screen='sea.png', audio='sea.ogg' },
    ['sharkz_poolcue_deepblue']       = { hand = { dict='sharkz_deepblue_set', eff='shark_deepblue_effect', scale=0.2 }, dead = { dict='sharkz_deepblue_set', eff='sharkz_deepblue_set', scale=0.6 }, screen='deepblue.png', audio='deepblue.mp3' },
    ['sharkz_bottle_deepblue']        = { hand = { dict='sharkz_deepblue_set', eff='shark_deepblue_effect', scale=0.2 }, dead = { dict='sharkz_deepblue_set', eff='sharkz_deepblue_set', scale=0.6 }, screen='deepblue.png', audio='deepblue.mp3' },
    ['sharkz_poolcue_poker']          = { hand = { dict='sharkz_poker_set', eff='sharkz_effect_poker', scale=0.2 }, dead = { dict='sharkz_poker_set', eff='sharkz_hit_poker', scale=1.0 }, screen='poker.png', audio='poker.ogg' },
    ['sharkz_bottle_poker']           = { hand = { dict='sharkz_poker_set', eff='sharkz_effect_poker', scale=0.2 }, dead = { dict='sharkz_poker_set', eff='sharkz_hit_poker', scale=1.0 }, screen='poker.png', audio='poker.ogg' },
    ['sharkz_poolcue_greendragon']    = { hand = { dict='sharkz_gdragon_set', eff='sharkz_effect_gdragon', scale=1.0 }, dead = { dict='sharkz_gdragon_set', eff='sharkz_hit_gdragon', scale=0.7 }, screen='gd.png', audio='gd.mp3' },
    ['sharkz_dagger_greendragon']     = { hand = { dict='sharkz_gdragon_set', eff='sharkz_effect_gdragon', scale=1.0 }, dead = { dict='sharkz_gdragon_set', eff='sharkz_hit_gdragon', scale=0.7 }, screen='gd.png', audio='gd.mp3' },
    ['sharkz_poolcue_halloween']      = { hand = { dict='sharkz_blood_effect', eff='sharkz_blood_effect', scale=1.0 }, dead = { dict='sharkz_halloween_set', eff='sharkz_halloween_set', scale=3.0 }, screen='halloween.png', audio='halloween.mp3' },
    ['sharkz_bottle_halloween']       = { hand = { dict='sharkz_blood_effect', eff='sharkz_blood_effect', scale=1.0 }, dead = { dict='sharkz_halloween_set', eff='sharkz_halloween_set', scale=3.0 }, screen='halloween.png', audio='halloween.mp3' },
    ['sharkz_poolcue_white_wolf']     = { hand = { dict='sharkz_whitewolf_set', eff='sharkz_effect_whitewolf', scale=0.3 }, dead = { dict='sharkz_whitewolf_set', eff='sharkz_hit_whitewolf', scale=3.0 }, screen='wwolf.png', audio='wwolf.mp3' },
    ['sharkz_bottle_white_wolf']      = { hand = { dict='sharkz_whitewolf_set', eff='sharkz_effect_whitewolf', scale=0.3 }, dead = { dict='sharkz_whitewolf_set', eff='sharkz_hit_whitewolf', scale=3.0 }, screen='wwolf.png', audio='wwolf.mp3' },
    ['sharkz_poolcue_white_tiger']    = { hand = { dict='sharkz_effect_whitetiger', eff='sharkz_effect_whitetiger', scale=1.0 }, dead = { dict='sharkz_whitetiger_set', eff='sharkz_whitetiger_set', scale=0.3 }, screen='wtg.png', audio='wtg.mp3' },
    ['sharkz_bottle_white_tiger']     = { hand = { dict='sharkz_effect_whitetiger', eff='sharkz_effect_whitetiger', scale=1.0 }, dead = { dict='sharkz_whitetiger_set', eff='sharkz_whitetiger_set', scale=0.3 }, screen='wtg.png', audio='wtg.mp3' },
    ['gb_ponypink_poolcue']           = { hand = { dict='gb_ponybun_efx', eff='gb_ponybun_efx_5', scale=0.6 }, dead = { dict='gb_ponybun_efx', eff='gb_ponybun_efx_1', scale=0.2 }, screen='pony.png', audio='pony.mp3' },
    ['gb_ponyyell_poolcue']           = { hand = { dict='gb_ponybun_efx', eff='gb_ponybun_efx_5', scale=0.6 }, dead = { dict='gb_ponybun_efx', eff='gb_ponybun_efx_1', scale=0.2 }, screen='pony.png', audio='pony.mp3' },
    ['gb_ponypur_bottle']             = { hand = { dict='gb_ponybun_efx', eff='gb_ponybun_efx_5', scale=0.6 }, dead = { dict='gb_ponybun_efx', eff='gb_ponybun_efx_1', scale=0.2 }, screen='pony.png', audio='pony.mp3' },
    ['gb_bearx_poolcue_white']        = { hand = { dict='effect_bearx_1', eff='muz_clown', scale=0.4 }, dead = { dict='Prticle_bearx_1', eff='scr_exp_clown', scale=0.3 }, screen='brx.png', audio='brx.mp3' },
    ['gb_bearx_poolcue_black']        = { hand = { dict='effect_bearx_1', eff='muz_clown', scale=0.4 }, dead = { dict='Prticle_bearx_1', eff='scr_exp_clown', scale=0.3 }, screen='brx.png', audio='brx.mp3' },
    ['gb_bearx_bottle_white']         = { hand = { dict='effect_bearx_1', eff='muz_clown', scale=0.4 }, dead = { dict='Prticle_bearx_1', eff='scr_exp_clown', scale=0.3 }, screen='brx.png', audio='brx.mp3' },
    ['gb_bearx_bottle_black']         = { hand = { dict='effect_bearx_1', eff='muz_clown', scale=0.4 }, dead = { dict='Prticle_bearx_1', eff='scr_exp_clown', scale=0.3 }, screen='brx.png', audio='brx.mp3' },
    ['gb_neko_poolcue_white']         = { hand = { dict='girlbossefx_nekoblack', eff='girlbossefx_nekoblack', scale=0.3 }, dead = { dict='girlbossefx_nekowhite', eff='girlbossefx_nekowhite', scale=3.0 }, screen='nekowhite.png', audio='nekosound.mp3' },
    ['gb_neko_poolcue_black']         = { hand = { dict='girlbossefx_nekoblack', eff='girlbossefx_nekoblack', scale=0.3 }, dead = { dict='girlbossefx_nekoblack', eff='girlbossefx_nekoblack', scale=3.0 }, screen='nekoblack.png', audio='nekosound.mp3' },
    ['gb_neko_bottle_white']          = { hand = { dict='girlbossefx_nekoblack', eff='girlbossefx_nekoblack', scale=0.3 }, dead = { dict='girlbossefx_nekowhite', eff='girlbossefx_nekowhite', scale=3.0 }, screen='nekowhite.png', audio='nekosound.mp3' },
    ['gb_neko_bottle_black']          = { hand = { dict='girlbossefx_nekoblack', eff='girlbossefx_nekoblack', scale=0.3 }, dead = { dict='girlbossefx_nekoblack', eff='girlbossefx_nekoblack', scale=3.0 }, screen='nekoblack.png', audio='nekosound.mp3' },
    ['coolkids_duckysummer_poolcue']  = { hand = { dict='ar_coolkids', eff='efxcoolkids_duckysummer_star', scale=0.1 }, dead = { dict='ar_coolkids', eff='efxcoolkids_duckysummer_star', scale=0.7 }, screen='dsumer.png', audio='dsumer.mp3' },
    ['coolkids_duckysummer_bottle']   = { hand = { dict='ar_coolkids', eff='efxcoolkids_duckysummer_star', scale=0.1 }, dead = { dict='ar_coolkids', eff='efxcoolkids_duckysummer_star', scale=0.7 }, screen='dsumer.png', audio='dsumer.mp3' },
    ['coolkids_sanrio_poolcue']       = { hand = { dict='ar_coolkids', eff='efxcoolkids_sanrio_halloween_prop', scale=0.1 }, dead = { dict='ar_coolkids', eff='efxcoolkids_sanrio_halloween_prop', scale=1.5 }, screen='csro.png', audio='csro.mp3' },
    ['coolkids_sanrio_bottle']        = { hand = { dict='ar_coolkids', eff='efxcoolkids_sanrio_halloween_prop', scale=0.1 }, dead = { dict='ar_coolkids', eff='efxcoolkids_sanrio_halloween_prop', scale=1.5 }, screen='csro.png', audio='csro.mp3' },
    ['coolkids_babythree_poolcue']    = { dead = { dict='ar_coolkids', eff='coolkids_efx_01_prop', scale=1.0 }, screen='cbbt.png', audio='cbbt.mp3' },
    ['coolkids_babythree_bottle']     = { dead = { dict='ar_coolkids', eff='coolkids_efx_01_prop', scale=1.0 }, screen='cbbt.png', audio='cbbt.mp3' },
    ['coolkids_Sweet_poolcue']        = { dead = { dict='ar_coolkids', eff='efxcoolkids_sweet', scale=3.0 }, screen='SWEET_screen.png', audio='sound_SWEET.mp3' },
    ['coolkids_Sweet_bottle']         = { dead = { dict='ar_coolkids', eff='efxcoolkids_sweet', scale=3.0 }, screen='SWEET_screen.png', audio='sound_SWEET.mp3' },
    ['bbg_wp23_poolcue']              = { hand = { dict='ar_bbg', eff='heartspawn', scale=0.1 }, dead = { dict='ar_bbg', eff='cupidlover', scale=0.2 }, screen='v26.png', audio='v26.mp3' },
    ['bbg_wp23_bottle']               = { hand = { dict='ar_bbg', eff='heartspawn', scale=0.1 }, dead = { dict='ar_bbg', eff='cupidlover', scale=0.2 }, screen='v26.png', audio='v26.mp3' },
    ['w_me_poolcue_dds']              = { hand = { dict='deands_efx_lv', eff='deands_efx_lv11p', scale=1.5 }, dead = { dict='deands_efx_lv', eff='exp_air_deandesignstudio', scale=1.5 }, screen='lva.png', audio='lva.mp3' },
    ['w_me_bottle_dds']               = { hand = { dict='deands_efx_lv', eff='deands_efx_lv11p', scale=1.5 }, dead = { dict='deands_efx_lv', eff='exp_air_deandesignstudio', scale=1.5 }, screen='lva.png', audio='lva.mp3' },
    ['wm_baldwin_pool']               = { hand = { dict='handbaldwin', eff='handbaldwin', scale=0.8 }, dead = { dict='fire_baldwinkill', eff='fire_baldwinkill', scale=1.0 }, audio='fxbaldwin.mp3' },
    ['wm_baldwin_knife']              = { hand = { dict='handbaldwin', eff='handbaldwin', scale=0.1 }, dead = { dict='fire_baldwinkill', eff='fire_baldwinkill', scale=1.0 }, audio='fxbaldwin.mp3' },
    ['meow_buer_pool']                = { hand = { dict='buerfx', eff='buerfx', scale=0.8 }, dead = { dict='buerfx', eff='scr_clown_bul', scale=1.2 }, screen='meow_frame_buer.png', audio='fxbaldwin.mp3' },
    ['wm_virex_pool']                 = { hand = { dict='wishme_virex', eff='wishme_virex', scale=0.06 } },
    ['wm_virex_knife']                = { hand = { dict='wishme_virex', eff='wishme_virex', scale=0.05 } },
    ['lazy_cutestar_poolcue']         = { dead = { dict='ar_effect', eff='cutestar', scale=1.2 }, screen='cutestar.png', audio='cutestar.mp3' },
    ['lazy_cutestar_knife']           = { dead = { dict='ar_effect', eff='cutestar', scale=1.2 }, screen='cutestar.png', audio='cutestar.mp3' },
    ['lazy_fox_poolcue']              = { dead = { dict='ar_effect', eff='foxfx', scale=0.25 }, screen='lazyfox.png', audio='lazyfox.mp3' },
    ['lazy_fox_knife']                = { dead = { dict='ar_effect', eff='foxfx', scale=0.25 }, screen='lazyfox.png', audio='lazyfox.mp3' },
    ['lazy_badbunnie_poolcue']        = { dead = { dict='lazy_badbunnie', eff='lazy_badbunnie', scale=0.08 }, screen='badbunny.png', audio='badbunny.mp3' },
    ['lazy_badbunnie_knife']          = { dead = { dict='lazy_badbunnie', eff='lazy_badbunnie', scale=0.08 }, screen='badbunny.png', audio='badbunny.mp3' },
    ['things_freebunny_poolcue']      = { dead = { dict='things_freeskinbunny', eff='things_freeskinbunny', scale=1.2 }, screen='free_bunny.png', audio='free_bunny.mp3' },
    ['devilcute_poolcue']             = { dead = { dict='devilcute_hit_effects', eff='magicwarp', scale=0.4 }, screen='devilcute.png', audio='devilcute.mp3' },
    ['devilcute_bottle']              = { dead = { dict='devilcute_hit_effects', eff='magicwarp', scale=0.4 }, screen='devilcute.png', audio='devilcute.mp3' },
    ['w_me_zyndear_toothless_poolcue_white'] = { hand = { dict='ar_effect', eff='killtoothlesswhite', scale=0.1 }, dead = { dict='ar_effect', eff='killtoothlesswhite', scale=0.4 }, audio='jingle.mp3' },
    ['w_me_zyndear_toothless_bottle_white']  = { hand = { dict='ar_effect', eff='killtoothlesswhite', scale=0.1 }, dead = { dict='ar_effect', eff='killtoothlesswhite', scale=0.4 }, audio='jingle.mp3' },
    ['ohmmiwars_poolcue_squid']       = { dead = { dict='daffy_squidgame', eff='daffy_squidgame', scale=3.0 }, screen='squidgame.png', audio='squidgame.mp3' },
    ['ohmmiwars_bottle_squid']        = { dead = { dict='daffy_squidgame', eff='daffy_squidgame', scale=3.0 }, screen='squidgame.png', audio='squidgame.mp3' },
    ['ohmmiwars_poolcue_melody']      = { dead = { dict='ar_daffy', eff='daffy_melody', scale=3.0 }, screen='melody.png', audio='melody.mp3' },
    ['ohmmiwars_bottle_melody']       = { dead = { dict='ar_daffy', eff='daffy_melody', scale=3.0 }, screen='melody.png', audio='melody.mp3' },
    ['ohmmiwars_poolcue_wednesday']   = { dead = { dict='ar_daffy', eff='daffy_wd', scale=3.0 }, screen='wd.png', audio='wd.mp3' },
    ['ohmmiwars_bottle_wednesday']    = { dead = { dict='ar_daffy', eff='daffy_wd', scale=3.0 }, screen='wd.png', audio='wd.mp3' },
    ['COMPONENT_POOL_CRYBUNNY']       = { dead = { dict='zyndea_wepfx_crybunny_fx', eff='zyndea_wepfx_crybunny_fx', scale=3.0 }, screen='crybunnykill.png', audio='crybunnykill.mp3' },
    ['daffy_weapon_uk_poolcue']       = { dead = { dict='ar_daffy', eff='daffy_uk', scale=3.0 }, screen='uk.png', audio='uk.mp3' },
    ['daffy_weapon_uk_bottle']        = { dead = { dict='ar_daffy', eff='daffy_uk', scale=3.0 }, screen='uk.png', audio='uk.mp3' },
    ['daffy_rich_poolcue']            = { dead = { dict='ar_daffy', eff='daffy_rich', scale=3.0 }, screen='rich.png', audio='rich.mp3' },
    ['daffy_rich_bottle']             = { dead = { dict='ar_daffy', eff='daffy_rich', scale=3.0 }, screen='rich.png', audio='rich.mp3' },
    ['daffy_weapon_minon_poolcue']    = { dead = { dict='ar_daffy', eff='daffy_minion', scale=3.0 }, screen='minion.png', audio='minion.mp3' },
    ['daffy_weapon_minon_bottle']     = { dead = { dict='ar_daffy', eff='daffy_minion', scale=3.0 }, screen='minion.png', audio='minion.mp3' },
    ['daffy_demonslayer_poolcue']     = { dead = { dict='ar_daffy', eff='daffy_nezuko', scale=3.0 }, screen='nezuko.png', audio='nezuko.mp3' },
    ['daffy_demonslayer_bottle']      = { dead = { dict='ar_daffy', eff='daffy_zenitsu', scale=3.0 }, screen='DEMONSLAYER.png', audio='DEMONSLAYER.mp3' },
    ['daffy_chinese_set_poolcue']     = { dead = { dict='ar_daffy', eff='daffy_chinese', scale=3.0 }, screen='chinese.png', audio='chinese.mp3' },
    ['daffy_chinese_set_bottle']      = { dead = { dict='ar_daffy', eff='daffy_chinese', scale=3.0 }, screen='chinese.png', audio='chinese.mp3' },
    ['rb_duckysplash_poolcue']        = { dead = { dict='ar_rainbow', eff='rainbowfx_duckysplash', scale=3.0 }, screen='duckysplash.png', audio='duckysplash.mp3' },
    ['rb_duckysplash_bottle']         = { dead = { dict='ar_rainbow', eff='rainbowfx_duckysplash', scale=3.0 }, screen='duckysplash.png', audio='duckysplash.mp3' },
    ['rb_luvteddy_blue_poolcue']      = { hand = { dict='reaxw_effect_fantasy', eff='trail', scale=1.0 }, dead = { dict='ar_rainbow', eff='rainbowfx_luvteddy', scale=3.0 }, screen='luvteddy.png', audio='luvteddy.mp3' },
    ['rb_luvteddy_blue_knife']        = { hand = { dict='reaxw_effect_fantasy', eff='trail', scale=1.0 }, dead = { dict='ar_rainbow', eff='rainbowfx_luvteddy', scale=3.0 }, screen='luvteddy.png', audio='luvteddy.mp3' },
    ['rb_luvteddy_pink_poolcue']      = { dead = { dict='ar_rainbow', eff='rainbowfx_luvteddy', scale=3.0 }, screen='luvteddy.png', audio='luvteddy.mp3' },
    ['rb_luvteddy_pink_knife']        = { dead = { dict='ar_rainbow', eff='rainbowfx_luvteddy', scale=3.0 }, screen='luvteddy.png', audio='luvteddy.mp3' },
    ['rb_winterfrost_black_poolcue']  = { hand = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=0.3 }, dead = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=3.0 }, screen='winterfrost.png', audio='winterfrost.mp3' },
    ['rb_winterfrost_white_poolcue']  = { hand = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=0.3 }, dead = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=3.0 }, screen='winterfrost.png', audio='winterfrost.mp3' },
    ['rb_winterfrost_black_bottle']   = { hand = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=0.3 }, dead = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=3.0 }, screen='winterfrost.png', audio='winterfrost.mp3' },
    ['rb_winterfrost_white_bottle']   = { hand = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=0.3 }, dead = { dict='ar_rainbow', eff='rainbowfx_winterfrost', scale=3.0 }, screen='winterfrost.png', audio='winterfrost.mp3' },
    ['w_me_wbu_harajuku_poolcue']     = { dead = { dict='ar_rainbow', eff='wbu_harajuku', scale=3.0 }, screen='harajuku.png', audio='harajuku.mp3' },
    ['w_me_wbu_harajuku_bottle']      = { dead = { dict='ar_rainbow', eff='wbu_harajuku', scale=3.0 }, screen='harajuku.png', audio='harajuku.mp3' },
}

-- fallback สำหรับสกินที่ไม่มีใน SKIN_FX → ใช้ clown death
local DEFAULT_DEAD = { dict='scr_rcbarry2', eff='scr_clown_death', scale=1.0 }

-- ============================================================================
-- BUILD SKIN_DB จาก Config['WEAPON_SKIN']
-- ============================================================================
local function BuildSkinDB()
    SKIN_DB = {}
    if not Config or not Config['WEAPON_SKIN'] then return end
    for skinName, data in pairs(Config['WEAPON_SKIN']) do
        local model = data.MODEL or skinName
        local lower = string.lower(skinName)
        local cat = 'poolcue'
        if lower:find("bottle") or lower:find("knife") or lower:find("dagger")
        or lower:find("machete") or lower:find("machette") or lower:find("knuckle") then
            cat = 'bottle'
        end
        SKIN_DB[skinName] = {
            model = model,
            label = data.SKIN_LABEL or skinName,
            cat = cat,
        }
    end
end

-- ============================================================================
-- FIND SKIN
-- ============================================================================
local function FindSkin(query)
    if not query or query == '' then return nil, nil end
    local q = string.lower(query)
    if SKIN_DB[query] then return query, SKIN_DB[query] end
    for k, v in pairs(SKIN_DB) do
        if string.lower(k) == q then return k, v end
    end
    for k, v in pairs(SKIN_DB) do
        if string.lower(v.model) == q or string.lower(v.label) == q then return k, v end
    end
    for k, v in pairs(SKIN_DB) do
        if string.find(string.lower(k), q, 1, true) or string.find(string.lower(v.label), q, 1, true) then
            return k, v
        end
    end
    return nil, nil
end

-- ============================================================================
-- PROP ATTACH
-- ============================================================================
local function RemoveProp()
    if currentProp and DoesEntityExist(currentProp) then
        SetEntityAsMissionEntity(currentProp, true, true)
        DetachEntity(currentProp, true, true)
        DeleteEntity(currentProp)
    end
    currentProp = nil
    currentPropModel = nil
    SetPedCurrentWeaponVisible(PlayerPedId(), true, false, false, false)
end

local function AttachProp(ped, modelName)
    if not ped or not DoesEntityExist(ped) or not modelName then return false end
    if currentProp and DoesEntityExist(currentProp) and currentPropModel == modelName then
        SetPedCurrentWeaponVisible(ped, false, false, false, false)
        return true
    end
    RemoveProp()
    local modelHash = GetHashKey(modelName)
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.upper(modelName)) end
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.lower(modelName)) end
    if not IsModelValid(modelHash) then return false end
    RequestModel(modelHash)
    local deadline = GetGameTimer() + 800
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end
    local boneIndex = GetPedBoneIndex(ped, 57005)
    local pos = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, pos.x, pos.y, pos.z, true, true, false)
    if not DoesEntityExist(prop) then return false end
    SetEntityCollision(prop, false, false)
    SetEntityInvincible(prop, true)
    local px, py, pz = 0.080, -0.025, -0.021
    local rx, ry, rz = -85.0, -16.0, -23.0
    if Config and Config.WeaponPosition then
        local cfg = Config.WeaponPosition['POOL'] or Config.WeaponPosition['BOTTLE']
        if cfg then
            px = (cfg.Pos and cfg.Pos.x) or px; py = (cfg.Pos and cfg.Pos.y) or py; pz = (cfg.Pos and cfg.Pos.z) or pz
            rx = (cfg.Rot and cfg.Rot.x) or rx; ry = (cfg.Rot and cfg.Rot.y) or ry; rz = (cfg.Rot and cfg.Rot.z) or rz
        end
    end
    AttachEntityToEntity(prop, ped, boneIndex, px, py, pz, rx, ry, rz, true, true, false, true, 1, true)
    currentProp = prop
    currentPropModel = modelName
    SetModelAsNoLongerNeeded(modelHash)
    SetPedCurrentWeaponVisible(ped, false, false, false, false)
    return true
end

-- ============================================================================
-- APPLY / REMOVE SKIN
-- ============================================================================
local function ApplySkin(ped, weaponHash, skinName, model)
    if not ped or not DoesEntityExist(ped) or weaponHash == 0 then return false end
    local h1 = GetHashKey(skinName)
    local h2 = GetHashKey(model)
    local h3 = GetHashKey(string.upper(model))
    local h4 = GetHashKey("COMPONENT_" .. string.upper(model))
    GiveWeaponComponentToPed(ped, weaponHash, h1)
    GiveWeaponComponentToPed(ped, weaponHash, h2)
    GiveWeaponComponentToPed(ped, weaponHash, h3)
    GiveWeaponComponentToPed(ped, weaponHash, h4)
    if HasPedGotWeaponComponent(ped, weaponHash, h1)
    or HasPedGotWeaponComponent(ped, weaponHash, h2)
    or HasPedGotWeaponComponent(ped, weaponHash, h3)
    or HasPedGotWeaponComponent(ped, weaponHash, h4) then
        RemoveProp()
        return true
    end
    return AttachProp(ped, model)
end

-- ============================================================================
-- PTFX ENGINE — hardcoded effects
-- ============================================================================
local function EnsurePtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local deadline = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function TriggerHandAura(ped, fx)
    if not fx or not fx.dict then return end
    if EnsurePtfx(fx.dict) then
        UseParticleFxAsset(fx.dict)
        StartParticleFxNonLoopedOnPedBone(
            fx.eff, ped,
            0.12, 0.0, 0.0,
            0.0, 0.0, 65.0,
            GetPedBoneIndex(ped, 57005),
            fx.scale or 0.8,
            false, false, false
        )
    end
end

local function TriggerKillExplosion(victim, fx)
    if not fx or not fx.dict then return end
    local loaded = EnsurePtfx(fx.dict)
    if not loaded then
        loaded = EnsurePtfx(DEFAULT_DEAD.dict)
        if loaded then fx = DEFAULT_DEAD end
    end
    if not loaded then return end
    local pos = GetEntityCoords(victim)
    local headBone = GetPedBoneIndex(victim, 31086)
    if headBone ~= -1 then
        local bPos = GetWorldPositionOfEntityBone(victim, headBone)
        if bPos and #(bPos - pos) < 3.0 and bPos.z > 0.0 then pos = bPos end
    end
    UseParticleFxAsset(fx.dict)
    StartParticleFxNonLoopedAtCoord(fx.eff, pos.x, pos.y, pos.z, 0.0, 0.0, 0.0, fx.scale or 1.0, false, false, false)
end

local function PlayNUI(skinName)
    local fx = SKIN_FX[skinName]
    if not fx then return end
    if fx.screen then
        SendNUIMessage({ action = 'SHOW_SCREEN_EFFECT', image = fx.screen, time = 3000 })
    end
    if fx.audio then
        SendNUIMessage({ action = 'PLAY_SOUND', sound = fx.audio, volume = 0.5 })
    end
end

local function StopHandFx() handFxActive = false end

local function StartHandFx(skinName)
    local fx = SKIN_FX[skinName]
    if not fx or not fx.hand then return end
    handFxActive = true
    CreateThread(function()
        while handFxActive and equippedSkin do
            local ped = PlayerPedId()
            local curW = GetSelectedPedWeapon(ped)
            if curW == GetHashKey('WEAPON_UNARMED') or not ALL_HASHES[curW] then
                Wait(500)
            else
                TriggerHandAura(ped, fx.hand)
                Wait(800)
            end
        end
    end)
end

-- ============================================================================
-- ANTI-DETECT HOOKS
-- ============================================================================
local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComp = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

HasPedGotWeaponComponent = function(ped, weapon, component)
    if equippedSkin and ped == PlayerPedId() and equippedHash and component == equippedHash then
        return true
    end
    return origHasPedGot(ped, weapon, component)
end

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if equippedSkin and equippedHash and component == equippedHash then return end
    return origRemoveComp(ped, weapon, component)
end

TriggerServerEvent = function(eventName, ...)
    if type(eventName) == "string" then
        local lower = string.lower(eventName)
        if lower:find("weaponskin") or lower:find("gn_weapon") then
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

-- ============================================================================
-- DAMAGE HANDLER — ตีตาย = explosion + NUI
-- ============================================================================
local function RegisterDamageHandler()
    if damageRegistered then return end
    damageRegistered = true
    AddEventHandler("gameEventTriggered", function(eventName, eventData)
        if not equippedSkin then return end
        if eventName ~= "CEventNetworkEntityDamage" then return end
        local victim, attacker = eventData[1], eventData[2]
        local isDead = eventData[4]
        local ped = PlayerPedId()
        if attacker ~= ped or victim == ped then return end
        if isDead == 1 or IsEntityDead(victim) then
            local now = GetGameTimer()
            if now - lastEffectTime < 2000 then return end
            lastEffectTime = now
            local fx = SKIN_FX[equippedSkin]
            local deadFx = (fx and fx.dead) or DEFAULT_DEAD
            TriggerKillExplosion(victim, deadFx)
            PlayNUI(equippedSkin)
        end
    end)
end

-- ============================================================================
-- AUTO EQUIP LOOP
-- ============================================================================
local function StartAutoEquip()
    if autoEquipActive then return end
    autoEquipActive = true
    CreateThread(function()
        while autoEquipActive and equippedSkin do
            local ped = PlayerPedId()
            local curW = GetSelectedPedWeapon(ped)
            if curW ~= GetHashKey('WEAPON_UNARMED') and ALL_HASHES[curW] and not IsEntityDead(ped) then
                local skinData = SKIN_DB[equippedSkin]
                if skinData then
                    local h = GetHashKey(equippedSkin)
                    if not origHasPedGot(ped, curW, h) then
                        ApplySkin(ped, curW, equippedSkin, skinData.model)
                    end
                    equippedOnWeapon = curW
                    if currentProp and DoesEntityExist(currentProp) then
                        SetPedCurrentWeaponVisible(ped, false, false, false, false)
                    end
                end
            else
                if currentProp and DoesEntityExist(currentProp) then RemoveProp() end
            end
            Wait(200)
        end
        autoEquipActive = false
    end)
end

-- ============================================================================
-- KVP
-- ============================================================================
local function SaveSkin(name)
    if name and name ~= '' then SetResourceKvp("homeskin_sel", name)
    else DeleteResourceKvp("homeskin_sel") end
end
local function LoadSkin()
    local v = GetResourceKvpString("homeskin_sel")
    if v and v ~= '' then return v end
    return nil
end

-- ============================================================================
-- INIT
-- ============================================================================
CreateThread(function()
    Wait(3000)
    BuildSkinDB()
    RegisterDamageHandler()
    local saved = LoadSkin()
    if saved and SKIN_DB[saved] then
        equippedSkin = saved
        equippedHash = GetHashKey(saved)
        StartAutoEquip()
        StartHandFx(saved)
        print(("^2[HOME]^7 Auto-loaded: ^6%s^7"):format(SKIN_DB[saved].label))
    end
end)

AddEventHandler('onResourceStop', function(r)
    if r == GetCurrentResourceName() then RemoveProp(); StopHandFx() end
end)

-- ============================================================================
-- /home <skinname> | /homeoff | /homelist
-- ============================================================================
RegisterCommand('home', function(_, args)
    BuildSkinDB()
    if #args < 1 then print("^3[HOME]^7 /home <skin> | /homeoff | /homelist"); return end
    local input = args[1]
    if string.lower(input) == 'off' or string.lower(input) == 'default' then ExecuteCommand('homeoff'); return end

    local skinName, skinData = FindSkin(input)
    if not skinName then print(("^1[HOME]^7 ไม่พบสกิน: '%s' — /homelist"):format(input)); return end

    if equippedSkin then
        StopHandFx(); autoEquipActive = false
        if equippedOnWeapon and equippedOnWeapon ~= 0 then
            pcall(function() origRemoveComp(PlayerPedId(), equippedOnWeapon, equippedHash) end)
        end
        RemoveProp()
    end

    equippedSkin = skinName
    equippedHash = GetHashKey(skinName)
    equippedOnWeapon = nil
    SaveSkin(skinName)

    local ped = PlayerPedId()
    local curW = GetSelectedPedWeapon(ped)
    if curW ~= GetHashKey('WEAPON_UNARMED') and ALL_HASHES[curW] then
        ApplySkin(ped, curW, skinName, skinData.model)
        equippedOnWeapon = curW
    end

    StartAutoEquip()
    StartHandFx(skinName)
    local hasFx = SKIN_FX[skinName]
    local fxTag = hasFx and (hasFx.hand and "^3+HAND " or "") .. (hasFx.dead and "^2+KILL" or "") or ""
    print(("^2[HOME]^7 ใส่: ^6%s^7 (%s) %s"):format(skinData.label, skinName, fxTag))
end, false)

RegisterCommand('homeoff', function()
    StopHandFx(); autoEquipActive = false
    if equippedOnWeapon and equippedOnWeapon ~= 0 and equippedHash then
        pcall(function() origRemoveComp(PlayerPedId(), equippedOnWeapon, equippedHash) end)
    end
    RemoveProp()
    equippedSkin = nil; equippedHash = nil; equippedOnWeapon = nil
    SaveSkin(nil)
    print("^1[HOME]^7 ถอดสกินแล้ว")
end, false)

RegisterCommand('homelist', function()
    BuildSkinDB()
    local pools, bottles = {}, {}
    for k, v in pairs(SKIN_DB) do
        if v.cat == 'poolcue' then pools[#pools+1] = k else bottles[#bottles+1] = k end
    end
    table.sort(pools); table.sort(bottles)
    print(("^2===== POOLCUE (%d) =====^7"):format(#pools))
    for _, n in ipairs(pools) do
        local s = SKIN_DB[n]; local fx = SKIN_FX[n]
        local mark = (n == equippedSkin) and " ^2<< ON^7" or ""
        local tags = ""
        if fx then
            if fx.hand then tags = tags .. "^3HAND^7 " end
            if fx.dead then tags = tags .. "^2KILL^7 " end
            if fx.screen then tags = tags .. "^5SCR^7 " end
        end
        print(("  ^6%-40s^7 %s %s%s"):format(n, s.label, tags, mark))
    end
    print(("^2===== BOTTLE (%d) =====^7"):format(#bottles))
    for _, n in ipairs(bottles) do
        local s = SKIN_DB[n]; local fx = SKIN_FX[n]
        local mark = (n == equippedSkin) and " ^2<< ON^7" or ""
        local tags = ""
        if fx then
            if fx.hand then tags = tags .. "^3HAND^7 " end
            if fx.dead then tags = tags .. "^2KILL^7 " end
            if fx.screen then tags = tags .. "^5SCR^7 " end
        end
        print(("  ^6%-40s^7 %s %s%s"):format(n, s.label, tags, mark))
    end
    print(("^2=== รวม %d สกิน | /home <name> | /homeoff ===^7"):format(#pools + #bottles))
end, false)

print("^2[HOME]^7 Loaded! /home <skin> | /homeoff | /homelist")
