script_name('FBI Tools')
script_author('goatffs')
script_version('1.0.10')

local CONFIG = {
    AUTO_UPDATE = true,
    ALERT_INTERVAL = 30,  -- seconds
    BACKUP_INTERVAL = 10, -- seconds
    SU_INTERVAL = 900,    -- 15 minutes
    VEHICLE_HEALTH_THRESHOLDS = {
        [5000] = true,
        [4000] = true,
        [3000] = true,
        [2000] = true
    },
    AUTO_FIND_DELAYS = { -- I need actual data !
        [1] = 80,
        [2] = 70,
        [3] = 60,
        [4] = 47, -- verified
        [5] = 40,
        [6] = 30,
        [7] = 20,
        [8] = 10,
        [9] = 5,
        [10] = 0
    },
    QUIT_REASONS = {
        [0] = 'потеря связи/краш',
        [1] = 'вышел из игры',
        [2] = 'кикнул сервер/забанили'
    },
    WALKIE_TALKIE_MAX_LENGTH = 60,
    WALKIE_TALKIE_SEND_DELAY = 1500
}

local enable_autoupdate = CONFIG.AUTO_UPDATE
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring,
        [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url =
                "https://raw.githubusercontent.com/no-sanity-glitch/fbi-tools/refs/heads/main/version.json?" ..
                tostring(os.clock())
            Update.prefix = "{AC0046}[Tools]: "
            Update.url = "https://github.com/no-sanity-glitch/fbi-tools/"
        end
    end
end

require "lib.moonloader"
local imgui = require "imgui"
local inicfg = require 'inicfg'
local ImVec2 = imgui.ImVec2
local ImVec4 = imgui.ImVec4
local imadd = require 'imgui_addons'
local sampev = require 'lib.samp.events'
local vkeys = require "vkeys"
local rkeys = require 'rkeys'
imgui.HotKey = imadd.HotKey
local fa = require 'faIcons'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })
local encoding = require "encoding"
encoding.default = "CP1251"
u8 = encoding.UTF8

local mainIni = inicfg.load({
    config = {
        intImGui = 0,
        auto_find_level_selected = 10,
        skin = 0
    },
    admin = {
        nameTitle = false,
    },
    hotkeys = {
        main_menu = encodeJson({ vkeys.VK_F2 }),
        battlepass = encodeJson({ vkeys.VK_F3 }),
        backup = encodeJson({ vkeys.VK_U }),
        su = encodeJson({ vkeys.VK_I }),
        crosshair = encodeJson({ vkeys.VK_DELETE }),
        cruise_control_state = encodeJson({ vkeys.VK_NUMPAD8 }),
        cruise_control_speed_up = encodeJson({ vkeys.VK_MULTIPLY }),
        cruise_control_slow_down = encodeJson({ vkeys.VK_SUBTRACT }),
        bindTazer = encodeJson({ vkeys.VK_B }),
        bindBandage = encodeJson({ vkeys.VK_R }),
    },
    state = {
        auto_alert = false,
        auto_find = false,
        auto_fix = false,
        stroboscopes = false,
        cfgBindBattlePass = false,
        bindTazer = false,
        bindBandage = false,
        binder = false,
        bind_cuff = false,
        bind_fme = false,
        bind_frisk = false,
        bind_incar = false,
        bind_eject = false,
        bind_arest = false,
    },
    infopanel = {
        infoPanel = false,
        btnInfoPanel = false,
        btnInfoPanelID = false,
        btnInfoPanelCity = false,
        btnInfoPanelZone = false,
        btnInfoPanelPing = false,
        btnInfoPanelFPS = false,
        btnInfoPanelDateTime = false,

        widgetInfoPanelPosX = 400,
        widgetInfoPanelPosY = 400,
    }
}, 'Tools')

local json = getWorkingDirectory() .. '\\config\\fbi_tools_binds.json'
local binds = {}

local MoveWidgetInfoPanel = false

function jsonSave(jsonFilePath, t)
    file = io.open(jsonFilePath, "w")
    file:write(encodeJson(t))
    file:flush()
    file:close()
end

function jsonRead(jsonFilePath)
    local file = io.open(jsonFilePath, "r+")
    local jsonInString = file:read("*a")
    file:close()
    local jsonTable = decodeJson(jsonInString)
    return jsonTable
end

local State = {
    main_window = imgui.ImBool(false),
    CheckBoxDialogID = imgui.ImBool(false),
    straboscopes = imgui.ImBool(mainIni.state.stroboscopes),
    bindBattlePass = imgui.ImBool(mainIni.state.cfgBindBattlePass),
    bindTazer = imgui.ImBool(mainIni.state.bindTazer),
    bindBandage = imgui.ImBool(mainIni.state.bindBandage),
    binder = imgui.ImBool(mainIni.state.binder),
    auto_alert_state = imgui.ImBool(mainIni.state.auto_alert),
    auto_alert_backup_text_buffer = imgui.ImBuffer(256),
    binder_cuff_text_buffer = imgui.ImBuffer(256),
    binder_fme_text_buffer = imgui.ImBuffer(256),
    binder_frisk_text_buffer = imgui.ImBuffer(256),
    binder_incar_text_buffer = imgui.ImBuffer(256),
    binder_eject_text_buffer = imgui.ImBuffer(256),
    binder_arest_text_buffer = imgui.ImBuffer(256),
    auto_find_state = imgui.ImBool(mainIni.state.auto_find),
    auto_fix_state = imgui.ImBool(mainIni.state.auto_fix),
    menu = 0,
    blackout = false,
    blackout_textdraw_id = nil,
    statusSsMode = false,
    main_color = mainIni.config.intImGui,
    skinSearch = imgui.ImBuffer(256),
    crosshair_state = false,

    -- BINDS
    show_cuff_text_edit = imgui.ImBool(false),
    show_fme_text_edit = imgui.ImBool(false),
    show_frisk_text_edit = imgui.ImBool(false),
    show_incar_text_edit = imgui.ImBool(false),
    show_eject_text_edit = imgui.ImBool(false),
    show_arest_text_edit = imgui.ImBool(false),
}

local AutoAlert = {
    lastGlobalBackupTime = 0,
    attackerCooldowns = {},
    suCooldowns = {},
    pendingAttacker = nil,
    pendingExpireTime = 0
}

local AutoFind = {
    state = false,
    targetId = nil,
    zoneDestroyed = false,
    checkpointDisabled = false
}

local AutoFix = {
    lastCheckTime = 0,
    fillTexts = {},
    tehvehTexts = {},
    isFilling = false
}

local Binder = {
    cuff = imgui.ImBool(mainIni.state.bind_cuff),
    fme = imgui.ImBool(mainIni.state.bind_fme),
    frisk = imgui.ImBool(mainIni.state.bind_frisk),
    incar = imgui.ImBool(mainIni.state.bind_incar),
    eject = imgui.ImBool(mainIni.state.bind_eject),
    arest = imgui.ImBool(mainIni.state.bind_arest),
}

local InfoPanel = {
    infoPanel = imgui.ImBool(mainIni.infopanel.infoPanel),
    btnInfoPanel = imgui.ImBool(mainIni.infopanel.btnInfoPanel),
    btnInfoPanelID = imgui.ImBool(mainIni.infopanel.btnInfoPanelID),
    btnInfoPanelCity = imgui.ImBool(mainIni.infopanel.btnInfoPanelCity),
    btnInfoPanelZone = imgui.ImBool(mainIni.infopanel.btnInfoPanelZone),
    btnInfoPanelPing = imgui.ImBool(mainIni.infopanel.btnInfoPanelPing),
    btnInfoPanelFPS = imgui.ImBool(mainIni.infopanel.btnInfoPanelFPS),
    btnInfoPanelDateTime = imgui.ImBool(mainIni.infopanel.btnInfoPanelDateTime),
}

local SkinChanger = {
    selectedSkin = mainIni.config.skin
}

local CruiseControl = {
    state = false,
    speed = 0,
}

local elements = {
    checkbox = {},
    static = { nameStatis = imgui.ImBool(mainIni.admin.nameTitle) },
    int = { intImGui = imgui.ImInt(mainIni.config.intImGui) },
}

local HotKeys = {
    main_menu = { v = decodeJson(mainIni.hotkeys.main_menu) },
    battlepass = { v = decodeJson(mainIni.hotkeys.battlepass) },
    backup = { v = decodeJson(mainIni.hotkeys.backup) },
    su = { v = decodeJson(mainIni.hotkeys.su) },
    crosshair = { v = decodeJson(mainIni.hotkeys.crosshair) },
    cruise_control_state = { v = decodeJson(mainIni.hotkeys.cruise_control_state) },
    cruise_control_speed_up = { v = decodeJson(mainIni.hotkeys.cruise_control_speed_up) },
    cruise_control_slow_down = { v = decodeJson(mainIni.hotkeys.cruise_control_slow_down) },
    bindTazer = { v = decodeJson(mainIni.hotkeys.bindTazer) },
    bindBandage = { v = decodeJson(mainIni.hotkeys.bindBandage) },
}

local pearsSkins = {}

local skins = {
    { id = 1,   name = 'The Truth' },
    { id = 2,   name = 'Maccer' },
    { id = 3,   name = 'Andre' },
    { id = 4,   name = 'Barry "Big Bear" Thorne [Thin]' },
    { id = 5,   name = 'Barry "Big Bear" Thorne [Big]' },
    { id = 6,   name = 'Emmet' },
    { id = 7,   name = 'Taxi Driver/Train Driver' },
    { id = 8,   name = 'Janitor' },
    { id = 9,   name = 'Normal Ped' },
    { id = 10,  name = 'Old Woman' },
    { id = 11,  name = 'Casino croupier' },
    { id = 12,  name = 'Rich Woman' },
    { id = 13,  name = 'Street Girl' },
    { id = 14,  name = 'Normal Ped' },
    { id = 15,  name = 'Mr.Whittaker (RS Haul Owner)' },
    { id = 16,  name = 'Airport Ground Worker' },
    { id = 17,  name = 'Businessman' },
    { id = 18,  name = 'Beach Visitor' },
    { id = 19,  name = 'DJ' },
    { id = 20,  name = 'Rich Guy (Madd Dogg\'s Manager)' },
    { id = 21,  name = 'Normal Ped' },
    { id = 22,  name = 'Normal Ped' },
    { id = 23,  name = 'BMXer' },
    { id = 24,  name = 'Madd Dogg Bodyguard' },
    { id = 25,  name = 'Madd Dogg Bodyguard' },
    { id = 26,  name = 'Backpacker' },
    { id = 27,  name = 'Construction Worker' },
    { id = 28,  name = 'Drug Dealer' },
    { id = 29,  name = 'Drug Dealer' },
    { id = 30,  name = 'Drug Dealer' },
    { id = 31,  name = 'Farm-Town inhabitant' },
    { id = 32,  name = 'Farm-Town inhabitant' },
    { id = 33,  name = 'Farm-Town inhabitant' },
    { id = 34,  name = 'Farm-Town inhabitant' },
    { id = 35,  name = 'Gardener' },
    { id = 36,  name = 'Golfer' },
    { id = 37,  name = 'Golfer' },
    { id = 38,  name = 'Normal Ped' },
    { id = 39,  name = 'Normal Ped' },
    { id = 40,  name = 'Normal Ped' },
    { id = 41,  name = 'Normal Ped' },
    { id = 42,  name = 'Jethro' },
    { id = 43,  name = 'Normal Ped' },
    { id = 44,  name = 'Normal Ped' },
    { id = 45,  name = 'Beach Visitor' },
    { id = 46,  name = 'Normal Ped' },
    { id = 47,  name = 'Normal Ped' },
    { id = 48,  name = 'Normal Ped' },
    { id = 49,  name = 'Snakehead (Da Nang)' },
    { id = 50,  name = 'Mechanic' },
    { id = 51,  name = 'Mountain Biker' },
    { id = 52,  name = 'Mountain Biker' },
    { id = 53,  name = 'Unknown' },
    { id = 54,  name = 'Normal Ped' },
    { id = 55,  name = 'Normal Ped' },
    { id = 56,  name = 'Normal Ped' },
    { id = 57,  name = 'Oriental Ped' },
    { id = 58,  name = 'Oriental Ped' },
    { id = 59,  name = 'Normal Ped' },
    { id = 60,  name = 'Normal Ped' },
    { id = 61,  name = 'Pilot' },
    { id = 62,  name = 'Colonel Fuhrberger' },
    { id = 63,  name = 'Prostitute' },
    { id = 64,  name = 'Prostitute' },
    { id = 65,  name = 'Kendl Johnson' },
    { id = 66,  name = 'Pool Player' },
    { id = 67,  name = 'Pool Player' },
    { id = 68,  name = 'Priest/Preacher' },
    { id = 69,  name = 'Normal Ped' },
    { id = 70,  name = 'Scientist' },
    { id = 71,  name = 'Security Guard' },
    { id = 72,  name = 'Hippy' },
    { id = 73,  name = 'Hippy' },
    { id = 75,  name = 'Prostitute' },
    { id = 76,  name = 'Stewardess' },
    { id = 77,  name = 'Homeless' },
    { id = 78,  name = 'Homeless' },
    { id = 79,  name = 'Homeless' },
    { id = 80,  name = 'Boxer' },
    { id = 81,  name = 'Boxer' },
    { id = 82,  name = 'Black Elvis' },
    { id = 83,  name = 'White Elvis' },
    { id = 84,  name = 'Blue Elvis' },
    { id = 85,  name = 'Prostitute' },
    { id = 86,  name = 'Ryder with robbery mask' },
    { id = 87,  name = 'Stripper' },
    { id = 88,  name = 'Normal Ped' },
    { id = 89,  name = 'Normal Ped' },
    { id = 90,  name = 'Jogger' },
    { id = 91,  name = 'Rich Woman' },
    { id = 93,  name = 'Normal Ped' },
    { id = 94,  name = 'Normal Ped' },
    { id = 95,  name = 'Normal Ped, Works at or owns Dillimore Gas Station' },
    { id = 96,  name = 'Jogger' },
    { id = 97,  name = 'Lifeguard' },
    { id = 98,  name = 'Normal Ped' },
    { id = 100, name = 'Biker' },
    { id = 101, name = 'Normal Ped' },
    { id = 102, name = 'Balla' },
    { id = 103, name = 'Balla' },
    { id = 104, name = 'Balla' },
    { id = 105, name = 'Grove Street Families' },
    { id = 106, name = 'Grove Street Families' },
    { id = 107, name = 'Grove Street Families' },
    { id = 108, name = 'Los Santos Vagos' },
    { id = 109, name = 'Los Santos Vagos' },
    { id = 110, name = 'Los Santos Vagos' },
    { id = 111, name = 'The Russian Mafia' },
    { id = 112, name = 'The Russian Mafia' },
    { id = 113, name = 'The Russian Mafia' },
    { id = 114, name = 'Varios Los Aztecas' },
    { id = 115, name = 'Varios Los Aztecas' },
    { id = 116, name = 'Varios Los Aztecas' },
    { id = 117, name = 'Triad' },
    { id = 118, name = 'Triad' },
    { id = 119, name = 'Johhny Sindacco' },
    { id = 120, name = 'Triad Boss' },
    { id = 121, name = 'Da Nang Boy' },
    { id = 122, name = 'Da Nang Boy' },
    { id = 123, name = 'Da Nang Boy' },
    { id = 124, name = 'The Mafia' },
    { id = 125, name = 'The Mafia' },
    { id = 126, name = 'The Mafia' },
    { id = 127, name = 'The Mafia' },
    { id = 128, name = 'Farm Inhabitant' },
    { id = 129, name = 'Farm Inhabitant' },
    { id = 130, name = 'Farm Inhabitant' },
    { id = 131, name = 'Farm Inhabitant' },
    { id = 132, name = 'Farm Inhabitant' },
    { id = 133, name = 'Farm Inhabitant' },
    { id = 134, name = 'Homeless' },
    { id = 135, name = 'Homeless' },
    { id = 136, name = 'Normal Ped' },
    { id = 137, name = 'Homeless' },
    { id = 138, name = 'Beach Visitor' },
    { id = 139, name = 'Beach Visitor' },
    { id = 140, name = 'Beach Visitor' },
    { id = 141, name = 'Businesswoman' },
    { id = 142, name = 'Taxi Driver' },
    { id = 143, name = 'Crack Maker' },
    { id = 144, name = 'Crack Maker' },
    { id = 145, name = 'Crack Maker' },
    { id = 146, name = 'Crack Maker' },
    { id = 147, name = 'Businessman' },
    { id = 148, name = 'Businesswoman' },
    { id = 149, name = 'Big Smoke Armored' },
    { id = 150, name = 'Businesswoman' },
    { id = 151, name = 'Normal Ped' },
    { id = 152, name = 'Prostitute' },
    { id = 153, name = 'Construction Worker' },
    { id = 154, name = 'Beach Visitor' },
    { id = 155, name = 'Well Stacked Pizza Worker' },
    { id = 156, name = 'Barber' },
    { id = 157, name = 'Hillbilly' },
    { id = 158, name = 'Farmer' },
    { id = 159, name = 'Hillbilly' },
    { id = 160, name = 'Hillbilly' },
    { id = 161, name = 'Farmer' },
    { id = 162, name = 'Hillbilly' },
    { id = 163, name = 'Black Bouncer' },
    { id = 164, name = 'White Bouncer' },
    { id = 165, name = 'White MIB agent' },
    { id = 166, name = 'Black MIB agent' },
    { id = 167, name = 'Cluckin\' Bell Worker' },
    { id = 168, name = 'Hotdog/Chilli Dog Vendor' },
    { id = 169, name = 'Normal Ped' },
    { id = 170, name = 'Normal Ped' },
    { id = 171, name = 'Blackjack Dealer' },
    { id = 172, name = 'Casino croupier' },
    { id = 173, name = 'San Fierro Rifa' },
    { id = 174, name = 'San Fierro Rifa' },
    { id = 175, name = 'San Fierro Rifa' },
    { id = 176, name = 'Barber' },
    { id = 177, name = 'Barber' },
    { id = 178, name = 'Whore' },
    { id = 179, name = 'Ammunation Salesman' },
    { id = 180, name = 'Tattoo Artist' },
    { id = 181, name = 'Punk' },
    { id = 182, name = 'Cab Driver' },
    { id = 183, name = 'Normal Ped' },
    { id = 184, name = 'Normal Ped' },
    { id = 185, name = 'Normal Ped' },
    { id = 186, name = 'Normal Ped' },
    { id = 187, name = 'Businessman' },
    { id = 188, name = 'Normal Ped' },
    { id = 189, name = 'Valet' },
    { id = 190, name = 'Barbara Schternvart' },
    { id = 191, name = 'Helena Wankstein' },
    { id = 192, name = 'Michelle Cannes' },
    { id = 193, name = 'Katie Zhan' },
    { id = 194, name = 'Millie Perkins' },
    { id = 195, name = 'Denise Robinson' },
    { id = 196, name = 'Farm-Town inhabitant' },
    { id = 197, name = 'Hillbilly' },
    { id = 198, name = 'Farm-Town inhabitant' },
    { id = 199, name = 'Farm-Town inhabitant' },
    { id = 200, name = 'Hillbilly' },
    { id = 201, name = 'Farmer' },
    { id = 202, name = 'Farmer' },
    { id = 203, name = 'Karate Teacher' },
    { id = 204, name = 'Karate Teacher' },
    { id = 205, name = 'Burger Shot Cashier' },
    { id = 206, name = 'Cab Driver' },
    { id = 207, name = 'Prostitute' },
    { id = 208, name = 'Su Xi Mu (Suzie)' },
    { id = 209, name = 'Oriental Noodle stand vendor' },
    { id = 210, name = 'Oriental Boating School Instructor' },
    { id = 211, name = 'Clothes shop staff' },
    { id = 212, name = 'Homeless' },
    { id = 213, name = 'Weird old man' },
    { id = 214, name = 'Waitress (Maria Latore)' },
    { id = 215, name = 'Normal Ped' },
    { id = 216, name = 'Normal Ped' },
    { id = 217, name = 'Clothes shop staff' },
    { id = 218, name = 'Normal Ped' },
    { id = 219, name = 'Rich Woman' },
    { id = 220, name = 'Cab Driver' },
    { id = 221, name = 'Normal Ped' },
    { id = 222, name = 'Normal Ped' },
    { id = 223, name = 'Normal Ped' },
    { id = 224, name = 'Normal Ped' },
    { id = 225, name = 'Normal Ped' },
    { id = 226, name = 'Normal Ped' },
    { id = 227, name = 'Oriental Businessman' },
    { id = 228, name = 'Oriental Ped' },
    { id = 229, name = 'Oriental Ped' },
    { id = 230, name = 'Homeless' },
    { id = 231, name = 'Normal Ped' },
    { id = 232, name = 'Normal Ped' },
    { id = 233, name = 'Normal Ped' },
    { id = 234, name = 'Cab Driver' },
    { id = 235, name = 'Normal Ped' },
    { id = 236, name = 'Normal Ped' },
    { id = 237, name = 'Prostitute' },
    { id = 238, name = 'Prostitute' },
    { id = 239, name = 'Homeless' },
    { id = 240, name = 'The D.A' },
    { id = 241, name = 'Afro-American' },
    { id = 242, name = 'Mexican' },
    { id = 243, name = 'Prostitute' },
    { id = 244, name = 'Stripper' },
    { id = 245, name = 'Prostitute' },
    { id = 246, name = 'Stripper' },
    { id = 247, name = 'Biker' },
    { id = 248, name = 'Biker' },
    { id = 249, name = 'Pimp' },
    { id = 250, name = 'Normal Ped' },
    { id = 251, name = 'Lifeguard' },
    { id = 252, name = 'Naked Valet' },
    { id = 253, name = 'Bus Driver' },
    { id = 254, name = 'Biker Drug Dealer' },
    { id = 255, name = 'Chauffeur (Limo Driver)' },
    { id = 256, name = 'Stripper' },
    { id = 257, name = 'Stripper' },
    { id = 258, name = 'Heckler' },
    { id = 259, name = 'Heckler' },
    { id = 260, name = 'Construction Worker' },
    { id = 261, name = 'Cab driver' },
    { id = 262, name = 'Cab driver' },
    { id = 263, name = 'Normal Ped' },
    { id = 264, name = 'Clown (Ice-cream Van Driver)' },
    { id = 265, name = 'Officer Frank Tenpenny (Corrupt Cop)' },
    { id = 266, name = 'Officer Eddie Pulaski (Corrupt Cop)' },
    { id = 267, name = 'Officer Jimmy Hernandez' },
    { id = 268, name = 'Dwaine/Dwayne' },
    { id = 269, name = 'Melvin "Big Smoke" Harris (Mission)' },
    { id = 270, name = 'Sean \'Sweet\' Johnson' },
    { id = 271, name = 'Lance \'Ryder\' Wilson' },
    { id = 272, name = 'Mafia Boss' },
    { id = 273, name = 'T-Bone Mendez' },
    { id = 274, name = 'Paramedic (Emergency Medical Technician)' },
    { id = 275, name = 'Paramedic (Emergency Medical Technician)' },
    { id = 276, name = 'Paramedic (Emergency Medical Technician)' },
    { id = 277, name = 'Firefighter' },
    { id = 278, name = 'Firefighter' },
    { id = 279, name = 'Firefighter' },
    { id = 280, name = 'Los Santos Police Officer' },
    { id = 281, name = 'San Fierro Police Officer' },
    { id = 282, name = 'Las Venturas Police Officer' },
    { id = 283, name = 'County Sheriff' },
    { id = 284, name = 'LSPD Motorbike Cop' },
    { id = 285, name = 'S.W.A.T Special Forces' },
    { id = 286, name = 'Federal Agent' },
    { id = 287, name = 'San Andreas Army' },
    { id = 288, name = 'Desert Sheriff' },
    { id = 289, name = 'Zero' },
    { id = 290, name = 'Ken Rosenberg' },
    { id = 291, name = 'Kent Paul' },
    { id = 292, name = 'Cesar Vialpando' },
    { id = 293, name = 'Jeffery "OG Loc" Martin/Cross' },
    { id = 294, name = 'Wu Zi Mu (Woozie)' },
    { id = 295, name = 'Michael Toreno' },
    { id = 296, name = 'Jizzy B.' },
    { id = 297, name = 'Madd Dogg' },
    { id = 298, name = 'Catalina' },
    { id = 299, name = 'Claude Speed' },
    { id = 300, name = 'Los Santos Police Officer (Without gun holster)' },
    { id = 301, name = 'San Fierro Police Officer (Without gun holster)' },
    { id = 302, name = 'Las Venturas Police Officer (Without gun holster)' },
    { id = 303, name = 'Los Santos Police Officer (Without uniform)' },
    { id = 304, name = 'Los Santos Police Officer (Without uniform)' },
    { id = 305, name = 'Las Venturas Police Officer (Without uniform)' },
    { id = 306, name = 'Los Santos Police Officer' },
    { id = 307, name = 'San Fierro Police Officer' },
    { id = 308, name = 'San Fierro Paramedic (Emergency Medical Technician)' },
    { id = 309, name = 'Las Venturas Police Officer' },
    { id = 310, name = 'Country Sheriff (Without hat)' },
    { id = 311, name = 'Desert Sheriff (Without hat)' },
}

