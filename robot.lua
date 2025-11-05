print(_VERSION)

local discordia = require('discordia')
local http,https = require('http'),require('https')
local json = require('json')
local client = discordia.Client()
local config = require('config')
local coro_http = require('coro-http')
local coro = coro_http.coro or coro_http

local reload = require('util.reload')
local commands = require('util.commands')

local modules = {
    ooc = require('responses.ooc'),
    tip = require('responses.tip'),
    descriptors = {
        require('responses.wordbank.1_opinion'),
        require('responses.wordbank.2_size'),
        require('responses.wordbank.3_age'),
        require('responses.wordbank.4_shape'),
        require('responses.wordbank.5_color'),
        require('responses.wordbank.6_origin'),
        require('responses.wordbank.7_material'),
        require('responses.wordbank.8_purpose')
    },
    noun = require('responses.wordbank.noun')
}

local admins = {}
for _, id in ipairs(config.admins) do
    admins[id] = true
end

local TtB_triggers = {'^'}
for i = 1, 100 do
	TtB_triggers[#TtB_triggers+1] = TtB_triggers[i]..'^'
end

for i = 1, 1000 do
	math.random()
end


function httpGET(url, callback)
    url = http.parseUrl(url)
    local req = (url.protocol == 'https' and https or http).get(url, function(res)
      local body={}
      res:on('data', function(s)
        body[#body+1] = s
      end)
      res:on('end', function()
        res.body = table.concat(body)
        callback(res)
      end)
      res:on('error', function(err)
        callback(res, err)
      end)
    end)
    req:on('error', function(err)
      callback(nil, err)
    end)
end

-----------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------

client:on('ready', function()
	print('Logged in as '..client.user.username)
end)

client:on('messageCreate', function(message)
    if commands.handle_ooc(message, modules, admins) then return end
    if commands.handle_tip(message, modules, admins) then return end
    if commands.handle_ttb(message, modules) then return end
    if commands.handle_suck(message) then return end
    
    if string.sub(message.content, 1, 8) == '!reload ' then
        if admins[message.author.id] then
            local module = message.content:sub(9)
            if module == 'logic' then
                package.loaded['util.commands'] = nil
                package.loaded['commands.ooc'] = nil
                package.loaded['commands.ttb'] = nil
                package.loaded['commands.suck'] = nil
                package.loaded['commands.tip'] = nil
                commands = require('util.commands')
                message.channel:send('Reloaded logic module.')
            else
                local response = reload.reload(module, modules)
                message.channel:send(response)
            end
        else
            message.channel:send('You are not authorized to use reload commands.')
        end
    end
end)

client:run('Bot ' .. config.token)