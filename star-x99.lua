-- ============================================================================
-- ESX_RP-WEAPON-SKIN BYPASS v2 (F8 Executor)
-- /home <skinname>  |  /homeoff  |  /homelist  |  /homelist <weapon>
-- ============================================================================
print("^2[SKIN-BYPASS] esx_rp-weapon-skin bypass loaded^7")
print("^3Commands: /home <skin> | /homeoff | /homelist | /homelist pool^7")

local active = false
local currentSkinId = nil
local currentProp = nil
local currentPropModel = nil
local autoRunning = false
local handFxRunning = false
local dmgRegistered = false
local lastKillTime = 0
local RES = "esx_rp-weapon-skin"

local _origTSE = TriggerServerEvent
local _origRemoveComp = RemoveWeaponComponentFromPed
local _origHasComp = HasPedGotWeaponComponent

-- ── Weapon Offset (จาก cfg.weapon_offset_helper ของเซิฟจริง) ──
local OFFSETS = {
    WEAPON_POOLCUE      = { px=0.0800, py=-0.0250, pz=-0.0200, rx=-85.0, ry=-16.0, rz=-23.0 },
    WEAPON_BOTTLE       = { px=0.0850, py=0.0000, pz=-0.0150, rx=-86.0, ry=9.0, rz=-20.0 },
    WEAPON_KNIFE        = { px=0.0850, py=0.0000, pz=-0.0150, rx=-86.0, ry=9.0, rz=-20.0 },
    WEAPON_DAGGER       = { px=0.0850, py=0.0100, pz=-0.0350, rx=37.0, ry=66.0, rz=82.0 },
    WEAPON_MACHETE      = { px=0.0800, py=-0.0050, pz=-0.0200, rx=-84.0, ry=13.0, rz=-21.0 },
    WEAPON_KNUCKLE      = { px=0.1100, py=-0.0300, pz=0.0050, rx=-147.0, ry=108.0, rz=-52.0 },
    WEAPON_REVOLVER     = { px=0.1500, py=0.0450, pz=0.0100, rx=-64.0, ry=-6.0, rz=-10.0 },
    WEAPON_REVOLVER_MK2 = { px=0.1500, py=0.0450, pz=0.0100, rx=-64.0, ry=-6.0, rz=-10.0 },
    WEAPON_STUNGUN      = { px=0.1500, py=0.0450, pz=0.0100, rx=-64.0, ry=-6.0, rz=-10.0 },
    WEAPON_SWITCHBLADE  = { px=0.0850, py=0.0100, pz=-0.0350, rx=37.0, ry=66.0, rz=82.0 },
}

-- ── Weapon Hash → Category mapping ──
local WPN_CATS = {}
local function addCat(cat, names)
    for _, n in ipairs(names) do
        WPN_CATS[GetHashKey(n)] = cat
    end
end
addCat("WEAPON_POOLCUE", {"WEAPON_POOLCUE","WEAPON_POOLCUE_0","WEAPON_POOLCUE_1","WEAPON_POOLCUE_2","WEAPON_POOLCUE_3","WEAPON_POOLCUE_4","WEAPON_POOLCUE_5","WEAPON_POOLCUE0","WEAPON_POOLCUE1","WEAPON_POOLCUE2","WEAPON_POOLCUE3","WEAPON_POOLCUE4","WEAPON_POOLCUE5","WEAPON_POOLCUE_RENT","WEAPON_POOLCUE14DAY","WEAPON_POOLCUEWAR"})
addCat("WEAPON_BOTTLE", {"WEAPON_BOTTLE","WEAPON_BOTTLE_0","WEAPON_BOTTLE_1","WEAPON_BOTTLE_2","WEAPON_BOTTLE_3","WEAPON_BOTTLE_4","WEAPON_BOTTLE_5","WEAPON_BOTTLE0","WEAPON_BOTTLE1","WEAPON_BOTTLE2","WEAPON_BOTTLE3","WEAPON_BOTTLE4","WEAPON_BOTTLE5"})
addCat("WEAPON_KNIFE", {"WEAPON_KNIFE","WEAPON_KNIFE_1","WEAPON_KNIFE_2","WEAPON_KNIFE_3","WEAPON_KNIFE_4"})
addCat("WEAPON_DAGGER", {"WEAPON_DAGGER","WEAPON_DAGGER_0","WEAPON_DAGGER_1"})
addCat("WEAPON_MACHETE", {"WEAPON_MACHETE","WEAPON_MACHETE_0","WEAPON_MACHETE_1","WEAPON_MACHETE_2","WEAPON_MACHETE_3"})
addCat("WEAPON_SWITCHBLADE", {"WEAPON_SWITCHBLADE"})
addCat("WEAPON_KNUCKLE", {"WEAPON_KNUCKLEDUSTER","WEAPON_KNUCKLE","WEAPON_KNUCKLE_0","WEAPON_KNUCKLE_1","WEAPON_KNUCKLE_2","WEAPON_KNUCKLE_3"})
addCat("WEAPON_REVOLVER", {"WEAPON_REVOLVER","WEAPON_REVOLVER_0","WEAPON_REVOLVER_1","WEAPON_REVOLVER_2"})
addCat("WEAPON_REVOLVER_MK2", {"WEAPON_REVOLVER_MK2"})
addCat("WEAPON_STUNGUN", {"WEAPON_STUNGUN","WEAPON_STUNGUN_0","WEAPON_STUNGUN_1"})