local BinderActions = {
    {
        pattern = "%* Вы ведёте за собой ([%w_]+)%.",
        bindKey = "fme_text",
        isEnabled = function() return Binder.fme.v end
    },
    {
        pattern = "Я посадил ([%w_]+) в машину",
        bindKey = "incar_text",
        isEnabled = function() return Binder.incar.v end
    },
    {
        pattern = "Я выкинул ([%w_]+) из транспорта",
        bindKey = "eject_text",
        isEnabled = function() return Binder.eject.v end
    }
}

-- Mutex lock

local locks = {}

function synchronized(name, fn)
    if locks[name] then return end -- already running
    locks[name] = true

    lua_thread.create(function()
        pcall(fn)
        locks[name] = false
    end)
end

-- FontAwesome Icons

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0,
            font_config, fa_glyph_ranges)
    end
end

function save()
    inicfg.save(mainIni, 'Tools.ini')
    jsonSave(json, binds)
end

-- Stroboscopes

local carsStoroscopes = {}
function table.contains(data, func)
    for k, v in pairs(data) do
        if func(k, v) then return true end
    end
    return false
end

function table.containsValue(data, value)
    return table.contains(data, function(k, v)
        if v == value then return true end
        return false
    end)
end

function table.getValueKey(data, value)
    for k, v in pairs(data) do
        if v == value then return k end
    end
    return nil
end

function stroboscopes(adress, ptr, _1, _2, _3, _4) -- функция стробоскопов
    if not isCharInAnyCar(PLAYER_PED) then return end

    if not isCarSirenOn(storeCarCharIsInNoSave(PLAYER_PED)) then
        forceCarLights(storeCarCharIsInNoSave(PLAYER_PED), 0)
        callMethod(7086336, ptr, 2, 0, 1, 3)
        callMethod(7086336, ptr, 2, 0, 0, 0)
        callMethod(7086336, ptr, 2, 0, 1, 0)
        markCarAsNoLongerNeeded(storeCarCharIsInNoSave(PLAYER_PED))
        return
    end

    callMethod(adress, ptr, _1, _2, _3, _4)
end

function main()
    while not isSampAvailable() do wait(100) end
    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

    updateFPS()
    loadBinds()
    loadPearsLauncherSkins()
    concatSkins()
    registerChatCommands()
    registerHotkeys()
    initializeMainThread()
end

function registerChatCommands()
    sampRegisterChatCommand('tt', function()
        State.main_window.v = not State.main_window.v
        menu = 0
    end)

    sampRegisterChatCommand("sw", cmdSetWeather)
    sampRegisterChatCommand("blackout", blackout)
    sampRegisterChatCommand("find", cmdFind)
    sampRegisterChatCommand("findoff", cmdFindOff)

    sampRegisterChatCommand('ss', function()
        State.statusSsMode = not State.statusSsMode
        printStringNow(State.statusSsMode and 'RPChat ~g~ON' or 'RPChat ~r~OFF', 1000)
    end)

    sampRegisterChatCommand('cc', function()
        for i = 1, 30 do sampAddChatMessage('', -1) end
    end)

    sampRegisterChatCommand("strobes", function()
        if State.straboscopes.v then
            if isCharInAnyCar(PLAYER_PED) then
                local car = storeCarCharIsInNoSave(PLAYER_PED)
                local driverPed = getDriverOfCar(car)

                if PLAYER_PED == driverPed then
                    local state = not isCarSirenOn(car)
                    switchCarSiren(car, state)
                end
            end
        end
    end)

    sampRegisterChatCommand('cuff', bind_cuff)
    sampRegisterChatCommand('frisk', bind_frisk)
    sampRegisterChatCommand('arest', bind_arest)
end

function registerHotkeys()
    ID_MAIN_MENU = rkeys.registerHotKey(HotKeys.main_menu.v, 1, mainMenu)
    ID_BATTLEPASS = rkeys.registerHotKey(HotKeys.battlepass.v, 1, battlepass)
    ID_BACKUP = rkeys.registerHotKey(HotKeys.backup.v, 1, backup)
    ID_SU = rkeys.registerHotKey(HotKeys.su.v, 1, su)
    ID_BINDTAZER = rkeys.registerHotKey(HotKeys.bindTazer.v, 1, bindTazer)
    ID_BINDBANDAGE = rkeys.registerHotKey(HotKeys.bindBandage.v, 1, bindBandage)
    ID_CROSSHAIR = rkeys.registerHotKey(HotKeys.crosshair.v, 1, crosshair)
    ID_CRUISE_CONTROL_STATE = rkeys.registerHotKey(HotKeys.cruise_control_state.v, 1, cruiseControlState)
    ID_CRUISE_CONTROL_SPEED_UP = rkeys.registerHotKey(HotKeys.cruise_control_speed_up.v, 1, function()
        CruiseControl.speed = CruiseControl.speed + 2.5
    end)
    ID_CRUISE_CONTROL_SLOW_DOWN = rkeys.registerHotKey(HotKeys.cruise_control_slow_down.v, 1, function()
        CruiseControl.speed = CruiseControl.speed - 2.5
    end)
end

function cruiseControlState()
    if isCharInAnyCar(playerPed) then
        CruiseControl.state = not CruiseControl.state
        if CruiseControl.state then
            CruiseControl.speed = getCarSpeed(storeCarCharIsInNoSave(playerPed))
        end
    end
end

function initializeMainThread()
    sampAddChatMessage("{AC0046}[Tools] {FFFFFF}Активирован.", -1)
    sampAddChatMessage("{AC0046}[Tools] {FFFFFF}Открыть меню - {AC0046}/tt", -1)
    while true do
        imgui.Process = State.main_window.v or InfoPanel.infoPanel.v
        if InfoPanel.infoPanel.v then imgui.ShowCursor = false end
        lua_thread.create(handleStroboscopes)
        lua_thread.create(handleSkinChanger)
        lua_thread.create(handleAutoFix)
        lua_thread.create(handleCrosshairHold)
        lua_thread.create(handleCruiseControl)
        wait(0)
    end
end

function handleCruiseControl()
    if isCharInAnyCar(playerPed) and CruiseControl.state then
        if getCarSpeed(storeCarCharIsInNoSave(playerPed)) < CruiseControl.speed then
            writeMemory(0xB73458 + 0x20, 1, 150, false)
        end
    end
end

function crosshair()
    local weapon = getCurrentCharWeapon(PLAYER_PED)
    if not isCharInAnyCar(PLAYER_PED) and weapon >= 22 and weapon <= 34 then
        State.crosshair_state = not State.crosshair_state
    end
end

function handleCrosshairHold()
    local weapon = getCurrentCharWeapon(PLAYER_PED)
    if State.crosshair_state and (weapon < 22 or weapon > 34) then
        State.crosshair_state = false
    end
    if State.crosshair_state then
        setGameKeyState(6, 255)
    end
end

function handleAutoFix()
    if not State.auto_fix_state.v or not isCharInAnyCar(PLAYER_PED) then return end
    local car = storeCarCharIsInNoSave(PLAYER_PED)
    if getDriverOfCar(car) == PLAYER_PED then
        if not AutoFix.lastCheckTime or os.clock() - AutoFix.lastCheckTime > 0.3 then
            AutoFix.lastCheckTime = os.clock()

            local px, py, pz = getCharCoordinates(PLAYER_PED)

            if isFillRequired() then
                for id, _ in pairs(AutoFix.fillTexts) do
                    local result, _, x, y, z, _, _, _, _ = sampGet3dTextInfoById(id)
                    if result and getDistanceBetweenCoords3d(px, py, pz, x, y, z) < 9.0 then
                        sampSendChat("/fill")
                        AutoFix.isFilling = true
                    else
                        AutoFix.isFilling = false
                    end
                end
            end

            if not CONFIG.VEHICLE_HEALTH_THRESHOLDS[getCarHealth(car)] then
                for id, _ in pairs(AutoFix.tehvehTexts) do
                    local result, _, x, y, z, _, _, _, _ = sampGet3dTextInfoById(id)
                    if result and getDistanceBetweenCoords3d(px, py, pz, x, y, z) < 5.0 then
                        if not isCarEngineOn(car) then
                            sampSendChat("/tehveh")
                        end
                    end
                end
            end
        end
    end
end

function handleStroboscopes()
    if not State.straboscopes.v then return end
    if wasKeyPressed(VK_P) and not sampIsChatInputActive() and not sampIsDialogActive() then
        if isCharInAnyCar(PLAYER_PED) and
            not isCharInAnyBoat(PLAYER_PED) and
            not isCharInAnyHeli(PLAYER_PED) and
            not isCharInAnyPlane(PLAYER_PED) and
            not isCharOnAnyBike(PLAYER_PED) and
            not isCharInAnyTrain(PLAYER_PED) then
            local carHandle = storeCarCharIsInNoSave(PLAYER_PED)
            if getDriverOfCar(carHandle) == PLAYER_PED then
                local res, id = sampGetVehicleIdByCarHandle(carHandle)
                if res then
                    local structure = getCarPointer(carHandle)
                    structure = structure + 1440
                    if carsStoroscopes[id] ~= nil then
                        carsStoroscopes[id]:terminate()
                        carsStoroscopes[id] = nil
                        callMethod(7086336, structure, 2, 0, 0, 0)
                        callMethod(7086336, structure, 2, 0, 1, 0)
                    else
                        carsStoroscopes[id] = lua_thread.create_suspended(function()
                            while true do
                                callMethod(7086336, structure, 2, 0, 1, 0)
                                callMethod(7086336, structure, 2, 0, 0, 1)
                                wait(100)
                                callMethod(7086336, structure, 2, 0, 0, 0)
                                callMethod(7086336, structure, 2, 0, 1, 1)
                                wait(100)
                            end
                        end)
                        carsStoroscopes[id]:run()
                    end
                end
            end
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if State.CheckBoxDialogID.v then
        sampAddChatMessage(id, State.main_color)
    end
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else
                imgui.Text(u8(w))
            end
        end
    end

    render_text(text)
end

function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(width / 2 - calc.x / 2)
    imgui.Text(text)
end

function getMyNick()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        local nick = sampGetPlayerNickname(id)
        return nick
    end
end

function getMyNickSpec()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        local nick = sampGetPlayerNickname(id)
        nick = nick:gsub("_", " ")
        return nick
    end
end

function mainMenu()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    State.main_window.v = not State.main_window.v
    State.menu = 0
end

function battlepass()
    if State.bindBattlePass.v then
        if sampIsChatInputActive() or sampIsDialogActive() then return end
        sampSendChat("/battlepass")
    end
