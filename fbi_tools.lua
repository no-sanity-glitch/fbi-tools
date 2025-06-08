script_name('FBI Tools')
script_author('goatffs')
script_version('1.0.4')

local enable_autoupdate = true -- false to disable auto-update + disable sending initial telemetry (server, moonloader version, script version, samp nickname, virtual volume serial number)
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
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/no-sanity-glitch/fbi-tools/"
        end
    end
end

require "lib.moonloader"
local imgui = require "imgui"
local encoding = require "encoding"
local inicfg = require 'inicfg'
local ImVec2 = imgui.ImVec2
local ImVec4 = imgui.ImVec4
local imadd = require 'imgui_addons'
local sampev = require 'lib.samp.events'
local vkeys = require "vkeys"
local rkeys = require 'rkeys'
local sampev = require("lib.samp.events")
imgui.HotKey = require('imgui_addons').HotKey

--------------------------------

local locks = {}

function synchronized(name, fn)
    if locks[name] then return end -- already running
    locks[name] = true

    lua_thread.create(function()
        pcall(fn)
        locks[name] = false
    end)
end

--------------------------------

----------- FA ICONS -----------
local fa = require 'faIcons'
local fa_glyph_ranges = imgui.ImGlyphRanges({ fa.min_range, fa.max_range })

function imgui.BeforeDrawFrame()
    if fa_font == nil then
        local font_config = imgui.ImFontConfig()
        font_config.MergeMode = true
        fa_font = imgui.GetIO().Fonts:AddFontFromFileTTF('moonloader/resource/fonts/fontawesome-webfont.ttf', 14.0,
            font_config, fa_glyph_ranges)
    end
end

--------------------------------

local mainIni = inicfg.load({
    config = {
        intImGui = 0,
        backup_text = "Требуется подкрепление. Район %s.",
        auto_find_level_selected = 10,
    },
    admin = {
        nameTitle = false,
    },
    hotkeys = {
        callback_1 = encodeJson({ vkeys.VK_F2 }),
        battlepass = encodeJson({ vkeys.VK_F3 }),
        backup = encodeJson({ vkeys.VK_U }),
        su = encodeJson({ vkeys.VK_I }),
    },
    state = {
        auto_alert = false,
        auto_find = false,
        auto_fix = false,
        stroboscopes = false,
    }
}, 'Tools')

encoding.default = "CP1251"
u8 = encoding.UTF8

----- GLOBAL PARAMENTS -----
local main_window = imgui.ImBool(false)
local CheckBoxDialogID = imgui.ImBool(false)
local straboscopes = imgui.ImBool(mainIni.state.stroboscopes)
local auto_alert_state = imgui.ImBool(mainIni.state.auto_alert)
local auto_alert_backup_text_buffer = imgui.ImBuffer(256)
local auto_find_state = imgui.ImBool(mainIni.state.auto_find)
local auto_fix_state = imgui.ImBool(mainIni.state.auto_fix)

----- LOCAL PARAMENTS -----
local main_color = mainIni.config.intImGui
local statusSsMode = false

local elements = {
    checkbox = {

    },
    static = {
        nameStatis = imgui.ImBool(mainIni.admin.nameTitle)
    },
    int = {
        intImGui = imgui.ImInt(mainIni.config.intImGui)
    },
}

local auto_alert = {
    lastGlobalBackupTime = 0,
    attackerCooldowns = {}, -- [playerId] = lastAlertTime
    suCooldowns = {},       -- [playerId] = lastSuTime
    ALERT_INTERVAL = 30,    -- seconds
    BACKUP_INTERVAL = 10,   -- seconds
    SU_INTERVAL = 900,      -- 15 minutes
    pendingAttacker = nil,
    pendingExpireTime = 0,
}

local auto_find = {
    state = false,
    targetId = nil,
    zoneDestroyed = false,
    checkpointDisabled = false
}