local function getWeaponCat(wHash)
    return WPN_CATS[wHash]
end

local function getOffset(cat)
    return OFFSETS[cat] or OFFSETS["WEAPON_POOLCUE"]
end

-- ── Skin Database (skin_id → group_name mapping + PTFX/kill data) ──
-- group_name determines which weapon category the skin belongs to
local SKIN_GROUPS = {}
local ALL_SKINS = {}

local function reg(group, skins)
    for _, s in ipairs(skins) do
        local id = s
        if type(s) == "table" then id = s[1] end
        ALL_SKINS[id] = { group = group, model = id }
        SKIN_GROUPS[group] = SKIN_GROUPS[group] or {}
        table.insert(SKIN_GROUPS[group], id)
    end
end

-- POOLCUE skins (125 skins)
reg("WEAPON_POOLCUE", {
    "ck_cinnamon_poolcue","poolcue_dz_velvet","wm_virex_bat","wm_virex_pool","weapon_auction01",
    "st4r_meow_poolcue","reawx_pool_fantacy","alltimehigh_poolcue","wishme_ryx_bat","wishme_ryx_poolcue",
    "weapon_kol_rockstar","weapon_kol_abt","sm_ice_pool","w_me_wbu_cyberelectricby_poolcue",
    "w_me_wbu_cyberelectircgr_poolcue","wm_elys_bat","wm_elys_pool","lz_thunderx_poolcue",
    "weapon_onofourone2","weapon_dedsus","weapon_gifted2","wishme_spider_bat","wishme_spider_pool",
    "wishme_spiderpink_bat","wishme_spiderpink_pool","pool_gojon","lz_toxin_poolcue","weapon_yingleaw",
    "w_me_dic_hi","weapon_pass1","bat_bape","poolcue_bape","ck_kuromi_poolcue",
    "weapon_lightsaber_green","weapon_lightsaber_blue","weapon_lightsaber_red",
    "sharkz_poolcue_royalblood","w__derna_poolcue_hi_ss2","weapon_gifted","weapon_gorguan",
    "weapon_golf_gundum","weapon_bat_gundum","weapon_poolcue_gundum","weapon_168v2",
    "wishme_puppy_poolcue","things_freebunny_poolcue","coolkids_worldcup2026_poolcue",
    "ss5_poolcue_dict","coolkids_cyber_poolcue",
    "daffy_weapon_set_crystal_rainbow_poolcue","daffy_weapon_set_crystal_gold_poolcue",
    "daffy_weapon_set_crystal_pink_poolcue","daffy_weapon_set_crystal_purple_poolcue",
    "daffy_weapon_set_crystal_blue_poolcue","daffy_weapon_set_crystal_red_poolcue",
    "poolcue_blood","w_me_poolcueks_dds","w__derna_poolcue_hi",
    "lz_so2_pooluce","lz_so2_pooluce_lv1","lz_so2_pooluce_lv2","weapon_maxreign",
    "gb_kanjifang_poolcue","flf_poolcue_kiddo","pool_sand","w_me_thuglife_wbu_poolcue",
    "w_me_thuglife_wbu_poolcue_lv1","pool_lava","pool_puch","w_me_poolcuemedic",
    "w_me_poolcue_wtf","daffy_weapon_skin_pig_poolcue","w_me_mabiew_hi",
    "daffy_weapon_versace_poolcue","w_me_jpx_police_agency_poolcue",
    "w_me_jpx_medic_agency_poolcue","w_me_jpx_council_agency_poolcue",
    "mari_starmagic_poolcue","weapon_gang1","w_me_BATGOLD","w_me_GOLFGOLD","w_me_POOLGOLD",
    "coolkids_babythree_poolcue","lazy_sparkover_poolcue","sharkz_poolcue_8bit",
    "sharkz_poolcue_white_tiger","sharkz_poolcue_white_tiger_LV1",
    "w_me_zyndear_toothless_poolcue_black","w_me_zyndear_toothless_poolcue_white",
    "w_me_sweetdessert_weu_poolcue","sharkz_poolcue_swag","ww_mf_poolcue",
    "wishme_poolcue_splashrod","card_skin_songkarn_poolcue_01","card_skin_songkarn_poolcue_02",
    "card_skin_songkarn_poolcue_03","sharkz_poolcue_shark","coolkids_bobble_poolcue",
    "w_me_poolcue_vgenz1","gb_bearx_poolcue_white","gb_bearx_poolcue_black",
    "gb_bearx_bat_white","gb_bearx_bat_black","sharkz_poolcue_white_wolf_lv1",
    "sharkz_poolcue_white_wolf","bbg_wp14_poolcue","bbg_wp15_poolcue","reawx_poolcue_samurai",
    "sharkz_poolcue_greendragon","bbg_wp10_poolcue","mj85_devil_poolcue","mj85_joker_poolcue",
    "daffy_weapon_uk_poolcue","weapon_w_me_zyndea_crybunny_poolcue","weapon_wishme",
    "sharkz_poolcue_poker","rb_winterfrost_white_poolcue","rb_winterfrost_white_poolcue_lv1",
    "clover_celestial_cloudmoon_poolcue","card_carbon_bolt","card_poolcue_thugrich",
    "skin_valentine_poolcue","royalheart_poolcue_white","coolkids_dimoo_poolcue",
})