end

function bindTazer()
    if State.bindTazer.v then
        if sampIsChatInputActive() or sampIsDialogActive() then return end
        sampSendChat("/tazer")
    end
end

function bindBandage()
    if State.bindBandage.v then
        if sampIsChatInputActive() or sampIsDialogActive() then return end
        sampSendChat("/bandage")
    end
end

function cmdSetWeather(param)
    if param == nil or param == "" then
        sampAddChatMessage("{AC0046}[Tools] {FFFFFF}Используйте: /sw [0-45]", 0xFFFFFF)
        return
    end

    local weather = tonumber(param)
    if weather ~= nil and weather >= 0 and weather <= 45 then
        forceWeatherNow(weather)
    end
end

function imgui.HelpMarker(text)
    imgui.TextDisabled('[?]')
    if imgui.IsItemHovered() then
        imgui.BeginTooltip()
        imgui.PushTextWrapPos(450)
        imgui.TextUnformatted(text)
        imgui.PopTextWrapPos()
        imgui.EndTooltip()
    end
end

function sampev.onServerMessage(color, text)
    -- IC chat only
    if text and State.statusSsMode then
        local filtered_patterns = {
            '%[AD%]',       -- AD messages
            ' SMS ',        -- SMS messages
            '%[ADM%]',      -- Admin messages
            '%[PP%]',       -- Punishment messages
            "^%*%*.+%*%*$", -- Department radio/news
            "^%*%* .-:",    -- Radio messages
            '%(%(.-%)%)',   -- OOC messages
            '____',         -- PayDay messages
            '{0088ff}'      -- Specific color messages
        }

        for _, pattern in ipairs(filtered_patterns) do
            if text:find(pattern) then
                logFilteredMessage(color, text)
                return false
            end
        end
    end

    -- Binder
    if text and State.binder.v then
        for _, action in ipairs(BinderActions) do
            if action.isEnabled and action.isEnabled() then
                local name = text:match(action.pattern)
                if name then
                    local template = binds[action.bindKey]
                    if template then
                        local msg = u8:decode(template):format(name)
                        sampSendChat(msg)
                    end
                    break
                end
            end
        end
    end

    return true
end

function logFilteredMessage(color, text)
    local hexColor = string.format('%06X', bit.band(color, 0xFFFFFF))
    local logText = string.format('{%s}[%s] %s', hexColor, os.date('%X'), text)
    sampfuncsLog(logText)
end

-- Black screen for screenshot situations
function blackout()
    State.blackout = not State.blackout

    if State.blackout then
        if not State.blackout_textdraw_id then
            for i = 1, 10000 do
                if not sampTextdrawIsExists(i) then
                    State.blackout_textdraw_id = i
                    break
                end
            end
        end

        if State.blackout_textdraw_id then
            sampTextdrawCreate(State.blackout_textdraw_id, "usebox", -7.0, -7.0)
            sampTextdrawSetLetterSizeAndColor(State.blackout_textdraw_id, 0.475, 55.0, 0x00000000)
            sampTextdrawSetBoxColorAndSize(State.blackout_textdraw_id, 1, 0xFF000000, 900.0, 900.0)
            sampTextdrawSetShadow(State.blackout_textdraw_id, 0, 0xFF000000)
            sampTextdrawSetOutlineColor(State.blackout_textdraw_id, 1, 0xFF000000)
            sampTextdrawSetAlign(State.blackout_textdraw_id, 1)
            sampTextdrawSetProportional(State.blackout_textdraw_id, 1)
        end
    else
        if State.blackout_textdraw_id then
            sampTextdrawDelete(State.blackout_textdraw_id)
            State.blackout_textdraw_id = nil
        end
    end
end

-- newLine for /r and /d
function sampev.onSendCommand(text)
    local lowerText = text:lower()

    if lowerText:find("^/r%s") or lowerText:find("^/d%s") then
        local cmd, msg = text:match("^(%/%a+)%s(.+)")
        if cmd and msg and #msg > CONFIG.WALKIE_TALKIE_MAX_LENGTH then
            local parts = splitMessageSmart(msg, CONFIG.WALKIE_TALKIE_MAX_LENGTH)

            lua_thread.create(function()
                for _, part in ipairs(parts) do
                    sampSendChat(cmd .. " " .. part)
                    wait(CONFIG.WALKIE_TALKIE_SEND_DELAY)
                end
            end)

            return false
        end
    end
end

