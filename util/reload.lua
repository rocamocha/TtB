local reload = {}

function reload.reload(module_name, modules)
    if module_name == 'ooc' then
        package.loaded['responses.ooc'] = nil
        modules.ooc = require('responses.ooc')
        return 'Reloaded ooc module.'
    elseif module_name == 'tip' then
        package.loaded['responses.tip'] = nil
        modules.tip = require('responses.tip')
        return 'Reloaded tip module.'
    elseif module_name == 'adjective' then
        package.loaded['responses.wordbank.adjective'] = nil
        modules.adjective = require('responses.wordbank.adjective')
        return 'Reloaded adjective module.'
    elseif module_name == 'noun' then
        package.loaded['responses.wordbank.noun'] = nil
        modules.noun = require('responses.wordbank.noun')
        return 'Reloaded noun module.'
    elseif module_name == 'all' then
        package.loaded['responses.ooc'] = nil
        modules.ooc = require('responses.ooc')
        package.loaded['responses.tip'] = nil
        modules.tip = require('responses.tip')
        package.loaded['responses.wordbank.adjective'] = nil
        modules.adjective = require('responses.wordbank.adjective')
        package.loaded['responses.wordbank.noun'] = nil
        modules.noun = require('responses.wordbank.noun')
        return 'Reloaded all modules.'
    else
        return 'Unknown module. Available: ooc, tip, adjective, noun, all'
    end
end

return reload