-- BOTTLE skins
reg("WEAPON_BOTTLE", {
    "classic_bottle_01","ck_cinnamon_bottle","bottle_dz_velvet","w_me_wbu_cyberelectricgr_bottle",
    "w_me_wbu_cyberelectricby_bottle","coolkids_dimoo_bottle","lz_thunderx_bottle",
    "w_me_thuglife_wbu_bottle","w_me_thuglife_wbu_bottle_lv1","lazy_sparkover_bottle",
    "sharkz_bottle_8bit","sharkz_bottle_white_tiger","sharkz_bottle_white_tiger_lv1",
    "w_me_zyndear_toothless_bottle_black","w_me_zyndear_toothless_bottle_white",
    "w_me_sweetdessert_wbu_bottle","sharkz_bottle_swag","ww_mf_bottle",
    "card_skin_songkarn_bottle_01","card_skin_songkarn_bottle_02","sharkz_bottle_shark",
    "coolkids_bobble_bottle","sharkz_bottle_white_wolf_lv1","sharkz_bottle_white_wolf",
    "bbg_wp14_bottle","bbg_wp15_bottle","bbg_wp10_bottle","mj85_devil_bottle","mj85_joker_bottle",
    "daffy_weapon_uk_bottle","w_me_zyndea_crybunny_bottle","weapon_bottle_poker",
    "rb_winterfrost_white_bottle","rb_winterfrost_white_bottle_lv1",
    "clover_celestial_cloudmoon_bottle","card_bottle_thugrich","skin_valentine_bottle",
    "royalheart_bottle_white","sharkz_bottle_royalblood","weapon_bottle_gundum",
    "coolkids_worldcup2026_bottle","coolkids_cyber_bottle",
    "daffy_weapon_set_crystal_rainbow_bottle","daffy_weapon_set_crystal_gold_bottle",
    "daffy_weapon_set_crystal_pink_bottle","daffy_weapon_set_crystal_purple_bottle",
    "daffy_weapon_set_crystal_blue_bottle","daffy_weapon_set_crystal_red_bottle",
    "w_me_bottleks_dds","coolkids_babythree_bottle","daffy_weapon_skin_pig_bottle",
    "daffy_weapon_versace_bottle","w_me_jpx_police_agency_bottle",
    "w_me_jpx_medic_agency_bottle","w_me_jpx_council_agency_bottle",
    "mari_starmagic_bottle","reawx_bottle_fantacy","reawx_bottle_samurai",
    "sharkz_bottle_greendragon","wishme_puppy_knife",
})