function splitMessageSmart(message, limit)
    local words = {}
    for word in message:gmatch("%S+") do
        table.insert(words, word)
    end

    local parts = {}
    local current = ""

    for i, word in ipairs(words) do
        local test = (#current > 0) and (current .. " " .. word) or word
        local suffix = (i < #words) and ".." or ""

        if #test + #suffix <= limit then
            current = test
        else
            table.insert(parts, current .. (i <= #words and ".." or ""))
            current = ".." .. word
        end
    end

    if #current > 0 then
        table.insert(parts, current)
    end

    return parts
end

---- Приветстиве -------
local changelog10 = [[
1. Смена стиля для меню.
2. Бинд кнопки открытия/закрытия меню.
3. Бинд кнопки открытия/закрытия battlepass.
4. Добавлены стробоскопы. Активация сирены /strobes | Активация стробоскопов P.
5. Добавлена смена погоды. Команда /sw [0-45].
6. Добавлено отключение ООС чата. Команда /ss.
7. Добавлено очистка чата. Команда /cc.
8. Добавлен авто поиск преступника.
9. Добавлена авто починка и заправка в гос. гаражах.
10. Добавлен вызов подкрепления и предложение о выдачи звёзд при стрельбе.
11. Добавлено автообновление скрипта.
12. Добавлен чёрный экран для ссок. /blackout
13. Добавлен авто перенос в /d и /r.
]]
local changelog20 = [[
1. Добавлена информационная панель Info Panel.
2. Добавлены базовые отыгровки /cuff, /fme, /frisk, /incar, /eject, /arest.
3. Добавлен скин ченджер.
4. Добавлен бинд для електрошокера /tazer.
5. Добалвен бинд для бинтов /bandage.
6. Добавлен круиз-контроль.
7. Добавлена задержка прицела для отыгровок.
]]

local authors = [[

    Спасибо за помощь:

    — Amelia Brown (режим IC-only чата и его очистка).
]]

function welcomeMenu()
    imgui.CenterText('' ..
        thisScript().name .. u8 ' | v' .. thisScript().version .. ' | Developers - Saburo Arasaka & Dave Grand')
    imgui.CenterText(u8 'Разработан специально для Pears Project')
    imgui.Text(u8(authors))

    imgui.Separator()

    if imgui.CollapsingHeader('Version 2.0.0') then
        imgui.Text(u8(changelog20))
    end
    if imgui.CollapsingHeader('Version 1.0.0') then
        imgui.Text(u8(changelog10))
    end
    imgui.Separator()
    imgui.CenterText(u8 'Контакты:')
    imgui.CenterText(u8 'Saburo Arasaka ' .. fa.ICON_TELEGRAM .. ' - @goatffs')
    imgui.CenterText(u8 'Dave Grand ' .. fa.ICON_TELEGRAM .. ' - @daveamp')
    imgui.CenterText(u8 'Amelia Brown ' .. fa.ICON_TELEGRAM .. ' - @wnenad')
end

-- Auto Alert
function sampev.onSendTakeDamage(playerId, _, weapon, _, _)
    if not playerId or playerId > 1000 or not State.auto_alert_state.v or weapon < 0 or weapon > 38 then return end
    local now = os.time()
    if not AutoAlert.attackerCooldowns[playerId] or now - AutoAlert.attackerCooldowns[playerId] >= CONFIG.ALERT_INTERVAL then
        local name = sampGetPlayerNickname(playerId)
        sampAddChatMessage(
            string.format(
                "{3399FF}По вам ведёт огонь %s. Вызвать подкрепление - {FFFF00}%s{3399FF}, объявить в розыск - {FFFF00}%s",
                name,
                vkeys.id_to_name(HotKeys.backup.v[1]),
                vkeys.id_to_name(HotKeys.su.v[1])
            ),
            -1
        )
        AutoAlert.pendingAttacker = playerId
        AutoAlert.pendingExpireTime = now + CONFIG.ALERT_INTERVAL
        AutoAlert.attackerCooldowns[playerId] = now
    end
end

function backup()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    if mainIni.state.auto_alert then
        if os.time() - AutoAlert.lastGlobalBackupTime >= CONFIG.BACKUP_INTERVAL then
            callForBackup()
            AutoAlert.lastGlobalBackupTime = os.time()
        end
    end
end

function callForBackup()
    local zone = getZoneName()
    local backup_message = u8:decode(binds['backup_text'])
    local message = ("/r " .. backup_message):format(zone)
    sampSendChat(message)
end

function su()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    if mainIni.state.auto_alert then
        if AutoAlert.pendingAttacker and os.time() <= AutoAlert.pendingExpireTime then
            if not AutoAlert.suCooldowns[AutoAlert.pendingAttacker] or os.time() - AutoAlert.suCooldowns[AutoAlert.pendingAttacker] >= AutoAlert.SU_INTERVAL then
                issueWanted(AutoAlert.pendingAttacker)
                AutoAlert.suCooldowns[AutoAlert.pendingAttacker] = os.time()
                AutoAlert.pendingAttacker = nil
            end
        end
    end
end

function issueWanted(attackerId)
    local name = sampGetPlayerNickname(attackerId)
    if name then
        sampSendChat(string.format("/su %d 1.4", attackerId))
    end
end

function getZoneName()
    local interior = getActiveInterior()
    if interior ~= 0 then
        return u8 "Вы в интерьере"
    end

    local x, y, z = getCharCoordinates(PLAYER_PED)
    return calculateZone(x, y, z)
end

function getMyCity()
    local x, y, z = getCharCoordinates(PLAYER_PED)

    -- Las Venturas
    if x > 869 and y > 596 then
        return "Las Venturas"
        -- San Fierro
    elseif x < -700 and y > 0 then
        return "San Fierro"
        -- Los Santos
    elseif x > 44 and y < -300 then
        return "Los Santos"
    else
        return u8 "Вне города"
    end
end

-- Auto Find
function cmdFind(arg)
    local id = tonumber(arg)
    if not id then
        sampAddChatMessage("[Tools] {ff0000}Неверный{ffffff} ID игрока.", State.main_color)
        return
    end

    AutoFind.state = true
    AutoFind.targetId = id
    AutoFind.zoneDestroyed = false
    AutoFind.checkpointDisabled = false

    if State.auto_find_state.v and AutoFind.state then
        printStringNow("~b~~h~~h~~h~Find: ~b~~h~~h~ enabled", 1600)
    end

    sampSendChat("/find " .. id)
end

function cmdFindOff()
    if not State.auto_find_state.v or not AutoFind.state then return end

    AutoFind.state = false
    AutoFind.targetId = nil
    AutoFind.zoneDestroyed = false
    AutoFind.checkpointDisabled = false

    printStringNow("~b~~h~~h~~h~Find: ~b~~h~~h~ disabled", 1600)
end

function trySendFind()
    if State.auto_find_state.v and AutoFind.state and
        AutoFind.zoneDestroyed and AutoFind.checkpointDisabled and
        AutoFind.targetId then
        synchronized("trySendFind", function()
            local delay = CONFIG.AUTO_FIND_DELAYS[mainIni.config.auto_find_level_selected] or 0
            if delay > 0 then wait(delay * 1000) end

            sampSendChat("/find " .. AutoFind.targetId)
            AutoFind.zoneDestroyed = false
            AutoFind.checkpointDisabled = false
        end)
    end
end

function sendFind()
    sampSendChat("/find " .. AutoFind.targetId)
    AutoFind.zoneDestroyed = false
    AutoFind.checkpointDisabled = false
end

function sampev.onGangZoneDestroy(zoneId)
    if State.auto_find_state.v and AutoFind.state and zoneId == 0 then
        AutoFind.zoneDestroyed = true
        trySendFind()
    end
end

function sampev.onDisableCheckpoint()
    if State.auto_find_state.v and AutoFind.state then
        AutoFind.checkpointDisabled = true
        trySendFind()
    end
end

function sampev.onPlayerQuit(playerId, reason)
    if State.auto_find_state.v and AutoFind.state and playerId == AutoFind.targetId then
        local nickname = sampGetPlayerNickname(playerId) or "Unknown"
        sampAddChatMessage(
            string.format(
                '[Tools] {ffffff}Игрок {FF9C00}%s[%d] {FFFFFF}вышел с сервера. {FF9C00}Причина: {FFFFFF}%s.',
                nickname, playerId, CONFIG.QUIT_REASONS[reason] or 'неизвестно'
            ),
            State.main_color
        )
        cmdFindOff()
    end
end

-- Auto Fix
function isFillRequired()
    if not State.auto_fix_state.v then return end
    if not sampTextdrawIsExists(2133) then return end
    local fuel = tonumber(sampTextdrawGetString(2133):match("(%d+)[,.]?%d*"))
    return fuel and fuel < 95
end

function sampev.onCreate3DText(id, _, _, _, _, _, _, text)
    local lowerText = text:lower()
    if lowerText:find("/fill ") then
        AutoFix.fillTexts[id] = true
    elseif lowerText:find("/tehveh") then
        AutoFix.tehvehTexts[id] = true
    end
end

function sampev.onRemove3DTextLabel(id)
    AutoFix.fillTexts[id] = nil
    AutoFix.tehvehTexts[id] = nil
end

-- SkinChanger
function handleSkinChanger()
    if SkinChanger.selectedSkin ~= 0 then
        if skins[SkinChanger.selectedSkin].id ~= getCharModel(PLAYER_PED) then
            apply()
        end
    end
end

function loadPearsLauncherSkins() -- from vAcs
    local file = getGameDirectory() .. '\\data\\peds.ide'
    if doesFileExist(file) then
        pearsSkins = {}
        local F = io.open(file, r)
        local Text = F:read('*all')
        F:close()

        local pedline   = 0
        local lineIndex = 0
        local l_s_count = 0
        for line in Text:gmatch('[^\n]+') do
            lineIndex = lineIndex + 1
            if line:find('^peds') then
                pedline = lineIndex
            end
            if pedline ~= 0 and lineIndex > pedline then
                if line:find('(%d+), (%w+)') then
                    local id, model = line:match('(%d+), (%w+)')
                    if tonumber(id) then
                        local model = model .. ' (' .. id .. ')'
                        if tonumber(id) > 311 then
                            table.insert(pearsSkins,
                                { id = tonumber(id) or 0, name = '(Pears Project) ' .. tostring(model) or 'unknown' })
                            l_s_count = l_s_count + 1
                        end
                    end
                end
            end
        end
        print('Загружено ' .. l_s_count .. ' скинов!')
    else
        print('Не удалось загрузить скины из лаунчера.', 2, true, false)
    end
end

function concatSkins()
    if isPearsLauncher() then
        for i = 1, #pearsSkins do
            table.insert(skins, pearsSkins[i])
        end
    end
end

function isPearsLauncher()
    return doesFileExist(getGameDirectory() .. '\\!pears_sentry.asi')
end

function isPearsSkin(id)
    return id > 311 or id < 0
end

function saveSkin()
    mainIni.config.skin = SkinChanger.selectedSkin
    inicfg.save(mainIni, 'Tools.ini')
end

function apply()
    saveSkin()
    if SkinChanger.selectedSkin ~= 0 then
        bs = raknetNewBitStream()
        raknetBitStreamWriteInt32(bs, select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)))
        raknetBitStreamWriteInt32(bs, skins[SkinChanger.selectedSkin].id)
        raknetEmulRpcReceiveBitStream(153, bs)
        raknetDeleteBitStream(bs)
    end
end

function setPlayerSkin(player, skin)
    saveSkin()
    bs = raknetNewBitStream()
    raknetBitStreamWriteInt32(bs, player)
    raknetBitStreamWriteInt32(bs, skin)
    raknetEmulRpcReceiveBitStream(153, bs)
    raknetDeleteBitStream(bs)
end

-- Simple Binder

function loadBinds()
    if not doesDirectoryExist(getWorkingDirectory() .. '\\config') then
        createDirectory(getWorkingDirectory() ..
            '\\config')
    end
    if not doesFileExist(json) then
        local t = {
            ['backup_text'] = u8("Требуется подкрепление. Район %s."),
            ['cuff_text'] = u8("/do Наручники на поясе."),
            ['fme_text'] = u8("/me взял %s за бицепс и повёл перед собой."),
            ['frisk_text'] = u8("/me ощупывает руки, ноги, торс %s, проверяя содержимое карманов."),
            ['incar_text'] = u8("/me открыл дверь авто, помог %s сесть, пристегнул ремнями безопасности, закрыл дверь."),
            ['eject_text'] = u8("/me открыл дверь авто, отстегнул ремни безопасности, помог %s выйти из авто."),
            ['arest_text'] = u8("/me достал ключ от камеры, открыл дверь, завёл %s, снял наручники, захлопнул дверь."),
        }
        jsonSave(json, t)
    end
    binds = jsonRead(json)
end

function bind_cuff(param)
    local id = tonumber(param)
    if not id then
        sampAddChatMessage('{CCCCCC}[ Мысли ]: Заковать в наручники [ /cuff ID ]', -1)
        return
    end

    if State.binder.v and Binder.cuff.v then
        lua_thread.create(function()
            local message = formatWithName(u8:decode(binds['cuff_text']), id)
            handle_binder_cmd(message, '/cuff ', id)
        end)
    else
        sampSendChat('/cuff ' .. id)
    end
end

function bind_frisk(param)
    local id = tonumber(param)
    if not id then
        sampAddChatMessage('{CCCCCC}[ Мысли ]: Обыскать игрока [ /frisk ID ]', -1)
        return
    end

    if State.binder.v and Binder.frisk.v then
        lua_thread.create(function()
            local message = formatWithName(u8:decode(binds['frisk_text']), id)
            handle_binder_cmd(message, '/frisk ', id)
        end)
    else
        sampSendChat('/frisk ' .. id)
    end
end

function bind_arest(param)
    local id = tonumber(param)
    if not id then
        sampAddChatMessage('{CCCCCC}[ Мысли ]: Посадить преступника [ /arest ID ]', -1)
        return
    end

    if State.binder.v and Binder.arest.v then
        lua_thread.create(function()
            local message = formatWithName(u8:decode(binds['arest_text']), id)
            handle_binder_cmd(message, '/arest ', id)
        end)
    else
        sampSendChat('/arest ' .. id)
    end
end

function formatWithName(msg, arg)
    local id = tonumber(arg)
    if not sampIsPlayerConnected(id) then return nil end
    local nickname = sampGetPlayerNickname(id)
    local name = nickname:match("([^_]+)")
    return (msg):format(name)
end

function handle_binder_cmd(msg, cmd, id)
    if msg and id then
        sampSendChat(msg)
        wait(500)
        sampSendChat(cmd .. tostring(id))
    else
        sampAddChatMessage("[Tools] {FFFFFF}Игрок не подключён.", State.main_color)
    end
end

function imgui.OnDrawFrame()
    setColorScheme()
    if State.main_window.v then renderMainWindow() end

    if InfoPanel.infoPanel.v then renderInfoPanel() end
end

function setColorScheme()
    if elements.int.intImGui.v == 0 then
        gray()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0x262e38
        save()
    elseif elements.int.intImGui.v == 1 then
        blackred()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0xFF0000
        save()
    elseif elements.int.intImGui.v == 2 then
        purple()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0x6830a1
        save()
    elseif elements.int.intImGui.v == 3 then
        blue()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0x3d3d3d
        save()
    elseif elements.int.intImGui.v == 4 then
        blackwhite()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0x072b8c
        save()
    elseif elements.int.intImGui.v == 5 then
        orange()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0xFFA500
        save()
    elseif elements.int.intImGui.v == 6 then
        pink()
        mainIni.config.intImGui = elements.int.intImGui.v
        State.main_color = 0xAC0046
        save()
    end
end

function renderMainWindow()
    imgui.SetNextWindowPos(imgui.ImVec2(imgui.GetIO().DisplaySize.x / 2, imgui.GetIO().DisplaySize.y / 2),
        imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.SetNextWindowSize(imgui.ImVec2(745, 450), imgui.Cond.FirstUseEver)
    imgui.Begin('' .. thisScript().name .. ' | v.' .. thisScript().version .. '', State.main_window,
        imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)
    imgui.ShowCursor = true

    renderLeftPanel()
    imgui.SameLine()
    renderRightPanel()

    imgui.End()
end

function renderLeftPanel()
    imgui.BeginChild("##left", imgui.ImVec2(180, 400), true)

    local menuButtons = {
        { text = u8 'Основное', menu = 1 },
        { text = u8 'Auto Alert', menu = 2 },
        { text = u8 'Auto Find', menu = 3 },
        { text = u8 'Круиз Контроль', menu = 4 },
        { text = u8 'Skin Changer', menu = 5 },
        { text = u8 'Info Panel', menu = 6 },
        { text = u8 'Биндер', menu = 7 },
        { text = u8 'Спец.Клавиши', menu = 9 },
        { text = u8 'Настройки', menu = 10 }
    }

    for _, button in ipairs(menuButtons) do
        if imgui.Button(button.text, imgui.ImVec2(155, 30)) then
            State.menu = button.menu
        end
    end

    imgui.EndChild()
end

function renderRightPanel()
    imgui.BeginChild("##right", imgui.ImVec2(520, 400), true)

    local menuRenderers = {
        [0] = welcomeMenu,
        [1] = menu_1,
        [2] = menu_2,
        [3] = menu_3,
        [4] = menu_4,
        [5] = menu_5,
        [6] = menu_6,
        [7] = menu_7,
        [9] = menu_9,
        [10] = menu_10
    }

    local renderer = menuRenderers[State.menu]
    if renderer then
        renderer()
    end

    imgui.EndChild()
end

function getMyId()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        return id
    end
end

function getMyPing()
    local result, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if result then
        return sampGetPlayerPing(id)
    end
    return nil
end

-------------GetMyFPS---------------
local currentFPS = 0
local lastTick = 0
local frameCounter = 0

function updateFPS()
    lua_thread.create(function()
        while true do
            wait(0)
            frameCounter = frameCounter + 1
            local now = os.clock()
            if now - lastTick >= 1 then
                currentFPS = frameCounter
                frameCounter = 0
                lastTick = now
            end
        end
    end)
end

function getMyFPS()
    return currentFPS
end

-------------------------------------


function renderInfoPanel()
    if InfoPanel.btnInfoPanel.v then
        if InfoPanel.infoPanel.v then
            imgui.SetNextWindowPos(
                imgui.ImVec2(mainIni.infopanel.widgetInfoPanelPosX, mainIni.infopanel.widgetInfoPanelPosY), imgui.Cond
                .Always)
            imgui.Begin(u8 "##InfoPanel", InfoPanel.infoPanel,
                imgui.WindowFlags.NoMove + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.AlwaysAutoResize +
                imgui.WindowFlags.ShowBorders + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoTitleBar)

            if MoveWidgetInfoPanel then
                sampSetCursorMode(2)

                local cx, cy = getCursorPos()
                mainIni.infopanel.widgetInfoPanelPosX = cx
                mainIni.infopanel.widgetInfoPanelPosY = cy

                if imgui.IsMouseClicked(0) then
                    MoveWidgetInfoPanel = false
                    State.main_window.v = true
                    sampSetCursorMode(0)
                    save()
                    sampAddChatMessage('{AC0046}[Tools] {FFFFFF}Позиция закреплена.', -1)
                end
            end

            imgui.CenterText(u8 "FBI Tools")
            imgui.Separator()
            if InfoPanel.btnInfoPanelID and InfoPanel.btnInfoPanelCity and InfoPanel.btnInfoPanelZone and InfoPanel.btnInfoPanelPing then
                if InfoPanel.btnInfoPanelID.v then
                    imgui.CenterText(fa.ICON_USER_CIRCLE ..
                        u8 " " .. getMyNickSpec() .. " [" .. getMyId() .. "]")
                else
                    imgui.CenterText(fa.ICON_USER ..
                        u8 " " .. getMyNickSpec())
                end
                if InfoPanel.btnInfoPanelCity.v then imgui.CenterText(fa.ICON_MAP_MARKER .. u8 " " .. getMyCity()) end
                if InfoPanel.btnInfoPanelZone.v then imgui.CenterText(u8 " " .. getZoneName()) end
                if InfoPanel.btnInfoPanelPing.v or InfoPanel.btnInfoPanelFPS.v then
                    local ping_fps_text = ''
                    if InfoPanel.btnInfoPanelPing.v then
                        ping_fps_text = ping_fps_text .. fa.ICON_RSS .. u8 " " .. getMyPing()
                    end
                    if InfoPanel.btnInfoPanelPing.v and InfoPanel.btnInfoPanelFPS.v then
                        ping_fps_text = ping_fps_text .. u8 " | "
                    end
                    if InfoPanel.btnInfoPanelFPS.v then
                        ping_fps_text = ping_fps_text .. fa.ICON_TACHOMETER .. u8 " " .. getMyFPS()
                    end
                    local winWidth = imgui.GetWindowSize().x
                    local textWidth = imgui.CalcTextSize(ping_fps_text).x
                    imgui.SetCursorPosX((winWidth - textWidth) / 2)
                    imgui.Text(ping_fps_text)
                end
                if InfoPanel.btnInfoPanelDateTime.v then
                    imgui.Separator()
                    imgui.CenterText(os.date("%d.%m.%y | %H:%M:%S"))
                end
                if CruiseControl.state then
                    imgui.Separator()
                    imgui.CenterText(u8("Скорость круиза: %.0f"):format(CruiseControl.speed * 2))
                end
            else
                imgui.Text(u8 "Функции отключены")
            end
            imgui.End()
        end
    end
end

function menu_1()
    imgui.CenterText(u8 'Добро пожаловать, ' .. getMyNickSpec())
    imgui.Separator()

    --STROBES
    if imadd.ToggleButton("##straboscopes", State.straboscopes) then
        if State.straboscopes.v then
            sampAddChatMessage("[Tools] {FFFFFF}Стробоскопы {01DF01}включены{ffffff}.", State.main_color)
            mainIni.state.stroboscopes = true
            save()
        else
            sampAddChatMessage("[Tools] {FFFFFF}Стробоскопы {ff0000}отключены{ffffff}.", State.main_color)
            mainIni.state.stroboscopes = false
            save()
        end
    end
    imgui.SameLine()
    imgui.Text(u8 "Стробоскопы")
    imgui.SameLine()
    imgui.HelpMarker(u8 "Активация сирены /strobes | Активация стробоскопов P")

    -- BATTLEPASS
    if imadd.ToggleButton("##bindBattlePass", State.bindBattlePass) then
        if State.bindBattlePass.v then
            sampAddChatMessage("[Tools] {FFFFFF}Бинд для BattlePass {01DF01}включен{ffffff}.", State.main_color)
            mainIni.state.cfgBindBattlePass = true
            save()
        else
            sampAddChatMessage("[Tools] {FFFFFF}Бинд для BattlePass {ff0000}отключен{ffffff}.", State.main_color)
            mainIni.state.cfgBindBattlePass = false
            save()
        end
    end
    imgui.SameLine()
    imgui.Text(u8 "Бинд для BattlePass'a")
    imgui.SameLine()
    imgui.HelpMarker(u8 "Бинд настроить можно в разделе 'Спец.Клавиши' | Стандартный бинд F3")

    -- TAZER
    if imadd.ToggleButton("##bindTazer", State.bindTazer) then
        if State.bindTazer.v then
            sampAddChatMessage("[Tools] {FFFFFF}Бинд для електрошокера {01DF01}включен{ffffff}.", State.main_color)
            mainIni.state.bindTazer = true
            save()
        else
            sampAddChatMessage("[Tools] {FFFFFF}Бинд для електрошокера {ff0000}отключен{ffffff}.", State.main_color)
            mainIni.state.bindTazer = false
            save()
        end
    end
    imgui.SameLine()
    imgui.Text(u8 "Бинд для електрошокера")
    imgui.SameLine()
    imgui.HelpMarker(u8 "Бинд настроить можно в разделе 'Спец.Клавиши' | Стандартный бинд B")

    -- BANDAGE
    if imadd.ToggleButton("##bindBandage", State.bindBandage) then
        if State.bindBandage.v then
            sampAddChatMessage("[Tools] {FFFFFF}Бинд для использования бинта {01DF01}включен{ffffff}.", State.main_color)
            mainIni.state.bindBandage = true
            save()
        else
            sampAddChatMessage("[Tools] {FFFFFF}Бинд для использования бинта {ff0000}отключен{ffffff}.", State
                .main_color)
            mainIni.state.bindBandage = false
            save()
        end
    end
    imgui.SameLine()
    imgui.Text(u8 "Бинд для использования бинта")
    imgui.SameLine()
    imgui.HelpMarker(u8 "Бинд настроить можно в разделе 'Спец.Клавиши' | Стандартный бинд R")

    -- AUTOFIXCAR
    if imadd.ToggleButton("##auto_fix_state", State.auto_fix_state) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Автопочинка " ..
            (State.auto_fix_state.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.auto_fix = State.auto_fix_state.v
        save()
    end
    imgui.SameLine()
    imgui.Text(u8 "Автопочинка и автозаправка")
    imgui.SameLine()
    imgui.HelpMarker(u8 "Автопочинка и автозаправка в гос.гаражах. Для починки нужно заглушить двигатель.")

    -- SS TOOLS
    if imgui.CollapsingHeader('SS Tools') then
        imgui.Text(u8 "/ss - только IC чат (удаление ad, админских строк, PayDay, /r, /d, OOC чатов).")
        imgui.Text(u8 "/сс - очистить чат.")
        imgui.Text(u8 "/blackout - чёрный экран.")
    end

    if imgui.Button(u8 'Перезагрузить скрипт', ImVec2(490, 0)) then
        sampAddChatMessage('[Tools] {FFFFFF}Перезагрузка...', State.main_color)
        showCursor(false)
        thisScript():reload()
    end
    if imgui.Button(u8 'Выключить скрипт', ImVec2(490, 0)) then
        sampAddChatMessage('[Tools] {FFFFFF}Выключаем скрипт...', State.main_color)
        showCursor(false)
        thisScript():unload()
    end
end

function menu_2()
    if imadd.ToggleButton("##auto_alert_state", State.auto_alert_state) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Запрос о поддержке " ..
            (State.auto_alert_state.v and "{01DF01}включён" or "{ff0000}отключён") .. "{ffffff}.", State.main_color)
        mainIni.state.auto_alert = State.auto_alert_state.v
        save()
    end
    imgui.SameLine()
    imgui.Text(u8 "Запрос о поддержке")
    -- backup button
    if imgui.HotKey("##HotKeys.backup", HotKeys.backup) then
        rkeys.changeHotKey(ID_BACKUP, HotKeys.backup.v)
        mainIni.hotkeys.backup = encodeJson(HotKeys.backup.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку запроса поддержки')
    -- su button
    if imgui.HotKey("##HotKeys.su", HotKeys.su) then
        rkeys.changeHotKey(ID_SU, HotKeys.su.v)
        mainIni.hotkeys.su = encodeJson(HotKeys.su.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку выдачи розыска')
    -- backup text
    imgui.Text(u8 'Изменить текст вызова поддержки')
    imgui.SameLine()
    imgui.HelpMarker(u8 "Используйте #zone для указания района. Например: Требуется подкрепление. Район #zone.")

    State.auto_alert_backup_text_buffer.v = binds['backup_text']:gsub("%%s", "#zone")
    if imgui.InputText('##auto_alert_backup_text_buffer', State.auto_alert_backup_text_buffer) then
        local backup_text = State.auto_alert_backup_text_buffer.v:gsub("#zone", "%%s")
        binds['backup_text'] = backup_text
        save()
    end
end

function menu_3()
    if imadd.ToggleButton("##auto_find_state", State.auto_find_state) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Автопоиск " ..
            (State.auto_find_state.v and "{01DF01}включён" or "{ff0000}отключён") .. "{ffffff}.", State.main_color)
        mainIni.state.auto_find = State.auto_find_state.v
        save()
    end
    imgui.SameLine()
    imgui.Text(u8 "Автопоиск")
    imgui.Text(u8 'Активация: /find [id]')
    imgui.Text(u8 'Деактивация: /findoff')
    -- Нужна инфа!!!
    -- imgui.Separator()
    -- imgui.Text(u8 'Уровень Сыщика')
    -- imgui.SameLine()
    -- imgui.HelpMarker(u8 "/skill - Навык Сыщика")
    -- for i = 10, 1, -1 do
    --     if imgui.RadioButton(tostring(i), mainIni.config.auto_find_level_selected == i) then
    --         mainIni.config.auto_find_level_selected = i
    --         save()
    --     end
    --     imgui.SameLine()
    -- end
end

function menu_4()
    imgui.CenterText(u8 "Круиз Контроль")
    imgui.Separator() -- cruise control state
    if imgui.HotKey("##HotKeys.cruise_control_state", HotKeys.cruise_control_state) then
        rkeys.changeHotKey(ID_CRUISE_CONTROL_STATE, HotKeys.cruise_control_state.v)
        mainIni.hotkeys.cruise_control_state = encodeJson(HotKeys.cruise_control_state.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку активации круиз контроля')
    -- cruise control speed up
    if imgui.HotKey("##HotKeys.cruise_control_speed_up", HotKeys.cruise_control_speed_up) then
        rkeys.changeHotKey(ID_CRUISE_CONTROL_SPEED_UP, HotKeys.cruise_control_speed_up.v)
        mainIni.hotkeys.cruise_control_speed_up = encodeJson(HotKeys.cruise_control_speed_up.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку увеличения скорости круиза')
    -- cruise control slow down
    if imgui.HotKey("##HotKeys.cruise_control_slow_down", HotKeys.cruise_control_slow_down) then
        rkeys.changeHotKey(ID_CRUISE_CONTROL_SLOW_DOWN, HotKeys.cruise_control_slow_down.v)
        mainIni.hotkeys.cruise_control_slow_down = encodeJson(HotKeys.cruise_control_slow_down.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку уменьшения скорости круиза')
end

function menu_5()
    imgui.CenterText(u8 "Визуальная смена скина")
    imgui.Separator()
    imgui.InputText(u8 'Поиск ##skin_search', State.skinSearch)
    if imgui.Selectable(u8 'Выкл', SkinChanger.selectedSkin == 0) then
        SkinChanger.selectedSkin = 0
        apply()
    end
    for i = 1, #skins do
        local text = tostring(skins[i].id) .. ' - ' .. skins[i].name
        if #State.skinSearch.v > 0 and text:lower():lower():find(State.skinSearch.v) or #State.skinSearch.v == 0 then
            if imgui.Selectable((SkinChanger.selectedSkin == i and u8 '• ' or '') .. text, SkinChanger.selectedSkin == i) then
                SkinChanger.selectedSkin = i
                apply()
                save()
            end
        end
    end
end

function menu_6()
    imgui.CenterText(u8 "Информационная панель")
    imgui.Separator()

    if InfoPanel.btnInfoPanel.v then
        if imgui.Button(u8 "Изменить координаты статистики", imgui.ImVec2(490, 0)) then
            State.main_window.v = false
            MoveWidgetInfoPanel = true
            sampSetCursorMode(2)
            sampAddChatMessage('{AC0046}[Tools] {FFFFFF}Чтобы подтвердить местоположение - нажмите {FFA500}ЛКМ{FFFFFF}.',
                -1)
        end
    else
        imgui.Text(" ")
    end

    imgui.Columns(2, "info_columns", true)
    imgui.SetColumnWidth(0, 60)
    imgui.SetColumnWidth(1, 500)
    imgui.Text(u8 "    " .. fa.ICON_POWER_OFF)
    imgui.NextColumn()
    imgui.CenterText(u8 "Описание")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##infoPanel', InfoPanel.btnInfoPanel) then
        -- mainIni.infopanel.btnInfoPanel = InfoPanel.btnInfoPanel.v
        -- save()
        -- mainIni.infopanel.infoPanel = not InfoPanel.infoPanel.v
        local newState = InfoPanel.btnInfoPanel.v
        InfoPanel.infoPanel.v = newState -- синхронизируем сразу

        mainIni.infopanel.btnInfoPanel = newState
        mainIni.infopanel.infoPanel = newState
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Информационная панель")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##btnInfoPanelID', InfoPanel.btnInfoPanelID) then
        mainIni.infopanel.btnInfoPanelID = InfoPanel.btnInfoPanelID.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Показывать ID")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##btnInfoPanelCity', InfoPanel.btnInfoPanelCity) then
        mainIni.infopanel.btnInfoPanelCity = InfoPanel.btnInfoPanelCity.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Показывать текущий город")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##btnInfoPanelZone', InfoPanel.btnInfoPanelZone) then
        mainIni.infopanel.btnInfoPanelZone = InfoPanel.btnInfoPanelZone.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Показывать текущий район")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##btnInfoPanelPing', InfoPanel.btnInfoPanelPing) then
        mainIni.infopanel.btnInfoPanelPing = InfoPanel.btnInfoPanelPing.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Показывать текущий пинг")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##btnInfoPanelFPS', InfoPanel.btnInfoPanelFPS) then
        mainIni.infopanel.btnInfoPanelFPS = InfoPanel.btnInfoPanelFPS.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Показывать текущий ФПС")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton(u8 '##btnInfoPanelDateTime', InfoPanel.btnInfoPanelDateTime) then
        mainIni.infopanel.btnInfoPanelDateTime = InfoPanel.btnInfoPanelDateTime.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Показывать текущую дату и время")
    imgui.Columns(1)
    imgui.Separator()
end

function menu_7()
    imgui.CenterText(u8 'Базовые отыгровки')
    imgui.Separator()
    if imadd.ToggleButton("##binder", State.binder) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Биндер " ..
            (State.binder.v and "{01DF01}включён" or "{ff0000}отключён") .. "{ffffff}.", State.main_color)
        mainIni.state.binder = State.binder.v
        save()
    end
    imgui.SameLine()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Биндер")
    imgui.SameLine()
    imgui.HelpMarker(u8 "Впишите вашу отыгровку или оставьте как есть, #name заменяется на имя человека id которого вы вписали.")

    -- TABLE 3 COLUMNS
    imgui.Columns(3, "binds_columns", true) -- true — для видимых разделителей
    imgui.SetColumnWidth(0, 60)             -- первая колонка, например, 80px
    imgui.SetColumnWidth(1, 390)            -- вторая колонка, 300px
    imgui.SetColumnWidth(2, 60)

    imgui.Text(u8 "    " .. fa.ICON_POWER_OFF)
    imgui.NextColumn()
    imgui.Text(u8 "Описание")
    imgui.NextColumn()
    imgui.Text(u8 "Редакт.")
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton("##bindcuff", Binder.cuff) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Отыгровка наручников " ..
            (Binder.cuff.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.bind_cuff = Binder.cuff.v
        save()
    end
    imgui.NextColumn()

    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Отыгровка наручников. /cuff")
    if State.show_cuff_text_edit.v then
        State.binder_cuff_text_buffer.v = binds['cuff_text']:gsub("%%s", "#name")
        imgui.PushItemWidth(-1)
        if imgui.InputText('##binder_cuff_text_buffer', State.binder_cuff_text_buffer) then
            local text = State.binder_cuff_text_buffer.v:gsub("#name", "%%s")
            binds['cuff_text'] = text
            save()
        end
        imgui.PopItemWidth()
    end
    imgui.NextColumn()

    if imgui.Button(fa.ICON_PENCIL .. "##editcuff", "##bindcuff_edit_button", ImVec2(30, 0)) then
        State.show_cuff_text_edit.v = not State.show_cuff_text_edit.v
    end
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton("##bindfme", Binder.fme) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Отыгровка вести за собой " ..
            (Binder.fme.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.bind_fme = Binder.fme.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Отыгровка вести за собой. /fme")
    if State.show_fme_text_edit.v then
        State.binder_fme_text_buffer.v = binds['fme_text']:gsub("%%s", "#name")
        imgui.PushItemWidth(-1)
        if imgui.InputText('##binder_fme_text_buffer', State.binder_fme_text_buffer) then
            binds['fme_text'] = State.binder_fme_text_buffer.v:gsub("#name", "%%s")
            save()
        end
        imgui.PopItemWidth()
    end
    imgui.NextColumn()

    if imgui.Button(u8 "" .. fa.ICON_PENCIL .. "##bindfme_edit_button") then
        State.show_fme_text_edit.v = not State.show_fme_text_edit.v
    end
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton("##bindfrisk", Binder.frisk) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Отыгровка обыска " ..
            (Binder.frisk.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.bind_frisk = Binder.frisk.v
        save()
    end
    imgui.NextColumn()

    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Отыгровка обыска. /frisk")
    if State.show_frisk_text_edit.v then
        State.binder_frisk_text_buffer.v = binds['frisk_text']:gsub("%%s", "#name")
        imgui.PushItemWidth(-1)
        if imgui.InputText('##binder_frisk_text_buffer', State.binder_frisk_text_buffer) then
            local text = State.binder_frisk_text_buffer.v:gsub("#name", "%%s")
            binds['frisk_text'] = text
            save()
        end
        imgui.PopItemWidth()
    end
    imgui.NextColumn()

    if imgui.Button(u8 "" .. fa.ICON_PENCIL .. "##bindfrisk_edit_button") then
        State.show_frisk_text_edit.v = not State.show_frisk_text_edit.v
    end
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton("##bindincar", Binder.incar) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Отыгровка /incar " ..
            (Binder.incar.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.bind_incar = Binder.incar.v
        save()
    end
    imgui.NextColumn()

    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Отыгровка /incar")
    if State.show_incar_text_edit.v then
        State.binder_incar_text_buffer.v = binds['incar_text']:gsub("%%s", "#name")
        imgui.PushItemWidth(-1)
        if imgui.InputText('##binder_incar_text_buffer', State.binder_incar_text_buffer) then
            local text = State.binder_incar_text_buffer.v:gsub("#name", "%%s")
            binds['incar_text'] = text
            save()
        end
        imgui.PopItemWidth()
    end
    imgui.NextColumn()

    if imgui.Button(u8 "" .. fa.ICON_PENCIL .. "##bindincar_edit_button") then
        State.show_incar_text_edit.v = not State.show_incar_text_edit.v
    end
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton("##bindeject", Binder.eject) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Отыгровка /eject " ..
            (Binder.eject.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.bind_eject = Binder.eject.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Отыгровка /eject")
    if State.show_eject_text_edit.v then
        State.binder_eject_text_buffer.v = binds['eject_text']:gsub("%%s", "#name")
        imgui.PushItemWidth(-1)
        if imgui.InputText('##binder_eject_text_buffer', State.binder_eject_text_buffer) then
            local text = State.binder_eject_text_buffer.v:gsub("#name", "%%s")
            binds['eject_text'] = text
            save()
        end
        imgui.PopItemWidth()
    end

    imgui.NextColumn()
    if imgui.Button(u8 "" .. fa.ICON_PENCIL .. "##bindeject_edit_button") then
        State.show_eject_text_edit.v = not State.show_eject_text_edit.v
    end
    imgui.NextColumn()
    imgui.Separator()

    if imadd.ToggleButton("##bindarest", Binder.arest) then
        sampAddChatMessage(
            "[Tools] {FFFFFF}Отыгровка /arest " ..
            (Binder.arest.v and "{01DF01}включена" or "{ff0000}отключена") .. "{ffffff}.", State.main_color)
        mainIni.state.bind_arest = Binder.arest.v
        save()
    end
    imgui.NextColumn()
    imgui.SetCursorPosY(imgui.GetCursorPosY() + 4)
    imgui.Text(u8 "Отыгровка /arest")
    if State.show_arest_text_edit.v then
        State.binder_arest_text_buffer.v = binds['arest_text']:gsub("%%s", "#name")
        imgui.PushItemWidth(-1)
        if imgui.InputText('##binder_arest_text_buffer', State.binder_arest_text_buffer) then
            local text = State.binder_arest_text_buffer.v:gsub("#name", "%%s")
            binds['arest_text'] = text
            save()
        end
        imgui.PopItemWidth()
    end
    imgui.NextColumn()
    if imgui.Button(u8 "" .. fa.ICON_PENCIL .. "##bindarest_edit_button") then
        State.show_arest_text_edit.v = not State.show_arest_text_edit.v
    end
    imgui.Columns(1) -- закрытие таблицы
    imgui.Separator()
end

function menu_9()
    -- callback 1
    if imgui.HotKey("##HotKeys.main_menu", HotKeys.main_menu) then
        rkeys.changeHotKey(ID_MAIN_MENU, HotKeys.main_menu.v)
        mainIni.hotkeys.main_menu = encodeJson(HotKeys.main_menu.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку активации меню')
    -- battlepass
    if imgui.HotKey("##HotKeys.battlepass", HotKeys.battlepass) then
        rkeys.changeHotKey(ID_BATTLEPASS, HotKeys.battlepass.v)
        mainIni.hotkeys.battlepass = encodeJson(HotKeys.battlepass.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку активации Battle Pass')
    -- crosshair hold
    if imgui.HotKey("##HotKeys.crosshair", HotKeys.crosshair) then
        rkeys.changeHotKey(ID_CROSSHAIR, HotKeys.crosshair.v)
        mainIni.hotkeys.crosshair = encodeJson(HotKeys.crosshair.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку активации задержки прицела')
    -- tazer
    if imgui.HotKey("##HotKeys.bindTazer", HotKeys.bindTazer) then
        rkeys.changeHotKey(ID_BINDTAZER, HotKeys.bindTazer.v)
        mainIni.hotkeys.bindTazer = encodeJson(HotKeys.bindTazer.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку активации електрошокера')
    -- bandage
    if imgui.HotKey("##HotKeys.bindBandage", HotKeys.bindBandage) then
        rkeys.changeHotKey(ID_BINDBANDAGE, HotKeys.bindBandage.v)
        mainIni.hotkeys.bindBandage = encodeJson(HotKeys.bindBandage.v)
        save()
        sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", State.main_color)
    end
    imgui.SameLine()
    imgui.Text(u8 'Изменить кнопку активации использования бинтов')
end

function menu_10()
    imgui.CenterText(u8 "Настройки")
    imgui.Separator()
    local styles = { u8 "Серая", u8 "Красная", u8 "Фиолетовая", u8 "Чёрная", u8 "Синяя", u8 "Оранжевая", u8 "Розовая" }
    imgui.Combo(u8 'Стиль интерфейса', elements.int.intImGui, styles)
    -- if imadd.ToggleButton("##idDialog", State.CheckBoxDialogID) then
    --     if State.CheckBoxDialogID.v then
    --         sampAddChatMessage("[Подсказка] {FFFFFF}Dialog ID {01DF01}включён{ffffff}.", State.main_color)
    --     else
    --         sampAddChatMessage("[Подсказка] {FFFFFF}Dialog ID {ff0000}отключён{ffffff}.", State.main_color)
    --     end
    -- end
    -- imgui.SameLine()
    -- imgui.TextColoredRGB('[Выкл/Вкл]  {FF0000}Dialog ID')
end

function brown()
    imgui.SwitchContext()
    local style                      = imgui.GetStyle()
    local colors                     = style.Colors
    local clr                        = imgui.Col
    local ImVec4                     = imgui.ImVec4

    style.WindowRounding             = 2.0
    style.WindowTitleAlign           = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding        = 2.0
    style.FrameRounding              = 2.0
    style.ItemSpacing                = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize              = 9.0
    style.ScrollbarRounding          = 0
    style.GrabMinSize                = 8.0
    style.GrabRounding               = 1.0

    colors[clr.FrameBg]              = ImVec4(0.48, 0.23, 0.16, 0.54)
    colors[clr.FrameBgHovered]       = ImVec4(0.98, 0.43, 0.26, 0.40)
    colors[clr.FrameBgActive]        = ImVec4(0.98, 0.43, 0.26, 0.67)
    colors[clr.TitleBg]              = ImVec4(0.48, 0.23, 0.16, 1.00)
    colors[clr.TitleBgActive]        = ImVec4(0.48, 0.23, 0.16, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.48, 0.23, 0.16, 1.00)
    colors[clr.CheckMark]            = ImVec4(0.98, 0.43, 0.26, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.88, 0.39, 0.24, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(0.98, 0.43, 0.26, 1.00)
    colors[clr.Button]               = ImVec4(0.98, 0.43, 0.26, 0.40)
    colors[clr.ButtonHovered]        = ImVec4(0.98, 0.43, 0.26, 1.00)
    colors[clr.ButtonActive]         = ImVec4(0.98, 0.28, 0.06, 1.00)
    colors[clr.Header]               = ImVec4(0.98, 0.43, 0.26, 0.31)
    colors[clr.HeaderHovered]        = ImVec4(0.98, 0.43, 0.26, 0.80)
    colors[clr.HeaderActive]         = ImVec4(0.98, 0.43, 0.26, 1.00)
    colors[clr.Separator]            = colors[clr.Border]
    colors[clr.SeparatorHovered]     = ImVec4(0.75, 0.25, 0.10, 0.78)
    colors[clr.SeparatorActive]      = ImVec4(0.75, 0.25, 0.10, 1.00)
    colors[clr.ResizeGrip]           = ImVec4(0.98, 0.43, 0.26, 0.25)
    colors[clr.ResizeGripHovered]    = ImVec4(0.98, 0.43, 0.26, 0.67)
    colors[clr.ResizeGripActive]     = ImVec4(0.98, 0.43, 0.26, 0.95)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.50, 0.35, 1.00)
    colors[clr.TextSelectedBg]       = ImVec4(0.98, 0.43, 0.26, 0.35)
    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]         = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]             = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]        = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]              = colors[clr.PopupBg]
    colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]            = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]          = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]   = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]    = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function gray()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 15.0
    style.FramePadding = ImVec2(5, 5)
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 15.0
    style.GrabMinSize = 15.0
    style.GrabRounding = 7.0
    style.ChildWindowRounding = 8.0
    style.FrameRounding = 6.0


    colors[clr.Text] = ImVec4(0.95, 0.96, 0.98, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.36, 0.42, 0.47, 1.00)
    colors[clr.WindowBg] = ImVec4(0.11, 0.15, 0.17, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.PopupBg] = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.Border] = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.FrameBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.12, 0.20, 0.28, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.09, 0.12, 0.14, 1.00)
    colors[clr.TitleBg] = ImVec4(0.09, 0.12, 0.14, 0.65)
    colors[clr.TitleBgCollapsed] = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.TitleBgActive] = ImVec4(0.08, 0.10, 0.12, 1.00)
    colors[clr.MenuBarBg] = ImVec4(0.15, 0.18, 0.22, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.02, 0.02, 0.02, 0.39)
    colors[clr.ScrollbarGrab] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.18, 0.22, 0.25, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.09, 0.21, 0.31, 1.00)
    colors[clr.ComboBg] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.CheckMark] = ImVec4(0.28, 0.56, 1.00, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.28, 0.56, 1.00, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.37, 0.61, 1.00, 1.00)
    colors[clr.Button] = ImVec4(0.20, 0.25, 0.29, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.28, 0.56, 1.00, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header] = ImVec4(0.20, 0.25, 0.29, 0.55)
    colors[clr.HeaderHovered] = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive] = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered] = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.40, 0.39, 0.38, 0.16)
    colors[clr.CloseButtonHovered] = ImVec4(0.40, 0.39, 0.38, 0.39)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered] = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function blackred()
    imgui.SwitchContext()
    local style                      = imgui.GetStyle()
    local colors                     = style.Colors
    local clr                        = imgui.Col
    local ImVec4                     = imgui.ImVec4

    style.WindowPadding              = ImVec2(15, 15)
    style.WindowRounding             = 6.0
    style.FramePadding               = ImVec2(5, 5)
    style.FrameRounding              = 4.0
    style.ItemSpacing                = ImVec2(12, 8)
    style.ItemInnerSpacing           = ImVec2(8, 6)
    style.IndentSpacing              = 25.0
    style.ScrollbarSize              = 15.0
    style.ScrollbarRounding          = 9.0
    style.GrabMinSize                = 5.0
    style.GrabRounding               = 3.0

    colors[clr.FrameBg]              = ImVec4(0.48, 0.16, 0.16, 0.54)
    colors[clr.FrameBgHovered]       = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.FrameBgActive]        = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.TitleBg]              = ImVec4(0.98, 0.06, 0.06, 1.00)
    colors[clr.TitleBgActive]        = ImVec4(0.98, 0.06, 0.06, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]            = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.88, 0.26, 0.24, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Button]               = ImVec4(0.98, 0.26, 0.26, 0.40)
    colors[clr.ButtonHovered]        = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.ButtonActive]         = ImVec4(0.98, 0.06, 0.06, 1.00)
    colors[clr.Header]               = ImVec4(0.98, 0.26, 0.26, 0.31)
    colors[clr.HeaderHovered]        = ImVec4(0.98, 0.26, 0.26, 0.80)
    colors[clr.HeaderActive]         = ImVec4(0.98, 0.26, 0.26, 1.00)
    colors[clr.Separator]            = colors[clr.Border]
    colors[clr.SeparatorHovered]     = ImVec4(0.75, 0.10, 0.10, 0.78)
    colors[clr.SeparatorActive]      = ImVec4(0.75, 0.10, 0.10, 1.00)
    colors[clr.ResizeGrip]           = ImVec4(0.98, 0.26, 0.26, 0.25)
    colors[clr.ResizeGripHovered]    = ImVec4(0.98, 0.26, 0.26, 0.67)
    colors[clr.ResizeGripActive]     = ImVec4(0.98, 0.26, 0.26, 0.95)
    colors[clr.TextSelectedBg]       = ImVec4(0.98, 0.26, 0.26, 0.35)
    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]         = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]             = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg]        = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]              = colors[clr.PopupBg]
    colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]            = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]          = ImVec4(0.120, 0.120, 0.120, 1.00)
    colors[clr.CloseButtonHovered]   = ImVec4(1.00, 0.00, 0.00, 1.00)
    colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function purple()
    imgui.SwitchContext()
    local style                      = imgui.GetStyle()
    local colors                     = style.Colors
    local clr                        = imgui.Col
    local ImVec4                     = imgui.ImVec4
    style.WindowPadding              = ImVec2(15, 15)
    style.WindowRounding             = 6.0
    style.FramePadding               = ImVec2(5, 5)
    style.FrameRounding              = 4.0
    style.ItemSpacing                = ImVec2(12, 8)
    style.ItemInnerSpacing           = ImVec2(8, 6)
    style.IndentSpacing              = 25.0
    style.ScrollbarSize              = 15.0
    style.ScrollbarRounding          = 9.0
    style.GrabMinSize                = 5.0
    style.GrabRounding               = 3.0
    colors[clr.WindowBg]             = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg]        = ImVec4(0.30, 0.20, 0.39, 0.00);
    colors[clr.PopupBg]              = ImVec4(0.05, 0.05, 0.10, 0.90);
    colors[clr.Border]               = ImVec4(0.89, 0.85, 0.92, 0.30);
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[clr.FrameBg]              = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.FrameBgHovered]       = ImVec4(0.41, 0.19, 0.63, 0.68);
    colors[clr.FrameBgActive]        = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TitleBg]              = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TitleBgCollapsed]     = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TitleBgActive]        = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.MenuBarBg]            = ImVec4(0.30, 0.20, 0.39, 0.57);
    colors[clr.ScrollbarBg]          = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.ScrollbarGrab]        = ImVec4(0.41, 0.19, 0.63, 0.31);
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ComboBg]              = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.CheckMark]            = ImVec4(0.56, 0.61, 1.00, 1.00);
    colors[clr.SliderGrab]           = ImVec4(0.41, 0.19, 0.63, 0.24);
    colors[clr.SliderGrabActive]     = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.Button]               = ImVec4(0.41, 0.19, 0.63, 0.44);
    colors[clr.ButtonHovered]        = ImVec4(0.41, 0.19, 0.63, 0.86);
    colors[clr.ButtonActive]         = ImVec4(0.64, 0.33, 0.94, 1.00);
    colors[clr.Header]               = ImVec4(0.41, 0.19, 0.63, 0.76);
    colors[clr.HeaderHovered]        = ImVec4(0.41, 0.19, 0.63, 0.86);
    colors[clr.HeaderActive]         = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ResizeGrip]           = ImVec4(0.41, 0.19, 0.63, 0.20);
    colors[clr.ResizeGripHovered]    = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ResizeGripActive]     = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.CloseButton]          = ImVec4(0.120, 0.120, 0.120, 1.00)
    colors[clr.CloseButtonHovered]   = ImVec4(1.00, 0.00, 0.00, 1.00)
    colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotLinesHovered]     = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.PlotHistogram]        = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotHistogramHovered] = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TextSelectedBg]       = ImVec4(0.41, 0.19, 0.63, 0.43);
    colors[clr.ModalWindowDarkening] = ImVec4(0.20, 0.20, 0.20, 0.35);