local auto_find_delay_by_level = {
    [1] = 80,
    [2] = 70,
    [3] = 60,
    [4] = 50,
    [5] = 40,
    [6] = 30,
    [7] = 20,
    [8] = 10,
    [9] = 5,
    [10] = 0
}

local quit_reasons = {
    [0] = 'потеря связи/краш',
    [1] = 'вышел из игры',
    [2] = 'кикнул сервер/забанили'
}

local auto_fix = {
    fillTexts = {},
    tehvehTexts = {},
    isFilling = false,
}

local vehHealth = {
    [5000] = true,
    [4000] = true,
    [3000] = true,
    [2000] = true
}

local lastCheckTime = 0

function save()
    inicfg.save(mainIni, 'Tools.ini')
end

local HotKeys = {
    callback_1 = {
        v = decodeJson(mainIni.hotkeys.callback_1)
    },
    battlepass = {
        v = decodeJson(mainIni.hotkeys.battlepass)
    },
    backup = {
        v = decodeJson(mainIni.hotkeys.backup)
    },
    su = {
        v = decodeJson(mainIni.hotkeys.su)
    },
}

-----------------Stroboscopes-------------------
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

--------------------------------------------------------------

function main()
    while not isSampAvailable() do wait(100) end

    if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

    sampAddChatMessage("{AC0046}[Tools] {FFFFFF}Активирован.", -1)
    sampAddChatMessage("{AC0046}[Tools] {FFFFFF}Открыть меню - {AC0046}/tt", -1)
    sampRegisterChatCommand('tt', function()
        main_window.v = not main_window.v
        menu = 0
    end)

    sampRegisterChatCommand("sw", cmdSetWeather)

    -- Команда для включения/выключения основного скрипта
    sampRegisterChatCommand('ss', function()
        statusSsMode = not statusSsMode
        printStringNow(statusSsMode and 'RPChat ~g~ON' or 'RPChat ~r~OFF', 1000)
    end)
    -- Команда для очистки чата
    sampRegisterChatCommand('cc', function()
        for i = 1, 99 do
            sampAddChatMessage('', -1)
        end
    end)

    sampRegisterChatCommand("find", cmdFind)
    sampRegisterChatCommand("findoff", cmdFindOff)

    ID_CALLBACK_1 = rkeys.registerHotKey(HotKeys.callback_1.v, 1, callback_1)
    ID_BATTLEPASS = rkeys.registerHotKey(HotKeys.battlepass.v, 1, battlepass)
    ID_BACKUP = rkeys.registerHotKey(HotKeys.backup.v, 1, backup)
    ID_SU = rkeys.registerHotKey(HotKeys.su.v, 1, su)


    sampRegisterChatCommand("strobes", function()
        if straboscopes.v then
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

    lua_thread.create(function()
        while true do
            imgui.Process = main_window.v

            -- if wasKeyPressed(113) then main_window.v = not main_window.v end
            -- imgui.Process = main_window.v

            if straboscopes.v then
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

            if auto_fix_state.v then
                if isCharInAnyCar(PLAYER_PED) and getDriverOfCar(storeCarCharIsInNoSave(PLAYER_PED)) == PLAYER_PED then
                    if not lastCheckTime or os.clock() - lastCheckTime > 0.3 then
                        lastCheckTime = os.clock()

                        local px, py, pz = getCharCoordinates(PLAYER_PED)

                        if isFillRequired() then
                            for id, _ in pairs(auto_fix.fillTexts) do
                                local result, _, x, y, z, _, _, _, _ = sampGet3dTextInfoById(id)
                                if result and getDistanceBetweenCoords3d(px, py, pz, x, y, z) < 9.0 then
                                    sampSendChat("/fill")
                                    auto_fix.isFilling = true
                                else
                                    auto_fix.isFilling = false
                                end
                            end
                        end

                        if not vehHealth[getCarHealth(storeCarCharIsInNoSave(PLAYER_PED))] then
                            for id, _ in pairs(auto_fix.tehvehTexts) do
                                local result, _, x, y, z, _, _, _, _ = sampGet3dTextInfoById(id)
                                if result and getDistanceBetweenCoords3d(px, py, pz, x, y, z) < 5.0 then
                                    if not isCarEngineOn(storeCarCharIsInNoSave(PLAYER_PED)) then
                                        sampSendChat("/tehveh")
                                    end
                                end
                            end
                        end
                    end
                end
            end

            wait(0)
        end
    end)
end

------------- SHOW DIALOG ID -------------------
function sampev.onShowDialog(id, style, title, button1, button2, text)
    if CheckBoxDialogID.v then
        sampAddChatMessage(id, main_color)
    end
end

--------------------------------------------------

----------------TEXT COLOR RGB ----------------
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

------------------------------------------------

----------------- CENTER TEXT ------------------
function imgui.CenterText(text)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(width / 2 - calc.x / 2)
    imgui.Text(text)
end

------------------------------------------------
-------------- GET MY NICK ---------------------
function getMyNick()
    local result, id = sampGetPlayerIdByCharHandle(playerPed)
    if result then
        local nick = sampGetPlayerNickname(id)
        return nick
    end
end

-----------------------------------------------
---------- OPEN/CLOSE MAIN MENU ---------------
function callback_1()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    main_window.v = not main_window.v
    menu = 0
end

------------------------------------------------
------------------BattlePass--------------------
function battlepass()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    sampSendChat("/battlepass")
end

------------------------------------------------

----------------------SetWeather----------------------
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

------------------------------------------------
------------------HelpMarker--------------------
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

------------------------------------------------

---------------------SS/CC----------------------

function sampev.onServerMessage(color, text)
    if not text or not statusSsMode then return true end
    if text:find('%[AD%]')
        or text:find(' SMS ')        -- Фильтрация СМС
        or text:find('%[ADM%]')      -- Фильтрация Админских сообщений
        or text:find('%[PP%]')       -- Фильтрация наказаний
        or text:find("^%*%*.+%*%*$") -- Фильтрация рации департамента/иные новости
        or text:find("^%*%* .-:")    -- Фильтрация рации
        or text:find('%(%(.-%)%)')   -- Фильтрация ООС сообщений
        or text:find('____')         -- Фильтрация PayDay
        or text:find('{0088ff}')

    then
        logFilteredMessage(color, text)
        return false
    else
        return true
    end
end

function logFilteredMessage(color, text)
    local hexColor = string.format('%06X', bit.band(color, 0xFFFFFF))
    local logText = string.format('{%s}[%s] %s', hexColor, os.date('%X'), text)
    sampfuncsLog(logText)
end

------------------------------------------------

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
]]

