-- ============================================================================
-- UNIFIED WEAPON SKIN ENGINE (ALL-IN-ONE)
-- /home <skinname>  = equip skin | /homeoff = remove | /homelist = list all
-- Component + Prop hybrid | PTFX hand aura | Kill explosion | NUI screen/audio
-- Anti-detect hooks | KVP persistent save | No item check
-- ============================================================================

local SCRIPT_NAME = "HomeSkin"
local equippedSkins = {}
local allKnownComponentHashes = {}
local currentPropEntity = nil
local currentPropModel = nil

-- ============================================================================
-- 1. MASTER SKIN DATABASE (ALL SKINS MERGED)
-- ============================================================================
local MasterSkins = {
    -- ═══════════════════════════════════════════════
    -- POOLCUE SKINS
    -- ═══════════════════════════════════════════════
    ['sharkz_poolcue_starhero'] = {
        label = 'Star Hero', model = 'sharkz_poolcue_starhero', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_starhero', 'hero', 'starhero' },
        eff_dead = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_hit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_effect', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'hero.png', audio = 'hero.mp3',
    },
    ['sharkz_poolcue_8bit'] = {
        label = '8BIT', model = 'sharkz_poolcue_8bit', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_8bit', '8bit', 'poolcue_8bit' },
        eff_dead = { { dict = 'sharkz_8bit_set', eff = 'sharkz_hit_8bit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_8bit_set', eff = 'sharkz_effect_8bit', bone = 57005, scale = 0.3, time = 800 } },
        screen = '8bit.png', audio = '8bit.mp3',
    },
    ['wishme_momo_poolcue'] = {
        label = 'Momo', model = 'wishme_momo_poolcue', category = 'POOLCUE',
        aliases = { 'wishme_momo_poolcue', 'momo', 'wishme_momo' },
        eff_dead = { { dict = 'whitme_momo_efx', eff = 'scr_withme_firework_starburst', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'whitme_momo_efx', eff = 'scr_whitmemomo_beast_vanish', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'momo.png', audio = 'momo.mp3',
    },
    ['rb_swagblack_poolcue'] = {
        label = 'Swag Black', model = 'rb_swagblack_poolcue', category = 'POOLCUE',
        aliases = { 'rb_swagblack_poolcue', 'swagblack' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['rb_swagwhite_poolcue'] = {
        label = 'Swag White', model = 'rb_swagwhite_poolcue', category = 'POOLCUE',
        aliases = { 'rb_swagwhite_poolcue', 'swagwhite' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['sharkz_poolcue_phx_firestorm'] = {
        label = 'Phoenix', model = 'sharkz_poolcue_phx_firestorm', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_phx_firestorm', 'phoenix' },
        eff_dead = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_effect', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'phoenix.png', audio = 'phoenix.mp3',
    },
    ['cryo_poolcue'] = {
        label = 'CRYO', model = 'cryo_poolcue', category = 'POOLCUE',
        aliases = { 'cryo_poolcue', 'cryo' },
    },
    ['x_me_poolcue_anubis'] = {
        label = 'Anubis', model = 'x_me_poolcue_anubis', category = 'POOLCUE',
        aliases = { 'x_me_poolcue_anubis', 'anubis' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['w_me_poolcueks_dds'] = {
        label = 'Kitsune', model = 'w_me_poolcueks_dds', category = 'POOLCUE',
        aliases = { 'w_me_poolcueks_dds', 'kitsune' },
        eff_dead = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1v1_po', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1hxnd_po', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'kitsune.png', audio = 'kitsune.mp3',
    },
    ['wm_elys_pool'] = {
        label = 'ELYS', model = 'wm_elys_pool', category = 'POOLCUE',
        aliases = { 'wm_elys_pool', 'elys' },
        eff_dead = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys_hfx', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'elys.png', audio = 'elys.mp3',
    },
    ['w_me_poolcue_eden'] = {
        label = 'Eden', model = 'w_me_poolcue_eden', category = 'POOLCUE',
        aliases = { 'w_me_poolcue_eden', 'eden' },
        eff_dead = { { dict = 'eden', eff = 'eden', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        ptfx_bone = { { dict = 'eden', eff = 'eden', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'eden.png', audio = 'eden.mp3',
    },
    ['lazy_cutestar_poolcue'] = {
        label = 'Bunny Lazy', model = 'lazy_cutestar_poolcue', category = 'POOLCUE',
        aliases = { 'lazy_cutestar_poolcue', 'lazy', 'cutestar' },
        eff_dead = { { dict = 'ar_effect', eff = 'cutestar', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        screen = 'cutestar.png', audio = 'cutestar.mp3',
    },
    ['sharkz_poolcue_darkwolf'] = {
        label = 'Dark Wolf', model = 'sharkz_poolcue_darkwolf', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_darkwolf', 'darkwolf' },
        eff_dead = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_effect', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'darkwolf.png', audio = 'darkwolf.mp3',
    },
    ['w_me_poolcue_stl_green'] = {
        label = 'GREEN', model = 'w_me_poolcue_stl_green', category = 'POOLCUE',
        aliases = { 'w_me_poolcue_stl_green', 'green' },
        eff_dead = { { dict = 'stl_green', eff = 'stl_green', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.15 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'effect_energygreen', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'green.png', audio = 'green.mp3',
    },
    ['sharkz_poolcue_zap'] = {
        label = 'ZAP', model = 'sharkz_poolcue_zap', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_zap', 'zap' },
        eff_dead = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_effect', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'zap.png', audio = 'zap.mp3',
    },
    ['w_me_zyndear_toothless_poolcue_white'] = {
        label = 'Toothless', model = 'w_me_zyndear_toothless_poolcue_white', category = 'POOLCUE',
        aliases = { 'toothless_pool', 'toothless' },
        eff_dead = { { dict = 'ar_effect', eff = 'killtoothlesswhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'killtoothlesswhite', bone = 57005, scale = 0.1, time = 800 } },
        audio = 'jingle.mp3',
    },
    ['lazy_fox_poolcue'] = {
        label = 'Fox Lazy', model = 'lazy_fox_poolcue', category = 'POOLCUE',
        aliases = { 'lazy_fox_poolcue', 'lazyfox', 'fox' },
        eff_dead = { { dict = 'ar_effect', eff = 'foxfx', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.25 } },
        screen = 'lazyfox.png', audio = 'lazyfox.mp3',
    },
    ['w_me_poolcueredfire'] = {
        label = 'FIRE', model = 'w_me_poolcueredfire', category = 'POOLCUE',
        aliases = { 'w_me_poolcueredfire', 'fire', 'redfire' },
        eff_dead = { { dict = 'ptfx_fireredsmoke', eff = 'ptfx_fireredsmoke', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'redfire', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'vdframefire.png', audio = 'vdfirered.mp3',
    },
    ['things_freebunny_poolcue'] = {
        label = 'BUNNY', model = 'things_freebunny_poolcue', category = 'POOLCUE',
        aliases = { 'things_freebunny_poolcue', 'bunny', 'freebunny' },
        eff_dead = { { dict = 'things_freeskinbunny', eff = 'things_freeskinbunny', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        screen = 'free_bunny.png', audio = 'free_bunny.mp3',
    },
    ['devilcute_poolcue'] = {
        label = 'Devilcute', model = 'devilcute_poolcue', category = 'POOLCUE',
        aliases = { 'devilcute_poolcue', 'devilcute' },
        eff_dead = { { dict = 'devilcute_hit_effects', eff = 'magicwarp', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        screen = 'devilcute.png', audio = 'devilcute.mp3',
    },
    ['reawx_pool_fantacy'] = {
        label = 'Zephyron', model = 'reawx_pool_fantacy', category = 'POOLCUE',
        aliases = { 'reawx_pool_fantacy', 'zephyron' },
        eff_dead = { { dict = 'reawx_particle_fantasy', eff = 'reawx_particle_fantasy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'ZEPHYRON.png', audio = 'ZEPHYRON.mp3',
    },
    ['bbg_wp26_poolcue'] = {
        label = 'Pink Pig', model = 'bbg_wp26_poolcue', category = 'POOLCUE',
        aliases = { 'bbg_wp26_poolcue', 'pinkpig', 'wp26' },
        eff_dead = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.5 } },
        ptfx_bone = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy_star', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'pinkpig.png', audio = 'pinkpig.ogg',
    },
    ['wishme_poolcue_chromium'] = {
        label = 'Chromium', model = 'wishme_poolcue_chromium', category = 'POOLCUE',
        aliases = { 'wishme_poolcue_chromium', 'chromium' },
        eff_dead = { { dict = 'weapon_wishme', eff = 'wishme', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.1 } },
        ptfx_bone = { { dict = 'weapon_wishme', eff = 'wishme', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'wishme_kill.png', audio = 'wishme_kill.mp3',
    },
    ['w_me_songkran_poolcue'] = {
        label = 'Water', model = 'w_me_songkran_poolcue', category = 'POOLCUE',
        aliases = { 'w_me_songkran_poolcue', 'water', 'songkran' },
    },
    ['lazy_badbunnie_poolcue'] = {
        label = 'Bad Bunnie', model = 'lazy_badbunnie_poolcue', category = 'POOLCUE',
        aliases = { 'lazy_badbunnie_poolcue', 'badbunnie' },
        eff_dead = { { dict = 'lazy_badbunnie', eff = 'lazy_badbunnie', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.08 } },
        screen = 'badbunny.png', audio = 'badbunny.mp3',
    },
    ['gb_ponypink_poolcue'] = {
        label = 'Pony Pink', model = 'gb_ponypink_poolcue', category = 'POOLCUE',
        aliases = { 'gb_ponypink_poolcue', 'ponypink' },
        eff_dead = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_5', bone = 57005, scale = 0.6, time = 800 } },
        screen = 'pony.png', audio = 'pony.mp3',
    },
    ['gb_ponyyell_poolcue'] = {
        label = 'Pony Yell', model = 'gb_ponyyell_poolcue', category = 'POOLCUE',
        aliases = { 'gb_ponyyell_poolcue', 'ponyyell' },
        eff_dead = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_5', bone = 57005, scale = 0.6, time = 800 } },
        screen = 'pony.png', audio = 'pony.mp3',
    },
    ['bbg_wp28_poolcue'] = {
        label = 'Sea Summer', model = 'bbg_wp28_poolcue', category = 'POOLCUE',
        aliases = { 'bbg_wp28_poolcue', 'seasummer', 'wp28' },
        eff_dead = { { dict = 'ar_bbg', eff = 'underthesea_kill', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'underthesea_bubble', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'sea.png', audio = 'sea.ogg',
    },
    ['sharkz_poolcue_deepblue'] = {
        label = 'Deep Blue', model = 'sharkz_poolcue_deepblue', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_deepblue', 'deepblue' },
        eff_dead = { { dict = 'sharkz_deepblue_set', eff = 'sharkz_deepblue_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.6 } },
        ptfx_bone = { { dict = 'sharkz_deepblue_set', eff = 'shark_deepblue_effect', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'deepblue.png', audio = 'deepblue.mp3',
    },
    ['coolkids_duckysummer_poolcue'] = {
        label = 'Ducky Summer', model = 'coolkids_duckysummer_poolcue', category = 'POOLCUE',
        aliases = { 'coolkids_duckysummer_poolcue', 'duckysummer' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'dsumer.png', audio = 'dsumer.mp3',
    },
    ['sharkz_poolcue_poker'] = {
        label = 'Poker', model = 'sharkz_poolcue_poker', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_poker', 'poker' },
        eff_dead = { { dict = 'sharkz_poker_set', eff = 'sharkz_hit_poker', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_poker_set', eff = 'sharkz_effect_poker', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'poker.png', audio = 'poker.ogg',
    },
    ['coolkids_sanrio_poolcue'] = {
        label = 'Sanrio', model = 'coolkids_sanrio_poolcue', category = 'POOLCUE',
        aliases = { 'coolkids_sanrio_poolcue', 'sanrio' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'csro.png', audio = 'csro.mp3',
    },
    ['gb_bearx_poolcue_white'] = {
        label = 'BearX White', model = 'gb_bearx_poolcue_white', category = 'POOLCUE',
        aliases = { 'gb_bearx_poolcue_white', 'bearxwhite' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 800 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['gb_bearx_poolcue_black'] = {
        label = 'BearX Black', model = 'gb_bearx_poolcue_black', category = 'POOLCUE',
        aliases = { 'gb_bearx_poolcue_black', 'bearxblack' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 800 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['sharkz_poolcue_greendragon'] = {
        label = 'Green Dragon', model = 'sharkz_poolcue_greendragon', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_greendragon', 'greendragon' },
        eff_dead = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_hit_gdragon', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_effect_gdragon', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'gd.png', audio = 'gd.mp3',
    },
    ['sharkz_poolcue_halloween'] = {
        label = 'Halloween', model = 'sharkz_poolcue_halloween', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_halloween', 'halloween' },
        eff_dead = { { dict = 'sharkz_halloween_set', eff = 'sharkz_halloween_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_blood_effect', eff = 'sharkz_blood_effect', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'halloween.png', audio = 'halloween.mp3',
    },
    ['rb_duckysplash_poolcue'] = {
        label = 'Ducky Splash', model = 'rb_duckysplash_poolcue', category = 'POOLCUE',
        aliases = { 'rb_duckysplash_poolcue', 'duckysplash' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_duckysplash', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['rb_luvteddy_blue_poolcue'] = {
        label = 'Luv Teddy Blue', model = 'rb_luvteddy_blue_poolcue', category = 'POOLCUE',
        aliases = { 'rb_luvteddy_blue_poolcue', 'luvteddyblue' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['rb_luvteddy_pink_poolcue'] = {
        label = 'Luv Teddy Pink', model = 'rb_luvteddy_pink_poolcue', category = 'POOLCUE',
        aliases = { 'rb_luvteddy_pink_poolcue', 'luvteddypink' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['rb_winterfrost_black_poolcue'] = {
        label = 'Winterfrost Black', model = 'rb_winterfrost_black_poolcue', category = 'POOLCUE',
        aliases = { 'rb_winterfrost_black_poolcue', 'winterfrostblack' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['rb_winterfrost_white_poolcue'] = {
        label = 'Winterfrost White', model = 'rb_winterfrost_white_poolcue', category = 'POOLCUE',
        aliases = { 'rb_winterfrost_white_poolcue', 'winterfrostwhite' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['w_me_wbu_harajuku_poolcue'] = {
        label = 'Harajuku', model = 'w_me_wbu_harajuku_poolcue', category = 'POOLCUE',
        aliases = { 'w_me_wbu_harajuku_poolcue', 'harajuku' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'wbu_harajuku', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'harajuku.png', audio = 'harajuku.mp3',
    },
    ['ohmmiwars_poolcue_squid'] = {
        label = 'Squidgame', model = 'ohmmiwars_poolcue_squid', category = 'POOLCUE',
        aliases = { 'ohmmiwars_poolcue_squid', 'squidgame', 'squid' },
        eff_dead = { { dict = 'daffy_squidgame', eff = 'daffy_squidgame', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'squidgame.png', audio = 'squidgame.mp3',
    },
    ['COMPONENT_POOL_CRYBUNNY'] = {
        label = 'Crybunny', model = 'COMPONENT_POOL_CRYBUNNY', category = 'POOLCUE',
        aliases = { 'component_pool_crybunny', 'crybunny' },
        eff_dead = { { dict = 'zyndea_wepfx_crybunny_fx', eff = 'zyndea_wepfx_crybunny_fx', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'crybunnykill.png', audio = 'crybunnykill.mp3',
    },
    ['daffy_weapon_uk_poolcue'] = {
        label = 'UK', model = 'daffy_weapon_uk_poolcue', category = 'POOLCUE',
        aliases = { 'daffy_weapon_uk_poolcue', 'uk' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_uk', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'uk.png', audio = 'uk.mp3',
    },
    ['coolkids_babythree_poolcue'] = {
        label = 'Baby Three', model = 'coolkids_babythree_poolcue', category = 'POOLCUE',
        aliases = { 'coolkids_babythree_poolcue', 'babythree' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'coolkids_efx_01_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'cbbt.png', audio = 'cbbt.mp3',
    },
    ['sharkz_poolcue_white_wolf'] = {
        label = 'White Wolf', model = 'sharkz_poolcue_white_wolf', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_white_wolf', 'whitewolf' },
        eff_dead = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_hit_whitewolf', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_effect_whitewolf', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'wwolf.png', audio = 'wwolf.mp3',
    },
    ['coolkids_Sweet_poolcue'] = {
        label = 'Sweet', model = 'coolkids_Sweet_poolcue', category = 'POOLCUE',
        aliases = { 'coolkids_sweet_poolcue', 'sweet' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sweet', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'SWEET_screen.png', audio = 'sound_SWEET.mp3',
    },
    ['ohmmiwars_poolcue_melody'] = {
        label = 'Melody', model = 'ohmmiwars_poolcue_melody', category = 'POOLCUE',
        aliases = { 'ohmmiwars_poolcue_melody', 'melody' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_melody', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'melody.png', audio = 'melody.mp3',
    },
    ['ohmmiwars_poolcue_wednesday'] = {
        label = 'Wednesday', model = 'ohmmiwars_poolcue_wednesday', category = 'POOLCUE',
        aliases = { 'ohmmiwars_poolcue_wednesday', 'wednesday' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_wd', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'wd.png', audio = 'wd.mp3',
    },
    ['daffy_rich_poolcue'] = {
        label = 'Rich', model = 'daffy_rich_poolcue', category = 'POOLCUE',
        aliases = { 'daffy_rich_poolcue', 'rich' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_rich', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'rich.png', audio = 'rich.mp3',
    },
    ['daffy_weapon_minon_poolcue'] = {
        label = 'Minion', model = 'daffy_weapon_minon_poolcue', category = 'POOLCUE',
        aliases = { 'daffy_weapon_minon_poolcue', 'minion' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_minion', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'minion.png', audio = 'minion.mp3',
    },
    ['daffy_demonslayer_poolcue'] = {
        label = 'Demonslayer', model = 'daffy_demonslayer_poolcue', category = 'POOLCUE',
        aliases = { 'daffy_demonslayer_poolcue', 'demonslayer' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_nezuko', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'nezuko.png', audio = 'nezuko.mp3',
    },
    ['daffy_chinese_set_poolcue'] = {
        label = 'Chinese Set', model = 'daffy_chinese_set_poolcue', category = 'POOLCUE',
        aliases = { 'daffy_chinese_set_poolcue', 'chinese', 'chineseset' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_chinese', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'chinese.png', audio = 'chinese.mp3',
    },
    ['gb_neko_poolcue_white'] = {
        label = 'Neko White', model = 'gb_neko_poolcue_white', category = 'POOLCUE',
        aliases = { 'gb_neko_poolcue_white', 'nekowhite' },
        eff_dead = { { dict = 'girlbossefx_nekowhite', eff = 'girlbossefx_nekowhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'nekowhite.png', audio = 'nekosound.mp3',
    },
    ['gb_neko_poolcue_black'] = {
        label = 'Neko Black', model = 'gb_neko_poolcue_black', category = 'POOLCUE',
        aliases = { 'gb_neko_poolcue_black', 'nekoblack' },
        eff_dead = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'nekoblack.png', audio = 'nekosound.mp3',
    },
    ['sharkz_poolcue_white_tiger'] = {
        label = 'White Tiger', model = 'sharkz_poolcue_white_tiger', category = 'POOLCUE',
        aliases = { 'sharkz_poolcue_white_tiger', 'whitetiger' },
        eff_dead = { { dict = 'sharkz_whitetiger_set', eff = 'sharkz_whitetiger_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'sharkz_effect_whitetiger', eff = 'sharkz_effect_whitetiger', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'wtg.png', audio = 'wtg.mp3',
    },
    ['bbg_wp23_poolcue'] = {
        label = 'Valentine', model = 'bbg_wp23_poolcue', category = 'POOLCUE',
        aliases = { 'bbg_wp23_poolcue', 'valentine', 'wp23' },
        eff_dead = { { dict = 'ar_bbg', eff = 'cupidlover', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'heartspawn', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'v26.png', audio = 'v26.mp3',
    },
    ['w_me_poolcue_dds'] = {
        label = 'Lava', model = 'w_me_poolcue_dds', category = 'POOLCUE',
        aliases = { 'w_me_poolcue_dds', 'lava' },
        eff_dead = { { dict = 'deands_efx_lv', eff = 'exp_air_deandesignstudio', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'deands_efx_lv', eff = 'deands_efx_lv11p', bone = 57005, scale = 1.5, time = 800 } },
        screen = 'lva.png', audio = 'lva.mp3',
    },
    ['wm_baldwin_pool'] = {
        label = 'Baldwin', model = 'wm_baldwin_pool', category = 'POOLCUE',
        aliases = { 'wm_baldwin_pool', 'baldwin' },
        eff_dead = { { dict = 'fire_baldwinkill', eff = 'fire_baldwinkill', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'handbaldwin', eff = 'handbaldwin', bone = 57005, scale = 0.8, time = 800 } },
        audio = 'fxbaldwin.mp3',
    },
    ['meow_buer_pool'] = {
        label = 'Buer', model = 'MEOW_BUER_POOL', category = 'POOLCUE',
        aliases = { 'meow_buer_pool', 'buer' },
        eff_dead = { { dict = 'buerfx', eff = 'scr_clown_bul', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'buerfx', eff = 'buerfx', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'meow_frame_buer.png', audio = 'fxbaldwin.mp3',
    },
    ['orca_poolcue'] = {
        label = 'Orca', model = 'orca_poolcue', category = 'POOLCUE',
        aliases = { 'orca_poolcue', 'orca' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['w_me_duckpoolcue'] = {
        label = 'Duck', model = 'w_me_duckpoolcue', category = 'POOLCUE',
        aliases = { 'w_me_duckpoolcue', 'duck', 'ducky' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['w_me_pooldog'] = {
        label = 'Doggy', model = 'w_me_pooldog', category = 'POOLCUE',
        aliases = { 'w_me_pooldog', 'doggy', 'pooldog' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_judy_poolcue'] = {
        label = 'Judy', model = 'gb_judy_poolcue', category = 'POOLCUE',
        aliases = { 'gb_judy_poolcue', 'judy' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_nick_poolcue'] = {
        label = 'Nick', model = 'gb_nick_poolcue', category = 'POOLCUE',
        aliases = { 'gb_nick_poolcue', 'nick' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_kanjifang_poolcue'] = {
        label = 'Kanjifang', model = 'gb_kanjifang_poolcue', category = 'POOLCUE',
        aliases = { 'gb_kanjifang_poolcue', 'kanjifang' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['bbg_wp25_poolcue'] = {
        label = 'WP25', model = 'bbg_wp25_poolcue', category = 'POOLCUE',
        aliases = { 'bbg_wp25_poolcue', 'wp25' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['bbg_wp29_poolcue'] = {
        label = 'WP29', model = 'bbg_wp29_poolcue', category = 'POOLCUE',
        aliases = { 'bbg_wp29_poolcue', 'wp29' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['wm_virex_pool'] = {
        label = 'Virex', model = 'wm_virex_pool', category = 'POOLCUE',
        aliases = { 'wm_virex_pool', 'virex' },
        ptfx_bone = { { dict = 'wishme_virex', eff = 'wishme_virex', bone = 57005, scale = 0.06, time = 800 } },
    },

    -- ═══════════════════════════════════════════════
    -- BOTTLE / KNIFE / DAGGER SKINS
    -- ═══════════════════════════════════════════════
    ['sharkz_bottle_starhero'] = {
        label = 'Star Hero B', model = 'sharkz_bottle_starhero', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_starhero', 'hero_b' },
        eff_dead = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_hit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_effect', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'hero.png', audio = 'hero.mp3',
    },
    ['sharkz_bottle_8bit'] = {
        label = '8BIT B', model = 'sharkz_bottle_8bit', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_8bit', '8bit_b' },
        eff_dead = { { dict = 'sharkz_8bit_set', eff = 'sharkz_hit_8bit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_8bit_set', eff = 'sharkz_effect_8bit', bone = 57005, scale = 0.3, time = 800 } },
        screen = '8bit.png', audio = '8bit.mp3',
    },
    ['wishme_momo_1knife'] = {
        label = 'Momo Knife', model = 'wishme_momo_1knife', category = 'BOTTLE',
        aliases = { 'wishme_momo_1knife', 'momo_knife' },
        eff_dead = { { dict = 'whitme_momo_efx', eff = 'scr_withme_firework_starburst', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'whitme_momo_efx', eff = 'scr_whitmemomo_beast_vanish', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'momo.png', audio = 'momo.mp3',
    },
    ['rb_swagblack_knife'] = {
        label = 'Swag Black K', model = 'rb_swagblack_knife', category = 'BOTTLE',
        aliases = { 'rb_swagblack_knife', 'swagblack_k' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['rb_swagwhite_knife'] = {
        label = 'Swag White K', model = 'rb_swagwhite_knife', category = 'BOTTLE',
        aliases = { 'rb_swagwhite_knife', 'swagwhite_k' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['sharkz_knife_phx_firestorm'] = {
        label = 'Phoenix K', model = 'sharkz_knife_phx_firestorm', category = 'BOTTLE',
        aliases = { 'sharkz_knife_phx_firestorm', 'phoenix_k' },
        eff_dead = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_effect', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'phoenix.png', audio = 'phoenix.mp3',
    },
    ['lazy_cutestar_knife'] = {
        label = 'Bunny Lazy K', model = 'lazy_cutestar_knife', category = 'BOTTLE',
        aliases = { 'lazy_cutestar_knife', 'lazy_k', 'cutestar_k' },
        eff_dead = { { dict = 'ar_effect', eff = 'cutestar', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        screen = 'cutestar.png', audio = 'cutestar.mp3',
    },
    ['x_me_bottle_anubis'] = {
        label = 'Anubis B', model = 'x_me_bottle_anubis', category = 'BOTTLE',
        aliases = { 'x_me_bottle_anubis', 'anubis_b' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['x_me_dagger_anubis'] = {
        label = 'Anubis D', model = 'x_me_dagger_anubis', category = 'BOTTLE',
        aliases = { 'x_me_dagger_anubis', 'anubis_d' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['x_me_knife_anubis'] = {
        label = 'Anubis K', model = 'x_me_knife_anubis', category = 'BOTTLE',
        aliases = { 'x_me_knife_anubis', 'anubis_k' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['w_me_daggerks_dds'] = {
        label = 'Kitsune D', model = 'w_me_daggerks_dds', category = 'BOTTLE',
        aliases = { 'w_me_daggerks_dds', 'kitsune_d' },
        eff_dead = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1v1_po', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1hxnd_po', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'kitsune.png', audio = 'kitsune.mp3',
    },
    ['sharkz_bottle_zap'] = {
        label = 'ZAP B', model = 'sharkz_bottle_zap', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_zap', 'zap_b' },
        eff_dead = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_effect', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'zap.png', audio = 'zap.mp3',
    },
    ['w_me_bottle_eden'] = {
        label = 'Eden B', model = 'w_me_bottle_eden', category = 'BOTTLE',
        aliases = { 'w_me_bottle_eden', 'eden_b' },
        eff_dead = { { dict = 'eden', eff = 'eden', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        ptfx_bone = { { dict = 'eden', eff = 'eden', bone = 57005, scale = 0.8, time = 800 } },
        screen = 'eden.png', audio = 'eden.mp3',
    },
    ['w_me_zyndear_toothless_bottle_white'] = {
        label = 'Toothless B', model = 'w_me_zyndear_toothless_bottle_white', category = 'BOTTLE',
        aliases = { 'toothless_b' },
        eff_dead = { { dict = 'ar_effect', eff = 'killtoothlesswhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'killtoothlesswhite', bone = 57005, scale = 0.1, time = 800 } },
        audio = 'jingle.mp3',
    },
    ['wm_elys_knife'] = {
        label = 'ELYS K', model = 'wm_elys_knife', category = 'BOTTLE',
        aliases = { 'wm_elys_knife', 'elys_k' },
        eff_dead = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys_hfx', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'elys.png', audio = 'elys.mp3',
    },
    ['lazy_fox_knife'] = {
        label = 'Fox Lazy K', model = 'lazy_fox_knife', category = 'BOTTLE',
        aliases = { 'lazy_fox_knife', 'lazyfox_k' },
        eff_dead = { { dict = 'ar_effect', eff = 'foxfx', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.25 } },
        screen = 'lazyfox.png', audio = 'lazyfox.mp3',
    },
    ['w_me_bottleredfire'] = {
        label = 'FIRE B', model = 'w_me_bottleredfire', category = 'BOTTLE',
        aliases = { 'w_me_bottleredfire', 'fire_b', 'redfire_b' },
        eff_dead = { { dict = 'ptfx_fireredsmoke', eff = 'ptfx_fireredsmoke', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'redfire', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'vdframefire.png', audio = 'vdfirered.mp3',
    },
    ['rb_luvteddy_blue_knife'] = {
        label = 'Luv Teddy Blue K', model = 'rb_luvteddy_blue_knife', category = 'BOTTLE',
        aliases = { 'rb_luvteddy_blue_knife', 'luvteddyblue_k' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['rb_luvteddy_pink_knife'] = {
        label = 'Luv Teddy Pink K', model = 'rb_luvteddy_pink_knife', category = 'BOTTLE',
        aliases = { 'rb_luvteddy_pink_knife', 'luvteddypink_k' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['devilcute_bottle'] = {
        label = 'Devilcute B', model = 'devilcute_bottle', category = 'BOTTLE',
        aliases = { 'devilcute_bottle', 'devilcute_b' },
        eff_dead = { { dict = 'devilcute_hit_effects', eff = 'magicwarp', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        screen = 'devilcute.png', audio = 'devilcute.mp3',
    },
    ['reawx_bottle_fantacy'] = {
        label = 'Zephyron B', model = 'reawx_bottle_fantacy', category = 'BOTTLE',
        aliases = { 'reawx_bottle_fantacy', 'zephyron_b' },
        eff_dead = { { dict = 'reawx_particle_fantasy', eff = 'reawx_particle_fantasy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'ZEPHYRON.png', audio = 'ZEPHYRON.mp3',
    },
    ['sharkz_bottle_halloween'] = {
        label = 'Halloween B', model = 'sharkz_bottle_halloween', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_halloween', 'halloween_b' },
        eff_dead = { { dict = 'sharkz_halloween_set', eff = 'sharkz_halloween_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_blood_effect', eff = 'sharkz_blood_effect', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'halloween.png', audio = 'halloween.mp3',
    },
    ['sharkz_bottle_poker'] = {
        label = 'Poker B', model = 'sharkz_bottle_poker', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_poker', 'poker_b' },
        eff_dead = { { dict = 'sharkz_poker_set', eff = 'sharkz_hit_poker', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_poker_set', eff = 'sharkz_effect_poker', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'poker.png', audio = 'poker.ogg',
    },
    ['coolkids_Sweet_bottle'] = {
        label = 'Sweet B', model = 'coolkids_Sweet_bottle', category = 'BOTTLE',
        aliases = { 'coolkids_sweet_bottle', 'sweet_b' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sweet', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'SWEET_screen.png', audio = 'sound_SWEET.mp3',
    },
    ['bbg_wp26_bottle'] = {
        label = 'Pink Pig B', model = 'bbg_wp26_bottle', category = 'BOTTLE',
        aliases = { 'bbg_wp26_bottle', 'pinkpig_b' },
        eff_dead = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.5 } },
        ptfx_bone = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy_star', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'pinkpig.png', audio = 'pinkpig.ogg',
    },
    ['gb_ponypur_bottle'] = {
        label = 'Pony B', model = 'gb_ponypur_bottle', category = 'BOTTLE',
        aliases = { 'gb_ponypur_bottle', 'pony_b' },
        eff_dead = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_5', bone = 57005, scale = 0.6, time = 800 } },
        screen = 'pony.png', audio = 'pony.mp3',
    },
    ['w_me_songkran_knife'] = {
        label = 'Water K', model = 'w_me_songkran_knife', category = 'BOTTLE',
        aliases = { 'w_me_songkran_knife', 'water_k' },
    },
    ['lazy_badbunnie_knife'] = {
        label = 'Bad Bunnie K', model = 'lazy_badbunnie_knife', category = 'BOTTLE',
        aliases = { 'lazy_badbunnie_knife', 'badbunnie_k' },
        eff_dead = { { dict = 'lazy_badbunnie', eff = 'lazy_badbunnie', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.08 } },
        screen = 'badbunny.png', audio = 'badbunny.mp3',
    },
    ['bbg_wp28_bottle'] = {
        label = 'Sea Summer B', model = 'bbg_wp28_bottle', category = 'BOTTLE',
        aliases = { 'bbg_wp28_bottle', 'seasummer_b' },
        eff_dead = { { dict = 'ar_bbg', eff = 'underthesea_kill', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'underthesea_bubble', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'sea.png', audio = 'sea.ogg',
    },
    ['sharkz_knife_darkwolf'] = {
        label = 'Dark Wolf K', model = 'sharkz_knife_darkwolf', category = 'BOTTLE',
        aliases = { 'sharkz_knife_darkwolf', 'darkwolf_k' },
        eff_dead = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_effect', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'darkwolf.png', audio = 'darkwolf.mp3',
    },
    ['w_me_bottle_stl_green'] = {
        label = 'GREEN B', model = 'w_me_bottle_stl_green', category = 'BOTTLE',
        aliases = { 'w_me_bottle_stl_green', 'green_b' },
        eff_dead = { { dict = 'stl_green', eff = 'stl_green', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.15 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'effect_energygreen', bone = 57005, scale = 0.5, time = 800 } },
        screen = 'green.png', audio = 'green.mp3',
    },
    ['sharkz_bottle_deepblue'] = {
        label = 'Deep Blue B', model = 'sharkz_bottle_deepblue', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_deepblue', 'deepblue_b' },
        eff_dead = { { dict = 'sharkz_deepblue_set', eff = 'sharkz_deepblue_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.6 } },
        ptfx_bone = { { dict = 'sharkz_deepblue_set', eff = 'shark_deepblue_effect', bone = 57005, scale = 0.2, time = 800 } },
        screen = 'deepblue.png', audio = 'deepblue.mp3',
    },
    ['coolkids_duckysummer_bottle'] = {
        label = 'Ducky Summer B', model = 'coolkids_duckysummer_bottle', category = 'BOTTLE',
        aliases = { 'coolkids_duckysummer_bottle', 'duckysummer_b' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'dsumer.png', audio = 'dsumer.mp3',
    },
    ['w_me_bottle_dds'] = {
        label = 'Lava B', model = 'w_me_bottle_dds', category = 'BOTTLE',
        aliases = { 'w_me_bottle_dds', 'lava_b' },
        eff_dead = { { dict = 'deands_efx_lv', eff = 'exp_air_deandesignstudio', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'deands_efx_lv', eff = 'deands_efx_lv11p', bone = 57005, scale = 1.5, time = 800 } },
        screen = 'lva.png', audio = 'lva.mp3',
    },
    ['coolkids_sanrio_bottle'] = {
        label = 'Sanrio B', model = 'coolkids_sanrio_bottle', category = 'BOTTLE',
        aliases = { 'coolkids_sanrio_bottle', 'sanrio_b' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'csro.png', audio = 'csro.mp3',
    },
    ['gb_bearx_bottle_black'] = {
        label = 'BearX Black B', model = 'gb_bearx_bottle_black', category = 'BOTTLE',
        aliases = { 'gb_bearx_bottle_black', 'bearxblack_b' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 800 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['gb_bearx_bottle_white'] = {
        label = 'BearX White B', model = 'gb_bearx_bottle_white', category = 'BOTTLE',
        aliases = { 'gb_bearx_bottle_white', 'bearxwhite_b' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 800 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['sharkz_dagger_greendragon'] = {
        label = 'Green Dragon D', model = 'sharkz_dagger_greendragon', category = 'BOTTLE',
        aliases = { 'sharkz_dagger_greendragon', 'greendragon_d' },
        eff_dead = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_hit_gdragon', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_effect_gdragon', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'gd.png', audio = 'gd.mp3',
    },
    ['gb_neko_bottle_black'] = {
        label = 'Neko Black B', model = 'gb_neko_bottle_black', category = 'BOTTLE',
        aliases = { 'gb_neko_bottle_black', 'nekoblack_b' },
        eff_dead = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'nekoblack.png', audio = 'nekosound.mp3',
    },
    ['gb_neko_bottle_white'] = {
        label = 'Neko White B', model = 'gb_neko_bottle_white', category = 'BOTTLE',
        aliases = { 'gb_neko_bottle_white', 'nekowhite_b' },
        eff_dead = { { dict = 'girlbossefx_nekowhite', eff = 'girlbossefx_nekowhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'nekowhite.png', audio = 'nekosound.mp3',
    },
    ['bbg_wp23_bottle'] = {
        label = 'Valentine B', model = 'bbg_wp23_bottle', category = 'BOTTLE',
        aliases = { 'bbg_wp23_bottle', 'valentine_b' },
        eff_dead = { { dict = 'ar_bbg', eff = 'cupidlover', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'heartspawn', bone = 57005, scale = 0.1, time = 800 } },
        screen = 'v26.png', audio = 'v26.mp3',
    },
    ['sharkz_bottle_white_tiger'] = {
        label = 'White Tiger B', model = 'sharkz_bottle_white_tiger', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_white_tiger', 'whitetiger_b' },
        eff_dead = { { dict = 'sharkz_whitetiger_set', eff = 'sharkz_whitetiger_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'sharkz_effect_whitetiger', eff = 'sharkz_effect_whitetiger', bone = 57005, scale = 1.0, time = 800 } },
        screen = 'wtg.png', audio = 'wtg.mp3',
    },
    ['sharkz_bottle_white_wolf'] = {
        label = 'White Wolf B', model = 'sharkz_bottle_white_wolf', category = 'BOTTLE',
        aliases = { 'sharkz_bottle_white_wolf', 'whitewolf_b' },
        eff_dead = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_hit_whitewolf', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_effect_whitewolf', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'wwolf.png', audio = 'wwolf.mp3',
    },
    ['coolkids_babythree_bottle'] = {
        label = 'Baby Three B', model = 'coolkids_babythree_bottle', category = 'BOTTLE',
        aliases = { 'coolkids_babythree_bottle', 'babythree_b' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'coolkids_efx_01_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'cbbt.png', audio = 'cbbt.mp3',
    },
    ['daffy_weapon_uk_bottle'] = {
        label = 'UK B', model = 'daffy_weapon_uk_bottle', category = 'BOTTLE',
        aliases = { 'daffy_weapon_uk_bottle', 'uk_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_uk', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'uk.png', audio = 'uk.mp3',
    },
    ['ohmmiwars_bottle_melody'] = {
        label = 'Melody B', model = 'ohmmiwars_bottle_melody', category = 'BOTTLE',
        aliases = { 'ohmmiwars_bottle_melody', 'melody_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_melody', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'melody.png', audio = 'melody.mp3',
    },
    ['daffy_weapon_minon_bottle'] = {
        label = 'Minion B', model = 'daffy_weapon_minon_bottle', category = 'BOTTLE',
        aliases = { 'daffy_weapon_minon_bottle', 'minion_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_minion', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'minion.png', audio = 'minion.mp3',
    },
    ['ohmmiwars_bottle_wednesday'] = {
        label = 'Wednesday B', model = 'ohmmiwars_bottle_wednesday', category = 'BOTTLE',
        aliases = { 'ohmmiwars_bottle_wednesday', 'wednesday_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_wd', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'wd.png', audio = 'wd.mp3',
    },
    ['daffy_demonslayer_bottle'] = {
        label = 'Demonslayer B', model = 'daffy_demonslayer_bottle', category = 'BOTTLE',
        aliases = { 'daffy_demonslayer_bottle', 'demonslayer_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_zenitsu', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'DEMONSLAYER.png', audio = 'DEMONSLAYER.mp3',
    },
    ['daffy_rich_bottle'] = {
        label = 'Rich B', model = 'daffy_rich_bottle', category = 'BOTTLE',
        aliases = { 'daffy_rich_bottle', 'rich_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_rich', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'rich.png', audio = 'rich.mp3',
    },
    ['rb_duckysplash_bottle'] = {
        label = 'Ducky Splash B', model = 'rb_duckysplash_bottle', category = 'BOTTLE',
        aliases = { 'rb_duckysplash_bottle', 'duckysplash_b' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_duckysplash', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['rb_winterfrost_black_bottle'] = {
        label = 'Winterfrost Black B', model = 'rb_winterfrost_black_bottle', category = 'BOTTLE',
        aliases = { 'rb_winterfrost_black_bottle', 'winterfrostblack_b' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['rb_winterfrost_white_bottle'] = {
        label = 'Winterfrost White B', model = 'rb_winterfrost_white_bottle', category = 'BOTTLE',
        aliases = { 'rb_winterfrost_white_bottle', 'winterfrostwhite_b' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 800 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['w_me_wbu_harajuku_bottle'] = {
        label = 'Harajuku B', model = 'w_me_wbu_harajuku_bottle', category = 'BOTTLE',
        aliases = { 'w_me_wbu_harajuku_bottle', 'harajuku_b' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'wbu_harajuku', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'harajuku.png', audio = 'harajuku.mp3',
    },
    ['ohmmiwars_bottle_squid'] = {
        label = 'Squidgame B', model = 'ohmmiwars_bottle_squid', category = 'BOTTLE',
        aliases = { 'ohmmiwars_bottle_squid', 'squidgame_b' },
        eff_dead = { { dict = 'daffy_squidgame', eff = 'daffy_squidgame', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'squidgame.png', audio = 'squidgame.mp3',
    },
    ['meow_buer_bottle'] = {
        label = 'Buer B', model = 'meow_buer_bottle', category = 'BOTTLE',
        aliases = { 'meow_buer_bottle', 'buer_b' },
    },
    ['w_me_knifeduck'] = {
        label = 'Duck K', model = 'w_me_knifeduck', category = 'BOTTLE',
        aliases = { 'w_me_knifeduck', 'duck_k' },
    },
    ['w_me_knifedog'] = {
        label = 'Doggy K', model = 'w_me_knifedog', category = 'BOTTLE',
        aliases = { 'w_me_knifedog', 'doggy_k' },
    },
    ['gb_kanjifang_knife'] = {
        label = 'Kanjifang K', model = 'gb_kanjifang_knife', category = 'BOTTLE',
        aliases = { 'gb_kanjifang_knife', 'kanjifang_k' },
    },
    ['orca_bottle'] = {
        label = 'Orca B', model = 'orca_bottle', category = 'BOTTLE',
        aliases = { 'orca_bottle', 'orca_b' },
    },
    ['wm_virex_knife'] = {
        label = 'Virex K', model = 'wm_virex_knife', category = 'BOTTLE',
        aliases = { 'wm_virex_knife', 'virex_k' },
        ptfx_bone = { { dict = 'wishme_virex', eff = 'wishme_virex', bone = 57005, scale = 0.05, time = 800 } },
    },
    ['wm_baldwin_knife'] = {
        label = 'Baldwin K', model = 'wm_baldwin_knife', category = 'BOTTLE',
        aliases = { 'wm_baldwin_knife', 'baldwin_k' },
        ptfx_bone = { { dict = 'handbaldwin', eff = 'handbaldwin', bone = 57005, scale = 0.1, time = 800 } },
    },
    ['daffy_chinese_set_bottle'] = {
        label = 'Chinese B', model = 'daffy_chinese_set_bottle', category = 'BOTTLE',
        aliases = { 'daffy_chinese_set_bottle', 'chinese_b' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_chinese', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'chinese.png', audio = 'chinese.mp3',
    },
}

-- ============================================================================
-- 2. WEAPON CATEGORIES
-- ============================================================================
local WeaponCategories = {
    ['POOLCUE'] = {
        GetHashKey('WEAPON_POOLCUE'), GetHashKey('WEAPON_POOLCUE_0'), GetHashKey('WEAPON_POOLCUE_1'),
        GetHashKey('WEAPON_POOLCUE_2'), GetHashKey('WEAPON_POOLCUE_3'), GetHashKey('WEAPON_POOLCUE_4'),
        GetHashKey('WEAPON_POOLCUE_5'), GetHashKey('WEAPON_POOLCUE0'), GetHashKey('WEAPON_POOLCUE1'),
        GetHashKey('WEAPON_POOLCUE2'), GetHashKey('WEAPON_POOLCUE3'), GetHashKey('WEAPON_POOLCUE4'),
        GetHashKey('WEAPON_POOLCUE5'), GetHashKey('WEAPON_POOLCUE_RENT'),
        GetHashKey('WEAPON_POOLCUE14DAY'), GetHashKey('WEAPON_POOLCUEWAR'),
    },
    ['BOTTLE'] = {
        GetHashKey('WEAPON_BOTTLE'), GetHashKey('WEAPON_BOTTLE_0'), GetHashKey('WEAPON_BOTTLE_1'),
        GetHashKey('WEAPON_BOTTLE_2'), GetHashKey('WEAPON_BOTTLE_3'), GetHashKey('WEAPON_BOTTLE_4'),
        GetHashKey('WEAPON_BOTTLE_5'), GetHashKey('WEAPON_BOTTLE0'), GetHashKey('WEAPON_BOTTLE1'),
        GetHashKey('WEAPON_BOTTLE2'), GetHashKey('WEAPON_BOTTLE3'), GetHashKey('WEAPON_BOTTLE4'),
        GetHashKey('WEAPON_BOTTLE5'), GetHashKey('WEAPON_DAGGER'), GetHashKey('WEAPON_KNIFE'),
        GetHashKey('WEAPON_KNIFE_1'), GetHashKey('WEAPON_KNIFE_2'), GetHashKey('WEAPON_KNIFE_3'),
        GetHashKey('WEAPON_KNIFE_4'), GetHashKey('WEAPON_SWITCHBLADE'),
        GetHashKey('WEAPON_MACHETE'), GetHashKey('WEAPON_MACHETE_0'), GetHashKey('WEAPON_MACHETE_1'),
        GetHashKey('WEAPON_MACHETE_2'), GetHashKey('WEAPON_MACHETE_3'),
        GetHashKey('WEAPON_MACHETTE_0'), GetHashKey('WEAPON_MACHETTE_1'),
        GetHashKey('WEAPON_MACHETTE_2'), GetHashKey('WEAPON_MACHETTE_3'),
        GetHashKey('WEAPON_KNUCKLEDUSTER'), GetHashKey('WEAPON_KNUCKLE'),
        GetHashKey('WEAPON_KNUCKLE_0'), GetHashKey('WEAPON_KNUCKLE_1'),
        GetHashKey('WEAPON_KNUCKLE_2'), GetHashKey('WEAPON_KNUCKLE_3'),
    },
}

-- ============================================================================
-- 3. HELPERS
-- ============================================================================
local function buildComponentHashes()
    for _, s in pairs(MasterSkins) do
        allKnownComponentHashes[GetHashKey(s.model)] = true
        allKnownComponentHashes[GetHashKey(string.upper(s.model))] = true
        allKnownComponentHashes[GetHashKey(string.lower(s.model))] = true
        allKnownComponentHashes[GetHashKey("COMPONENT_" .. string.upper(s.model))] = true
    end
    if Config and type(Config.Weapon) == 'table' then
        for skinName, _ in pairs(Config.Weapon) do
            allKnownComponentHashes[GetHashKey(skinName)] = true
            allKnownComponentHashes[GetHashKey(string.upper(skinName))] = true
        end
    end
    if Config and Config['WEAPON_SKIN'] then
        for skinName, data in pairs(Config['WEAPON_SKIN']) do
            local model = data.MODEL or skinName
            allKnownComponentHashes[GetHashKey(model)] = true
            allKnownComponentHashes[GetHashKey(string.upper(model))] = true
            if not MasterSkins[skinName] then
                local cat = 'POOLCUE'
                local lower = string.lower(skinName)
                if lower:find("bottle") or lower:find("knife") or lower:find("dagger") or lower:find("machete") or lower:find("knuckle") then cat = 'BOTTLE' end
                MasterSkins[skinName] = {
                    label = data.SKIN_LABEL or skinName, model = model, category = cat,
                    aliases = { string.lower(skinName) },
                }
            end
        end
    end
end

local function getCategoryFromWeaponHash(weaponHash)
    for cat, hashes in pairs(WeaponCategories) do
        for _, h in ipairs(hashes) do
            if h == weaponHash then return cat end
        end
    end
    return 'OTHER'
end

local function findSkinData(query, currentWeaponCategory)
    if not query or query == '' then return nil, nil end
    local q = string.lower(query:gsub('^%s*(.-)%s*$', '%1'))
    if MasterSkins[q] then return q, MasterSkins[q] end
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
        if string.find(string.lower(k), q, 1, true) or string.find(string.lower(v.model), q, 1, true) then
            return k, v
        end
    end
    return nil, nil
end

local function saveSkin(key, skinKey)
    local kvpKey = ("homeskin_%s"):format(tostring(key))
    if not skinKey or skinKey == 'default' or skinKey == '' then
        DeleteResourceKvp(kvpKey)
        equippedSkins[key] = nil
    else
        SetResourceKvp(kvpKey, tostring(skinKey))
        equippedSkins[key] = skinKey
    end
end

local function loadSavedSkin(key)
    local val = GetResourceKvpString(("homeskin_%s"):format(tostring(key)))
    if val and val ~= '' and val ~= 'default' then return val end
    return nil
end

-- ============================================================================
-- 4. PROP & COMPONENT ENGINE
-- ============================================================================
local function removeAllSkinComponents(ped, weaponHash)
    if not ped or not DoesEntityExist(ped) or weaponHash == 0 then return end
    for compHash in pairs(allKnownComponentHashes) do
        if HasPedGotWeaponComponent(ped, weaponHash, compHash) then
            RemoveWeaponComponentFromPed(ped, weaponHash, compHash)
        end
    end
end

local function removeSkinProp()
    if currentPropEntity and DoesEntityExist(currentPropEntity) then
        SetEntityAsMissionEntity(currentPropEntity, true, true)
        DetachEntity(currentPropEntity, true, true)
        DeleteEntity(currentPropEntity)
        currentPropEntity = nil
        currentPropModel = nil
    end
    SetPedCurrentWeaponVisible(PlayerPedId(), true, false, false, false)
end

local function attachSkinProp(ped, modelName, category)
    if not ped or not DoesEntityExist(ped) or not modelName then return false end
    if currentPropEntity and DoesEntityExist(currentPropEntity) and currentPropModel == modelName then
        SetPedCurrentWeaponVisible(ped, false, false, false, false)
        return true
    end
    removeSkinProp()
    local modelHash = GetHashKey(modelName)
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.lower(modelName)) end
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.upper(modelName)) end
    RequestModel(modelHash)
    local deadline = GetGameTimer() + 800
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end
    local boneIndex = GetPedBoneIndex(ped, 57005)
    local pCoords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, pCoords.x, pCoords.y, pCoords.z, true, true, false)
    if DoesEntityExist(prop) then
        SetEntityCollision(prop, false, false)
        SetEntityInvincible(prop, true)
        local cfg = (Config and Config.WeaponPosition and Config.WeaponPosition[category == 'POOLCUE' and 'POOL' or category])
                 or { Pos = { x = 0.080, y = -0.025, z = -0.021 }, Rot = { x = -85.0, y = -16.0, z = -23.0 } }
        local px = (cfg.Pos and cfg.Pos.x) or 0.080
        local py = (cfg.Pos and cfg.Pos.y) or -0.025
        local pz = (cfg.Pos and cfg.Pos.z) or -0.021
        local rx = (cfg.Rot and cfg.Rot.x) or -85.0
        local ry = (cfg.Rot and cfg.Rot.y) or -16.0
        local rz = (cfg.Rot and cfg.Rot.z) or -23.0
        AttachEntityToEntity(prop, ped, boneIndex, px, py, pz, rx, ry, rz, true, true, false, true, 1, true)
        currentPropEntity = prop
        currentPropModel = modelName
        SetModelAsNoLongerNeeded(modelHash)
        SetPedCurrentWeaponVisible(ped, false, false, false, false)
        return true
    end
    return false
end

local function applySkinModel(ped, curWeapon, modelName, category)
    if not ped or not DoesEntityExist(ped) or curWeapon == 0 or not modelName then return false end
    local primaryHash = GetHashKey(modelName)
    local upperHash = GetHashKey(string.upper(modelName))
    local compHash = GetHashKey("COMPONENT_" .. string.upper(modelName))
    GiveWeaponComponentToPed(ped, curWeapon, primaryHash)
    GiveWeaponComponentToPed(ped, curWeapon, upperHash)
    GiveWeaponComponentToPed(ped, curWeapon, compHash)
    if HasPedGotWeaponComponent(ped, curWeapon, primaryHash)
    or HasPedGotWeaponComponent(ped, curWeapon, upperHash)
    or HasPedGotWeaponComponent(ped, curWeapon, compHash) then
        removeSkinProp()
        return true
    else
        return attachSkinProp(ped, modelName, category)
    end
end

-- ============================================================================
-- 5. PTFX & KILL EFFECTS
-- ============================================================================
local function ensurePtfxLoaded(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local deadline = GetGameTimer() + 350
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function triggerHandAura(ped, auraList)
    if not ped or not DoesEntityExist(ped) or not auraList then return end
    for _, aura in ipairs(auraList) do
        local dict = aura.dict or aura.Dict
        local eff = aura.eff or aura.Eff
        local bone = aura.bone or aura.Bone or 57005
        local scale = tonumber(aura.scale or aura.Scale) or 0.8
        local boneIndex = GetPedBoneIndex(ped, bone)
        if dict and eff then
            local loaded = ensurePtfxLoaded(dict)
            if not loaded and aura.fallback_dict then
                dict = aura.fallback_dict; eff = aura.fallback_eff; loaded = ensurePtfxLoaded(dict)
            end
            if loaded and boneIndex ~= -1 then
                UseParticleFxAsset(dict)
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedOnPedBone(eff, ped,
                    aura.x or 0.12, aura.y or 0.0, aura.z or 0.0,
                    aura.rx or 0.0, aura.ry or 0.0, aura.rz or 65.0,
                    boneIndex, scale, false, false, false)
            end
        end
    end
end

local function triggerKillExplosion(victim, effList)
    if not victim or not DoesEntityExist(victim) or not effList then return end
    local pedCoords = GetEntityCoords(victim)
    local targetPos = pedCoords + vector3(0.0, 0.0, 0.65)
    local headBone = GetPedBoneIndex(victim, 31086)
    if headBone ~= -1 then
        local bPos = GetWorldPositionOfEntityBone(victim, headBone)
        if bPos and #(bPos - pedCoords) < 3.0 and bPos.z > 0.0 then targetPos = bPos end
    end
    for _, effect in ipairs(effList) do
        local dict = effect.dict or effect.DICT
        local eff = effect.eff or effect.EFF
        local scale = tonumber(effect.scale or effect.SCALE) or 1.0
        if dict and eff then
            local loaded = ensurePtfxLoaded(dict)
            if not loaded and effect.fallback_dict then
                dict = effect.fallback_dict; eff = effect.fallback_eff; loaded = ensurePtfxLoaded(dict)
            end
            if loaded then
                UseParticleFxAsset(dict)
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedAtCoord(eff, targetPos.x, targetPos.y, targetPos.z, 0.0, 0.0, 0.0, scale, false, false, false)
                UseParticleFxAsset(dict)
                UseParticleFxAssetNextCall(dict)
                StartNetworkedParticleFxNonLoopedAtCoord(eff, targetPos.x, targetPos.y, targetPos.z, 0.0, 0.0, 0.0, scale, false, false, false)
            end
        end
    end
end

-- ============================================================================
-- 6. ANTI-DETECT HOOKS
-- ============================================================================
local origHasPedGot = HasPedGotWeaponComponent
local origRemoveComp = RemoveWeaponComponentFromPed
local origTSE = TriggerServerEvent

HasPedGotWeaponComponent = function(ped, weapon, component)
    if ped == PlayerPedId() and allKnownComponentHashes[component] then
        local cat = getCategoryFromWeaponHash(weapon)
        local skinKey = equippedSkins[weapon] or equippedSkins[cat]
        if skinKey then
            local sData = MasterSkins[skinKey]
            if sData then
                local skinHash = GetHashKey(sData.model)
                if component == skinHash or component == GetHashKey(string.upper(sData.model))
                or component == GetHashKey("COMPONENT_" .. string.upper(sData.model)) then
                    return true
                end
            end
        end
    end
    return origHasPedGot(ped, weapon, component)
end

RemoveWeaponComponentFromPed = function(ped, weapon, component)
    if ped == PlayerPedId() and allKnownComponentHashes[component] then
        local cat = getCategoryFromWeaponHash(weapon)
        local skinKey = equippedSkins[weapon] or equippedSkins[cat]
        if skinKey then
            local sData = MasterSkins[skinKey]
            if sData then
                local skinHash = GetHashKey(sData.model)
                if component == skinHash or component == GetHashKey(string.upper(sData.model))
                or component == GetHashKey("COMPONENT_" .. string.upper(sData.model)) then
                    return
                end
            end
        end
    end
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
-- 7. CORE WATCHER THREAD
-- ============================================================================
CreateThread(function()
    buildComponentHashes()
    for cat in pairs(WeaponCategories) do
        local saved = loadSavedSkin(cat)
        if saved then equippedSkins[cat] = saved end
    end

    local lastWeapon = 0
    local nextAuraTime = 0
    local deadVictims = {}

    CreateThread(function()
        while true do
            local ped = PlayerPedId()
            local curWeapon = GetSelectedPedWeapon(ped)
            if curWeapon ~= 0 and curWeapon ~= GetHashKey('WEAPON_UNARMED') and not IsEntityDead(ped) then
                local cat = getCategoryFromWeaponHash(curWeapon)
                local skinKey = equippedSkins[curWeapon] or equippedSkins[cat]
                if skinKey and skinKey ~= 'default' then
                    local sData = MasterSkins[skinKey]
                    local modelName = (sData and sData.model) or skinKey
                    if curWeapon ~= lastWeapon or (not currentPropEntity and not HasPedGotWeaponComponent(ped, curWeapon, GetHashKey(modelName))) then
                        removeAllSkinComponents(ped, curWeapon)
                        applySkinModel(ped, curWeapon, modelName, cat)
                        lastWeapon = curWeapon
                    end
                    if currentPropEntity and DoesEntityExist(currentPropEntity) then
                        SetPedCurrentWeaponVisible(ped, false, false, false, false)
                    end
                    local auraList = sData and sData.ptfx_bone
                    if auraList and #auraList > 0 then
                        local now = GetGameTimer()
                        if now >= nextAuraTime then
                            triggerHandAura(ped, auraList)
                            nextAuraTime = now + (auraList[1].time or 800)
                        end
                    end
                else
                    if curWeapon ~= lastWeapon then removeSkinProp(); lastWeapon = curWeapon end
                end
            else
                if lastWeapon ~= 0 then removeSkinProp(); lastWeapon = 0 end
            end
            Wait(100)
        end
    end)

    AddEventHandler('gameEventTriggered', function(eventName, data)
        if eventName ~= 'CEventNetworkEntityDamage' then return end
        local victim, attacker = data[1], data[2]
        local fatal = (data[4] == 1 or data[6] == 1)
        local myPed = PlayerPedId()
        if not victim or victim == 0 or victim == myPed then return end
        if attacker ~= myPed then
            if not (GetPedSourceOfDeath(victim) == myPed or HasEntityBeenDamagedByEntity(victim, myPed, true)) then return end
        end
        local curWeapon = GetSelectedPedWeapon(myPed)
        local cat = getCategoryFromWeaponHash(curWeapon)
        local skinKey = equippedSkins[curWeapon] or equippedSkins[cat]
        if not skinKey then return end
        local isDead = fatal or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0
        if isDead then
            local now = GetGameTimer()
            if not deadVictims[victim] or (now - deadVictims[victim] >= 2000) then
                deadVictims[victim] = now
                local sData = MasterSkins[skinKey]
                if sData and sData.eff_dead then
                    triggerKillExplosion(victim, sData.eff_dead)
                end
                if sData and (sData.screen or sData.audio) then
                    SendNUIMessage({ action = "screen", screen = sData.screen or "", sound = sData.audio or "", volum = 0.5 })
                end
            end
        end
    end)
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then removeSkinProp() end
end)

-- ============================================================================
-- 8. COMMANDS: /home <skinname> | /homeoff | /homelist
-- ============================================================================
RegisterCommand('home', function(source, args)
    buildComponentHashes()
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    local curCategory = getCategoryFromWeaponHash(curWeapon)
    local inputName = args[1]

    if not inputName or inputName == '' then
        print("^3[HOME]^7 Usage: /home <skinname> | /homeoff | /homelist")
        return
    end

    local lowerInput = string.lower(inputName)
    if lowerInput == 'off' or lowerInput == 'default' or lowerInput == 'remove' or lowerInput == '0' then
        ExecuteCommand('homeoff')
        return
    end

    local skinKey, skinData = findSkinData(inputName, curCategory)
    if not skinKey or not skinData then
        print(("^1[HOME]^7 Skin not found: '%s' - use /homelist"):format(inputName))
        return
    end

    saveSkin(curCategory, skinKey)
    saveSkin(skinData.category, skinKey)
    if curWeapon ~= 0 and curWeapon ~= GetHashKey('WEAPON_UNARMED') then
        saveSkin(curWeapon, skinKey)
        removeAllSkinComponents(ped, curWeapon)
        applySkinModel(ped, curWeapon, skinData.model, skinData.category)
    end
    print(("^2[HOME]^7 Equipped: ^6%s^7 (%s)"):format(skinData.label, skinKey))
end, false)

RegisterCommand('homeoff', function()
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    local curCategory = getCategoryFromWeaponHash(curWeapon)
    saveSkin(curCategory, 'default')
    for cat in pairs(WeaponCategories) do saveSkin(cat, 'default') end
    if curWeapon ~= 0 and curWeapon ~= GetHashKey('WEAPON_UNARMED') then
        saveSkin(curWeapon, 'default')
        removeAllSkinComponents(ped, curWeapon)
    end
    removeSkinProp()
    print("^1[HOME]^7 Skin removed.")
end, false)

RegisterCommand('homelist', function()
    local poolSkins, bottleSkins = {}, {}
    for k, v in pairs(MasterSkins) do
        if v.category == 'POOLCUE' then poolSkins[#poolSkins+1] = k
        elseif v.category == 'BOTTLE' then bottleSkins[#bottleSkins+1] = k
        end
    end
    table.sort(poolSkins)
    table.sort(bottleSkins)
    print("^2========== POOLCUE SKINS (" .. #poolSkins .. ") ==========^7")
    for _, name in ipairs(poolSkins) do
        local s = MasterSkins[name]
        local fx = (s.eff_dead and #s.eff_dead > 0) and "^2FX^7" or ""
        local hand = (s.ptfx_bone and #s.ptfx_bone > 0) and "^3+HAND^7" or ""
        print(("  ^6%-40s^7 (%s) %s %s"):format(name, s.label, fx, hand))
    end
    print("^2========== BOTTLE/KNIFE SKINS (" .. #bottleSkins .. ") ==========^7")
    for _, name in ipairs(bottleSkins) do
        local s = MasterSkins[name]
        local fx = (s.eff_dead and #s.eff_dead > 0) and "^2FX^7" or ""
        local hand = (s.ptfx_bone and #s.ptfx_bone > 0) and "^3+HAND^7" or ""
        print(("  ^6%-40s^7 (%s) %s %s"):format(name, s.label, fx, hand))
    end
    print("^2==============================================^7")
    print("^3[HOME]^7 Use: /home <skinname> | /homeoff to remove")
end, false)

print(("^2[%s]^7 Loaded! /home <skin> | /homeoff | /homelist"):format(SCRIPT_NAME))