end

function blue()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowPadding = imgui.ImVec2(15, 15)
    style.WindowRounding = 1.5
    style.FramePadding = imgui.ImVec2(5, 5)
    style.FrameRounding = 4.0
    style.ItemSpacing = imgui.ImVec2(12, 8)
    style.ItemInnerSpacing = imgui.ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 9.0
    style.GrabMinSize = 5.0
    style.GrabRounding = 3.0

    colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
    colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
    colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.TitleBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
    colors[clr.TitleBgActive] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
    colors[clr.CheckMark] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.SliderGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.SliderGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.120, 0.120, 0.120, 1.00)
    colors[clr.CloseButtonHovered] = ImVec4(1.00, 0.00, 0.00, 1.00)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function blackwhite()
    imgui.SwitchContext()
    local style                      = imgui.GetStyle()
    local colors                     = style.Colors
    local clr                        = imgui.Col
    local ImVec4                     = imgui.ImVec4

    style.WindowPadding              = ImVec2(15, 15)
    style.WindowRounding             = 6.0
    style.FramePadding               = ImVec2(5, 5)
    style.FrameRounding              = 4.0
    style.ItemSpacing                = ImVec2(12, 8)
    style.ItemInnerSpacing           = ImVec2(8, 6)
    style.IndentSpacing              = 25.0
    style.ScrollbarSize              = 15.0
    style.ScrollbarRounding          = 9.0
    style.GrabMinSize                = 5.0
    style.GrabRounding               = 3.0

    colors[clr.FrameBg]              = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]       = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]        = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]              = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgActive]        = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.CheckMark]            = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]           = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]     = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]               = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.ButtonHovered]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ButtonActive]         = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header]               = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]        = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]         = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]            = colors[clr.Border]
    colors[clr.SeparatorHovered]     = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]      = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]           = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]    = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]     = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]         = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]             = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg]        = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]              = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]              = colors[clr.PopupBg]
    colors[clr.Border]               = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]            = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]          = ImVec4(0.120, 0.120, 0.120, 1.00)
    colors[clr.CloseButtonHovered]   = ImVec4(1.00, 0.00, 0.00, 1.00)
    colors[clr.CloseButtonActive]    = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening] = ImVec4(0.80, 0.80, 0.80, 0.35)