local authors = [[

    Спасибо за помощь:
    — Dave Grand (красивая imgui менюшка, стробоскопы, смена погоды);
    — Amelia Brown (режим IC-only чата и его очистка).
]]

function menu_0()
    imgui.CenterText('' .. thisScript().name .. u8 ' | v' .. thisScript().version .. ' | Developers - Saburo Arasaka')
    imgui.CenterText(u8 'Разработан специально для Pears Project')
    imgui.Text(u8(authors))

    imgui.Separator()
    if imgui.CollapsingHeader('Version 1.0') then
        imgui.Text(u8(changelog10))
    end
    imgui.Separator()
    imgui.CenterText(u8 'Контакты:')
    imgui.CenterText(u8 'Saburo Arasaka ' .. fa.ICON_TELEGRAM .. ' - @goatffs')
    -- imgui.CenterText(u8 '' .. fa.ICON_VK .. ' - vladbagmut')
    imgui.CenterText(u8 'Dave Grand ' .. fa.ICON_TELEGRAM .. ' - @daveamp')
    imgui.CenterText(u8 'Amelia Brown ' .. fa.ICON_TELEGRAM .. ' - @wnenad')
end

-------------------Auto Alert---------------------

function sampev.onSendTakeDamage(playerId, _, _, _, _)
    if not playerId or playerId > 1000 or not mainIni.state.auto_alert then return end
    local now = os.time()
    if not auto_alert.attackerCooldowns[playerId] or now - auto_alert.attackerCooldowns[playerId] >= auto_alert.ALERT_INTERVAL then
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
        auto_alert.pendingAttacker = playerId
        auto_alert.pendingExpireTime = now + auto_alert.ALERT_INTERVAL
        auto_alert.attackerCooldowns[playerId] = now
    end
