require "lib.moonloader"
require "lib.sampfuncs"
local dlstatus = require("moonloader").download_status
local inicfg = require 'inicfg'
local sampev = require 'lib.samp.events'
local key = require 'vkeys'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

update_state = false

local script_vers = 1
local script_vers_text = "1.0"

local admin_cmd = true
local command_from_admin_chat_status = false
local notf_chat= true
local active_forma = false
local stop_forma = false

local update_url = "https://raw.githubusercontent.com/nixonoff/script/master/update.ini"
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = "https://raw.githubusercontent.com/nixonoff/script/master/script.lua"
local script_path = thisScript().path

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end

    downloadUrlToFile(update_url, update_path, function (id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateini = inicfg.load(nil, update_path)
            if tonumber(updateini.info.vers) > script_vers then 
                message("Найдено обновление. Версия:{FFA500} "..updateini.info.vers_text)
                update_state = true
            end
            if tonumber(updateini.info.vers) <= script_vers and not update_state then
                message("Written by {FFA500}Anton Nixon")
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

        _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
		myname = sampGetPlayerNickname(myid)
        
    end

end

function sampev.onServerMessage(color, text)
    if admin_cmd then
		if not isGamePaused() then
			if not isPauseMenuActive() then
				adm_name, adm_id, adm_command = string.match(text, "%[A%d+%]%s+(%w+_?%w+)%[(%d+)%]%: (.*)")
				if adm_name ~= nil then
					if adm_id ~= nil then
						if adm_command ~= nil then
							if string.find(adm_command, "/") then
								command_from_admin_chat_status = true
							end
                        else
                            return true
						end
                    else
                        return true
					end
                else
                    return true
				end
			end
		end
	end
    if command_from_admin_chat_status == true then

        if adm_command:find("/hp") then
            adm_chat_cmd_player_id, adm_chat_cmd_player_val = string.match(adm_command, "/hp%s+(%d+)%s+(%d+)") -- hp
            if adm_chat_cmd_player_id ~= nil then
                if adm_chat_cmd_player_val ~= nil then
                    active_forma = true
                    lua_thread.create(function()
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет изменить HP игроку {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения.")
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
                                message("Время ожидания истекло.")
                            end
                            local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                            local adm_name = string.match(adm_name, "%a+")
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                adm_nick = first_name.. ". "..last_name
                                sampSendChat("/hp "..adm_chat_cmd_player_id.." "..adm_chat_cmd_player_val.." • "..adm_nick)
                                wait(200)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                --sampSendChat("/ans "..adm_chat_cmd_player_id.. " HP выдано по просьбе администратора "..adm_name)
                                active_forma = false
                                break
                            end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/mute") then
            adm_chat_cmd_player_id, term, reason_mute = string.match(adm_command, "/mute%s+(%d+)%s+(%d+)%s+(.+)") -- mute
            if adm_chat_cmd_player_id ~= nil then
                if term ~= nil then
                    if reason_mute == nil then
                        reason_mute = ""
                    else
                        active_forma = true
                        lua_thread.create(function()
                            wait(100)
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            text = string.format("Администратор %s[%d] хочет поставить затычку игроку {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения.")
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
                                    message("Время ожидания истекло.")
                                end
                                local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                                local adm_name = string.match(adm_name, "%a+")
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    adm_nick = first_name.. ". "..last_name
                                    new_reason_mute = reason_mute .. " • " ..adm_nick
                                    sampSendChat("/mute "..adm_chat_cmd_player_id.." "..term.." "..new_reason_mute)
                                    wait(200)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    --sampSendChat("/ans "..adm_chat_cmd_player_id.." Наказание выдано по просьбе администратора "..adm_name..".")
                                    active_forma = false
                                    break
                                end
                            end
                        end)
                    end
                end
            end
        end

        if adm_command:find("/ban") then
            adm_chat_cmd_player_id, term, reason_ban = string.match(adm_command, "/ban%s+(%d+)%s+(%d+)%s+(.+)") -- ban
            if adm_chat_cmd_player_id ~= nil then
                if term ~= nil then
                    if reason_ban == nil then
                        reason_ban = ""
                    else
                        active_forma = true
                        lua_thread.create(function()
                            wait(100)
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            text = string.format("Администратор %s[%d] хочет забанить игрока {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения.")
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
                                    message("Время ожидания истекло.")
                                end
                                local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                                local adm_name = string.match(adm_name, "%a+")
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    adm_nick = first_name.. ". "..last_name
                                    new_reason_ban = reason_ban .. " • " ..adm_nick
                                    sampSendChat("/ban "..adm_chat_cmd_player_id.." "..term.." "..new_reason_ban)
                                    wait(200)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    --sampSendChat("/ans "..adm_chat_cmd_player_id.." Наказание выдано по просьбе администратора "..adm_name..".")
                                    active_forma = false
                                    break
                                end
                            end
                        end)
                    end
                end
            end
        end

        if adm_command:find("/jail") or adm_command:find("/prison") then
            adm_chat_cmd_player_id, term, reason_jail = string.match(adm_command, "/jail%s+(%d+)%s+(%d+)%s+(.+)") -- jail
            adm_chat_cmd_player_id, term, reason_jail = string.match(adm_command, "/prison%s+(%d+)%s+(%d+)%s+(.+)")
            if adm_chat_cmd_player_id ~= nil then
                if term ~= nil then
                    if reason_jail == nil then
                        reason_jail = ""
                    else
                        active_forma = true
                        lua_thread.create(function()
                            wait(100)
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            text = string.format("Администратор %s[%d] хочет посадить в тюрьму игрока {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения.")
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
                                    message("Время ожидания истекло.")
                                end
                                local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                                local adm_name = string.match(adm_name, "%a+")
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    adm_nick = first_name.. ". "..last_name
                                    new_reason_jail = reason_jail .. " • " ..adm_nick
                                    sampSendChat("/prison "..adm_chat_cmd_player_id.." "..term.." "..new_reason_jail)
                                    wait(200)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    --sampSendChat("/ans "..adm_chat_cmd_player_id.." Наказание выдано по просьбе администратора "..adm_name..".")
                                    active_forma = false
                                    break
                                end
                            end
                        end)
                    end
                end
            end
        end

        if adm_command:find("/warn") then
            adm_chat_cmd_player_id, reason_warn = string.match(adm_command, "/warn%s+(%d+)%s+(.+)") -- ban
            if adm_chat_cmd_player_id ~= nil then
                    if reason_warn == nil then
                        reason_warn = ""
                    else
                        active_forma = true
                        lua_thread.create(function()
                            wait(100)
                            adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                            text = string.format("Администратор %s[%d] хочет выдать предупреждение игроку {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                            message(text)
                            message("Нажмите клавишу подтверждения.")
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
                                    message("Время ожидания истекло.")
                                end
                                local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                                local adm_name = string.match(adm_name, "%a+")
                                if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                    adm_nick = first_name.. ". "..last_name
                                    new_reason_warn = reason_warn .. " • " ..adm_nick
                                    sampSendChat("/warn "..adm_chat_cmd_player_id.." "..new_reason_warn)
                                    wait(200)
                                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                    --sampSendChat("/ans "..adm_chat_cmd_player_id.." Наказание выдано по просьбе администратора "..adm_name..".")
                                    active_forma = false
                                    break
                                end
                            end
                        end)
                    end
            end
        end

        if adm_command:find("/kick") then
            adm_chat_cmd_player_id, reason_kick = string.match(adm_command, "/kick%s+(%d+)%s+(.+)") -- ban
            if adm_chat_cmd_player_id ~= nil then
                if reason_kick == nil then
                    reason_kick = ""
                else
                    active_forma = true
                    lua_thread.create(function()
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        text = string.format("Администратор %s[%d] хочет кикнуть игрока {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        message("Нажмите клавишу подтверждения.")
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
                                message("Время ожидания истекло.")
                            end
                            local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                            local adm_name = string.match(adm_name, "%a+")
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                adm_nick = first_name.. ". "..last_name
                                new_reason_kick = reason_kick .. " • " ..adm_nick
                                sampSendChat("/kick "..adm_chat_cmd_player_id.." "..new_reason_kick)
                                wait(200)
                                sampSendChat(string.format("/a %s, команда применена.", adm_name))
                                --sampSendChat("/ans "..adm_chat_cmd_player_id.." Наказание выдано по просьбе администратора "..adm_name..".")
                                active_forma = false
                                break
                            end
                        end
                    end)
                end
            end
        end

        if adm_command:find("/msg") then
            msg_text = string.match(adm_command, "/msg%s+(.+)") -- ban
            if msg_text ~= nil then
                active_forma = true
                    lua_thread.create(function()
                        wait(100)
                        text = string.format("Администратор %s[%d] хочет сделать объявление.", adm_name, adm_id)
                        message(text)
                        message("Нажмите клавишу подтверждения <K>.")
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
                                message("Время ожидания истекло.")
                            end
                            local first_name, last_name = string.match(adm_name, "(%a)%a+_(%a+)")
                            local adm_name = string.match(adm_name, "%a+")
                            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                                adm_nick = first_name.. ". "..last_name
                                new_text_msg = msg_text .. " • " ..adm_nick
                                sampSendChat("/msg "..new_text_msg)
                                active_forma = false
                                break
                            end
                        end
                    end)
            end
        end

        if adm_command:find("/skick") then
            adm_chat_cmd_player_id = string.match(adm_command, "/skick%s+(%d+)") -- ban
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет кикнуть {FFD700}%s[%d] {FFFFFF}без лишнего шума.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    message("Нажмите клавишу подтверждения.")
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 15
                    local adm_name = string.match(adm_name, "%a+")
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
                            message("Время ожидания истекло.")
                        end
                        if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat("/skick "..adm_chat_cmd_player_id)
                            wait(200)
                            sampSendChat(string.format("/a %s, команда применена.", adm_name))
                            --sampSendChat("/ans "..adm_chat_cmd_player_id.." Наказание выдано по просьбе администратора "..adm_name..".")
                            active_forma = false
                            break
                        end
                    end
                end)
            end
        end

        if adm_command:find("/unmute") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unmute%s+(%d+)") -- unmute
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет снять затычку с игрока {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    message("Нажмите клавишу подтверждения.")
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 15
                    local adm_name = string.match(adm_name, "%a+")
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
                            message("Время ожидания истекло.")
                        end
                        if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat("/unmute "..adm_chat_cmd_player_id)
                            wait(200)
                            sampSendChat(string.format("/a %s, команда применена.", adm_name))
                            active_forma = false
                            break
                        end
                    end
                end)
            end
        end

        if adm_command:find("/unban") then
            adm_chat_cmd_player_name = string.match(adm_command, "/unban%s+(%w+_?%w+)") -- unban
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    text = string.format("Администратор %s[%d] хочет разбанить игрока {ffd700}%s{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    message("Нажмите клавишу подтверждения.")
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 15
                    local adm_name = string.match(adm_name, "%a+")
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
                            message("Время ожидания истекло.")
                        end
                        if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat("/unban "..adm_chat_cmd_player_name)
                            wait(200)
                            sampSendChat(string.format("/a %s, команда применена.", adm_name))
                            active_forma = false
                            break
                        end
                    end
                end)
            end
        end

        if adm_command:find("/unwarn") then
            adm_chat_cmd_player_name = string.match(adm_command, "/unwarn%s+(%w+_?%w+)") -- unwarn
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    text = string.format("Администратор %s[%d] хочет разбанить игрока {ffd700}%s{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name)
                    message(text)
                    message("Нажмите клавишу подтверждения.")
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 15
                    local adm_name = string.match(adm_name, "%a+")
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
                            message("Время ожидания истекло.")
                        end
                        if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat("/unwarn "..adm_chat_cmd_player_name)
                            wait(200)
                            sampSendChat(string.format("/a %s, команда применена.", adm_name))
                            active_forma = false
                            break
                        end
                    end
                end)
            end
        end

        if adm_command:find("/unjail") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unjail%s+(%d+)") -- unjail
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет выпустить из тюрьмы игрока {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    message("Нажмите клавишу подтверждения.")
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 15
                    local adm_name = string.match(adm_name, "%a+")
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
                            message("Время ожидания истекло.")
                        end
                        if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat("/unprison "..adm_chat_cmd_player_id)
                            wait(200)
                            sampSendChat(string.format("/a %s, команда применена.", adm_name))
                            active_forma = false
                            break
                        end
                    end
                end)
            end
        end

        if adm_command:find("/unprison") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unprison%s+(%d+)") -- unjail
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет выпустить из тюрьмы игрока {ffd700}%s[%d]{ffffff}.", adm_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    message("Нажмите клавишу подтверждения.")
                    lasttime = os.time()
                    lasttimes = 0
                    time_out = 15
                    local adm_name = string.match(adm_name, "%a+")
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
                            message("Время ожидания истекло.")
                        end
                        if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                            sampSendChat("/unprison "..adm_chat_cmd_player_id)
                            wait(200)
                            sampSendChat(string.format("/a %s, команда применена.", adm_name))
                            active_forma = false
                            break
                        end
                    end
                end)
            end
        end

    end
end

function message(text)
	sampAddChatMessage("{FFA500}[AdminTools] {FFFFFF}"..text, 0xffffffff)
end