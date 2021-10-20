require "lib.moonloader"
require "lib.sampfuncs"
local dlstatus = require("moonloader").download_status
local inicfg = require 'inicfg'
local sampev = require 'samp.events'
local key = require 'vkeys'
local mem = require "memory"
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

update_state = false

local car_info = false
local get_car = false

local script_vers = 15
local script_vers_text = '1.5'

local admin_cmd, command_from_admin_chat_status, notf_chat, active_forma, stop_forma = true, false, true, false, false

local update_url = "https://raw.githubusercontent.com/nixonoff/AutoPunish/main/update.ini"
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = "https://github.com/nixonoff/AutoPunish/blob/main/autopun.luac?raw=true"
local script_path = thisScript().path

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    sampRegisterChatCommand("cdl", function() 
        car_info = not car_info 
    end)
    sampRegisterChatCommand("sinfo", function()
		sampShowDialog(2435445, "{edce00}Лог обновлений", "{ed8e00}v.1.5 {c9c9c7}- Обновлен список поддерживаемых команд;\n         - Добавлена функция, заменяющая стандартный dl(/cdl - вкл/выкл);\n         - Добавлен GodMode. Активация - Insert;\n         - Добавлен WallHack по никам. Активация - Delete.\n{ed8e00}v.1.4 {c9c9c7}- Добавлен лог обновлений(/sinfo).\n{ed8e00}v.1.3 {c9c9c7}- Исправление ошибок.\n{ed8e00}v.1.2 {c9c9c7}- Добавлено автообновление.\n{ed8e00}v.1.1 {c9c9c7}- Исправление ошибок.\n{ed8e00}v.1.0 {c9c9c7}- Запуск скрипта.", "Закрыть", "", 0)
	end)
    sampRegisterChatCommand("getcar", getcar)

    message("Written by {FFA500}Anton Nixon{ffffff}. Проверить лог обновлений - {FFA500}/sinfo{ffffff}.")

    downloadUrlToFile(update_url, update_path, function (id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateini = inicfg.load(nil, update_path)
            if tonumber(updateini.info.vers) > script_vers then
                message("Найдено обновление. Версия:{FFA500} "..updateini.info.vers_text)
                update_state = true
            end
            os.remove(update_path)
        end
    end)

    while true do
        wait(0)

        if update_state then
            downloadUrlToFile(script_url, script_path, function (id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    message("Обновление успешно установлено.")
                    update_state = false
                    thisScript():reload()
                end
            end)
            break
        end 

        if car_info then -- информация о т/с
			local x, y, z = getCharCoordinates(PLAYER_PED)
			local result, handle_car = findAllRandomVehiclesInSphere(x, y, z, 50, true, true)
			if result then
				local res, id_car = sampGetVehicleIdByCarHandle(handle_car)
				local veh_exist = doesVehicleExist(handle_car)
				if veh_exist then
					local car_info_speed = getCarSpeed(handle_car)
					local car_info_model = getCarModel(handle_car)
					local car_info_name = getNameOfVehicleModel(car_info_model)
					local car_info_health = getCarHealth(handle_car)
					local text_info_car = "Модель: %s[%i]\nСкорость: %.1f км/ч\nHP: %i | ID: %i"
					text_on_car = string.format(text_info_car, car_info_name, car_info_model, car_info_speed, car_info_health, id_car)
					id_3d = id_car
					sampCreate3dTextEx(id_3d, text_on_car, 2547834076, 0, 0, 0.2, 50, true, -1, id_car)
				end
			end
		else
			local x, y, z = getCharCoordinates(PLAYER_PED)
			local result, handle_car = findAllRandomVehiclesInSphere(x, y, z, 50, true, true)
			if result then
				local res, id_car = sampGetVehicleIdByCarHandle(handle_car)
				local veh_exist = doesVehicleExist(handle_car)
				if veh_exist then
					id_3d = id_car
					sampDestroy3dText(id_3d)
				end
			end
        end

        if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isKeyJustPressed(VK_INSERT) then
            gm_enable = not gm_enable
            if gm_enable then
                printStringNow("~g~GodMode ON", 2000)
            else
                printStringNow("~r~GodMode OFF", 2000)
            end
        end
        if not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive() and isKeyJustPressed(VK_DELETE) then
            wh_enable = not wh_enable
            if wh_enable then
                printStringNow("~g~WallHack ON", 2000)
            else
                printStringNow("~r~WallHack OFF", 2000)
            end
        end
        if gm_enable then -- гм
            
            setCharProofs(PLAYER_PED, true, true, true, true, true)
            writeMemory(0x96916D, 1, 1, true)
            if isCharInAnyCar(PLAYER_PED) then
                handle_car = storeCarCharIsInNoSave(PLAYER_PED)
                --setCarRoll(handle_car, 0)
                fixCar(handle_car)
                setCarProofs(handle_car, true, true, true, true, true)
            end
        else
            
            setCharProofs(PLAYER_PED, false, false, false, false, false)
            writeMemory(0x96916D,1, 1, false)
            if isCharInAnyCar(PLAYER_PED) then
                handle_car = storeCarCharIsInNoSave(PLAYER_PED)
                setCarProofs(handle_car, false, false, false, false, false)
            end
        end
        if wh_enable then -- вх
            nameTagOn()
        else
            nameTagOff()
        end

    end
end



function sampev.onServerMessage(color, text)
    --if admin_cmd and not isPauseMenuActive() then
        admin_name, adm_id, adm_command = string.match(text, "%[A%d+%]%s+(%w+_?%w+)%[(%d+)%]%: (.*)")
        if admin_name ~= nil and adm_id ~= nil and adm_command ~= nil and string.find(adm_command, "/") then
            command_from_admin_chat_status = true
        else return true end
    --end

    if command_from_admin_chat_status then
        if adm_command:find("/hp") then
            adm_chat_cmd_player_id, adm_chat_cmd_player_val = string.match(adm_command, "/hp%s+(%d+)%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil and adm_chat_cmd_player_val ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет изменить HP игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                        lasttime = os.time()
                        lasttimes = 0
                        time_out = 15
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            active_forma = true
                            if stop_forma then
                                message("Команду выполнил другой администратор.")
                                stop_forma = false
                                break
                            end
                            if lasttimes == time_out then
                                active_forma = false
                                message("Время ожидания истекло.")
                            end
                            
                            adm_name = string.match(admin_name, "%a+")
                            
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                sampSendChat("/hp "..adm_chat_cmd_player_id.." "..adm_chat_cmd_player_val)
                                wait(100)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                active_forma = false
                                break
                            end
                        end
                    else
                        --if isKeyJustPressed(VK_K) then
                            adm_name = string.match(admin_name, "%a+")
                            sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                            active_forma = false
                        --end
                    end
                end)
            end
        end

        if adm_command:find("/tempskin") then
            adm_chat_cmd_player_id, tempskin_id = string.match(adm_command, "/tempskin%s+(%d+)%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil and tempskin_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет выдать временный скин игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                        lasttime = os.time()
                        lasttimes = 0
                        time_out = 15
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            active_forma = true
                            if stop_forma then
                                message("Команду выполнил другой администратор.")
                                stop_forma = false
                                break
                            end
                            if lasttimes == time_out then
                                active_forma = false
                                message("Время ожидания истекло.")
                            end
                            
                            adm_name = string.match(admin_name, "%a+")
                            
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                sampSendChat("/tempskin "..adm_chat_cmd_player_id.." "..tempskin_id)
                                wait(100)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                active_forma = false
                                break
                            end
                        end
                    else
                        --if isKeyJustPressed(VK_K) then
                            adm_name = string.match(admin_name, "%a+")
                            sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                            active_forma = false
                        --end
                    end
                end)
            end
        end

        if adm_command:find("/mute") then
            adm_chat_cmd_player_id, term, reason_mute = string.match(adm_command, "/mute%s+(%d+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil and term ~= nil then
                if reason_mute == nil then
                    reason_mute = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                            local adm_nick = first_name.. ". "..last_name
                            text = string.format("Администратор %s[%d] хочет поставить затычку игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/mute "..adm_chat_cmd_player_id.." "..term.." ".. reason_mute .. " • " ..adm_nick)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/ban") then
            adm_chat_cmd_player_id, term, reason_ban = string.match(adm_command, "/ban%s+(%d+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil and term ~= nil then
                if reason_ban == nil then
                    reason_ban = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                            local adm_nick = first_name.. ". "..last_name
                            text = string.format("Администратор %s[%d] хочет забанить игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/ban "..adm_chat_cmd_player_id.." "..term.." ".. reason_ban .. " • " ..adm_nick)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/offban") then
            adm_chat_cmd_player_name, term, reason_offban = string.match(adm_command, "/offban%s+(.+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_name ~= nil and term ~= nil then
                if reason_offban == nil then
                    reason_offban = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет забанить игрока {ffd700}%s{ffffff} в оффлайне.", admin_name, adm_id, adm_chat_cmd_player_name)
                        message(text)
                        addTime("/offban "..adm_chat_cmd_player_name.." "..term.." ".. reason_offban .. " • " ..adm_nick)
                    end)
                end
            end
        end

        if adm_command:find("/offmute") then
            adm_chat_cmd_player_name, term, reason_offmute = string.match(adm_command, "/offmute%s+(.+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_name ~= nil and term ~= nil then
                if reason_offmute == nil then
                    reason_offmute = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет поставить затычку игроку {ffd700}%s{ffffff} в оффлайне.", admin_name, adm_id, adm_chat_cmd_player_name)
                        message(text)
                        addTime("/offmute "..adm_chat_cmd_player_name.." "..term.." ".. reason_offmute .. " • " ..adm_nick)
                    end)
                end
            end
        end

        if adm_command:find("/offunmute") then
            adm_chat_cmd_player_name = string.match(adm_command, "/offunmute%s+(.+)")
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    text = string.format("Администратор %s[%d] хочет снять затычку с игрока {ffd700}%s{ffffff} в оффлайне.", admin_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    addTime("/offunmute "..adm_chat_cmd_player_name)
                end)
            end
        end

        if adm_command:find("/offprison") then
            adm_chat_cmd_player_name, term, reason_offprison = string.match(adm_command, "/offprison%s+(.+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_name ~= nil and term ~= nil then
                if reason_offprison == nil then
                    reason_offprison = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет посадить оффлайн игрока {ffd700}%s{ffffff} в тюрьму.", admin_name, adm_id, adm_chat_cmd_player_name)
                        message(text)
                        addTime("/offprison "..adm_chat_cmd_player_name.." "..term.." ".. reason_offprison .. " • " ..adm_nick)
                    end)
                end
            end
        end

        if adm_command:find("/offjail") then
            adm_chat_cmd_player_name, term, reason_offjail = string.match(adm_command, "/offjail%s+(.+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_name ~= nil and term ~= nil then
                if reason_offjail == nil then
                    reason_offjail = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет посадить оффлайн игрока {ffd700}%s{ffffff} в тюрьму.", admin_name, adm_id, adm_chat_cmd_player_name)
                        message(text)
                        addTime("/offprison "..adm_chat_cmd_player_name.." "..term.." ".. reason_offjail .. " • " ..adm_nick)
                    end)
                end
            end
        end

        if adm_command:find("/offunjail") then
            adm_chat_cmd_player_name = string.match(adm_command, "/offunjail%s+(.+)")
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    text = string.format("Администратор %s[%d] хочет выпустить игрока оффлайн {ffd700}%s{ffffff} и тюрьмы.", admin_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    addTime("/offunprison "..adm_chat_cmd_player_name)
                end)
            end
        end

        if adm_command:find("/offunprison") then
            adm_chat_cmd_player_name = string.match(adm_command, "/offunprison%s+(.+)")
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    text = string.format("Администратор %s[%d] хочет выпустить игрока оффлайн {ffd700}%s{ffffff} и тюрьмы.", admin_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    addTime("/offunprison "..adm_chat_cmd_player_name)
                end)
            end
        end

        if adm_command:find("/offwarn") then
            adm_chat_cmd_player_name, reason_offwarn = string.match(adm_command, "/offwarn%s+(.+)%s+(.+)")
            if adm_chat_cmd_player_name ~= nil and term ~= nil then
                if reason_offwarn == nil then
                    reason_offwarn = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет выдать предупреждение игроку {ffd700}%s{ffffff} в оффлайне.", admin_name, adm_id, adm_chat_cmd_player_name)
                        message(text)
                        addTime("/offwarn "..adm_chat_cmd_player_name.." ".. reason_offwarn .. " • " ..adm_nick)
                    end)
                end
            end
        end

        if adm_command:find("/jail") then
            adm_chat_cmd_player_id, term, reason_jail = string.match(adm_command, "/jail%s+(%d+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil and term ~= nil then
                if reason_jail == nil then
                    reason_jail = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                            local adm_nick = first_name.. ". "..last_name
                            text = string.format("Администратор %s[%d] хочет посадить в тюрьму игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/prison "..adm_chat_cmd_player_id.." "..term.." ".. reason_jail .. " • " ..adm_nick)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/prison") then
            adm_chat_cmd_player_id, term, reason_jail = string.match(adm_command, "/prison%s+(%d+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil and term ~= nil then
                if reason_jail == nil then
                    reason_jail = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                            local adm_nick = first_name.. ". "..last_name
                            text = string.format("Администратор %s[%d] хочет посадить в тюрьму игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/prison "..adm_chat_cmd_player_id.." "..term.." ".. reason_jail .. " • " ..adm_nick)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/warn") then
            adm_chat_cmd_player_id, reason_warn = string.match(adm_command, "/warn%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil then
                if reason_warn == nil then
                    reason_warn = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                            local adm_nick = first_name.. ". "..last_name
                            text = string.format("Администратор %s[%d] хочет выдать предупреждение игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/warn "..adm_chat_cmd_player_id.." "..reason_warn .. " • " ..adm_nick)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/kick") then
            adm_chat_cmd_player_id, reason_kick = string.match(adm_command, "/kick%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil then
                if reason_kick == nil then
                    reason_kick = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(1)
                        if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                            local adm_nick = first_name.. ". "..last_name
                            text = string.format("Администратор %s[%d] хочет кикнуть игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/kick "..adm_chat_cmd_player_id.." ".. reason_kick .. " • " ..adm_nick)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/msg") then
            msg_text = string.match(adm_command, "/msg%s+(.+)")
            if msg_text ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                    local adm_nick = first_name.. ". "..last_name
                    text = string.format("Администратор %s[%d] хочет сделать объявление.", admin_name, adm_id)
                    message(text)
                    addTime("/msg ".. msg_text .. " • " ..adm_nick, 123)
                end)
            end
        end

        if adm_command:find("/skick") then
            adm_chat_cmd_player_id = string.match(adm_command, "/skick%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет кикнуть {FFD700}%s[%d] {FFFFFF}без лишнего шума.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/skick "..adm_chat_cmd_player_id)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                end)
            end
        end

        if adm_command:find("/unmute") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unmute%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет снять затычку с игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/unmute "..adm_chat_cmd_player_id)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                end)
            end
        end

        if adm_command:find("/unban") then
            adm_chat_cmd_player_name = string.match(adm_command, "/unban%s+(%w+_?%w+)")
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    text = string.format("Администратор %s[%d] хочет разбанить игрока {ffd700}%s{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    addTime("/unban "..adm_chat_cmd_player_name)
                end)
            end
        end

        if adm_command:find("/unwarn") then
            adm_chat_cmd_player_name = string.match(adm_command, "/unwarn%s+(%w+_?%w+)")
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    text = string.format("Администратор %s[%d] хочет разбанить игрока {ffd700}%s{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    addTime("/unwarn "..adm_chat_cmd_player_name)
                end)
            end
        end

        if adm_command:find("/unjail") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unjail%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет выпустить из тюрьмы игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                            lasttime = os.time()
                            lasttimes = 0
                            time_out = 15
                            while lasttimes < time_out do
                                lasttimes = os.time() - lasttime
                                wait(0)
                                active_forma = true
                                if stop_forma then
                                    message("Команду выполнил другой администратор.")
                                    stop_forma = false
                                    break
                                end
                                if lasttimes == time_out then
                                    active_forma = false
                                    message("Время ожидания истекло.")
                                end
                                
                                adm_name = string.match(admin_name, "%a+")
                                
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    sampSendChat("/unprison "..adm_chat_cmd_player_id)
                                    wait(100)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    active_forma = false
                                    break
                                end
                            end
                        else
                            --if isKeyJustPressed(VK_K) then
                                adm_name = string.match(admin_name, "%a+")
                                sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                                active_forma = false
                            --end
                        end
                end)
            end
        end

        if adm_command:find("/unprison") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unprison%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет выпустить из тюрьмы игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                        lasttime = os.time()
                        lasttimes = 0
                        time_out = 15
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            active_forma = true
                            if stop_forma then
                                message("Команду выполнил другой администратор.")
                                stop_forma = false
                                break
                            end
                            if lasttimes == time_out then
                                active_forma = false
                                message("Время ожидания истекло.")
                            end
                            
                            adm_name = string.match(admin_name, "%a+")
                            
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                sampSendChat("/unprison "..adm_chat_cmd_player_id)
                                wait(100)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                active_forma = false
                                break
                            end
                        end
                    else
                        --if isKeyJustPressed(VK_K) then
                            adm_name = string.match(admin_name, "%a+")
                            sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                            active_forma = false
                        --end
                    end
                end)
            end
        end

        if adm_command:find("/spawn") then
            adm_chat_cmd_player_id = string.match(adm_command, "/spawn%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет отправить игрока {ffd700}%s[%d]{ffffff} на спавн.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                        lasttime = os.time()
                        lasttimes = 0
                        time_out = 15
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            active_forma = true
                            if stop_forma then
                                message("Команду выполнил другой администратор.")
                                stop_forma = false
                                break
                            end
                            if lasttimes == time_out then
                                active_forma = false
                                message("Время ожидания истекло.")
                            end
                            
                            adm_name = string.match(admin_name, "%a+")
                            
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                sampSendChat("/spawn "..adm_chat_cmd_player_id)
                                wait(100)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                active_forma = false
                                break
                            end
                        end
                    else
                        --if isKeyJustPressed(VK_K) then
                            adm_name = string.match(admin_name, "%a+")
                            sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                            active_forma = false
                        --end
                    end
                end)
            end
        end

        if adm_command:find("/freeze") then
            adm_chat_cmd_player_id = string.match(adm_command, "/freeze%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет заморозить игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                        lasttime = os.time()
                        lasttimes = 0
                        time_out = 15
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            active_forma = true
                            if stop_forma then
                                message("Команду выполнил другой администратор.")
                                stop_forma = false
                                break
                            end
                            if lasttimes == time_out then
                                active_forma = false
                                message("Время ожидания истекло.")
                            end
                            
                            adm_name = string.match(admin_name, "%a+")
                            
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                sampSendChat("/freeze "..adm_chat_cmd_player_id)
                                wait(100)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                active_forma = false
                                break
                            end
                        end
                    else
                        --if isKeyJustPressed(VK_K) then
                            adm_name = string.match(admin_name, "%a+")
                            sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                            active_forma = false
                        --end
                    end
                end)
            end
        end

        if adm_command:find("/unfreeze") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unfreeze%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(1)
                    if sampIsPlayerConnected(adm_chat_cmd_player_id) then
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет разморозить игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения {FFA500}<K>{FFFFFF}.")
                        lasttime = os.time()
                        lasttimes = 0
                        time_out = 15
                        while lasttimes < time_out do
                            lasttimes = os.time() - lasttime
                            wait(0)
                            active_forma = true
                            if stop_forma then
                                message("Команду выполнил другой администратор.")
                                stop_forma = false
                                break
                            end
                            if lasttimes == time_out then
                                active_forma = false
                                message("Время ожидания истекло.")
                            end
                            
                            adm_name = string.match(admin_name, "%a+")
                            
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                sampSendChat("/unfreeze "..adm_chat_cmd_player_id)
                                wait(100)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                active_forma = false
                                break
                            end
                        end
                    else
                        --if isKeyJustPressed(VK_K) then
                            adm_name = string.match(admin_name, "%a+")
                            sampSendChat(string.format("/a %s, игрока с ID %i нет в сети.", adm_name, adm_chat_cmd_player_id))
                            active_forma = false
                        --end
                    end
                end)
            end
        end

    end
end

function message(text)
    sampAddChatMessage("{FFA500}[AdminTools] {FFFFFF}"..text, 0xffffffff)
end

function nameTagOn()
	local pStSet = sampGetServerSettingsPtr()
	mem.setfloat(pStSet + 39, 1488.0)
	mem.setint8(pStSet + 47, 0)
	mem.setint8(pStSet + 56, 1)
end

function nameTagOff()
	local pStSet = sampGetServerSettingsPtr()
	mem.setfloat(pStSet + 39, 50.0)
	mem.setint8(pStSet + 47, 0)
	mem.setint8(pStSet + 56, 1)
end

function getcar(param)
    carid = tonumber(param)
    if carid ~= nil or carid ~= "" then
            local text = string.match(carid, "%d")
            if text then
                local result, handle_car = sampGetCarHandleBySampVehicleId(carid)
                local car_exist = doesVehicleExist(handle_car)
                if car_exist then
                    car_model = getCarModel(handle_car)
                    driver = getDriverOfCar(handle_car)
                    if driver == -1 then
                        x, y, z = getCharCoordinates(PLAYER_PED)
                        sampSendEnterVehicle(carid, false)
                        warpCharIntoCar(PLAYER_PED, handle_car)
                        restoreCameraJumpcut()
                        setCarCoordinates(handle_car, x, y, z)
                    else
                        message(driver)
                        message("Нельзя телепортироваться в ТС с игроком.")
                    end
                else
                    message("Транспортного средства с таким ID в зоне стрима нет.")
                end
            else
                message("Используйте /getcar [ID транспортного средства]")
            end
        else
            return
        end
end