end

function backup()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    if mainIni.state.auto_alert then
        if os.time() - auto_alert.lastGlobalBackupTime >= auto_alert.BACKUP_INTERVAL then
            callForBackup()
            auto_alert.lastGlobalBackupTime = os.time()
        end
    end
end

function callForBackup()
    local zone = getZoneName()
    local backup_message = u8:decode(mainIni.config.backup_text)
    local message = ("/r " .. backup_message):format(zone)
    sampSendChat(message)
end

function su()
    if sampIsChatInputActive() or sampIsDialogActive() then return end
    if mainIni.state.auto_alert then
        if auto_alert.pendingAttacker and os.time() <= auto_alert.pendingExpireTime then
            if not auto_alert.suCooldowns[auto_alert.pendingAttacker] or os.time() - auto_alert.suCooldowns[auto_alert.pendingAttacker] >= auto_alert.SU_INTERVAL then
                issueWanted(auto_alert.pendingAttacker)
                auto_alert.suCooldowns[auto_alert.pendingAttacker] = os.time()
                pendingAttacker = nil
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
    local x, y, z = getCharCoordinates(PLAYER_PED)
    return calculateZone(x, y, z)
end

--------------------------------------------------

-------------------Auto Find----------------------

function cmdFind(arg)
    local id = tonumber(arg)
    if not id then
        sampAddChatMessage("[Tools] {ff0000}Неверный{ffffff} ID игрока.", main_color)
        return
    end

    auto_find.state = true
    auto_find.targetId = id
    auto_find.zoneDestroyed = false
    auto_find.checkpointDisabled = false

    if auto_find_state.v and auto_find.state then
        printStringNow("~b~~h~~h~~h~Find: ~b~~h~~h~ enabled", 1600)
    end

    sampSendChat("/find " .. id)
end

function cmdFindOff()
    if not auto_find_state.v or not auto_find.state then return end

    auto_find.state = false
    auto_find.targetId = nil
    auto_find.zoneDestroyed = false
    auto_find.checkpointDisabled = false

    printStringNow("~b~~h~~h~~h~Find: ~b~~h~~h~ disabled", 1600)
end

function closeDialogAsync()
    lua_thread.create(function()
        wait(1)
        sampCloseCurrentDialogWithButton(0)
    end)
end

function trySendFind()
    if auto_find_state.v and auto_find.state and auto_find.zoneDestroyed and auto_find.checkpointDisabled and auto_find.targetId then
        synchronized("trySendFind", function()
            local delay = auto_find_delay_by_level[mainIni.config.auto_find_level_selected] or 0
            if delay > 0 then wait(delay * 1000) end

            sampSendChat("/find " .. auto_find.targetId)
            auto_find.zoneDestroyed = false
            auto_find.checkpointDisabled = false
        end)
    end
end

function sendFind()
    sampSendChat("/find " .. auto_find.targetId)
    auto_find.zoneDestroyed = false
    auto_find.checkpointDisabled = false
end

function sampev.onGangZoneDestroy(zoneId)
    if auto_find_state.v and auto_find.state and zoneId == 0 then
        auto_find.zoneDestroyed = true
        trySendFind()
    end
end

