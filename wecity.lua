-- ============================================================================
-- AR_WEAPONSKIN: Hybrid Skin Engine (Component & Prop Auto-Attacher)
-- คำสั่ง: /homelist | /home [ชื่อสกิน] | /homeoff
-- Hybrid: ลอง GTA Component ก่อน → ถ้าไม่ได้ spawn Prop แปะมือแทน
-- KVP Storage: บันทึกสกินถาวรฝั่ง client
-- Kill Effect + NUI screen/sound เมื่อตีคนตาย
-- ============================================================================

-- ── State ──────────────────────────────────────────────────────
local equippedSkins       = {}   -- [category] = skinKey
local currentPropEntity   = nil
local currentPropModel    = nil
local allComponentHashes  = {}   -- เก็บ hash ทุกโมเดลเพื่อถอดได้ครบ

-- ── Master Database ────────────────────────────────────────────
local MasterSkins = {
    -- ===================== POOLCUE =====================
    ['sharkz_poolcue_starhero'] = {
        label = 'Star Hero', model = 'sharkz_poolcue_starhero', category = 'POOLCUE',
        aliases = { 'hero', 'starhero', 'poolcue_starhero' },
        eff_dead = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_hit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_effect', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'hero.png', audio = 'hero.mp3',
    },
    ['sharkz_poolcue_8bit'] = {
        label = '8BIT', model = 'sharkz_poolcue_8bit', category = 'POOLCUE',
        aliases = { '8bit', 'poolcue_8bit' },
        eff_dead = { { dict = 'sharkz_8bit_set', eff = 'sharkz_hit_8bit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_8bit_set', eff = 'sharkz_effect_8bit', bone = 57005, scale = 0.3, y = 0.05, rz = 60.0, time = 50 } },
        screen = '8bit.png', audio = '8bit.mp3',
    },
    ['wishme_momo_poolcue'] = {
        label = 'Momo', model = 'wishme_momo_poolcue', category = 'POOLCUE',
        aliases = { 'momo', 'wishme_momo' },
        eff_dead = { { dict = 'whitme_momo_efx', eff = 'scr_withme_firework_starburst', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'whitme_momo_efx', eff = 'scr_whitmemomo_beast_vanish', bone = 57005, scale = 0.1, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'momo.png', audio = 'momo.mp3',
    },
    ['rb_swagblack_poolcue'] = {
        label = 'Swag Black', model = 'rb_swagblack_poolcue', category = 'POOLCUE',
        aliases = { 'swag_b', 'swagblack' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = {
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, y = 0.05, rz = 60.0, time = 900 },
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_2', bone = 57005, scale = 1.0, y = 0.05, rz = 60.0, time = 900 },
        },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['rb_swagwhite_poolcue'] = {
        label = 'Swag White', model = 'rb_swagwhite_poolcue', category = 'POOLCUE',
        aliases = { 'swag_w', 'swagwhite' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = {
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, y = 0.05, rz = 60.0, time = 900 },
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_2', bone = 57005, scale = 1.0, y = 0.05, rz = 60.0, time = 900 },
        },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['sharkz_poolcue_phx_firestorm'] = {
        label = 'Phoenix', model = 'sharkz_poolcue_phx_firestorm', category = 'POOLCUE',
        aliases = { 'phoenix', 'poolcue_phx_firestorm' },
        eff_dead = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_effect', bone = 57005, scale = 0.8, y = 0.05, rz = 60.0, time = 20 } },
        screen = 'phoenix.png', audio = 'phoenix.mp3',
    },
    ['cryo_poolcue'] = {
        label = 'CRYO', model = 'cryo_poolcue', category = 'POOLCUE',
        aliases = { 'cryo_pool', 'cryo' },
    },
    ['x_me_poolcue_anubis'] = {
        label = 'Anubis', model = 'x_me_poolcue_anubis', category = 'POOLCUE',
        aliases = { 'anubis' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['w_me_poolcueks_dds'] = {
        label = 'Kitsune', model = 'w_me_poolcueks_dds', category = 'POOLCUE',
        aliases = { 'kitsune', 'poolcueks_dds' },
        eff_dead = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1v1_po', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1hxnd_po', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'kitsune.png', audio = 'kitsune.mp3',
    },
    ['wm_elys_pool'] = {
        label = 'ELYS', model = 'wm_elys_pool', category = 'POOLCUE',
        aliases = { 'elys' },
        eff_dead = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys_hfx', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'elys.png', audio = 'elys.mp3',
    },
    ['w_me_poolcue_eden'] = {
        label = 'Eden', model = 'w_me_poolcue_eden', category = 'POOLCUE',
        aliases = { 'eden', 'poolcue_eden' },
        eff_dead = { { dict = 'eden', eff = 'eden', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        screen = 'eden.png', audio = 'eden.mp3',
    },
    ['lazy_cutestar_poolcue'] = {
        label = 'Bunny Lazy', model = 'lazy_cutestar_poolcue', category = 'POOLCUE',
        aliases = { 'lazy', 'bunnylazy', 'cutestar' },
        eff_dead = { { dict = 'ar_effect', eff = 'cutestar', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        screen = 'cutestar.png', audio = 'cutestar.mp3',
    },
    ['sharkz_poolcue_darkwolf'] = {
        label = 'Dark Wolf', model = 'sharkz_poolcue_darkwolf', category = 'POOLCUE',
        aliases = { 'darkwolf', 'poolcue_darkwolf' },
        eff_dead = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_effect', bone = 57005, scale = 0.1, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'darkwolf.png', audio = 'darkwolf.mp3',
    },
    ['w_me_poolcue_stl_green'] = {
        label = 'Green', model = 'w_me_poolcue_stl_green', category = 'POOLCUE',
        aliases = { 'green', 'poolcue_stl_green' },
        eff_dead = { { dict = 'stl_green', eff = 'stl_green', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.15 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'effect_energygreen', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'green.png', audio = 'green.mp3',
    },
    ['sharkz_poolcue_zap'] = {
        label = 'ZAP', model = 'sharkz_poolcue_zap', category = 'POOLCUE',
        aliases = { 'zap', 'poolcue_zap' },
        eff_dead = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_effect', bone = 57005, scale = 0.8, y = 0.05, rz = 60.0, time = 20 } },
        screen = 'zap.png', audio = 'zap.mp3',
    },
    ['w_me_zyndear_toothless_poolcue_white'] = {
        label = 'Toothless', model = 'w_me_zyndear_toothless_poolcue_white', category = 'POOLCUE',
        aliases = { 'toothless', 'zyndear_toothless_poolcue_white' },
        eff_dead = { { dict = 'ar_effect', eff = 'killtoothlesswhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'killtoothlesswhite', bone = 57005, scale = 0.1, y = 0.05, rz = 60.0, time = 100 } },
        audio = 'jingle.mp3',
    },
    ['lazy_fox_poolcue'] = {
        label = 'Fox Lazy', model = 'lazy_fox_poolcue', category = 'POOLCUE',
        aliases = { 'lazyfox', 'foxlazy', 'fox' },
        eff_dead = { { dict = 'ar_effect', eff = 'foxfx', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.25 } },
        screen = 'lazyfox.png', audio = 'lazyfox.mp3',
    },
    ['w_me_poolcueredfire'] = {
        label = 'Fire', model = 'w_me_poolcueredfire', category = 'POOLCUE',
        aliases = { 'fire', 'poolcueredfire' },
        eff_dead = { { dict = 'ptfx_fireredsmoke', eff = 'ptfx_fireredsmoke', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'redfire', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'vdframefire.png', audio = 'vdfirered.mp3',
    },
    ['things_freebunny_poolcue'] = {
        label = 'Bunny', model = 'things_freebunny_poolcue', category = 'POOLCUE',
        aliases = { 'bunny', 'freebunny' },
        eff_dead = { { dict = 'things_freeskinbunny', eff = 'things_freeskinbunny', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        screen = 'free_bunny.png', audio = 'free_bunny.mp3',
    },
    ['devilcute_poolcue'] = {
        label = 'Devilcute', model = 'devilcute_poolcue', category = 'POOLCUE',
        aliases = { 'devcu_pool', 'devilcute' },
        eff_dead = { { dict = 'devilcute_hit_effects', eff = 'magicwarp', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        screen = 'devilcute.png', audio = 'devilcute.mp3',
    },
    ['reawx_pool_fantacy'] = {
        label = 'Zephyron', model = 'reawx_pool_fantacy', category = 'POOLCUE',
        aliases = { 'zep_pool', 'zephyron' },
        eff_dead = { { dict = 'reawx_particle_fantasy', eff = 'reawx_particle_fantasy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'ZEPHYRON.png', audio = 'ZEPHYRON.mp3',
    },
    ['bbg_wp26_poolcue'] = {
        label = 'Pink Pig', model = 'bbg_wp26_poolcue', category = 'POOLCUE',
        aliases = { 'pigpink_pool', 'pinkpig', 'wp26' },
        eff_dead = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.5 } },
        ptfx_bone = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy_star', bone = 57005, scale = 0.2, time = 100 } },
        screen = 'pinkpig.png', audio = 'pinkpig.ogg',
    },
    ['wishme_poolcue_chromium'] = {
        label = 'Chromium', model = 'wishme_poolcue_chromium', category = 'POOLCUE',
        aliases = { 'chromium' },
        eff_dead = { { dict = 'weapon_wishme', eff = 'wishme', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.1 } },
        ptfx_bone = { { dict = 'weapon_wishme', eff = 'wishme', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'wishme_kill.png', audio = 'wishme_kill.mp3',
    },
    ['w_me_songkran_poolcue'] = {
        label = 'Water', model = 'w_me_songkran_poolcue', category = 'POOLCUE',
        aliases = { 'water', 'songkran' },
    },
    ['lazy_badbunnie_poolcue'] = {
        label = 'Bad Bunnie', model = 'lazy_badbunnie_poolcue', category = 'POOLCUE',
        aliases = { 'badbunie', 'badbunnie' },
        eff_dead = { { dict = 'lazy_badbunnie', eff = 'lazy_badbunnie', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.08 } },
        screen = 'badbunny.png', audio = 'badbunny.mp3',
    },
    ['gb_ponypink_poolcue'] = {
        label = 'Ponybunny Pink', model = 'gb_ponypink_poolcue', category = 'POOLCUE',
        aliases = { 'pony_p', 'ponybunnypink', 'ponypink' },
        eff_dead = {
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_1', scale = 0.2 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_2', scale = 0.11 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_3', scale = 0.6 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_4', scale = 0.6 },
        },
        ptfx_bone = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_5', bone = 57005, scale = 0.6, time = 100 } },
        screen = 'pony.png', audio = 'pony.mp3',
    },
    ['gb_ponyyell_poolcue'] = {
        label = 'Ponybunny Yell', model = 'gb_ponyyell_poolcue', category = 'POOLCUE',
        aliases = { 'pony_y', 'ponybunnyyell', 'ponyyell' },
        eff_dead = {
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_1', scale = 0.2 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_2', scale = 0.11 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_3', scale = 0.6 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_4', scale = 0.6 },
        },
        ptfx_bone = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_5', bone = 57005, scale = 0.6, time = 100 } },
        screen = 'pony.png', audio = 'pony.mp3',
    },
    ['bbg_wp28_poolcue'] = {
        label = 'Sea Summer', model = 'bbg_wp28_poolcue', category = 'POOLCUE',
        aliases = { 'sea', 'seasummer', 'wp28' },
        eff_dead = {
            { dict = 'ar_bbg', eff = 'underthesea_kill', scale = 0.4 },
            { dict = 'ar_bbg', eff = 'underthesea_spawn', scale = 0.1 },
        },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'underthesea_bubble', bone = 1, scale = 0.3, time = 500 } },
        screen = 'sea.png', audio = 'sea.ogg',
    },
    ['sharkz_poolcue_deepblue'] = {
        label = 'Deep Blue', model = 'sharkz_poolcue_deepblue', category = 'POOLCUE',
        aliases = { 'db', 'deepblue', 'poolcue_deepblue' },
        eff_dead = { { dict = 'sharkz_deepblue_set', eff = 'sharkz_deepblue_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.6 } },
        ptfx_bone = { { dict = 'sharkz_deepblue_set', eff = 'shark_deepblue_effect', bone = 57005, scale = 0.2, time = 100 } },
        screen = 'deepblue.png', audio = 'deepblue.mp3',
    },
    ['coolkids_duckysummer_poolcue'] = {
        label = 'Ducky Summer', model = 'coolkids_duckysummer_poolcue', category = 'POOLCUE',
        aliases = { 'dsumer', 'duckysummer' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', bone = 57005, scale = 0.1, time = 100 } },
        screen = 'dsumer.png', audio = 'dsumer.mp3',
    },
    ['sharkz_poolcue_poker'] = {
        label = 'Poker', model = 'sharkz_poolcue_poker', category = 'POOLCUE',
        aliases = { 'poker', 'poolcue_poker' },
        eff_dead = { { dict = 'sharkz_poker_set', eff = 'sharkz_hit_poker', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_poker_set', eff = 'sharkz_effect_poker', bone = 57005, scale = 0.2, time = 100 } },
        screen = 'poker.png', audio = 'poker.ogg',
    },
    ['coolkids_sanrio_poolcue'] = {
        label = 'Sanrio', model = 'coolkids_sanrio_poolcue', category = 'POOLCUE',
        aliases = { 'sanrio' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', bone = 57005, scale = 0.1, time = 100 } },
        screen = 'csro.png', audio = 'csro.mp3',
    },
    ['gb_bearx_poolcue_white'] = {
        label = 'BearX White', model = 'gb_bearx_poolcue_white', category = 'POOLCUE',
        aliases = { 'bearx_w', 'bearxwhite' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 100 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['gb_bearx_poolcue_black'] = {
        label = 'BearX Black', model = 'gb_bearx_poolcue_black', category = 'POOLCUE',
        aliases = { 'bearx_b', 'bearxblack' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 100 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['sharkz_poolcue_greendragon'] = {
        label = 'Green Dragon', model = 'sharkz_poolcue_greendragon', category = 'POOLCUE',
        aliases = { 'gd', 'greendragon', 'poolcue_greendragon' },
        eff_dead = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_hit_gdragon', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_effect_gdragon', bone = 57005, scale = 1.0, time = 10 } },
        screen = 'gd.png', audio = 'gd.mp3',
    },
    ['sharkz_poolcue_halloween'] = {
        label = 'Halloween', model = 'sharkz_poolcue_halloween', category = 'POOLCUE',
        aliases = { 'halloween', 'halloweens', 'poolcue_halloween' },
        eff_dead = { { dict = 'sharkz_halloween_set', eff = 'sharkz_halloween_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_blood_effect', eff = 'sharkz_blood_effect', bone = 57005, scale = 1.0, time = 10 } },
        screen = 'halloween.png', audio = 'halloween.mp3',
    },
    ['rb_duckysplash_poolcue'] = {
        label = 'Ducky Splash', model = 'rb_duckysplash_poolcue', category = 'POOLCUE',
        aliases = { 'duckysplash' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_duckysplash', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['rb_luvteddy_blue_poolcue'] = {
        label = 'Luv Teddy Blue', model = 'rb_luvteddy_blue_poolcue', category = 'POOLCUE',
        aliases = { 'luv_b', 'luvteddyblue', 'luvteddy_blue' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['rb_luvteddy_pink_poolcue'] = {
        label = 'Luv Teddy Pink', model = 'rb_luvteddy_pink_poolcue', category = 'POOLCUE',
        aliases = { 'luv_p', 'luvteddypink', 'luvteddy_pink' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['rb_winterfrost_black_poolcue'] = {
        label = 'Winterfrost Black', model = 'rb_winterfrost_black_poolcue', category = 'POOLCUE',
        aliases = { 'winter_black', 'winterfrostblack' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 50 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['rb_winterfrost_white_poolcue'] = {
        label = 'Winterfrost White', model = 'rb_winterfrost_white_poolcue', category = 'POOLCUE',
        aliases = { 'winter_white', 'winterfrostwhite' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 50 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['w_me_wbu_harajuku_poolcue'] = {
        label = 'Harajuku', model = 'w_me_wbu_harajuku_poolcue', category = 'POOLCUE',
        aliases = { 'harajuku', 'wbu_harajuku' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'wbu_harajuku', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'harajuku.png', audio = 'harajuku.mp3',
    },
    ['ohmmiwars_poolcue_squid'] = {
        label = 'Squidgame', model = 'ohmmiwars_poolcue_squid', category = 'POOLCUE',
        aliases = { 'squid', 'squidgame', 'poolcue_squid' },
        eff_dead = { { dict = 'daffy_squidgame', eff = 'daffy_squidgame', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'squidgame.png', audio = 'squidgame.mp3',
    },
    ['COMPONENT_POOL_CRYBUNNY'] = {
        label = 'Crybunny', model = 'COMPONENT_POOL_CRYBUNNY', category = 'POOLCUE',
        aliases = { 'crybunny' },
        eff_dead = { { dict = 'zyndea_wepfx_crybunny_fx', eff = 'zyndea_wepfx_crybunny_fx', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'crybunnykill.png', audio = 'crybunnykill.mp3',
    },
    ['daffy_weapon_uk_poolcue'] = {
        label = 'UK', model = 'daffy_weapon_uk_poolcue', category = 'POOLCUE',
        aliases = { 'uk', 'weapon_uk' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_uk', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'uk.png', audio = 'uk.mp3',
    },
    ['coolkids_babythree_poolcue'] = {
        label = 'Baby Three', model = 'coolkids_babythree_poolcue', category = 'POOLCUE',
        aliases = { 'babythree' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'coolkids_efx_01_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'cbbt.png', audio = 'cbbt.mp3',
    },
    ['sharkz_poolcue_white_wolf'] = {
        label = 'White Wolf', model = 'sharkz_poolcue_white_wolf', category = 'POOLCUE',
        aliases = { 'wwolf', 'whitewolf', 'poolcue_white_wolf' },
        eff_dead = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_hit_whitewolf', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_effect_whitewolf', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'wwolf.png', audio = 'wwolf.mp3',
    },
    ['coolkids_Sweet_poolcue'] = {
        label = 'Sweet', model = 'coolkids_Sweet_poolcue', category = 'POOLCUE',
        aliases = { 'cksweet', 'sweet' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sweet', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'SWEET_screen.png', audio = 'sound_SWEET.mp3',
    },
    ['ohmmiwars_poolcue_melody'] = {
        label = 'Melody', model = 'ohmmiwars_poolcue_melody', category = 'POOLCUE',
        aliases = { 'melody', 'poolcue_melody' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_melody', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'melody.png', audio = 'melody.mp3',
    },
    ['ohmmiwars_poolcue_wednesday'] = {
        label = 'Wednesday', model = 'ohmmiwars_poolcue_wednesday', category = 'POOLCUE',
        aliases = { 'wednesday', 'poolcue_wednesday' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_wd', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'wd.png', audio = 'wd.mp3',
    },
    ['daffy_rich_poolcue'] = {
        label = 'Rich', model = 'daffy_rich_poolcue', category = 'POOLCUE',
        aliases = { 'rich' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_rich', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'rich.png', audio = 'rich.mp3',
    },
    ['daffy_weapon_minon_poolcue'] = {
        label = 'Minion', model = 'daffy_weapon_minon_poolcue', category = 'POOLCUE',
        aliases = { 'minion', 'weapon_minon' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_minion', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'minion.png', audio = 'minion.mp3',
    },
    ['daffy_demonslayer_poolcue'] = {
        label = 'Demonslayer', model = 'daffy_demonslayer_poolcue', category = 'POOLCUE',
        aliases = { 'demonslayer' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_nezuko', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'nezuko.png', audio = 'nezuko.mp3',
    },
    ['daffy_chinese_set_poolcue'] = {
        label = 'Chinese Set', model = 'daffy_chinese_set_poolcue', category = 'POOLCUE',
        aliases = { 'chinese', 'chineseset' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_chinese', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'chinese.png', audio = 'chinese.mp3',
    },
    ['gb_neko_poolcue_white'] = {
        label = 'Neko White', model = 'gb_neko_poolcue_white', category = 'POOLCUE',
        aliases = { 'neko_w', 'nekowhite' },
        eff_dead = { { dict = 'girlbossefx_nekowhite', eff = 'girlbossefx_nekowhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'nekowhite.png', audio = 'nekosound.mp3',
    },
    ['gb_neko_poolcue_black'] = {
        label = 'Neko Black', model = 'gb_neko_poolcue_black', category = 'POOLCUE',
        aliases = { 'neko_b', 'nekoblack' },
        eff_dead = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'nekoblack.png', audio = 'nekosound.mp3',
    },
    ['sharkz_poolcue_white_tiger'] = {
        label = 'White Tiger', model = 'sharkz_poolcue_white_tiger', category = 'POOLCUE',
        aliases = { 'wtiger', 'whitetiger', 'poolcue_white_tiger' },
        eff_dead = { { dict = 'sharkz_whitetiger_set', eff = 'sharkz_whitetiger_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'sharkz_effect_whitetiger', eff = 'sharkz_effect_whitetiger', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'wtg.png', audio = 'wtg.mp3',
    },
    ['bbg_wp23_poolcue'] = {
        label = 'Valentine', model = 'bbg_wp23_poolcue', category = 'POOLCUE',
        aliases = { 'v26', 'valentines', 'wp23' },
        eff_dead = { { dict = 'ar_bbg', eff = 'cupidlover', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'heartspawn', bone = 57005, scale = 0.1, time = 50 } },
        screen = 'v26.png', audio = 'v26.mp3',
    },
    ['w_me_poolcue_dds'] = {
        label = 'Lava', model = 'w_me_poolcue_dds', category = 'POOLCUE',
        aliases = { 'lva', 'lava', 'poolcue_dds' },
        eff_dead = { { dict = 'deands_efx_lv', eff = 'exp_air_deandesignstudio', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'deands_efx_lv', eff = 'deands_efx_lv11p', bone = 57005, scale = 1.5, time = 10 } },
        screen = 'lva.png', audio = 'lva.mp3',
    },
    ['wm_baldwin_pool'] = {
        label = 'Baldwin', model = 'wm_baldwin_pool', category = 'POOLCUE',
        aliases = { 'baldwin', 'baldwinpool', 'bwpool' },
        eff_dead = { { dict = 'fire_baldwinkill', eff = 'fire_baldwinkill', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'handbaldwin', eff = 'handbaldwin', bone = 57005, scale = 0.8, time = 100 } },
        audio = 'fxbaldwin.mp3',
    },
    ['meow_buer_pool'] = {
        label = 'Buer', model = 'meow_buer_pool', category = 'POOLCUE',
        aliases = { 'buer', 'buerpool', 'meowpool' },
        eff_dead = { { dict = 'buerfx', eff = 'scr_clown_bul', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'buerfx', eff = 'buerfx', bone = 57005, scale = 0.8, time = 100 } },
        screen = 'meow_frame_buer.png', audio = 'fxbaldwin.mp3',
    },
    ['orca_poolcue'] = {
        label = 'Orca', model = 'orca_poolcue', category = 'POOLCUE',
        aliases = { 'orca', 'orcapool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['w_me_duckpoolcue'] = {
        label = 'Duck', model = 'w_me_duckpoolcue', category = 'POOLCUE',
        aliases = { 'duck', 'duckpool', 'ducky' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['w_me_pooldog'] = {
        label = 'Doggy', model = 'w_me_pooldog', category = 'POOLCUE',
        aliases = { 'dog', 'doggy', 'pooldog' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_judy_poolcue'] = {
        label = 'Judy', model = 'gb_judy_poolcue', category = 'POOLCUE',
        aliases = { 'judy', 'judypool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_nick_poolcue'] = {
        label = 'Nick', model = 'gb_nick_poolcue', category = 'POOLCUE',
        aliases = { 'nick', 'nickpool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['gb_kanjifang_poolcue'] = {
        label = 'Kanjifang', model = 'gb_kanjifang_poolcue', category = 'POOLCUE',
        aliases = { 'kanjifang', 'kanjipool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['bbg_wp25_poolcue'] = {
        label = 'WP25', model = 'bbg_wp25_poolcue', category = 'POOLCUE',
        aliases = { 'wp25', 'wp25pool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },
    ['bbg_wp29_poolcue'] = {
        label = 'WP29', model = 'bbg_wp29_poolcue', category = 'POOLCUE',
        aliases = { 'wp29', 'wp29pool' },
        eff_dead = { { dict = 'scr_rcbarry2', eff = 'scr_clown_death', scale = 1.0 } },
    },

    -- ===================== BOTTLE =====================
    ['sharkz_bottle_starhero'] = {
        label = 'Star Hero', model = 'sharkz_bottle_starhero', category = 'BOTTLE',
        aliases = { 'hero', 'bottle_starhero' },
        eff_dead = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_hit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_starhero_set', eff = 'sharkz_starhero_effect', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'hero.png', audio = 'hero.mp3',
    },
    ['sharkz_bottle_8bit'] = {
        label = '8BIT', model = 'sharkz_bottle_8bit', category = 'BOTTLE',
        aliases = { '8bit', 'bottle_8bit' },
        eff_dead = { { dict = 'sharkz_8bit_set', eff = 'sharkz_hit_8bit', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'sharkz_8bit_set', eff = 'sharkz_effect_8bit', bone = 57005, scale = 0.3, y = 0.05, rz = 60.0, time = 50 } },
        screen = '8bit.png', audio = '8bit.mp3',
    },
    ['wishme_momo_1knife'] = {
        label = 'Momo', model = 'wishme_momo_1knife', category = 'BOTTLE',
        aliases = { 'momo' },
        eff_dead = { { dict = 'whitme_momo_efx', eff = 'scr_withme_firework_starburst', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'whitme_momo_efx', eff = 'scr_whitmemomo_beast_vanish', bone = 57005, scale = 0.1, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'momo.png', audio = 'momo.mp3',
    },
    ['rb_swagblack_knife'] = {
        label = 'Swag Black', model = 'rb_swagblack_knife', category = 'BOTTLE',
        aliases = { 'swag_b', 'swagblack' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = {
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, y = 0.05, rz = 60.0, time = 900 },
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_2', bone = 57005, scale = 1.0, y = 0.05, rz = 60.0, time = 900 },
        },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['rb_swagwhite_knife'] = {
        label = 'Swag White', model = 'rb_swagwhite_knife', category = 'BOTTLE',
        aliases = { 'swag_w', 'swagwhite' },
        eff_dead = { { dict = 'gb_efx_swag', eff = 'gb_efx_swag_1', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = {
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_1', bone = 57005, scale = 0.3, y = 0.05, rz = 60.0, time = 900 },
            { dict = 'gb_efx_swag', eff = 'gb_efx_swaghand_2', bone = 57005, scale = 1.0, y = 0.05, rz = 60.0, time = 900 },
        },
        screen = 'swag.png', audio = 'swag.mp3',
    },
    ['sharkz_knife_phx_firestorm'] = {
        label = 'Phoenix', model = 'sharkz_knife_phx_firestorm', category = 'BOTTLE',
        aliases = { 'phoenix', 'knife_phx_firestorm' },
        eff_dead = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_phoenix_set', eff = 'sharkz_phoenix_effect', bone = 57005, scale = 0.8, y = 0.05, rz = 60.0, time = 20 } },
        screen = 'phoenix.png', audio = 'phoenix.mp3',
    },
    ['lazy_cutestar_knife'] = {
        label = 'Bunny Lazy', model = 'lazy_cutestar_knife', category = 'BOTTLE',
        aliases = { 'lazy', 'bunnylazy', 'cutestar' },
        eff_dead = { { dict = 'ar_effect', eff = 'cutestar', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        screen = 'cutestar.png', audio = 'cutestar.mp3',
    },
    ['x_me_bottle_anubis'] = {
        label = 'Anubis 1', model = 'x_me_bottle_anubis', category = 'BOTTLE',
        aliases = { 'anubis', 'anubis1' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['x_me_dagger_anubis'] = {
        label = 'Anubis 2', model = 'x_me_dagger_anubis', category = 'BOTTLE',
        aliases = { 'anubis2' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['x_me_knife_anubis'] = {
        label = 'Anubis 3', model = 'x_me_knife_anubis', category = 'BOTTLE',
        aliases = { 'anubis3' },
        eff_dead = { { dict = 'eff_anubis', eff = 'eff_anubis', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'eff_anubis2', eff = 'eff_anubis2', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'anubis.png', audio = 'anubis.mp3',
    },
    ['w_me_daggerks_dds'] = {
        label = 'Kitsune', model = 'w_me_daggerks_dds', category = 'BOTTLE',
        aliases = { 'kitsune', 'daggerks_dds' },
        eff_dead = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1v1_po', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'dds_ksn1v1_po', eff = 'dds_ksn1hxnd_po', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'kitsune.png', audio = 'kitsune.mp3',
    },
    ['sharkz_bottle_zap'] = {
        label = 'ZAP', model = 'sharkz_bottle_zap', category = 'BOTTLE',
        aliases = { 'zap', 'bottle_zap' },
        eff_dead = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.2 } },
        ptfx_bone = { { dict = 'sharkz_zap_set', eff = 'sharkz_zap_effect', bone = 57005, scale = 0.8, y = 0.05, rz = 60.0, time = 20 } },
        screen = 'zap.png', audio = 'zap.mp3',
    },
    ['w_me_bottle_eden'] = {
        label = 'Eden', model = 'w_me_bottle_eden', category = 'BOTTLE',
        aliases = { 'eden', 'bottle_eden' },
        eff_dead = { { dict = 'eden', eff = 'eden', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        screen = 'eden.png', audio = 'eden.mp3',
    },
    ['w_me_zyndear_toothless_bottle_white'] = {
        label = 'Toothless', model = 'w_me_zyndear_toothless_bottle_white', category = 'BOTTLE',
        aliases = { 'toothless', 'zyndear_toothless_bottle_white' },
        eff_dead = { { dict = 'ar_effect', eff = 'killtoothlesswhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'killtoothlesswhite', bone = 57005, scale = 0.1, y = 0.05, rz = 60.0, time = 100 } },
        audio = 'jingle.mp3',
    },
    ['wm_elys_knife'] = {
        label = 'ELYS', model = 'wm_elys_knife', category = 'BOTTLE',
        aliases = { 'elys' },
        eff_dead = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'wm_ef_elys', eff = 'wm_ef_elys_hfx', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'elys.png', audio = 'elys.mp3',
    },
    ['lazy_fox_knife'] = {
        label = 'Fox Lazy', model = 'lazy_fox_knife', category = 'BOTTLE',
        aliases = { 'lazyfox', 'foxlazy', 'fox' },
        eff_dead = { { dict = 'ar_effect', eff = 'foxfx', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.25 } },
        screen = 'lazyfox.png', audio = 'lazyfox.mp3',
    },
    ['w_me_bottleredfire'] = {
        label = 'Fire', model = 'w_me_bottleredfire', category = 'BOTTLE',
        aliases = { 'fire', 'bottleredfire' },
        eff_dead = { { dict = 'ptfx_fireredsmoke', eff = 'ptfx_fireredsmoke', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.5 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'redfire', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'vdframefire.png', audio = 'vdfirered.mp3',
    },
    ['rb_luvteddy_blue_knife'] = {
        label = 'Luv Teddy Blue', model = 'rb_luvteddy_blue_knife', category = 'BOTTLE',
        aliases = { 'luv_b', 'luvteddyblue' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['rb_luvteddy_pink_knife'] = {
        label = 'Luv Teddy Pink', model = 'rb_luvteddy_pink_knife', category = 'BOTTLE',
        aliases = { 'luv_p', 'luvteddypink' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_luvteddy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'luvteddy.png', audio = 'luvteddy.mp3',
    },
    ['devilcute_bottle'] = {
        label = 'Devilcute', model = 'devilcute_bottle', category = 'BOTTLE',
        aliases = { 'devcu_bot', 'devilcute' },
        eff_dead = { { dict = 'devilcute_hit_effects', eff = 'magicwarp', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.4 } },
        screen = 'devilcute.png', audio = 'devilcute.mp3',
    },
    ['reawx_bottle_fantacy'] = {
        label = 'Zephyron', model = 'reawx_bottle_fantacy', category = 'BOTTLE',
        aliases = { 'zep_bottle', 'zephyron' },
        eff_dead = { { dict = 'reawx_particle_fantasy', eff = 'reawx_particle_fantasy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 2.0 } },
        ptfx_bone = { { dict = 'reaxw_effect_fantasy', eff = 'trail', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'ZEPHYRON.png', audio = 'ZEPHYRON.mp3',
    },
    ['bbg_wp26_bottle'] = {
        label = 'Pink Pig', model = 'bbg_wp26_bottle', category = 'BOTTLE',
        aliases = { 'pigpink_bottle', 'pinkpig', 'wp26' },
        eff_dead = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.5 } },
        ptfx_bone = { { dict = 'bbg_wp26_1', eff = 'bbg_effect_sleepy_star', bone = 57005, scale = 0.2, time = 100 } },
        screen = 'pinkpig.png', audio = 'pinkpig.ogg',
    },
    ['gb_ponypur_bottle'] = {
        label = 'Ponybunny', model = 'gb_ponypur_bottle', category = 'BOTTLE',
        aliases = { 'pony', 'ponybunny', 'ponypur' },
        eff_dead = {
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_1', scale = 0.2 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_2', scale = 0.11 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_3', scale = 0.6 },
            { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_4', scale = 0.6 },
        },
        ptfx_bone = { { dict = 'gb_ponybun_efx', eff = 'gb_ponybun_efx_5', bone = 57005, scale = 0.6, time = 100 } },
        screen = 'pony.png', audio = 'pony.mp3',
    },
    ['w_me_songkran_knife'] = {
        label = 'Water', model = 'w_me_songkran_knife', category = 'BOTTLE',
        aliases = { 'water', 'songkran' },
    },
    ['lazy_badbunnie_knife'] = {
        label = 'Bad Bunnie', model = 'lazy_badbunnie_knife', category = 'BOTTLE',
        aliases = { 'badbunie', 'badbunnie' },
        eff_dead = { { dict = 'lazy_badbunnie', eff = 'lazy_badbunnie', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.08 } },
        screen = 'badbunny.png', audio = 'badbunny.mp3',
    },
    ['bbg_wp28_bottle'] = {
        label = 'Sea Summer', model = 'bbg_wp28_bottle', category = 'BOTTLE',
        aliases = { 'sea', 'seasummer', 'wp28' },
        eff_dead = {
            { dict = 'ar_bbg', eff = 'underthesea_kill', scale = 0.4 },
            { dict = 'ar_bbg', eff = 'underthesea_spawn', scale = 0.1 },
        },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'underthesea_bubble', bone = 1, scale = 0.3, time = 500 } },
        screen = 'sea.png', audio = 'sea.ogg',
    },
    ['sharkz_knife_darkwolf'] = {
        label = 'Dark Wolf', model = 'sharkz_knife_darkwolf', category = 'BOTTLE',
        aliases = { 'darkwolf', 'knife_darkwolf' },
        eff_dead = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_darkwolf_set', eff = 'sharkz_darkwolf_effect', bone = 57005, scale = 0.1, time = 100 } },
        screen = 'darkwolf.png', audio = 'darkwolf.mp3',
    },
    ['w_me_bottle_stl_green'] = {
        label = 'Green', model = 'w_me_bottle_stl_green', category = 'BOTTLE',
        aliases = { 'green', 'bottle_stl_green' },
        eff_dead = { { dict = 'stl_green', eff = 'stl_green', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.15 } },
        ptfx_bone = { { dict = 'ar_effect', eff = 'effect_energygreen', bone = 57005, scale = 0.5, y = 0.05, rz = 60.0, time = 100 } },
        screen = 'green.png', audio = 'green.mp3',
    },
    ['sharkz_bottle_deepblue'] = {
        label = 'Deep Blue', model = 'sharkz_bottle_deepblue', category = 'BOTTLE',
        aliases = { 'db', 'deepblue', 'bottle_deepblue' },
        eff_dead = { { dict = 'sharkz_deepblue_set', eff = 'sharkz_deepblue_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.6 } },
        ptfx_bone = { { dict = 'sharkz_deepblue_set', eff = 'shark_deepblue_effect', bone = 57005, scale = 0.2, time = 100 } },
        screen = 'deepblue.png', audio = 'deepblue.mp3',
    },
    ['coolkids_duckysummer_bottle'] = {
        label = 'Ducky Summer', model = 'coolkids_duckysummer_bottle', category = 'BOTTLE',
        aliases = { 'dsumer', 'duckysummer' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_duckysummer_star', bone = 57005, scale = 0.1, time = 100 } },
        screen = 'dsumer.png', audio = 'dsumer.mp3',
    },
    ['w_me_bottle_dds'] = {
        label = 'Lava', model = 'w_me_bottle_dds', category = 'BOTTLE',
        aliases = { 'lva', 'lava', 'bottle_dds' },
        eff_dead = { { dict = 'deands_efx_lv', eff = 'exp_air_deandesignstudio', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'deands_efx_lv', eff = 'deands_efx_lv11p', bone = 57005, scale = 1.5, time = 10 } },
        screen = 'lva.png', audio = 'lva.mp3',
    },
    ['coolkids_sanrio_bottle'] = {
        label = 'Sanrio', model = 'coolkids_sanrio_bottle', category = 'BOTTLE',
        aliases = { 'sanrio' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.5 } },
        ptfx_bone = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sanrio_halloween_prop', bone = 57005, scale = 0.1, time = 100 } },
        screen = 'csro.png', audio = 'csro.mp3',
    },
    ['gb_bearx_bottle_black'] = {
        label = 'BearX Black', model = 'gb_bearx_bottle_black', category = 'BOTTLE',
        aliases = { 'bearx_b', 'bearxblack' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 100 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['gb_bearx_bottle_white'] = {
        label = 'BearX White', model = 'gb_bearx_bottle_white', category = 'BOTTLE',
        aliases = { 'bearx_w', 'bearxwhite' },
        eff_dead = { { dict = 'Prticle_bearx_1', eff = 'scr_exp_clown', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'effect_bearx_1', eff = 'muz_clown', bone = 57005, scale = 0.4, time = 100 } },
        screen = 'brx.png', audio = 'brx.mp3',
    },
    ['sharkz_dagger_greendragon'] = {
        label = 'Green Dragon', model = 'sharkz_dagger_greendragon', category = 'BOTTLE',
        aliases = { 'gd', 'greendragon' },
        eff_dead = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_hit_gdragon', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.7 } },
        ptfx_bone = { { dict = 'sharkz_gdragon_set', eff = 'sharkz_effect_gdragon', bone = 57005, scale = 1.0, time = 10 } },
        screen = 'gd.png', audio = 'gd.mp3',
    },
    ['gb_neko_bottle_black'] = {
        label = 'Neko Black', model = 'gb_neko_bottle_black', category = 'BOTTLE',
        aliases = { 'neko_b', 'nekoblack' },
        eff_dead = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'nekoblack.png', audio = 'nekosound.mp3',
    },
    ['gb_neko_bottle_white'] = {
        label = 'Neko White', model = 'gb_neko_bottle_white', category = 'BOTTLE',
        aliases = { 'neko_w', 'nekowhite' },
        eff_dead = { { dict = 'girlbossefx_nekowhite', eff = 'girlbossefx_nekowhite', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'girlbossefx_nekoblack', eff = 'girlbossefx_nekoblack', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'nekowhite.png', audio = 'nekosound.mp3',
    },
    ['bbg_wp23_bottle'] = {
        label = 'Valentine', model = 'bbg_wp23_bottle', category = 'BOTTLE',
        aliases = { 'v26', 'valentines', 'wp23' },
        eff_dead = { { dict = 'ar_bbg', eff = 'cupidlover', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.2 } },
        ptfx_bone = { { dict = 'ar_bbg', eff = 'heartspawn', bone = 57005, scale = 0.1, time = 50 } },
        screen = 'v26.png', audio = 'v26.mp3',
    },
    ['sharkz_bottle_white_tiger'] = {
        label = 'White Tiger', model = 'sharkz_bottle_white_tiger', category = 'BOTTLE',
        aliases = { 'wtiger', 'whitetiger' },
        eff_dead = { { dict = 'sharkz_whitetiger_set', eff = 'sharkz_whitetiger_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 0.3 } },
        ptfx_bone = { { dict = 'sharkz_effect_whitetiger', eff = 'sharkz_effect_whitetiger', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'wtg.png', audio = 'wtg.mp3',
    },
    ['sharkz_bottle_white_wolf'] = {
        label = 'White Wolf', model = 'sharkz_bottle_white_wolf', category = 'BOTTLE',
        aliases = { 'wwolf', 'whitewolf' },
        eff_dead = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_hit_whitewolf', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_whitewolf_set', eff = 'sharkz_effect_whitewolf', bone = 57005, scale = 0.3, time = 100 } },
        screen = 'wwolf.png', audio = 'wwolf.mp3',
    },
    ['coolkids_babythree_bottle'] = {
        label = 'Baby Three', model = 'coolkids_babythree_bottle', category = 'BOTTLE',
        aliases = { 'babythree' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'coolkids_efx_01_prop', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        screen = 'cbbt.png', audio = 'cbbt.mp3',
    },
    ['daffy_weapon_uk_bottle'] = {
        label = 'UK', model = 'daffy_weapon_uk_bottle', category = 'BOTTLE',
        aliases = { 'uk', 'weapon_uk' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_uk', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'uk.png', audio = 'uk.mp3',
    },
    ['ohmmiwars_bottle_melody'] = {
        label = 'Melody', model = 'ohmmiwars_bottle_melody', category = 'BOTTLE',
        aliases = { 'melody', 'bottle_melody' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_melody', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'melody.png', audio = 'melody.mp3',
    },
    ['daffy_weapon_minon_bottle'] = {
        label = 'Minion', model = 'daffy_weapon_minon_bottle', category = 'BOTTLE',
        aliases = { 'minion', 'weapon_minon' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_minion', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'minion.png', audio = 'minion.mp3',
    },
    ['ohmmiwars_bottle_wednesday'] = {
        label = 'Wednesday', model = 'ohmmiwars_bottle_wednesday', category = 'BOTTLE',
        aliases = { 'wd', 'wednesday' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_wd', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'wd.png', audio = 'wd.mp3',
    },
    ['daffy_demonslayer_bottle'] = {
        label = 'Demonslayer', model = 'daffy_demonslayer_bottle', category = 'BOTTLE',
        aliases = { 'demon', 'demonslayer' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_zenitsu', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'DEMONSLAYER.png', audio = 'DEMONSLAYER.mp3',
    },
    ['daffy_rich_bottle'] = {
        label = 'Rich', model = 'daffy_rich_bottle', category = 'BOTTLE',
        aliases = { 'rich' },
        eff_dead = { { dict = 'ar_daffy', eff = 'daffy_rich', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'rich.png', audio = 'rich.mp3',
    },
    ['rb_duckysplash_bottle'] = {
        label = 'Ducky Splash', model = 'rb_duckysplash_bottle', category = 'BOTTLE',
        aliases = { 'duckysplash' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_duckysplash', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'duckysplash.png', audio = 'duckysplash.mp3',
    },
    ['rb_winterfrost_black_bottle'] = {
        label = 'Winterfrost Black', model = 'rb_winterfrost_black_bottle', category = 'BOTTLE',
        aliases = { 'winter_black', 'winterfrostblack' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 50 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['rb_winterfrost_white_bottle'] = {
        label = 'Winterfrost White', model = 'rb_winterfrost_white_bottle', category = 'BOTTLE',
        aliases = { 'winter_white', 'winterfrostwhite' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'ar_rainbow', eff = 'rainbowfx_winterfrost', bone = 57005, scale = 0.3, time = 50 } },
        screen = 'winterfrost.png', audio = 'winterfrost.mp3',
    },
    ['w_me_wbu_harajuku_bottle'] = {
        label = 'Harajuku', model = 'w_me_wbu_harajuku_bottle', category = 'BOTTLE',
        aliases = { 'harajuku', 'wbu_harajuku' },
        eff_dead = { { dict = 'ar_rainbow', eff = 'wbu_harajuku', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'harajuku.png', audio = 'harajuku.mp3',
    },
    ['ohmmiwars_bottle_squid'] = {
        label = 'Squidgame', model = 'ohmmiwars_bottle_squid', category = 'BOTTLE',
        aliases = { 'squid', 'squidgame' },
        eff_dead = { { dict = 'daffy_squidgame', eff = 'daffy_squidgame', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'squidgame.png', audio = 'squidgame.mp3',
    },
    ['sharkz_bottle_halloween'] = {
        label = 'Halloween', model = 'sharkz_bottle_halloween', category = 'BOTTLE',
        aliases = { 'halloween', 'halloweens' },
        eff_dead = { { dict = 'sharkz_halloween_set', eff = 'sharkz_halloween_set', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        ptfx_bone = { { dict = 'sharkz_blood_effect', eff = 'sharkz_blood_effect', bone = 57005, scale = 1.0, time = 100 } },
        screen = 'halloween.png', audio = 'halloween.mp3',
    },
    ['sharkz_bottle_poker'] = {
        label = 'Poker', model = 'sharkz_bottle_poker', category = 'BOTTLE',
        aliases = { 'poker', 'bottle_poker' },
        eff_dead = { { dict = 'sharkz_poker_set', eff = 'sharkz_hit_poker', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 1.0 } },
        ptfx_bone = { { dict = 'sharkz_poker_set', eff = 'sharkz_effect_poker', bone = 57005, scale = 0.2, time = 100 } },
        screen = 'poker.png', audio = 'poker.ogg',
    },
    ['coolkids_Sweet_bottle'] = {
        label = 'Sweet', model = 'coolkids_Sweet_bottle', category = 'BOTTLE',
        aliases = { 'cksweet', 'sweet' },
        eff_dead = { { dict = 'ar_coolkids', eff = 'efxcoolkids_sweet', fallback_dict = 'scr_rcbarry2', fallback_eff = 'scr_clown_death', scale = 3.0 } },
        screen = 'SWEET_screen.png', audio = 'sound_SWEET.mp3',
    },
}

-- ── Weapon Hash Database ───────────────────────────────────────
local WeaponCategories = {
    ['POOLCUE'] = {
        'WEAPON_POOLCUE', 'WEAPON_POOLCUE0', 'WEAPON_POOLCUE1', 'WEAPON_POOLCUE2',
        'WEAPON_POOLCUE3', 'WEAPON_POOLCUE4', 'WEAPON_POOLCUE5',
        'WEAPON_POOLCUE_0', 'WEAPON_POOLCUE_1', 'WEAPON_POOLCUE_2',
        'WEAPON_POOLCUE_3', 'WEAPON_POOLCUE_4', 'WEAPON_POOLCUE_5',
        'WEAPON_POOLCUE_RENT', 'WEAPON_POOLCUE14DAY', 'WEAPON_POOLCUEWAR',
    },
    ['BOTTLE'] = {
        'WEAPON_BOTTLE', 'WEAPON_BOTTLE0', 'WEAPON_BOTTLE1', 'WEAPON_BOTTLE2',
        'WEAPON_BOTTLE3', 'WEAPON_BOTTLE4', 'WEAPON_BOTTLE5',
        'WEAPON_BOTTLE_0', 'WEAPON_BOTTLE_1', 'WEAPON_BOTTLE_2',
        'WEAPON_BOTTLE_3', 'WEAPON_BOTTLE_4', 'WEAPON_BOTTLE_5',
        'WEAPON_DAGGER', 'WEAPON_KNIFE', 'WEAPON_KNIFE_1', 'WEAPON_KNIFE_2',
        'WEAPON_KNIFE_3', 'WEAPON_KNIFE_4', 'WEAPON_SWITCHBLADE',
        'WEAPON_MACHETTE_0', 'WEAPON_MACHETTE_1', 'WEAPON_MACHETTE_2', 'WEAPON_MACHETTE_3',
    },
}

-- แปลงชื่อเป็น hash ล่วงหน้า
local WeaponHashLookup = {}
for cat, names in pairs(WeaponCategories) do
    for _, name in ipairs(names) do
        local h = GetHashKey(name)
        WeaponHashLookup[h] = cat
    end
end

-- สร้าง component hash cache
local function BuildComponentHashCache()
    for _, sData in pairs(MasterSkins) do
        local m = sData.model
        allComponentHashes[GetHashKey(m)] = true
        allComponentHashes[GetHashKey(string.upper(m))] = true
        allComponentHashes[GetHashKey(string.lower(m))] = true
        allComponentHashes[GetHashKey('COMPONENT_' .. string.upper(m))] = true
    end
end

-- ── Helper Functions ───────────────────────────────────────────
local UNARMED = GetHashKey('WEAPON_UNARMED')

local function GetWeaponCategory(wHash)
    if not wHash or wHash == 0 or wHash == UNARMED then return nil end
    return WeaponHashLookup[wHash]
end

local function FindSkin(query, category)
    if not query or query == '' then return nil, nil end
    local q = string.lower(query)

    if MasterSkins[q] then return q, MasterSkins[q] end
    for k, v in pairs(MasterSkins) do
        if string.lower(k) == q then return k, v end
    end

    for k, v in pairs(MasterSkins) do
        if v.aliases then
            for _, alias in ipairs(v.aliases) do
                if string.lower(alias) == q then return k, v end
            end
        end
    end

    if category then
        for k, v in pairs(MasterSkins) do
            if v.category == category then
                if string.find(string.lower(k), q, 1, true) or string.find(string.lower(v.label), q, 1, true) then
                    return k, v
                end
                if v.aliases then
                    for _, alias in ipairs(v.aliases) do
                        if string.find(string.lower(alias), q, 1, true) then return k, v end
                    end
                end
            end
        end
    end

    for k, v in pairs(MasterSkins) do
        if string.find(string.lower(k), q, 1, true) or string.find(string.lower(v.label), q, 1, true) then
            return k, v
        end
    end

    return nil, nil
end

-- ── KVP Storage ────────────────────────────────────────────────
local function SaveSkin(category, skinKey)
    local kvp = 'arskin_' .. category
    if not skinKey or skinKey == 'default' or skinKey == '' then
        DeleteResourceKvp(kvp)
        equippedSkins[category] = nil
    else
        SetResourceKvp(kvp, skinKey)
        equippedSkins[category] = skinKey
    end
end

local function LoadSavedSkins()
    for cat in pairs(WeaponCategories) do
        local val = GetResourceKvpString('arskin_' .. cat)
        if val and val ~= '' and val ~= 'default' then
            equippedSkins[cat] = val
        end
    end
end

-- ── Prop Engine ────────────────────────────────────────────────
local function RemoveProp()
    if currentPropEntity and DoesEntityExist(currentPropEntity) then
        SetEntityAsMissionEntity(currentPropEntity, true, true)
        DetachEntity(currentPropEntity, true, true)
        DeleteEntity(currentPropEntity)
    end
    currentPropEntity = nil
    currentPropModel = nil
    SetPedCurrentWeaponVisible(PlayerPedId(), true, false, false, false)
end

local function AttachProp(ped, modelName, category)
    if not ped or not DoesEntityExist(ped) or not modelName then return false end

    if currentPropEntity and DoesEntityExist(currentPropEntity) and currentPropModel == modelName then
        SetPedCurrentWeaponVisible(ped, false, false, false, false)
        return true
    end

    RemoveProp()

    local modelHash = GetHashKey(modelName)
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.lower(modelName)) end
    if not IsModelValid(modelHash) then modelHash = GetHashKey(string.upper(modelName)) end
    if not IsModelValid(modelHash) then return false end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + 800
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end

    local coords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    if not DoesEntityExist(prop) then return false end

    SetEntityCollision(prop, false, false)
    SetEntityInvincible(prop, true)

    local px, py, pz = 0.080, -0.025, -0.021
    local rx, ry, rz = -85.0, -16.0, -23.0

    if Config and Config.WeaponPosition then
        local posCat = (category == 'POOLCUE') and 'POOL' or category
        local cfg = Config.WeaponPosition[posCat] or Config.WeaponPosition['POOL']
        if cfg then
            px = (cfg.Pos and cfg.Pos.x) or px
            py = (cfg.Pos and cfg.Pos.y) or py
            pz = (cfg.Pos and cfg.Pos.z) or pz
            rx = (cfg.Rot and cfg.Rot.x) or rx
            ry = (cfg.Rot and cfg.Rot.y) or ry
            rz = (cfg.Rot and cfg.Rot.z) or rz
        end
    end

    AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, 57005),
        px, py, pz, rx, ry, rz, true, true, false, true, 1, true)

    currentPropEntity = prop
    currentPropModel = modelName
    SetModelAsNoLongerNeeded(modelHash)
    SetPedCurrentWeaponVisible(ped, false, false, false, false)
    return true
end

-- ── Component Engine ───────────────────────────────────────────
local function RemoveAllComponents(ped, wHash)
    if not ped or not DoesEntityExist(ped) or wHash == 0 then return end
    for compHash in pairs(allComponentHashes) do
        if HasPedGotWeaponComponent(ped, wHash, compHash) then
            RemoveWeaponComponentFromPed(ped, wHash, compHash)
        end
    end
end

local function ApplySkinModel(ped, wHash, modelName, category)
    if not ped or not DoesEntityExist(ped) or wHash == 0 or not modelName then return false end

    local hashes = {
        GetHashKey(modelName),
        GetHashKey(string.upper(modelName)),
        GetHashKey(string.lower(modelName)),
        GetHashKey('COMPONENT_' .. string.upper(modelName)),
    }

    for _, h in ipairs(hashes) do
        GiveWeaponComponentToPed(ped, wHash, h)
    end

    for _, h in ipairs(hashes) do
        if HasPedGotWeaponComponent(ped, wHash, h) then
            RemoveProp()
            return true
        end
    end

    return AttachProp(ped, modelName, category)
end

-- ── PTFX Engine ────────────────────────────────────────────────
local function LoadPtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local deadline = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < deadline do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function PlayHandAura(ped, auraList)
    if not ped or not DoesEntityExist(ped) or not auraList then return end
    for _, aura in ipairs(auraList) do
        local dict = aura.dict
        local eff = aura.eff
        local bone = aura.bone or 57005
        local scale = aura.scale or 0.8
        local boneIdx = GetPedBoneIndex(ped, bone)

        if dict and eff and boneIdx ~= -1 then
            local loaded = LoadPtfx(dict)
            if not loaded and aura.fallback_dict then
                dict, eff = aura.fallback_dict, aura.fallback_eff
                loaded = LoadPtfx(dict)
            end
            if loaded then
                UseParticleFxAssetNextCall(dict)
                StartParticleFxNonLoopedOnPedBone(
                    eff, ped,
                    aura.x or 0.1, aura.y or 0.0, aura.z or 0.0,
                    aura.rx or 0.0, aura.ry or 0.0, aura.rz or 0.0,
                    boneIdx, scale, false, false, false
                )
            end
        end
    end
end

local function PlayKillEffect(victim, effList)
    if not victim or not DoesEntityExist(victim) or not effList then return end

    -- ป้องกันเอฟเฟคซ้อนตัวเอง: ถ้าเหยื่ออยู่ใกล้เกินไป ใช้ bone ของเหยื่อเท่านั้น
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local victimCoords = GetEntityCoords(victim)

    -- ถ้า victim กับ player อยู่ตำแหน่งเดียวกัน = entity ผิด ข้าม
    if victim == myPed then return end

    local headBone = GetPedBoneIndex(victim, 31086)
    local useBone = (headBone ~= -1)

    for _, fx in ipairs(effList) do
        local dict = fx.dict
        local eff = fx.eff
        local scale = fx.scale or 1.0

        if dict and eff then
            local loaded = LoadPtfx(dict)
            if not loaded and fx.fallback_dict then
                dict, eff = fx.fallback_dict, fx.fallback_eff
                loaded = LoadPtfx(dict)
            end
            if loaded then
                if useBone then
                    -- เล่นเอฟเฟคบน bone ของเหยื่อ (ติดตัวเหยื่อ ไม่หลุดมาที่ตัวเรา)
                    UseParticleFxAssetNextCall(dict)
                    StartNetworkedParticleFxNonLoopedOnPedBone(
                        eff, victim,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        headBone, scale,
                        false, false, false
                    )
                else
                    -- fallback: เล่นบน entity โดยตรง
                    UseParticleFxAssetNextCall(dict)
                    StartNetworkedParticleFxNonLoopedOnEntity(
                        eff, victim,
                        0.0, 0.0, 0.65,
                        0.0, 0.0, 0.0,
                        scale, false, false, false
                    )
                end

                -- เล่นซ้ำแบบ local เผื่อ networked ไม่แสดง
                UseParticleFxAssetNextCall(dict)
                if useBone then
                    StartParticleFxNonLoopedOnPedBone(
                        eff, victim,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        headBone, scale,
                        false, false, false
                    )
                else
                    StartParticleFxNonLoopedOnEntity(
                        eff, victim,
                        0.0, 0.0, 0.65,
                        0.0, 0.0, 0.0,
                        scale, false, false, false
                    )
                end
            end
        end
    end
end

-- ── Main Watcher Thread ────────────────────────────────────────
CreateThread(function()
    BuildComponentHashCache()
    LoadSavedSkins()

    local lastWeapon = 0
    local nextAuraTime = 0

    while true do
        local waitMs = 100
        local ped = PlayerPedId()

        if not DoesEntityExist(ped) or IsEntityDead(ped) then
            if lastWeapon ~= 0 then
                RemoveProp()
                lastWeapon = 0
            end
            waitMs = 1000
        else
            local curWeapon = GetSelectedPedWeapon(ped)

            if curWeapon ~= 0 and curWeapon ~= UNARMED then
                local cat = GetWeaponCategory(curWeapon)
                local skinKey = cat and equippedSkins[cat]

                if skinKey and MasterSkins[skinKey] then
                    local sData = MasterSkins[skinKey]

                    if curWeapon ~= lastWeapon or (not currentPropEntity and not HasPedGotWeaponComponent(ped, curWeapon, GetHashKey(sData.model))) then
                        RemoveAllComponents(ped, curWeapon)
                        ApplySkinModel(ped, curWeapon, sData.model, sData.category)
                        lastWeapon = curWeapon
                    end

                    if currentPropEntity and DoesEntityExist(currentPropEntity) then
                        SetPedCurrentWeaponVisible(ped, false, false, false, false)
                    end

                    if sData.ptfx_bone then
                        local now = GetGameTimer()
                        if now >= nextAuraTime then
                            PlayHandAura(ped, sData.ptfx_bone)
                            local interval = sData.ptfx_bone[1].time or 800
                            if interval < 200 then interval = 200 end
                            nextAuraTime = now + interval
                        end
                    end
                else
                    if curWeapon ~= lastWeapon then
                        RemoveProp()
                        lastWeapon = curWeapon
                    end
                end
            else
                if lastWeapon ~= 0 then
                    RemoveProp()
                    lastWeapon = 0
                end
            end
        end

        Wait(waitMs)
    end
end)

-- ── Kill Detection (gameEventTriggered) ────────────────────────
local recentHits = {}
local deadVictims = {}

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName ~= 'CEventNetworkEntityDamage' then return end

    local victim = data[1]
    local attacker = data[2]
    local fatal = (data[4] == 1 or data[6] == 1)
    local myPed = PlayerPedId()

    if not victim or victim == 0 or victim == myPed then return end

    local isMe = (attacker == myPed)
    if not isMe and DoesEntityExist(victim) then
        if GetPedSourceOfDeath(victim) == myPed or HasEntityBeenDamagedByEntity(victim, myPed, true) then
            isMe = true
        end
    end
    if not isMe then return end

    if GetVehiclePedIsIn(myPed, false) ~= 0 then return end

    local curWeapon = GetSelectedPedWeapon(myPed)
    if curWeapon == 0 or curWeapon == UNARMED then return end

    local cat = GetWeaponCategory(curWeapon)
    local skinKey = cat and equippedSkins[cat]
    if not skinKey then return end

    local now = GetGameTimer()
    local isDead = fatal or IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0

    if isDead then
        if not deadVictims[victim] or (now - deadVictims[victim] >= 2000) then
            deadVictims[victim] = now
            recentHits[victim] = nil

            local sData = MasterSkins[skinKey]
            if sData and sData.eff_dead then
                PlayKillEffect(victim, sData.eff_dead)
            end
            if sData and (sData.screen or sData.audio) then
                SendNUIMessage({
                    action = 'screen',
                    screen = sData.screen or '',
                    sound = sData.audio or '',
                    volum = 0.5,
                })
            end
        end
    else
        recentHits[victim] = { time = now, skinKey = skinKey }
    end
end)

-- สแกนเป้าที่ตีแล้วเผื่อตายดีเลย์
CreateThread(function()
    while true do
        local now = GetGameTimer()
        local hasEntries = false

        for victim, hitData in pairs(recentHits) do
            hasEntries = true
            if not DoesEntityExist(victim) or (now - hitData.time > 4500) then
                recentHits[victim] = nil
            else
                local isDead = IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0
                if isDead then
                    recentHits[victim] = nil
                    if not deadVictims[victim] or (now - deadVictims[victim] >= 2000) then
                        deadVictims[victim] = now
                        local sData = MasterSkins[hitData.skinKey]
                        if sData and sData.eff_dead then
                            PlayKillEffect(victim, sData.eff_dead)
                        end
                    end
                end
            end
        end

        Wait(hasEntries and 25 or 100)
    end
end)

-- ── Cleanup ────────────────────────────────────────────────────
AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        RemoveProp()
    end
end)

-- ── Commands ───────────────────────────────────────────────────
RegisterCommand('home', function(_, args)
    local input = args[1]
    if not input or input == '' or input == 'list' or input == 'help' then
        ShowSkinList()
        return
    end

    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    local cat = GetWeaponCategory(curWeapon)

    if input == 'off' or input == 'clear' or input == 'default' then
        if cat then
            SaveSkin(cat, 'default')
            RemoveAllComponents(ped, curWeapon)
            RemoveProp()
        else
            for c in pairs(WeaponCategories) do SaveSkin(c, 'default') end
            RemoveProp()
        end
        return
    end

    local skinKey, sData = FindSkin(input, cat)
    if not skinKey or not sData then return end

    SaveSkin(sData.category, skinKey)

    if cat and curWeapon ~= 0 and curWeapon ~= UNARMED then
        RemoveAllComponents(ped, curWeapon)
        ApplySkinModel(ped, curWeapon, sData.model, sData.category)
    end
end, false)

RegisterCommand('homeoff', function()
    local ped = PlayerPedId()
    local curWeapon = GetSelectedPedWeapon(ped)
    local cat = GetWeaponCategory(curWeapon)
    if cat then
        SaveSkin(cat, 'default')
        RemoveAllComponents(ped, curWeapon)
    else
        for c in pairs(WeaponCategories) do SaveSkin(c, 'default') end
    end
    RemoveProp()
end, false)

function ShowSkinList()
    local poolList, bottleList = {}, {}
    for k, v in pairs(MasterSkins) do
        if v.category == 'POOLCUE' then
            poolList[#poolList + 1] = k
        elseif v.category == 'BOTTLE' then
            bottleList[#bottleList + 1] = k
        end
    end
    table.sort(poolList)
    table.sort(bottleList)

    print('^2================== [AR WEAPON SKINS] ==================^7')
    print('^3--- POOLCUE ---^7')
    for _, name in ipairs(poolList) do
        print(('  /home ^6%-40s^7 (%s)'):format(name, MasterSkins[name].label))
    end
    print('^3--- BOTTLE/KNIFE ---^7')
    for _, name in ipairs(bottleList) do
        print(('  /home ^6%-40s^7 (%s)'):format(name, MasterSkins[name].label))
    end
    print('^2========================================================^7')

    pcall(function()
        TriggerEvent('chat:addMessage', {
            args = { '[SKIN]', '^2[F8 ดูรายชื่อ]^0 ถืออาวุธ พิมพ์ ^3/home [ชื่อ]^0 | ถอด: ^1/home off^0 หรือ ^1/homeoff^0' }
        })
    end)
end

RegisterCommand('homelist', function()
    ShowSkinList()
end, false)