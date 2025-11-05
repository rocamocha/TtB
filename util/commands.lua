local commands = {}

commands.ooc = require('commands.ooc')
commands.ttb = require('commands.ttb')
commands.suck = require('commands.suck')
commands.tip = require('commands.tip')

function commands.handle_ooc(message, modules, admins)
    return commands.ooc(message, modules, admins)
end

function commands.handle_ttb(message, modules)
    return commands.ttb(message, modules)
end

function commands.handle_suck(message)
    return commands.suck(message)
end

function commands.handle_tip(message, modules, admins)
    return commands.tip(message, modules, admins)
end

return commands