function sampev.onDisableCheckpoint()
    if auto_find_state.v and auto_find.state then
        auto_find.checkpointDisabled = true
        trySendFind()
    end
end

function sampev.onShowDialog(dialogId, style, title, button1, button2, text)
    if not auto_find_state.v or not auto_find.state or not text then return end

    if text:find("Этот игрок не в сети, или ещё не залогинился") then
        sampAddChatMessage("[Tools] {ffffff}Игрок {ff0000}оффлайн{ffffff}.", main_color)
        cmdFindOff()
        closeDialogAsync()
    elseif text:find("У вас активна зона поиска, дождитесь её окончания") then
        closeDialogAsync()
    end
end

function sampev.onPlayerQuit(playerId, reason)
    if auto_find_state.v and auto_find.state and playerId == auto_find.targetId then
        local nickname = sampGetPlayerNickname(playerId) or "Unknown"
        sampAddChatMessage(
            string.format(
                '[Tools] {ffffff}Игрок {FF9C00}%s[%d] {FFFFFF}вышел с сервера. {FF9C00}Причина: {FFFFFF}%s.',
                nickname, playerId, quit_reasons[reason] or 'неизвестно'
            ),
            main_color
        )
        cmdFindOff()
    end
end

--------------------------------------------------

--------------------Auto Fix----------------------

function isFillRequired()
    if not auto_fix_state.v then return end
    if not sampTextdrawIsExists(2133) then return end
    local fuel = tonumber(sampTextdrawGetString(2133):match("(%d+)[,.]?%d*"))
    return fuel < 95
end

function sampev.onCreate3DText(id, _, _, _, _, _, _, text)
    local lowerText = text:lower()
    if lowerText:find("/fill ") then
        auto_fix.fillTexts[id] = true
    elseif lowerText:find("/tehveh") then
        auto_fix.tehvehTexts[id] = true
    end
end

function sampev.onRemove3DTextLabel(id)
    auto_fix.fillTexts[id] = nil
    auto_fix.tehvehTexts[id] = nil
end

--------------------------------------------------

---- Приветстиве -------