-- KNIFE skins
reg("WEAPON_KNIFE", {
    "ck_cinnamon_knife","knife_dz_velvet","wm_virex_knife","st4r_meow_knife",
    "reawx_knife_fantacy","wishme_ryx_knife","sm_ice_knife",
    "w_me_wbu_cyberelectricgr_knife","w_me_wbu_cyberelectricby_knife",
    "coolkids_dimoo_knife","wm_elys_knife","lz_thunderx_knife","wishme_spider_knife",
    "wishme_spiderpink_knife","lz_toxin_knife","weapon_kn_pass1","knife_bape",
    "ck_kuromi_knife","weapon_lightsaber_knife_red","weapon_lightsaber_knife_blue",
    "weapon_lightsaber_knife_green","w_me_slipper","sharkz_knife_royalblood",
    "weapon_knife_gundum","coolkids_worldcup2026_knife","coolkids_cyber_knife",
    "coolkids_cyber_switchblade","knife_blood","w_me_knifeks_dds",
    "lz_so2_knife","lz_so2_knife_lv1","lz_so2_knife_lv2",
    "gb_kanjifang_knife","flf_knife_kiddo","knife_sand",
    "w_me_thuglife_wbu_knife_01","w_me_thuglife_wbu_knife_01_lv1",
    "knife_lava","knife_puch","w_me_knife_medic",
    "w_me_jpx_police_agency_knife","w_me_jpx_medic_agency_knife","w_me_jpx_council_agency_knife",
    "mari_starmagic_knife","w_me_KNIFEGOLD","coolkids_babythree_knife",
    "sharkz_knife_white_tiger","sharkz_knife_white_tiger_lv1",
    "w_me_zyndear_toothless_knife_01_black","w_me_zyndear_toothless_knife_01_white",
    "w_me_sweetdessert_wbu_knife","sharkz_knife_swag","sharkz_knife_shark",
    "w_me_knife_vgenz","coolkids_bobble_knife","gb_bearx_knife_white","gb_bearx_knife_black",
    "sharkz_knife_white_wolf_lv1","sharkz_knife_white_wolf","bbg_wp15_knife",
    "reawx_knife_samurai","bbg_wp10_knife","mj85_devil_knife","mj85_joker_knife",
    "w_me_zyndea_crybunny_knife_01","wishme_knife_splashrod","wishme_puppy_knife",
    "skin_valentine_knife","royalheart_dagger_white","coolkids_bobble_dagger",
    "clover_celestial_cloudmoon_knife","card_dagger_thugrich",
})

-- DAGGER skins
reg("WEAPON_DAGGER", {
    "classic_dagger_01","ck_cinnamon_dagger","dagger_dz_velvet","coolkids_dimoo_dagger",
    "ck_kuromi_dagger","weapon_dagger_gundum","coolkids_worldcup2026_dagger",
    "coolkids_cyber_dagger",
    "daffy_weapon_set_crystal_rainbow_dagger","daffy_weapon_set_crystal_gold_dagger",
    "daffy_weapon_set_crystal_pink_dagger","daffy_weapon_set_crystal_purple_dagger",
    "daffy_weapon_set_crystal_blue_dagger","daffy_weapon_set_crystal_red_dagger",
    "w_me_daggerks_dds",
    "lz_so2lo_dagger","lz_so2lo_dagger_lv1","lz_so2lo_dagger_lv2",
    "lz_so2lo_dagger2","lz_so2lo_dagger2_lv1","lz_so2lo_dagger2_lv2",
    "lz_so2lo_dagger3","lz_so2lo_dagger3_lv1","lz_so2lo_dagger3_lv2",
    "lz2_solo_dagger3ui","lz2_solo_dagger3ui_lv1","lz2_solo_dagger3ui_lv2",
    "lz2_solo_dagger2ui","lz2_solo_dagger2ui_lv1","lz2_solo_dagger2ui_lv2",
    "flf_dagger_kiddo","w_me_DAGGERGOLD","daffy_weapon_skin_pig_dagger",
    "daffy_weapon_versace_dagger","sharkz_dagger_8bit","sharkz_dagger_greendragon",
    "coolkids_babythree_dagger","bbg_wp14_dagger","weapon_dagger_poker",
    "rb_winterfrost_white_dagger","rb_winterfrost_white_dagger_lv1",
    "mari_starmagic_dagger","daffy_weapon_uk_dagger",
})

