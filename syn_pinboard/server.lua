TriggerEvent("getCore", function(core)
    VorpCore = core
end)
VorpInv = exports.vorp_inventory:vorp_inventoryApi()

RegisterServerEvent("syn_pinboard:get_posters")
AddEventHandler("syn_pinboard:get_posters", function(city)
    local _source = source
    local tablex = {}
    local User = VorpCore.getUser(source)
    local Character = User.getUsedCharacter
    local charidentifier = Character.charIdentifier
    local group = User.getGroup
    exports.ghmattimysql:execute('SELECT * FROM posters WHERE city=@city', { ['city'] = city }, function(result)
        if result[1] ~= nil then
            for i = 1, #result, 1 do
                table.insert(tablex, {
                    title = result[i].title,
                    poster_link = result[i].poster_link,
                    charidentifier = result[i].charidentifier,
                    id = result[i].id,
                })
            end
        end
        TriggerClientEvent("syn_pinboard:send_list", _source, tablex, charidentifier, group)
    end)
end)

RegisterServerEvent("syn_pinboard:set_link")
AddEventHandler("syn_pinboard:set_link", function(title, poster_link, city, webhook)

    if poster_link ~= nil then
        local Character = VorpCore.getUser(source).getUsedCharacter
        local charidentifier = Character.charIdentifier
        Discord(webhook, title, poster_link, Config.color, city)
        local parameters = { ['title'] = title, ['poster_link'] = poster_link, ['city'] = city, ['charidentifier'] = charidentifier }
        exports.ghmattimysql:execute("INSERT INTO posters ( `title`, `poster_link`, `city`, `charidentifier`) VALUES ( @title, @poster_link, @city, @charidentifier)", parameters)
    end
end)

RegisterServerEvent("syn_pinboard:removeposter")
AddEventHandler("syn_pinboard:removeposter", function(id)

    exports.ghmattimysql:execute("DELETE FROM posters WHERE id=@id", { ["id"] = id })
end)

RegisterCommand("clearpins", function(source, args)

    if args ~= nil then
        local User = VorpCore.getUser(source) -- Return User with functions and all characters
        local group = User.getGroup -- Return user group (not character group)
        if group == "admin" then
            exports.ghmattimysql:execute("TRUNCATE TABLE posters", {})
        else return false
        end
    end
end)


function Discord(webhook, title, description, color, city)
    local _source   = source
    local Character = VorpCore.getUser(_source).getUsedCharacter
    local name      = Character.firstname .. ' ' .. Character.lastname
    local logs      = ""
    local avatar    = Config.avatar
    local message   = "Town: " .. city -- translate here
    local message1  = "**By:**`" .. name .. "`\n **Tittle:** `" .. title .. "`" --translate here

    if string.match(description, "http") then
        logs = {
            {
                ["color"] = color,
                ["title"] = message1,
                ["image"] = { ["url"] = description },
                ["footer"] = { ["text"] = message, ["icon_url"] = Config.footerIcon }
            }
        }
    else
        logs = {
            {
                ["color"] = color,
                ["title"] = message1,
                ["description"] = " **Message:** `" .. description .. "`",
                ["footer"] = { ["text"] = message, ["icon_url"] = Config.footerIcon }
            }
        }
    end
    PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({ ["username"] = name, ["avatar_url"] = avatar, embeds = logs }), { ['Content-Type'] = 'application/json' })
end