end

function orange()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 6.0
    style.FramePadding = ImVec2(5, 5)
    style.FrameRounding = 4.0
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 9.0
    style.GrabMinSize = 5.0
    style.GrabRounding = 3.0

    colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
    colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
    colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.TitleBg] = ImVec4(0.76, 0.31, 0.00, 1.00)
    colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
    colors[clr.TitleBgActive] = ImVec4(0.80, 0.33, 0.00, 1.00)
    colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
    colors[clr.CheckMark] = ImVec4(1.00, 0.42, 0.00, 0.53)
    colors[clr.SliderGrab] = ImVec4(1.00, 0.42, 0.00, 0.53)
    colors[clr.SliderGrabActive] = ImVec4(1.00, 0.42, 0.00, 1.00)
    colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.80, 0.33, 0.00, 1.00)
    colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.120, 0.120, 0.120, 1.00)
    colors[clr.CloseButtonHovered] = ImVec4(1.00, 0.00, 0.00, 1.00)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function pink()
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2

    style.WindowPadding = ImVec2(15, 15)
    style.WindowRounding = 6.0
    style.FramePadding = ImVec2(5, 5)
    style.FrameRounding = 4.0
    style.ItemSpacing = ImVec2(12, 8)
    style.ItemInnerSpacing = ImVec2(8, 6)
    style.IndentSpacing = 25.0
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 9.0
    style.GrabMinSize = 5.0
    style.GrabRounding = 3.0

    colors[clr.Text] = ImVec4(0.80, 0.80, 0.83, 1.00)
    colors[clr.TextDisabled] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.WindowBg] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ChildWindowBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.PopupBg] = ImVec4(0.07, 0.07, 0.09, 1.00)
    colors[clr.Border] = ImVec4(0.80, 0.80, 0.83, 0.88)
    colors[clr.BorderShadow] = ImVec4(0.92, 0.91, 0.88, 0.00)
    colors[clr.FrameBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.FrameBgHovered] = ImVec4(0.24, 0.23, 0.29, 1.00)
    colors[clr.FrameBgActive] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.TitleBg] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.TitleBgCollapsed] = ImVec4(1.00, 0.98, 0.95, 0.75)
    colors[clr.TitleBgActive] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.MenuBarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarBg] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ScrollbarGrab] = ImVec4(0.80, 0.80, 0.83, 0.31)
    colors[clr.ScrollbarGrabHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ScrollbarGrabActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ComboBg] = ImVec4(0.19, 0.18, 0.21, 1.00)
    colors[clr.CheckMark] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.SliderGrab] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.SliderGrabActive] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.Button] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.ButtonHovered] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.ButtonActive] = ImVec4(0.675, 0.000, 0.275, 1.00)
    colors[clr.Header] = ImVec4(0.10, 0.09, 0.12, 1.00)
    colors[clr.HeaderHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.HeaderActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.ResizeGrip] = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.ResizeGripHovered] = ImVec4(0.56, 0.56, 0.58, 1.00)
    colors[clr.ResizeGripActive] = ImVec4(0.06, 0.05, 0.07, 1.00)
    colors[clr.CloseButton] = ImVec4(0.120, 0.120, 0.120, 1.00)
    colors[clr.CloseButtonHovered] = ImVec4(1.00, 0.00, 0.00, 1.00)
    colors[clr.CloseButtonActive] = ImVec4(0.40, 0.39, 0.38, 1.00)
    colors[clr.PlotLines] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotLinesHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.PlotHistogram] = ImVec4(0.40, 0.39, 0.38, 0.63)
    colors[clr.PlotHistogramHovered] = ImVec4(0.25, 1.00, 0.00, 1.00)
    colors[clr.TextSelectedBg] = ImVec4(0.25, 1.00, 0.00, 0.43)
    colors[clr.ModalWindowDarkening] = ImVec4(1.00, 0.98, 0.95, 0.73)
end

