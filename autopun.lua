require "lib.moonloader"
require "lib.sampfuncs"
local dlstatus = require("moonloader").download_status
local inicfg = require 'inicfg'
local sampev = require 'samp.events'
local key = require 'vkeys'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

--local adm_nick = ""

local update_state = false
local script_vers = 12
local script_vers_text = '1.2'
local admin_cmd, command_from_admin_chat_status, notf_chat, active_forma, stop_forma = true, false, true, false, false

local update_url = "https://raw.githubusercontent.com/nixonoff/AutoPunish/main/update.ini"
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = "https://raw.githubusercontent.com/nixonoff/AutoPunish/main/autopun.lua"
local script_path = thisScript().path

function main()
    if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    sampRegisterChatCommand("getcar", function(param)
        carid = tonumber(param); text = string.match(carid, "%d")
        if text then
            local result, handle_car = sampGetCarHandleBySampVehicleId(carid)
            local car_exist = doesVehicleExist(handle_car)
            if car_exist then
                local driver = getDriverOfCar(handle_car)
                if driver == -1 then
                    local x, y, z = getCharCoordinates(PLAYER_PED)
                    sampSendEnterVehicle(carid, false); warpCharIntoCar(PLAYER_PED, handle_car)
                    restoreCameraJumpcut(); setCarCoordinates(handle_car, x, y, z)
                else sampAddChatMessage(driver, -1); sampAddChatMessage("Нельзя телепортироваться в ТС с игроком.", -1) end
            else sampAddChatMessage("Транспортного средства с таким ID в зоне стрима нет.", -1) end
        else sampAddChatMessage("Используйте /getcar [ID транспортного средства]", -1) end
    end)
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
    end
end



function sampev.onServerMessage(color, text)
    --if admin_cmd and not isPauseMenuActive() then
        admin_name, adm_id, adm_command = string.match(text, "%[A%d+%]%s+(%w+_?%w+)%[(%d+)%]%: (.*)")
        if admin_name ~= nil and adm_id ~= nil and adm_command ~= nil and string.find(adm_command, "/") then
            command_from_admin_chat_status = true
        else return true end
    --end

    local function addTime(str, newReason, strReason, type)
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
                message("Время ожидания истекло.")
            end
            
            adm_name = string.match(admin_name, "%a+")
            
            if isKeyJustPressed(VK_K) and not sampIsChatInputActive() and not sampIsDialogActive() then
                
                if newReason ~= nil and strReason ~= nil then
                    newReason = strReason
                end
                if type ~= nil then
                    sampSendChat(str)
                else
                    sampSendChat(str)
                    wait(100)
                    sampSendChat(string.format("/a %s, команда применена.", adm_name))
                end
                active_forma = false
                break
            end
        end
    end

    if command_from_admin_chat_status then
        if adm_command:find("/hp") then
            adm_chat_cmd_player_id, adm_chat_cmd_player_val = string.match(adm_command, "/hp%s+(%d+)%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil and adm_chat_cmd_player_val ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет изменить HP игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/hp "..adm_chat_cmd_player_id.." "..adm_chat_cmd_player_val)
                    
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
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет поставить затычку игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        addTime("/mute "..adm_chat_cmd_player_id.." "..term.." ".. reason_mute .. " • " ..adm_nick)
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
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет забанить игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        addTime("/ban "..adm_chat_cmd_player_id.." "..term.." ".. reason_ban .. " • " ..adm_nick)
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
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет посадить в тюрьму игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        addTime("/prison "..adm_chat_cmd_player_id.." "..term.." ".. reason_jail .. " • " ..adm_nick)
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
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет посадить в тюрьму игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        addTime("/prison "..adm_chat_cmd_player_id.." "..term.." "..reason_jail .. " • " ..adm_nick)
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
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет выдать предупреждение игроку {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        addTime("/warn "..adm_chat_cmd_player_id.." "..reason_warn .. " • " ..adm_nick)
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
                        wait(100)
                        adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                        local first_name, last_name = string.match(admin_name, "(%a)%a+_(%a+)")
                        local adm_nick = first_name.. ". "..last_name
                        text = string.format("Администратор %s[%d] хочет кикнуть игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                        message(text)
                        addTime("/kick "..adm_chat_cmd_player_id.." ".. reason_kick .. " • " ..adm_nick)
                    end)
                end
            end
        end

        if adm_command:find("/msg") then
            msg_text = string.match(adm_command, "/msg%s+(.+)")
            if msg_text ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
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
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет кикнуть {FFD700}%s[%d] {FFFFFF}без лишнего шума.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/skick "..adm_chat_cmd_player_id)
                end)
            end
        end

        if adm_command:find("/unmute") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unmute%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет снять затычку с игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/unmute "..adm_chat_cmd_player_id)
                end)
            end
        end

        if adm_command:find("/unban") then
            adm_chat_cmd_player_name = string.match(adm_command, "/unban%s+(%w+_?%w+)")
            if adm_chat_cmd_player_name ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
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
                    wait(100)
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
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет выпустить из тюрьмы игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/unprison "..adm_chat_cmd_player_id)
                end)
            end
        end

        if adm_command:find("/unprison") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unprison%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет выпустить из тюрьмы игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/unprison "..adm_chat_cmd_player_id)
                end)
            end
        end

        if adm_command:find("/spawn") then
            adm_chat_cmd_player_id = string.match(adm_command, "/spawn%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет отправить игрока {ffd700}%s[%d]{ffffff} на спавн.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/spawn "..adm_chat_cmd_player_id)
                end)
            end
        end

        if adm_command:find("/freeze") then
            adm_chat_cmd_player_id = string.match(adm_command, "/freeze%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет заморозить игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/freeze "..adm_chat_cmd_player_id)
                end)
            end
        end

        if adm_command:find("/unfreeze") then
            adm_chat_cmd_player_id = string.match(adm_command, "/unfreeze%s+(%d+)")
            if adm_chat_cmd_player_id ~= nil then
                active_forma = true
                lua_thread.create(function()
                    wait(100)
                    adm_chat_cmd_player_name = sampGetPlayerNickname(tonumber(adm_chat_cmd_player_id))
                    text = string.format("Администратор %s[%d] хочет разморозить игрока {ffd700}%s[%d]{ffffff}.", admin_name, adm_id, adm_chat_cmd_player_name, adm_chat_cmd_player_id)
                    message(text)
                    addTime("/unfreeze "..adm_chat_cmd_player_id)
                end)
            end
        end

    end
end

function message(text)
    sampAddChatMessage("{FFA500}[AdminTools] {FFFFFF}"..text, 0xffffffff)
end