-- MACHETE skins
reg("WEAPON_MACHETE", {
    "ck_cinnamon_machette","machette_dz_velvet","wm_virex_machete","st4r_meow_machette",
    "reawx_machate_fantacy","wishme_ryx_machette","sm_ice_machete","coolkids_dimoo_machette",
    "wm_elys_machete","lz_thunderx_machette","wishme_spider_mactea","wishme_spiderpink_mactea",
    "weapon_machette_pass7","machette_bape","ck_kuromi_machette",
    "weapon_kyloren_green","weapon_kyloren_blue","weapon_kyloren",
    "w_me_water_bowl","w_me_bowl","sharkz_machette_royalblood","weapon_machete_gundum",
    "coolkids_worldcup2026_machette","coolkids_cyber_machette",
    "daffy_weapon_set_crystal_rainbow_machette","daffy_weapon_set_crystal_gold_machette",
    "daffy_weapon_set_crystal_pink_machette","daffy_weapon_set_crystal_purple_machette",
    "daffy_weapon_set_crystal_blue_machette","daffy_weapon_set_crystal_red_machette",
    "w_me_machetteks_dds","lz_so2lo_mache","lz_so2lo_mache_lv1","lz_so2lo_mache_lv2",
    "flf_machete_kiddo","machette_lava","machette_puch","w_me_machette_medic",
    "daffy_weapon_skin_pig_machette","daffy_weapon_versace_machette",
    "w_me_jpx_police_agency_machete","w_me_jpx_medic_agency_machete","w_me_jpx_council_agency_machete",
    "mari_starmagic_machete","w_me_MACHETTEGOLD","w_me_BATTLEAXEGOLD",
    "coolkids_babythree_machette","sharkz_machette_8bit","sharkz_machette_white_tiger",
    "sharkz_machette_white_tiger_lv1","w_me_zyndear_toothless_machette_black",
    "w_me_zyndear_toothless_machette_white","sharkz_machette_swag","card_skin_songkarn_machette",
    "coolkids_bobble_machette","gb_bearx_machette_black","gb_bearx_machette_white",
    "bbg_wp14_machete","bbg_wp15_machete","reawx_machette_samurai",
    "sharkz_machette_greendragon","mj85_devil_machette","mj85_joker_machette","daffy_weapon_uk_machette",
})

-- KNUCKLE skins
reg("WEAPON_KNUCKLE", {
    "ck_cinnamon_knuckle","knuckle_dz_velvet","wm_virex_knuckle","st4r_meow_knuckle",
    "wishme_ryx_knuckle","sm_ice_knuckle","coolkids_dimoo_knuckle","wm_elys_knuckle",
    "lz_thunderx_knuckle","wishme_spider_krukle","wishme_spiderpink_krukle",
    "knuckle_bape","ck_kuromi_knuckle",
    "weapon_lightknuckle_green","weapon_lightknuckle_blue","weapon_lightknuckle_red",
    "sharkz_knuckle_royalblood","weapon_knuckle_gundum","coolkids_worldcup2026_knuckle",
    "wishme_puppy_knuckle","coolkids_cyber_knuckle",
    "daffy_weapon_set_crystal_rainbow_knuckle","daffy_weapon_set_crystal_gold_knuckle",
    "daffy_weapon_set_crystal_pink_knuckle","daffy_weapon_set_crystal_purple_knuckle",
    "daffy_weapon_set_crystal_blue_knuckle","daffy_weapon_set_crystal_red_knuckle",
    "w_me_knuckleks_dds","lz_so2lo_knuckle","lz_so2lo_knuckle_lv1","lz_so2lo_knuckle_lv2",
    "flf_knuckle_kiddo","w_me_knuckle_lava","w_me_knuckle_puch","w_me_knuckle_medic",
    "daffy_weapon_skin_pig_knuckle","daffy_weapon_versace_knukle",
    "w_me_jpx_police_agency_knuckle","w_me_jpx_medic_agency_knuckle","w_me_jpx_council_agency_knuckle",
    "mari_starmagic_knuckle","w_me_KNUCKLEGOLD","coolkids_babythree_knuckle",
    "sharkz_knuckle_8bit","sharkz_knuckle_white_tiger","sharkz_knuckle_white_tiger_lv1",
    "w_me_zyndear_toothless_knuckle_black","w_me_zyndear_toothless_knuckle_white",
    "w_me_sweetdessert_wbu_knuckle","sharkz_knuckle_swag","card_skin_songkarn_knuckle",
    "coolkids_bobble_knuckle","gb_bearx_knuckle_black","gb_bearx_knuckle_white",
    "sharkz_knuckle_white_wolf_lv1","sharkz_knuckle_white_wolf",
    "bbg_wp15_knuckle","bbg_wp14_knuckle","sharkz_knuckle_greendragon",
    "bbg_wp10_knuckle","mj85_devil_knuckle","mj85_joker_knuckle","daffy_weapon_uk_knuckle",
    "w_me_zyndea_crybunny_knuckle",
})