function calculateZone(x, y, z)
    local streets = {
        { "Avispa Country Club",        -2667.810, -302.135,  -28.831,  -2646.400, -262.320,  71.169 },
        { "Easter Bay Airport",         -1315.420, -405.388,  15.406,   -1264.400, -209.543,  25.406 },
        { "Avispa Country Club",        -2550.040, -355.493,  0.000,    -2470.040, -318.493,  39.700 },
        { "Easter Bay Airport",         -1490.330, -209.543,  15.406,   -1264.400, -148.388,  25.406 },
        { "Garcia",                     -2395.140, -222.589,  -5.3,     -2354.090, -204.792,  200.000 },
        { "Shady Cabin",                -1632.830, -2263.440, -3.0,     -1601.330, -2231.790, 200.000 },
        { "East Los Santos",            2381.680,  -1494.030, -89.084,  2421.030,  -1454.350, 110.916 },
        { "LVA Freight Depot",          1236.630,  1163.410,  -89.084,  1277.050,  1203.280,  110.916 },
        { "Blackfield Intersection",    1277.050,  1044.690,  -89.084,  1315.350,  1087.630,  110.916 },
        { "Avispa Country Club",        -2470.040, -355.493,  0.000,    -2270.040, -318.493,  46.100 },
        { "Temple",                     1252.330,  -926.999,  -89.084,  1357.000,  -910.170,  110.916 },
        { "Unity Station",              1692.620,  -1971.800, -20.492,  1812.620,  -1932.800, 79.508 },
        { "LVA Freight Depot",          1315.350,  1044.690,  -89.084,  1375.600,  1087.630,  110.916 },
        { "Los Flores",                 2581.730,  -1454.350, -89.084,  2632.830,  -1393.420, 110.916 },
        { "Starfish Casino",            2437.390,  1858.100,  -39.084,  2495.090,  1970.850,  60.916 },
        { "Easter Bay Chemicals",       -1132.820, -787.391,  0.000,    -956.476,  -768.027,  200.000 },
        { "Downtown Los Santos",        1370.850,  -1170.870, -89.084,  1463.900,  -1130.850, 110.916 },
        { "Esplanade East",             -1620.300, 1176.520,  -4.5,     -1580.010, 1274.260,  200.000 },
        { "Market Station",             787.461,   -1410.930, -34.126,  866.009,   -1310.210, 65.874 },
        { "Linden Station",             2811.250,  1229.590,  -39.594,  2861.250,  1407.590,  60.406 },
        { "Montgomery Intersection",    1582.440,  347.457,   0.000,    1664.620,  401.750,   200.000 },
        { "Frederick Bridge",           2759.250,  296.501,   0.000,    2774.250,  594.757,   200.000 },
        { "Yellow Bell Station",        1377.480,  2600.430,  -21.926,  1492.450,  2687.360,  78.074 },
        { "Downtown Los Santos",        1507.510,  -1385.210, 110.916,  1582.550,  -1325.310, 335.916 },
        { "Jefferson",                  2185.330,  -1210.740, -89.084,  2281.450,  -1154.590, 110.916 },
        { "Mulholland",                 1318.130,  -910.170,  -89.084,  1357.000,  -768.027,  110.916 },
        { "Avispa Country Club",        -2361.510, -417.199,  0.000,    -2270.040, -355.493,  200.000 },
        { "Jefferson",                  1996.910,  -1449.670, -89.084,  2056.860,  -1350.720, 110.916 },
        { "Julius Thruway West",        1236.630,  2142.860,  -89.084,  1297.470,  2243.230,  110.916 },
        { "Jefferson",                  2124.660,  -1494.030, -89.084,  2266.210,  -1449.670, 110.916 },
        { "Julius Thruway North",       1848.400,  2478.490,  -89.084,  1938.800,  2553.490,  110.916 },
        { "Rodeo",                      422.680,   -1570.200, -89.084,  466.223,   -1406.050, 110.916 },
        { "Cranberry Station",          -2007.830, 56.306,    0.000,    -1922.000, 224.782,   100.000 },
        { "Downtown Los Santos",        1391.050,  -1026.330, -89.084,  1463.900,  -926.999,  110.916 },
        { "Redsands West",              1704.590,  2243.230,  -89.084,  1777.390,  2342.830,  110.916 },
        { "Little Mexico",              1758.900,  -1722.260, -89.084,  1812.620,  -1577.590, 110.916 },
        { "Blackfield Intersection",    1375.600,  823.228,   -89.084,  1457.390,  919.447,   110.916 },
        { "Los Santos International",   1974.630,  -2394.330, -39.084,  2089.000,  -2256.590, 60.916 },
        { "Beacon Hill",                -399.633,  -1075.520, -1.489,   -319.033,  -977.516,  198.511 },
        { "Rodeo",                      334.503,   -1501.950, -89.084,  422.680,   -1406.050, 110.916 },
        { "Richman",                    225.165,   -1369.620, -89.084,  334.503,   -1292.070, 110.916 },
        { "Downtown Los Santos",        1724.760,  -1250.900, -89.084,  1812.620,  -1150.870, 110.916 },
        { "The Strip",                  2027.400,  1703.230,  -89.084,  2137.400,  1783.230,  110.916 },
        { "Downtown Los Santos",        1378.330,  -1130.850, -89.084,  1463.900,  -1026.330, 110.916 },
        { "Blackfield Intersection",    1197.390,  1044.690,  -89.084,  1277.050,  1163.390,  110.916 },
        { "Conference Center",          1073.220,  -1842.270, -89.084,  1323.900,  -1804.210, 110.916 },
        { "Montgomery",                 1451.400,  347.457,   -6.1,     1582.440,  420.802,   200.000 },
        { "Foster Valley",              -2270.040, -430.276,  -1.2,     -2178.690, -324.114,  200.000 },
        { "Blackfield Chapel",          1325.600,  596.349,   -89.084,  1375.600,  795.010,   110.916 },
        { "Los Santos International",   2051.630,  -2597.260, -39.084,  2152.450,  -2394.330, 60.916 },
        { "Mulholland",                 1096.470,  -910.170,  -89.084,  1169.130,  -768.027,  110.916 },
        { "Yellow Bell Gol Course",     1457.460,  2723.230,  -89.084,  1534.560,  2863.230,  110.916 },
        { "The Strip",                  2027.400,  1783.230,  -89.084,  2162.390,  1863.230,  110.916 },
        { "Jefferson",                  2056.860,  -1210.740, -89.084,  2185.330,  -1126.320, 110.916 },
        { "Mulholland",                 952.604,   -937.184,  -89.084,  1096.470,  -860.619,  110.916 },
        { "Aldea Malvada",              -1372.140, 2498.520,  0.000,    -1277.590, 2615.350,  200.000 },
        { "Las Colinas",                2126.860,  -1126.320, -89.084,  2185.330,  -934.489,  110.916 },
        { "Las Colinas",                1994.330,  -1100.820, -89.084,  2056.860,  -920.815,  110.916 },
        { "Richman",                    647.557,   -954.662,  -89.084,  768.694,   -860.619,  110.916 },
        { "LVA Freight Depot",          1277.050,  1087.630,  -89.084,  1375.600,  1203.280,  110.916 },
        { "Julius Thruway North",       1377.390,  2433.230,  -89.084,  1534.560,  2507.230,  110.916 },
        { "Willowfield",                2201.820,  -2095.000, -89.084,  2324.000,  -1989.900, 110.916 },
        { "Julius Thruway North",       1704.590,  2342.830,  -89.084,  1848.400,  2433.230,  110.916 },
        { "Temple",                     1252.330,  -1130.850, -89.084,  1378.330,  -1026.330, 110.916 },
        { "Little Mexico",              1701.900,  -1842.270, -89.084,  1812.620,  -1722.260, 110.916 },
        { "Queens",                     -2411.220, 373.539,   0.000,    -2253.540, 458.411,   200.000 },
        { "Las Venturas Airport",       1515.810,  1586.400,  -12.500,  1729.950,  1714.560,  87.500 },
        { "Richman",                    225.165,   -1292.070, -89.084,  466.223,   -1235.070, 110.916 },
        { "Temple",                     1252.330,  -1026.330, -89.084,  1391.050,  -926.999,  110.916 },
        { "East Los Santos",            2266.260,  -1494.030, -89.084,  2381.680,  -1372.040, 110.916 },
        { "Julius Thruway East",        2623.180,  943.235,   -89.084,  2749.900,  1055.960,  110.916 },
        { "Willowfield",                2541.700,  -1941.400, -89.084,  2703.580,  -1852.870, 110.916 },
        { "Las Colinas",                2056.860,  -1126.320, -89.084,  2126.860,  -920.815,  110.916 },
        { "Julius Thruway East",        2625.160,  2202.760,  -89.084,  2685.160,  2442.550,  110.916 },
        { "Rodeo",                      225.165,   -1501.950, -89.084,  334.503,   -1369.620, 110.916 },
        { "Las Brujas",                 -365.167,  2123.010,  -3.0,     -208.570,  2217.680,  200.000 },
        { "Julius Thruway East",        2536.430,  2442.550,  -89.084,  2685.160,  2542.550,  110.916 },
        { "Rodeo",                      334.503,   -1406.050, -89.084,  466.223,   -1292.070, 110.916 },
        { "Vinewood",                   647.557,   -1227.280, -89.084,  787.461,   -1118.280, 110.916 },
        { "Rodeo",                      422.680,   -1684.650, -89.084,  558.099,   -1570.200, 110.916 },
        { "Julius Thruway North",       2498.210,  2542.550,  -89.084,  2685.160,  2626.550,  110.916 },
        { "Downtown Los Santos",        1724.760,  -1430.870, -89.084,  1812.620,  -1250.900, 110.916 },
        { "Rodeo",                      225.165,   -1684.650, -89.084,  312.803,   -1501.950, 110.916 },
        { "Jefferson",                  2056.860,  -1449.670, -89.084,  2266.210,  -1372.040, 110.916 },
        { "Hampton Barns",              603.035,   264.312,   0.000,    761.994,   366.572,   200.000 },
        { "Temple",                     1096.470,  -1130.840, -89.084,  1252.330,  -1026.330, 110.916 },
        { "Kincaid Bridge",             -1087.930, 855.370,   -89.084,  -961.950,  986.281,   110.916 },
        { "Verona Beach",               1046.150,  -1722.260, -89.084,  1161.520,  -1577.590, 110.916 },
        { "Commerce",                   1323.900,  -1722.260, -89.084,  1440.900,  -1577.590, 110.916 },
        { "Mulholland",                 1357.000,  -926.999,  -89.084,  1463.900,  -768.027,  110.916 },
        { "Rodeo",                      466.223,   -1570.200, -89.084,  558.099,   -1385.070, 110.916 },
        { "Mulholland",                 911.802,   -860.619,  -89.084,  1096.470,  -768.027,  110.916 },
        { "Mulholland",                 768.694,   -954.662,  -89.084,  952.604,   -860.619,  110.916 },
        { "Julius Thruway South",       2377.390,  788.894,   -89.084,  2537.390,  897.901,   110.916 },
        { "Idlewood",                   1812.620,  -1852.870, -89.084,  1971.660,  -1742.310, 110.916 },
        { "Ocean Docks",                2089.000,  -2394.330, -89.084,  2201.820,  -2235.840, 110.916 },
        { "Commerce",                   1370.850,  -1577.590, -89.084,  1463.900,  -1384.950, 110.916 },
        { "Julius Thruway North",       2121.400,  2508.230,  -89.084,  2237.400,  2663.170,  110.916 },
        { "Temple",                     1096.470,  -1026.330, -89.084,  1252.330,  -910.170,  110.916 },
        { "Glen Park",                  1812.620,  -1449.670, -89.084,  1996.910,  -1350.720, 110.916 },
        { "Easter Bay Airport",         -1242.980, -50.096,   0.000,    -1213.910, 578.396,   200.000 },
        { "Martin Bridge",              -222.179,  293.324,   0.000,    -122.126,  476.465,   200.000 },
        { "The Strip",                  2106.700,  1863.230,  -89.084,  2162.390,  2202.760,  110.916 },
        { "Willowfield",                2541.700,  -2059.230, -89.084,  2703.580,  -1941.400, 110.916 },
        { "Marina",                     807.922,   -1577.590, -89.084,  926.922,   -1416.250, 110.916 },
        { "Las Venturas Airport",       1457.370,  1143.210,  -89.084,  1777.400,  1203.280,  110.916 },
        { "Idlewood",                   1812.620,  -1742.310, -89.084,  1951.660,  -1602.310, 110.916 },
        { "Esplanade East",             -1580.010, 1025.980,  -6.1,     -1499.890, 1274.260,  200.000 },
        { "Downtown Los Santos",        1370.850,  -1384.950, -89.084,  1463.900,  -1170.870, 110.916 },
        { "The Mako Span",              1664.620,  401.750,   0.000,    1785.140,  567.203,   200.000 },
        { "Rodeo",                      312.803,   -1684.650, -89.084,  422.680,   -1501.950, 110.916 },
        { "Pershing Square",            1440.900,  -1722.260, -89.084,  1583.500,  -1577.590, 110.916 },
        { "Mulholland",                 687.802,   -860.619,  -89.084,  911.802,   -768.027,  110.916 },
        { "Gant Bridge",                -2741.070, 1490.470,  -6.1,     -2616.400, 1659.680,  200.000 },
        { "Las Colinas",                2185.330,  -1154.590, -89.084,  2281.450,  -934.489,  110.916 },
        { "Mulholland",                 1169.130,  -910.170,  -89.084,  1318.130,  -768.027,  110.916 },
        { "Julius Thruway North",       1938.800,  2508.230,  -89.084,  2121.400,  2624.230,  110.916 },
        { "Commerce",                   1667.960,  -1577.590, -89.084,  1812.620,  -1430.870, 110.916 },
        { "Rodeo",                      72.648,    -1544.170, -89.084,  225.165,   -1404.970, 110.916 },
        { "Roca Escalante",             2536.430,  2202.760,  -89.084,  2625.160,  2442.550,  110.916 },
        { "Rodeo",                      72.648,    -1684.650, -89.084,  225.165,   -1544.170, 110.916 },
        { "Market",                     952.663,   -1310.210, -89.084,  1072.660,  -1130.850, 110.916 },
        { "Las Colinas",                2632.740,  -1135.040, -89.084,  2747.740,  -945.035,  110.916 },
        { "Mulholland",                 861.085,   -674.885,  -89.084,  1156.550,  -600.896,  110.916 },
        { "King's",                     -2253.540, 373.539,   -9.1,     -1993.280, 458.411,   200.000 },
        { "Redsands East",              1848.400,  2342.830,  -89.084,  2011.940,  2478.490,  110.916 },
        { "Downtown",                   -1580.010, 744.267,   -6.1,     -1499.890, 1025.980,  200.000 },
        { "Conference Center",          1046.150,  -1804.210, -89.084,  1323.900,  -1722.260, 110.916 },
        { "Richman",                    647.557,   -1118.280, -89.084,  787.461,   -954.662,  110.916 },
        { "Ocean Flats",                -2994.490, 277.411,   -9.1,     -2867.850, 458.411,   200.000 },
        { "Greenglass College",         964.391,   930.890,   -89.084,  1166.530,  1044.690,  110.916 },
        { "Glen Park",                  1812.620,  -1100.820, -89.084,  1994.330,  -973.380,  110.916 },
        { "LVA Freight Depot",          1375.600,  919.447,   -89.084,  1457.370,  1203.280,  110.916 },
        { "Regular Tom",                -405.770,  1712.860,  -3.0,     -276.719,  1892.750,  200.000 },
        { "Verona Beach",               1161.520,  -1722.260, -89.084,  1323.900,  -1577.590, 110.916 },
        { "East Los Santos",            2281.450,  -1372.040, -89.084,  2381.680,  -1135.040, 110.916 },
        { "Caligula's Palace",          2137.400,  1703.230,  -89.084,  2437.390,  1783.230,  110.916 },
        { "Idlewood",                   1951.660,  -1742.310, -89.084,  2124.660,  -1602.310, 110.916 },
        { "Pilgrim",                    2624.400,  1383.230,  -89.084,  2685.160,  1783.230,  110.916 },
        { "Idlewood",                   2124.660,  -1742.310, -89.084,  2222.560,  -1494.030, 110.916 },
        { "Queens",                     -2533.040, 458.411,   0.000,    -2329.310, 578.396,   200.000 },
        { "Downtown",                   -1871.720, 1176.420,  -4.5,     -1620.300, 1274.260,  200.000 },
        { "Commerce",                   1583.500,  -1722.260, -89.084,  1758.900,  -1577.590, 110.916 },
        { "East Los Santos",            2381.680,  -1454.350, -89.084,  2462.130,  -1135.040, 110.916 },
        { "Marina",                     647.712,   -1577.590, -89.084,  807.922,   -1416.250, 110.916 },
        { "Richman",                    72.648,    -1404.970, -89.084,  225.165,   -1235.070, 110.916 },
        { "Vinewood",                   647.712,   -1416.250, -89.084,  787.461,   -1227.280, 110.916 },
        { "East Los Santos",            2222.560,  -1628.530, -89.084,  2421.030,  -1494.030, 110.916 },
        { "Rodeo",                      558.099,   -1684.650, -89.084,  647.522,   -1384.930, 110.916 },
        { "Easter Tunnel",              -1709.710, -833.034,  -1.5,     -1446.010, -730.118,  200.000 },
        { "Rodeo",                      466.223,   -1385.070, -89.084,  647.522,   -1235.070, 110.916 },
        { "Redsands East",              1817.390,  2202.760,  -89.084,  2011.940,  2342.830,  110.916 },
        { "The Clown's Pocket",         2162.390,  1783.230,  -89.084,  2437.390,  1883.230,  110.916 },
        { "Idlewood",                   1971.660,  -1852.870, -89.084,  2222.560,  -1742.310, 110.916 },
        { "Montgomery Intersection",    1546.650,  208.164,   0.000,    1745.830,  347.457,   200.000 },
        { "Willowfield",                2089.000,  -2235.840, -89.084,  2201.820,  -1989.900, 110.916 },
        { "Temple",                     952.663,   -1130.840, -89.084,  1096.470,  -937.184,  110.916 },
        { "Prickle Pine",               1848.400,  2553.490,  -89.084,  1938.800,  2863.230,  110.916 },
        { "Los Santos International",   1400.970,  -2669.260, -39.084,  2189.820,  -2597.260, 60.916 },
        { "Garver Bridge",              -1213.910, 950.022,   -89.084,  -1087.930, 1178.930,  110.916 },
        { "Garver Bridge",              -1339.890, 828.129,   -89.084,  -1213.910, 1057.040,  110.916 },
        { "Kincaid Bridge",             -1339.890, 599.218,   -89.084,  -1213.910, 828.129,   110.916 },
        { "Kincaid Bridge",             -1213.910, 721.111,   -89.084,  -1087.930, 950.022,   110.916 },
        { "Verona Beach",               930.221,   -2006.780, -89.084,  1073.220,  -1804.210, 110.916 },
        { "Verdant Bluffs",             1073.220,  -2006.780, -89.084,  1249.620,  -1842.270, 110.916 },
        { "Vinewood",                   787.461,   -1130.840, -89.084,  952.604,   -954.662,  110.916 },
        { "Vinewood",                   787.461,   -1310.210, -89.084,  952.663,   -1130.840, 110.916 },
        { "Commerce",                   1463.900,  -1577.590, -89.084,  1667.960,  -1430.870, 110.916 },
        { "Market",                     787.461,   -1416.250, -89.084,  1072.660,  -1310.210, 110.916 },
        { "Rockshore West",             2377.390,  596.349,   -89.084,  2537.390,  788.894,   110.916 },
        { "Julius Thruway North",       2237.400,  2542.550,  -89.084,  2498.210,  2663.170,  110.916 },
        { "East Beach",                 2632.830,  -1668.130, -89.084,  2747.740,  -1393.420, 110.916 },
        { "Fallow Bridge",              434.341,   366.572,   0.000,    603.035,   555.680,   200.000 },
        { "Willowfield",                2089.000,  -1989.900, -89.084,  2324.000,  -1852.870, 110.916 },
        { "Chinatown",                  -2274.170, 578.396,   -7.6,     -2078.670, 744.170,   200.000 },
        { "El Castillo del Diablo",     -208.570,  2337.180,  0.000,    8.430,     2487.180,  200.000 },
        { "Ocean Docks",                2324.000,  -2145.100, -89.084,  2703.580,  -2059.230, 110.916 },
        { "Easter Bay Chemicals",       -1132.820, -768.027,  0.000,    -956.476,  -578.118,  200.000 },
        { "The Visage",                 1817.390,  1703.230,  -89.084,  2027.400,  1863.230,  110.916 },
        { "Ocean Flats",                -2994.490, -430.276,  -1.2,     -2831.890, -222.589,  200.000 },
        { "Richman",                    321.356,   -860.619,  -89.084,  687.802,   -768.027,  110.916 },
        { "Green Palms",                176.581,   1305.450,  -3.0,     338.658,   1520.720,  200.000 },
        { "Richman",                    321.356,   -768.027,  -89.084,  700.794,   -674.885,  110.916 },
        { "Starfish Casino",            2162.390,  1883.230,  -89.084,  2437.390,  2012.180,  110.916 },
        { "East Beach",                 2747.740,  -1668.130, -89.084,  2959.350,  -1498.620, 110.916 },
        { "Jefferson",                  2056.860,  -1372.040, -89.084,  2281.450,  -1210.740, 110.916 },
        { "Downtown Los Santos",        1463.900,  -1290.870, -89.084,  1724.760,  -1150.870, 110.916 },
        { "Downtown Los Santos",        1463.900,  -1430.870, -89.084,  1724.760,  -1290.870, 110.916 },
        { "Garver Bridge",              -1499.890, 696.442,   -179.615, -1339.890, 925.353,   20.385 },
        { "Julius Thruway South",       1457.390,  823.228,   -89.084,  2377.390,  863.229,   110.916 },
        { "East Los Santos",            2421.030,  -1628.530, -89.084,  2632.830,  -1454.350, 110.916 },
        { "Greenglass College",         964.391,   1044.690,  -89.084,  1197.390,  1203.220,  110.916 },
        { "Las Colinas",                2747.740,  -1120.040, -89.084,  2959.350,  -945.035,  110.916 },
        { "Mulholland",                 737.573,   -768.027,  -89.084,  1142.290,  -674.885,  110.916 },
        { "Ocean Docks",                2201.820,  -2730.880, -89.084,  2324.000,  -2418.330, 110.916 },
        { "East Los Santos",            2462.130,  -1454.350, -89.084,  2581.730,  -1135.040, 110.916 },
        { "Ganton",                     2222.560,  -1722.330, -89.084,  2632.830,  -1628.530, 110.916 },
        { "Avispa Country Club",        -2831.890, -430.276,  -6.1,     -2646.400, -222.589,  200.000 },
        { "Willowfield",                1970.620,  -2179.250, -89.084,  2089.000,  -1852.870, 110.916 },
        { "Esplanade North",            -1982.320, 1274.260,  -4.5,     -1524.240, 1358.900,  200.000 },
        { "The High Roller",            1817.390,  1283.230,  -89.084,  2027.390,  1469.230,  110.916 },
        { "Ocean Docks",                2201.820,  -2418.330, -89.084,  2324.000,  -2095.000, 110.916 },
        { "Last Dime Motel",            1823.080,  596.349,   -89.084,  1997.220,  823.228,   110.916 },
        { "Bayside Marina",             -2353.170, 2275.790,  0.000,    -2153.170, 2475.790,  200.000 },
        { "King's",                     -2329.310, 458.411,   -7.6,     -1993.280, 578.396,   200.000 },
        { "El Corona",                  1692.620,  -2179.250, -89.084,  1812.620,  -1842.270, 110.916 },
        { "Blackfield Chapel",          1375.600,  596.349,   -89.084,  1558.090,  823.228,   110.916 },
        { "The Pink Swan",              1817.390,  1083.230,  -89.084,  2027.390,  1283.230,  110.916 },
        { "Julius Thruway West",        1197.390,  1163.390,  -89.084,  1236.630,  2243.230,  110.916 },
        { "Los Flores",                 2581.730,  -1393.420, -89.084,  2747.740,  -1135.040, 110.916 },
        { "The Visage",                 1817.390,  1863.230,  -89.084,  2106.700,  2011.830,  110.916 },
        { "Prickle Pine",               1938.800,  2624.230,  -89.084,  2121.400,  2861.550,  110.916 },
        { "Verona Beach",               851.449,   -1804.210, -89.084,  1046.150,  -1577.590, 110.916 },
        { "Robada Intersection",        -1119.010, 1178.930,  -89.084,  -862.025,  1351.450,  110.916 },
        { "Linden Side",                2749.900,  943.235,   -89.084,  2923.390,  1198.990,  110.916 },
        { "Ocean Docks",                2703.580,  -2302.330, -89.084,  2959.350,  -2126.900, 110.916 },
        { "Willowfield",                2324.000,  -2059.230, -89.084,  2541.700,  -1852.870, 110.916 },
        { "King's",                     -2411.220, 265.243,   -9.1,     -1993.280, 373.539,   200.000 },
        { "Commerce",                   1323.900,  -1842.270, -89.084,  1701.900,  -1722.260, 110.916 },
        { "Mulholland",                 1269.130,  -768.027,  -89.084,  1414.070,  -452.425,  110.916 },
        { "Marina",                     647.712,   -1804.210, -89.084,  851.449,   -1577.590, 110.916 },
        { "Battery Point",              -2741.070, 1268.410,  -4.5,     -2533.040, 1490.470,  200.000 },
        { "The Four Dragons Casino",    1817.390,  863.232,   -89.084,  2027.390,  1083.230,  110.916 },
        { "Blackfield",                 964.391,   1203.220,  -89.084,  1197.390,  1403.220,  110.916 },
        { "Julius Thruway North",       1534.560,  2433.230,  -89.084,  1848.400,  2583.230,  110.916 },
        { "Yellow Bell Gol Course",     1117.400,  2723.230,  -89.084,  1457.460,  2863.230,  110.916 },
        { "Idlewood",                   1812.620,  -1602.310, -89.084,  2124.660,  -1449.670, 110.916 },
        { "Redsands West",              1297.470,  2142.860,  -89.084,  1777.390,  2243.230,  110.916 },
        { "Doherty",                    -2270.040, -324.114,  -1.2,     -1794.920, -222.589,  200.000 },
        { "Hilltop Farm",               967.383,   -450.390,  -3.0,     1176.780,  -217.900,  200.000 },
        { "Las Barrancas",              -926.130,  1398.730,  -3.0,     -719.234,  1634.690,  200.000 },
        { "Pirates in Men's Pants",     1817.390,  1469.230,  -89.084,  2027.400,  1703.230,  110.916 },
        { "City Hall",                  -2867.850, 277.411,   -9.1,     -2593.440, 458.411,   200.000 },
        { "Avispa Country Club",        -2646.400, -355.493,  0.000,    -2270.040, -222.589,  200.000 },
        { "The Strip",                  2027.400,  863.229,   -89.084,  2087.390,  1703.230,  110.916 },
        { "Hashbury",                   -2593.440, -222.589,  -1.0,     -2411.220, 54.722,    200.000 },
        { "Los Santos International",   1852.000,  -2394.330, -89.084,  2089.000,  -2179.250, 110.916 },
        { "Whitewood Estates",          1098.310,  1726.220,  -89.084,  1197.390,  2243.230,  110.916 },
        { "Sherman Reservoir",          -789.737,  1659.680,  -89.084,  -599.505,  1929.410,  110.916 },
        { "El Corona",                  1812.620,  -2179.250, -89.084,  1970.620,  -1852.870, 110.916 },
        { "Downtown",                   -1700.010, 744.267,   -6.1,     -1580.010, 1176.520,  200.000 },
        { "Foster Valley",              -2178.690, -1250.970, 0.000,    -1794.920, -1115.580, 200.000 },
        { "Las Payasadas",              -354.332,  2580.360,  2.0,      -133.625,  2816.820,  200.000 },
        { "Valle Ocultado",             -936.668,  2611.440,  2.0,      -715.961,  2847.900,  200.000 },
        { "Blackfield Intersection",    1166.530,  795.010,   -89.084,  1375.600,  1044.690,  110.916 },
        { "Ganton",                     2222.560,  -1852.870, -89.084,  2632.830,  -1722.330, 110.916 },
        { "Easter Bay Airport",         -1213.910, -730.118,  0.000,    -1132.820, -50.096,   200.000 },
        { "Redsands East",              1817.390,  2011.830,  -89.084,  2106.700,  2202.760,  110.916 },
        { "Esplanade East",             -1499.890, 578.396,   -79.615,  -1339.890, 1274.260,  20.385 },
        { "Caligula's Palace",          2087.390,  1543.230,  -89.084,  2437.390,  1703.230,  110.916 },
        { "Royal Casino",               2087.390,  1383.230,  -89.084,  2437.390,  1543.230,  110.916 },
        { "Richman",                    72.648,    -1235.070, -89.084,  321.356,   -1008.150, 110.916 },
        { "Starfish Casino",            2437.390,  1783.230,  -89.084,  2685.160,  2012.180,  110.916 },
        { "Mulholland",                 1281.130,  -452.425,  -89.084,  1641.130,  -290.913,  110.916 },
        { "Downtown",                   -1982.320, 744.170,   -6.1,     -1871.720, 1274.260,  200.000 },
        { "Hankypanky Point",           2576.920,  62.158,    0.000,    2759.250,  385.503,   200.000 },
        { "K.A.C.C. Military Fuels",    2498.210,  2626.550,  -89.084,  2749.900,  2861.550,  110.916 },
        { "Harry Gold Parkway",         1777.390,  863.232,   -89.084,  1817.390,  2342.830,  110.916 },
        { "Bayside Tunnel",             -2290.190, 2548.290,  -89.084,  -1950.190, 2723.290,  110.916 },
        { "Ocean Docks",                2324.000,  -2302.330, -89.084,  2703.580,  -2145.100, 110.916 },
        { "Richman",                    321.356,   -1044.070, -89.084,  647.557,   -860.619,  110.916 },
        { "Randolph Industrial Estate", 1558.090,  596.349,   -89.084,  1823.080,  823.235,   110.916 },
        { "East Beach",                 2632.830,  -1852.870, -89.084,  2959.350,  -1668.130, 110.916 },
        { "Flint Water",                -314.426,  -753.874,  -89.084,  -106.339,  -463.073,  110.916 },
        { "Blueberry",                  19.607,    -404.136,  3.8,      349.607,   -220.137,  200.000 },
        { "Linden Station",             2749.900,  1198.990,  -89.084,  2923.390,  1548.990,  110.916 },
        { "Glen Park",                  1812.620,  -1350.720, -89.084,  2056.860,  -1100.820, 110.916 },
        { "Downtown",                   -1993.280, 265.243,   -9.1,     -1794.920, 578.396,   200.000 },
        { "Redsands West",              1377.390,  2243.230,  -89.084,  1704.590,  2433.230,  110.916 },
        { "Richman",                    321.356,   -1235.070, -89.084,  647.522,   -1044.070, 110.916 },
        { "Gant Bridge",                -2741.450, 1659.680,  -6.1,     -2616.400, 2175.150,  200.000 },
        { "Lil' Probe Inn",             -90.218,   1286.850,  -3.0,     153.859,   1554.120,  200.000 },
        { "Flint Intersection",         -187.700,  -1596.760, -89.084,  17.063,    -1276.600, 110.916 },
        { "Las Colinas",                2281.450,  -1135.040, -89.084,  2632.740,  -945.035,  110.916 },
        { "Sobell Rail Yards",          2749.900,  1548.990,  -89.084,  2923.390,  1937.250,  110.916 },
        { "The Emerald Isle",           2011.940,  2202.760,  -89.084,  2237.400,  2508.230,  110.916 },
        { "El Castillo del Diablo",     -208.570,  2123.010,  -7.6,     114.033,   2337.180,  200.000 },
        { "Santa Flora",                -2741.070, 458.411,   -7.6,     -2533.040, 793.411,   200.000 },
        { "Playa del Seville",          2703.580,  -2126.900, -89.084,  2959.350,  -1852.870, 110.916 },
        { "Market",                     926.922,   -1577.590, -89.084,  1370.850,  -1416.250, 110.916 },
        { "Queens",                     -2593.440, 54.722,    0.000,    -2411.220, 458.411,   200.000 },
        { "Pilson Intersection",        1098.390,  2243.230,  -89.084,  1377.390,  2507.230,  110.916 },
        { "Spinybed",                   2121.400,  2663.170,  -89.084,  2498.210,  2861.550,  110.916 },
        { "Pilgrim",                    2437.390,  1383.230,  -89.084,  2624.400,  1783.230,  110.916 },
        { "Blackfield",                 964.391,   1403.220,  -89.084,  1197.390,  1726.220,  110.916 },
        { "'The Big Ear'",              -410.020,  1403.340,  -3.0,     -137.969,  1681.230,  200.000 },
        { "Dillimore",                  580.794,   -674.885,  -9.5,     861.085,   -404.790,  200.000 },
        { "El Quebrados",               -1645.230, 2498.520,  0.000,    -1372.140, 2777.850,  200.000 },
        { "Esplanade North",            -2533.040, 1358.900,  -4.5,     -1996.660, 1501.210,  200.000 },
        { "Easter Bay Airport",         -1499.890, -50.096,   -1.0,     -1242.980, 249.904,   200.000 },
        { "Fisher's Lagoon",            1916.990,  -233.323,  -100.000, 2131.720,  13.800,    200.000 },
        { "Mulholland",                 1414.070,  -768.027,  -89.084,  1667.610,  -452.425,  110.916 },
        { "East Beach",                 2747.740,  -1498.620, -89.084,  2959.350,  -1120.040, 110.916 },
        { "San Andreas Sound",          2450.390,  385.503,   -100.000, 2759.250,  562.349,   200.000 },
        { "Shady Creeks",               -2030.120, -2174.890, -6.1,     -1820.640, -1771.660, 200.000 },
        { "Market",                     1072.660,  -1416.250, -89.084,  1370.850,  -1130.850, 110.916 },
        { "Rockshore West",             1997.220,  596.349,   -89.084,  2377.390,  823.228,   110.916 },
        { "Prickle Pine",               1534.560,  2583.230,  -89.084,  1848.400,  2863.230,  110.916 },
        { "Easter Basin",               -1794.920, -50.096,   -1.04,    -1499.890, 249.904,   200.000 },
        { "Leafy Hollow",               -1166.970, -1856.030, 0.000,    -815.624,  -1602.070, 200.000 },
        { "LVA Freight Depot",          1457.390,  863.229,   -89.084,  1777.400,  1143.210,  110.916 },
        { "Prickle Pine",               1117.400,  2507.230,  -89.084,  1534.560,  2723.230,  110.916 },
        { "Blueberry",                  104.534,   -220.137,  2.3,      349.607,   152.236,   200.000 },
        { "El Castillo del Diablo",     -464.515,  2217.680,  0.000,    -208.570,  2580.360,  200.000 },
        { "Downtown",                   -2078.670, 578.396,   -7.6,     -1499.890, 744.267,   200.000 },
        { "Rockshore East",             2537.390,  676.549,   -89.084,  2902.350,  943.235,   110.916 },
        { "San Fierro Bay",             -2616.400, 1501.210,  -3.0,     -1996.660, 1659.680,  200.000 },
        { "Paradiso",                   -2741.070, 793.411,   -6.1,     -2533.040, 1268.410,  200.000 },
        { "The Camel's Toe",            2087.390,  1203.230,  -89.084,  2640.400,  1383.230,  110.916 },
        { "Old Venturas Strip",         2162.390,  2012.180,  -89.084,  2685.160,  2202.760,  110.916 },
        { "Juniper Hill",               -2533.040, 578.396,   -7.6,     -2274.170, 968.369,   200.000 },
        { "Juniper Hollow",             -2533.040, 968.369,   -6.1,     -2274.170, 1358.900,  200.000 },
        { "Roca Escalante",             2237.400,  2202.760,  -89.084,  2536.430,  2542.550,  110.916 },
        { "Julius Thruway East",        2685.160,  1055.960,  -89.084,  2749.900,  2626.550,  110.916 },
        { "Verona Beach",               647.712,   -2173.290, -89.084,  930.221,   -1804.210, 110.916 },
        { "Foster Valley",              -2178.690, -599.884,  -1.2,     -1794.920, -324.114,  200.000 },
        { "Arco del Oeste",             -901.129,  2221.860,  0.000,    -592.090,  2571.970,  200.000 },
        { "Fallen Tree",                -792.254,  -698.555,  -5.3,     -452.404,  -380.043,  200.000 },
        { "The Farm",                   -1209.670, -1317.100, 114.981,  -908.161,  -787.391,  251.981 },
        { "The Sherman Dam",            -968.772,  1929.410,  -3.0,     -481.126,  2155.260,  200.000 },
        { "Esplanade North",            -1996.660, 1358.900,  -4.5,     -1524.240, 1592.510,  200.000 },
        { "Financial",                  -1871.720, 744.170,   -6.1,     -1701.300, 1176.420,  300.000 },
        { "Garcia",                     -2411.220, -222.589,  -1.14,    -2173.040, 265.243,   200.000 },
        { "Montgomery",                 1119.510,  119.526,   -3.0,     1451.400,  493.323,   200.000 },
        { "Creek",                      2749.900,  1937.250,  -89.084,  2921.620,  2669.790,  110.916 },
        { "Los Santos International",   1249.620,  -2394.330, -89.084,  1852.000,  -2179.250, 110.916 },
        { "Santa Maria Beach",          72.648,    -2173.290, -89.084,  342.648,   -1684.650, 110.916 },
        { "Mulholland Intersection",    1463.900,  -1150.870, -89.084,  1812.620,  -768.027,  110.916 },
        { "Angel Pine",                 -2324.940, -2584.290, -6.1,     -1964.220, -2212.110, 200.000 },
        { "Verdant Meadows",            37.032,    2337.180,  -3.0,     435.988,   2677.900,  200.000 },
        { "Octane Springs",             338.658,   1228.510,  0.000,    664.308,   1655.050,  200.000 },
        { "Come-A-Lot",                 2087.390,  943.235,   -89.084,  2623.180,  1203.230,  110.916 },
        { "Redsands West",              1236.630,  1883.110,  -89.084,  1777.390,  2142.860,  110.916 },
        { "Santa Maria Beach",          342.648,   -2173.290, -89.084,  647.712,   -1684.650, 110.916 },
        { "Verdant Bluffs",             1249.620,  -2179.250, -89.084,  1692.620,  -1842.270, 110.916 },
        { "Las Venturas Airport",       1236.630,  1203.280,  -89.084,  1457.370,  1883.110,  110.916 },
        { "Flint Range",                -594.191,  -1648.550, 0.000,    -187.700,  -1276.600, 200.000 },
        { "Verdant Bluffs",             930.221,   -2488.420, -89.084,  1249.620,  -2006.780, 110.916 },
        { "Palomino Creek",             2160.220,  -149.004,  0.000,    2576.920,  228.322,   200.000 },
        { "Ocean Docks",                2373.770,  -2697.090, -89.084,  2809.220,  -2330.460, 110.916 },
        { "Easter Bay Airport",         -1213.910, -50.096,   -4.5,     -947.980,  578.396,   200.000 },
        { "Whitewood Estates",          883.308,   1726.220,  -89.084,  1098.310,  2507.230,  110.916 },
        { "Calton Heights",             -2274.170, 744.170,   -6.1,     -1982.320, 1358.900,  200.000 },
        { "Easter Basin",               -1794.920, 249.904,   -9.1,     -1242.980, 578.396,   200.000 },
        { "Los Santos Inlet",           -321.744,  -2224.430, -89.084,  44.615,    -1724.430, 110.916 },
        { "Doherty",                    -2173.040, -222.589,  -1.0,     -1794.920, 265.243,   200.000 },
        { "Mount Chiliad",              -2178.690, -2189.910, -47.917,  -2030.120, -1771.660, 576.083 },
        { "Fort Carson",                -376.233,  826.326,   -3.0,     123.717,   1220.440,  200.000 },
        { "Foster Valley",              -2178.690, -1115.580, 0.000,    -1794.920, -599.884,  200.000 },
        { "Ocean Flats",                -2994.490, -222.589,  -1.0,     -2593.440, 277.411,   200.000 },
        { "Fern Ridge",                 508.189,   -139.259,  0.000,    1306.660,  119.526,   200.000 },
        { "Bayside",                    -2741.070, 2175.150,  0.000,    -2353.170, 2722.790,  200.000 },
        { "Las Venturas Airport",       1457.370,  1203.280,  -89.084,  1777.390,  1883.110,  110.916 },
        { "Blueberry Acres",            -319.676,  -220.137,  0.000,    104.534,   293.324,   200.000 },
        { "Palisades",                  -2994.490, 458.411,   -6.1,     -2741.070, 1339.610,  200.000 },
        { "North Rock",                 2285.370,  -768.027,  0.000,    2770.590,  -269.740,  200.000 },
        { "Hunter Quarry",              337.244,   710.840,   -115.239, 860.554,   1031.710,  203.761 },
        { "Los Santos International",   1382.730,  -2730.880, -89.084,  2201.820,  -2394.330, 110.916 },
        { "Missionary Hill",            -2994.490, -811.276,  0.000,    -2178.690, -430.276,  200.000 },
        { "San Fierro Bay",             -2616.400, 1659.680,  -3.0,     -1996.660, 2175.150,  200.000 },
        { "Restricted Area",            -91.586,   1655.050,  -50.000,  421.234,   2123.010,  250.000 },
        { "Mount Chiliad",              -2997.470, -1115.580, -47.917,  -2178.690, -971.913,  576.083 },
        { "Mount Chiliad",              -2178.690, -1771.660, -47.917,  -1936.120, -1250.970, 576.083 },
        { "Easter Bay Airport",         -1794.920, -730.118,  -3.0,     -1213.910, -50.096,   200.000 },
        { "The Panopticon",             -947.980,  -304.320,  -1.1,     -319.676,  327.071,   200.000 },
        { "Shady Creeks",               -1820.640, -2643.680, -8.0,     -1226.780, -1771.660, 200.000 },
        { "Back o Beyond",              -1166.970, -2641.190, 0.000,    -321.744,  -1856.030, 200.000 },
        { "Mount Chiliad",              -2994.490, -2189.910, -47.917,  -2178.690, -1115.580, 576.083 },
        { "Tierra Robada",              -1213.910, 596.349,   -242.990, -480.539,  1659.680,  900.000 },
        { "Flint County",               -1213.910, -2892.970, -242.990, 44.615,    -768.027,  900.000 },
        { "Whetstone",                  -2997.470, -2892.970, -242.990, -1213.910, -1115.580, 900.000 },
        { "Bone County",                -480.539,  596.349,   -242.990, 869.461,   2993.870,  900.000 },
        { "Tierra Robada",              -2997.470, 1659.680,  -242.990, -480.539,  2993.870,  900.000 },
        { "San Fierro",                 -2997.470, -1115.580, -242.990, -1213.910, 1659.680,  900.000 },
        { "Las Venturas",               869.461,   596.349,   -242.990, 2997.060,  2993.870,  900.000 },
        { "Red County",                 -1213.910, -768.027,  -242.990, 2997.060,  596.349,   900.000 },
        { "Los Santos",                 44.615,    -2892.970, -242.990, 2997.060,  -768.027,  900.000 }
    }
    for i, v in ipairs(streets) do
        if (x >= v[2]) and (y >= v[3]) and (z >= v[4]) and (x <= v[5]) and (y <= v[6]) and (z <= v[7]) then
            return v[1]
        end
    end
    return 'неизвестен'
end