function imgui.OnDrawFrame()
    if elements.int.intImGui.v == 0 then
        gray()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0x262e38
        save()
    elseif elements.int.intImGui.v == 1 then
        blackred()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0xFF0000
        save()
    elseif elements.int.intImGui.v == 2 then
        purple()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0x6830a1
        save()
    elseif elements.int.intImGui.v == 3 then
        blue()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0x3d3d3d
        save()
    elseif elements.int.intImGui.v == 4 then
        blackwhite()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0x072b8c
        save()
    elseif elements.int.intImGui.v == 5 then
        orange()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0xFFA500
        save()
    elseif elements.int.intImGui.v == 6 then
        pink()
        mainIni.config.intImGui = elements.int.intImGui.v
        main_color = 0xAC0046
        save()
    end
    result, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)

    if main_window.v then
        imgui.SetNextWindowPos(imgui.ImVec2(imgui.GetIO().DisplaySize.x / 2, imgui.GetIO().DisplaySize.y / 2),
            imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.SetNextWindowSize(imgui.ImVec2(745, 450), imgui.Cond.FirstUseEver)
        imgui.Begin('' .. thisScript().name .. ' | v.' .. thisScript().version .. '', main_window,
            imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

        imgui.BeginChild("##left", imgui.ImVec2(180, 400), true)
        if imgui.Button(u8 'Основное', imgui.ImVec2(155, 30)) then menu = 1 end
        if imgui.Button(u8 'Auto Alert', imgui.ImVec2(155, 30)) then menu = 2 end
        if imgui.Button(u8 'Auto Find', imgui.ImVec2(155, 30)) then menu = 3 end
        if imgui.Button(u8 'Auto Fix (experimental)', imgui.ImVec2(155, 30)) then menu = 4 end
        if imgui.Button(u8 'Спец.Клавиши', imgui.ImVec2(155, 30)) then menu = 9 end
        if imgui.Button(u8 'Настройки', imgui.ImVec2(155, 30)) then menu = 10 end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("##right", imgui.ImVec2(520, 400), true)
        if menu == 0 then
            menu_0()
        end
        if menu == 1 then
            imgui.CenterText(u8 'Добро пожаловать, ' .. getMyNick())
            imgui.Separator()
            if imadd.ToggleButton("##straboscopes", straboscopes) then
                if straboscopes.v then
                    sampAddChatMessage("[Tools] {FFFFFF}Стробоскопы {01DF01}включены{ffffff}.", main_color)
                    mainIni.state.stroboscopes = true
                    inicfg.save(mainIni, 'Tools.ini')
                else
                    sampAddChatMessage("[Tools] {FFFFFF}Стробоскопы {ff0000}отключены{ffffff}.", main_color)
                    mainIni.state.stroboscopes = false
                    inicfg.save(mainIni, 'Tools.ini')
                end
            end
            imgui.SameLine()
            imgui.Text(u8 "Стробоскопы")
            imgui.SameLine()
            imgui.HelpMarker(u8 "Активация сирены /strobes | Активация стробоскопов P")

            if imgui.Button(u8 'Перезагрузить скрипт', ImVec2(490, 0)) then
                sampAddChatMessage('[Tools] {FFFFFF}Перезагрузка...', main_color)
                showCursor(false)
                thisScript():reload()
            end
            if imgui.Button(u8 'Выключить скрипт', ImVec2(490, 0)) then
                sampAddChatMessage('[Tools] {FFFFFF}Выключаем скрипт...', main_color)
                showCursor(false)
                thisScript():unload()
            end
        end
        if menu == 2 then
            if imadd.ToggleButton("##auto_alert_state", auto_alert_state) then
                if auto_alert_state.v then
                    sampAddChatMessage("[Tools] {FFFFFF}Запрос о поддержке {01DF01}включён{ffffff}.", main_color)
                    mainIni.state.auto_alert = true
                    inicfg.save(mainIni, 'Tools.ini')
                else
                    sampAddChatMessage("[Tools] {FFFFFF}Запрос о поддержке {ff0000}отключён{ffffff}.", main_color)
                    mainIni.state.auto_alert = false
                    inicfg.save(mainIni, 'Tools.ini')
                end
            end
            imgui.SameLine()
            imgui.Text(u8 "Запрос о поддержке")
            -- backup button
            if imgui.HotKey("##HotKeys.backup", HotKeys.backup) then
                rkeys.changeHotKey(ID_BACKUP, HotKeys.backup.v)
                mainIni.hotkeys.backup = encodeJson(HotKeys.backup.v)
                inicfg.save(mainIni, 'Tools.ini')
                sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", main_color)
            end
            imgui.SameLine()
            imgui.Text(u8 'Изменить кнопку запроса поддержки')
            -- su button
            if imgui.HotKey("##HotKeys.su", HotKeys.su) then
                rkeys.changeHotKey(ID_SU, HotKeys.su.v)
                mainIni.hotkeys.su = encodeJson(HotKeys.su.v)
                inicfg.save(mainIni, 'Tools.ini')
                sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", main_color)
            end
            imgui.SameLine()
            imgui.Text(u8 'Изменить кнопку выдачи розыска')
            -- backup text
            imgui.Text(u8 'Изменить текст вызова поддержки')
            imgui.SameLine()
            imgui.HelpMarker(u8 "Используйте #zone для указания района. Например: Требуется подкрепление. Район #zone.")

            auto_alert_backup_text_buffer.v = mainIni.config.backup_text:gsub("%%s", "#zone")
            if imgui.InputText(u8 '', auto_alert_backup_text_buffer) then -- условие будет срабатывать при изменении текста
                local backup_text = auto_alert_backup_text_buffer.v:gsub("#zone", "%%s")
                mainIni.config.backup_text = backup_text
                inicfg.save(mainIni, 'Tools.ini')
            end
        end
        if menu == 3 then
            if imadd.ToggleButton("##auto_find_state", auto_find_state) then
                if auto_find_state.v then
                    sampAddChatMessage("[Tools] {FFFFFF}Автопоиск {01DF01}включён{ffffff}.", main_color)
                    mainIni.state.auto_find = true
                    inicfg.save(mainIni, 'Tools.ini')
                else
                    sampAddChatMessage("[Tools] {FFFFFF}Автопоиск {ff0000}отключён{ffffff}.", main_color)
                    mainIni.state.auto_find = false
                    inicfg.save(mainIni, 'Tools.ini')
                end
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
            --         inicfg.save(mainIni, 'Tools.ini')
            --     end
            --     imgui.SameLine()
            -- end
        end
        if menu == 4 then
            if imadd.ToggleButton("##auto_fix_state", auto_fix_state) then
                if auto_fix_state.v then
                    sampAddChatMessage("[Tools] {FFFFFF}Автопочинка {01DF01}включена{ffffff}.", main_color)
                    mainIni.state.auto_fix = true
                    inicfg.save(mainIni, 'Tools.ini')
                else
                    sampAddChatMessage("[Tools] {FFFFFF}Автопочинка {ff0000}отключена{ffffff}.", main_color)
                    mainIni.state.auto_fix = false
                    inicfg.save(mainIni, 'Tools.ini')
                end
            end
            imgui.SameLine()
            imgui.Text(u8 "Автопочинка и автозаправка")
            imgui.SameLine()
            imgui.HelpMarker(u8 "Автопочинка и автозаправка в гос.гаражах. Для починки нужно заглушить двигатель.")
        end
        if menu == 9 then
            -- callback 1
            if imgui.HotKey("##HotKeys.callback_1", HotKeys.callback_1) then
                rkeys.changeHotKey(ID_CALLBACK_1, HotKeys.callback_1.v)
                mainIni.hotkeys.callback_1 = encodeJson(HotKeys.callback_1.v)
                inicfg.save(mainIni, 'Tools.ini')
                sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", main_color)
            end
            imgui.SameLine()
            imgui.Text(u8 'Изменить кнопку активацию меню')
            -- battlepass
            if imgui.HotKey("##HotKeys.battlepass", HotKeys.battlepass) then
                rkeys.changeHotKey(ID_BATTLEPASS, HotKeys.battlepass.v)
                mainIni.hotkeys.battlepass = encodeJson(HotKeys.battlepass.v)
                inicfg.save(mainIni, 'Tools.ini')
                sampAddChatMessage("[Подсказка] {FFFFFF}Новая клавиша назначена.", main_color)
            end
            imgui.SameLine()
            imgui.Text(u8 'Изменить кнопку активацию battlepass')
        end
        if menu == 10 then
            local styles = { u8 "Серая", u8 "Красная", u8 "Фиолетовая", u8 "Чёрная", u8 "Синяя", u8 "Оранжевая", u8 "Розовая" }
            imgui.Combo(u8 'Стиль интерфейса', elements.int.intImGui, styles)
            -- imgui.Separator()
            -- if imadd.ToggleButton("##idDialog", CheckBoxDialogID) then
            --     if CheckBoxDialogID.v then
            --         sampAddChatMessage("[Подсказка] {FFFFFF}Dialog ID {01DF01}включён{ffffff}.", main_color)
            --     else
            --         sampAddChatMessage("[Подсказка] {FFFFFF}Dialog ID {ff0000}отключён{ffffff}.", main_color)
            --     end
            -- end
            -- imgui.SameLine()
            -- imgui.TextColoredRGB('[Выкл/Вкл]  {FF0000}Dialog ID')
            -- imgui.SameLine()
        end
        imgui.EndChild()
    end
    imgui.End()
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