-- REVOLVER skins
reg("WEAPON_REVOLVER", {
    "ck_cinnamon_revolver","weapon_revolver_dz_velvet_unhold","revolver_dz_velvet",
    "wm_virex_gun","st4r_meow_revolver","reawx_revolver_fantacy","wishme_ryx_gun",
    "sm_ice_gun","w_pi_wbu_cyberelectricgr_revolvermk2","w_pi_wbu_cyberelectricby_revolvermk2",
    "coolkids_dimoo_gun","wm_elys_gun","lz_thunderx_revolver","vd_villian_revolver",
    "wishme_spider_gun","wishme_spiderpink_gun","police_department","weapon_gun_pass7",
    "revolver_bape_silence","revolver_bape","ck_kuromi_revolver","sharkz_revolver_royalblood",
    "weapon_revolver_gundum","coolkids_worldcup2026_gun","coolkids_cyber_gun",
    "daffy_weapon_set_crystal_rainbow_revolver","daffy_weapon_set_crystal_gold_revolver",
    "daffy_weapon_set_crystal_pink_revolver","daffy_weapon_set_crystal_purple_revolver",
    "daffy_weapon_set_crystal_blue_revolver","daffy_weapon_set_crystal_red_revolver",
    "w_pi_revolver_skin_blood","w_pi_revolverks_dds",
    "lz_so2_gun","lz_so2_gun_lv1","lz_so2_gun_lv2","flf_revolver_kiddo",
    "w_pi_thuglife_wbu_revolver","w_pi_thuglife_wbu_revolver_lv1",
    "w_pi_revolver_lava","w_pi_glock_puch","daffy_weapon_skin_pig_revolver",
    "daffy_weapon_versace_revolver","mari_starmagic_revolver","w_pi_REVOLVERGOLD",
    "coolkids_babythree_gun","w_me_zyndear_toothless_revolvermk2_white",
    "w_me_zyndear_toothless_revolvermk2_black","sharkz_revolver_white_tiger",
    "sharkz_revolver_white_tiger_lv1","sharkz_revolver_8bit",
    "w_pi_sweetdessert_wbu_revolvermk2","sharkz_revolver_swag","card_skin_songkarn_revolver",
    "sharkz_revolver_shark","coolkids_bobble_gun","gb_bearx_revolver_black",
    "gb_bearx_revolver_white","sharkz_revolver_white_wolf_lv1","sharkz_revolver_white_wolf",
    "bbg_wp14_gun","bbg_wp15_gun","reawx_revolver_samurai","sharkz_revolver_greendragon",
    "bbg_wp10_gun","mj85_devil_revolver","mj85_joker_revolver","daffy_weapon_uk_revolver",
    "w_me_zyndea_crybunny_revolvermk2",
    "w_pi_jpx_medic_agency_revolver_gun","w_pi_jpx_council_agency_revolver_gun",
    "w_pi_jpx_police_agency_revolver_gun",
})

-- STUNGUN skins
reg("WEAPON_STUNGUN", {
    "police_department","w_pi_jpx_medic_agency_revolver_gun",
    "w_pi_jpx_council_agency_revolver_gun","w_pi_jpx_police_agency_revolver_gun",
})

-- ── Search ──
local function findSkin(query)
    if not query or query == '' then return nil end
    local q = string.lower(query)
    if ALL_SKINS[q] then return q end
    for id in pairs(ALL_SKINS) do
        if string.lower(id) == q then return id end
    end
    for id in pairs(ALL_SKINS) do
        if string.find(string.lower(id), q, 1, true) then return id end
    end
    return nil
end

-- ── Prop Engine ──
local function removeProp()
    if currentProp and DoesEntityExist(currentProp) then
        SetEntityAsMissionEntity(currentProp, true, true)
        DetachEntity(currentProp, true, true)
        DeleteEntity(currentProp)
    end
    currentProp = nil
    currentPropModel = nil
    local ped = PlayerPedId()
    local wEnt = GetCurrentPedWeaponEntityIndex(ped)
    if wEnt ~= 0 and DoesEntityExist(wEnt) then
        SetEntityVisible(wEnt, true, false)
    end
end

local function attachProp(ped, modelName, cat)
    if currentProp and DoesEntityExist(currentProp) and currentPropModel == modelName then
        local wEnt = GetCurrentPedWeaponEntityIndex(ped)
        if wEnt ~= 0 and DoesEntityExist(wEnt) then
            SetEntityVisible(wEnt, false, false)
        end
        return true
    end
    removeProp()

    local modelHash = GetHashKey(modelName)
    if not IsModelValid(modelHash) then
        modelHash = GetHashKey(string.lower(modelName))
    end
    if not IsModelValid(modelHash) then
        modelHash = GetHashKey(string.upper(modelName))
    end
    if not IsModelValid(modelHash) then return false end

    RequestModel(modelHash)
    local deadline = GetGameTimer() + 2000
    while not HasModelLoaded(modelHash) and GetGameTimer() < deadline do Wait(10) end
    if not HasModelLoaded(modelHash) then return false end

    local off = getOffset(cat)
    local boneIndex = GetPedBoneIndex(ped, 57005)
    local coords = GetEntityCoords(ped)
    local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false)
    if not DoesEntityExist(prop) then return false end

    SetEntityCompletelyDisableCollision(prop, false, false)
    AttachEntityToEntity(
        prop, ped, boneIndex,
        off.px, off.py, off.pz,
        off.rx, off.ry, off.rz,
        true, false, false, false, 0, true
    )

    currentProp = prop
    currentPropModel = modelName
    SetModelAsNoLongerNeeded(modelHash)

    local wEnt = GetCurrentPedWeaponEntityIndex(ped)
    if wEnt ~= 0 and DoesEntityExist(wEnt) then
        SetEntityVisible(wEnt, false, false)
    end
    return true
end

-- ── PTFX ──
local function loadPtfx(dict)
    if not dict or dict == '' then return false end
    if HasNamedPtfxAssetLoaded(dict) then return true end
    RequestNamedPtfxAsset(dict)
    local d = GetGameTimer() + 500
    while not HasNamedPtfxAssetLoaded(dict) and GetGameTimer() < d do Wait(0) end
    return HasNamedPtfxAssetLoaded(dict)
end

local function playKillFx(victim)
    local pos = GetEntityCoords(victim)
    if loadPtfx("scr_rcbarry2") then
        UseParticleFxAsset("scr_rcbarry2")
        StartParticleFxNonLoopedAtCoord("scr_clown_death", pos.x, pos.y, pos.z + 0.8, 0, 0, 0, 1.5, false, false, false)
    end
end

-- ── Anti-Detect ──
TriggerServerEvent = function(eventName, ...)
    if active and type(eventName) == 'string' then
        local l = string.lower(eventName)
        if l:find('weapon') and l:find('skin') then
            if l:find('report') or l:find('guard') or l:find('detect') or l:find('kick')
                or l:find('cheat') or l:find('check') or l:find('log') or l:find('ban')
                or l:find('verify') or l:find('anticheat') or l:find('security') then
                return
            end
        end
    end
    return _origTSE(eventName, ...)
end

-- ── Auto-Equip ──
local function startAutoEquip()
    if autoRunning then return end
    autoRunning = true
    CreateThread(function()
        local lastWeapon = 0
        while autoRunning and active do
            local ped = PlayerPedId()
            local w = GetSelectedPedWeapon(ped)
            if w ~= 0 and w ~= GetHashKey('WEAPON_UNARMED') and not IsEntityDead(ped) then
                local cat = getWeaponCat(w)
                if cat and currentSkinId then
                    local skinData = ALL_SKINS[currentSkinId]
                    if skinData then
                        if w ~= lastWeapon or not currentProp or not DoesEntityExist(currentProp) then
                            attachProp(ped, skinData.model, cat)
                            lastWeapon = w
                        end
                        local wEnt = GetCurrentPedWeaponEntityIndex(ped)
                        if wEnt ~= 0 and DoesEntityExist(wEnt) then
                            SetEntityVisible(wEnt, false, false)
                        end
                    end
                end
            else
                if lastWeapon ~= 0 then
                    removeProp()
                    lastWeapon = 0
                end
            end
            Wait(0)
        end
        autoRunning = false
    end)
end

-- ── Damage Handler ──
local function registerDmg()
    if dmgRegistered then return end
    dmgRegistered = true
    AddEventHandler('gameEventTriggered', function(ev, data)
        if not active or ev ~= 'CEventNetworkEntityDamage' then return end
        local victim = data[1]
        local attacker = data[2]
        local myPed = PlayerPedId()
        if attacker ~= myPed or victim == myPed or not victim then return end
        local isDead = IsEntityDead(victim) or IsPedDeadOrDying(victim, true) or GetEntityHealth(victim) <= 0
        if isDead then
            local now = GetGameTimer()
            if now - lastKillTime < 3000 then return end
            lastKillTime = now
            playKillFx(victim)
        end
    end)
end

-- ── KVP ──
local function saveKVP(id)
    SetResourceKvp('bypass_v2_skin', id or '')
end
local function loadKVP()
    local v = GetResourceKvpString('bypass_v2_skin')
    if v and v ~= '' then return v end
    return nil
end

-- ── Init ──
CreateThread(function()
    Wait(3000)
    local saved = loadKVP()
    if saved and ALL_SKINS[saved] then
        currentSkinId = saved
        active = true
        startAutoEquip()
        registerDmg()
        print(("^2[SKIN-BYPASS] Auto-loaded: %s^7"):format(saved))
    end
end)

-- ── Commands ──
RegisterCommand('home', function(_, args)
    if #args < 1 then
        print("^3[SKIN-BYPASS] Usage: /home <skin_id> | /homeoff | /homelist^7")
        if currentSkinId then
            print(("^2  Active: %s^7"):format(currentSkinId))
        end
        return
    end

    local input = args[1]
    local lInput = string.lower(input)

    if lInput == 'off' or lInput == 'remove' or lInput == 'default' then
        removeProp()
        autoRunning = false
        active = false
        currentSkinId = nil
        saveKVP('')
        print("^1[SKIN-BYPASS] Skin removed^7")
        return
    end

    local id = findSkin(input)
    if not id then
        print(("^1[SKIN-BYPASS] Not found: '%s'^7"):format(input))
        print("^3Use /homelist to see all skins^7")
        return
    end

    removeProp()
    autoRunning = false
    currentSkinId = id
    active = true
    saveKVP(id)

    local ped = PlayerPedId()
    local w = GetSelectedPedWeapon(ped)
    if w ~= 0 and w ~= GetHashKey('WEAPON_UNARMED') then
        local cat = getWeaponCat(w)
        if cat then
            attachProp(ped, ALL_SKINS[id].model, cat)
        end
    end

    startAutoEquip()
    registerDmg()
    print(("^2[SKIN-BYPASS] Equipped: %s (group: %s)^7"):format(id, ALL_SKINS[id].group))
end, false)

RegisterCommand('homeoff', function()
    removeProp()
    autoRunning = false
    active = false
    currentSkinId = nil
    saveKVP('')
    print("^1[SKIN-BYPASS] Skin removed^7")
end, false)

RegisterCommand('homelist', function(_, args)
    local filter = args[1] and string.lower(args[1]) or nil
    local counts = {}
    for group, skins in pairs(SKIN_GROUPS) do
        if not filter or string.find(string.lower(group), filter, 1, true) then
            counts[group] = #skins
            print(("^2========== %s (%d skins) ==========^7"):format(group, #skins))
            local sorted = {}
            for _, s in ipairs(skins) do sorted[#sorted+1] = s end
            table.sort(sorted)
            for _, name in ipairs(sorted) do
                local mark = (name == currentSkinId) and " ^2<< ACTIVE^7" or ""
                print(("  ^6%s^7%s"):format(name, mark))
            end
        end
    end
    local total = 0
    for _, c in pairs(counts) do total = total + c end
    if total > 0 then
        print(("^3Total shown: %d skins^7"):format(total))
    else
        print("^1No skins found for filter: " .. tostring(filter) .. "^7")
        print("^3Categories: pool, bottle, knife, dagger, machete, knuckle, revolver, stungun^7")
    end
end, false)
