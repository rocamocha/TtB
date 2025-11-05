local json = require('json')
local reload = require('util.reload')
local config = require('config')

local allowed_guilds = {}
for _, id in ipairs(config.ooc_allowed_guilds) do
    allowed_guilds[id] = true
end

local ooc_message_map = {}  -- message_id -> ooc_index, limited to 100 entries
local map_limit = 100
local last_ooc = {}  -- channel_id -> last ooc message_id

local function load_banned(guild_id)
    local path = 'banned_ooc/' .. guild_id .. '.json'
    local file = io.open(path, 'r')
    if file then
        local content = file:read('*a')
        file:close()
        if content and content ~= '' then
            local success, decoded = pcall(json.decode, content)
            if success and decoded then
                local banned = {}
                for k, v in pairs(decoded) do
                    banned[tonumber(k)] = v
                end
                return banned
            end
        end
    end
    return {}
end

local function save_banned(guild_id, banned)
    local path = 'banned_ooc/' .. guild_id .. '.json'
    local to_save = {}
    for k, v in pairs(banned) do
        to_save[tostring(k)] = v
    end
    local file = io.open(path, 'w')
    if file then
        file:write(json.encode(to_save))
        file:close()
    end
end

local function add_to_map(message_id, index)
    ooc_message_map[message_id] = index
    -- Limit to 100 entries
    local count = 0
    for k in pairs(ooc_message_map) do
        count = count + 1
        if count > map_limit then
            ooc_message_map[k] = nil
            break
        end
    end
end

return function(message, modules, admins)
    -- Only allow ooc commands from whitelisted guilds
    if not (message.guild and allowed_guilds[message.guild.id]) then
        return false
    end
    
    local ref = message.reference and message.reference.messageId or "nil"
    print("handle_ooc: content='" .. message.content .. "' ref=" .. ref)
    
    -- +ooc addition command (admin only) - usage: +ooc <message_id> [message_id] [message_id] ...
    print("DEBUG: Looking for +ooc pattern in: '" .. message.content .. "'")
    print("DEBUG: admins table: " .. tostring(admins))
    print("DEBUG: is admin: " .. tostring(admins and admins[message.author.id]))
    local ooc_prefix = message.content:lower():match('^%+ooc%s+')
    if ooc_prefix and admins and admins[message.author.id] then
        -- Extract all message IDs
        local ids = {}
        for id in message.content:sub(6):gmatch('%d+') do
            table.insert(ids, id)
        end
        print("DEBUG: ooc_add_match result: " .. tostring(#ids) .. " IDs found")
        
        if #ids > 0 then
            print("Processing +ooc with " .. #ids .. " ID(s)")
            
            local file = io.open('responses/ooc.lua', 'r')
            if not file then 
                print("Failed to open responses/ooc.lua")
                message.channel:send("Error: Could not open responses/ooc.lua")
                return true 
            end
            local content = file:read('*a')
            file:close()
            
            -- Find the highest index currently in the table
            local max_index = 0
            for idx in string.gmatch(content, '%[(%d+)%]') do
                local num = tonumber(idx)
                if num > max_index then
                    max_index = num
                end
            end
            
            local added_indices = {}
            local failed_count = 0
            
            for _, message_id in ipairs(ids) do
                local target_message = message.channel:getMessage(message_id)
                print("Target: " .. tostring(target_message) .. " type: " .. type(target_message))
                print("Target content: " .. tostring(target_message and target_message.content or "nil"))
                
                -- Build the entry (can be text, media, or both)
                local entry_parts = {}
                
                -- Add text content if it exists
                if target_message and target_message.content and target_message.content ~= "" then
                    table.insert(entry_parts, target_message.content)
                end
                
                -- Add media links if they exist
                if target_message and target_message.attachments and #target_message.attachments > 0 then
                    for _, attachment in ipairs(target_message.attachments) do
                        if attachment.url then
                            table.insert(entry_parts, attachment.url)
                        end
                    end
                end
                
                -- Only add if we have content or media
                if #entry_parts > 0 then
                    print("Adding ooc: " .. table.concat(entry_parts, " | "))
                    max_index = max_index + 1
                    table.insert(added_indices, max_index)
                    
                    local combined_content = table.concat(entry_parts, " | ")
                    local escaped = combined_content:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')
                    -- Insert before the closing brace with proper formatting
                    local last_entry_end = content:find('%]%s*=%s*"[^"]*"%s*\n')
                    if last_entry_end then
                        last_entry_end = content:find('\n', last_entry_end)
                    end
                    local before_brace = content:sub(1, last_entry_end or -2)
                    before_brace = before_brace:gsub('%s+$', '')
                    local new_entry = ',\n    [' .. max_index .. '] = "' .. escaped .. '"'
                    content = before_brace .. new_entry .. '\n}'
                else
                    print("Failed to get target message content or media for ID: " .. message_id)
                    failed_count = failed_count + 1
                end
            end
            
            if #added_indices > 0 then
                file = io.open('responses/ooc.lua', 'w')
                file:write(content)
                file:close()
                print("File written, reloading ooc")
                reload.reload('ooc', modules)
                print("Reloaded ooc")
                local indices_str = table.concat(added_indices, ", ")
                if failed_count > 0 then
                    message.channel:send("✅ Added " .. #added_indices .. " OOC response(s) (Indices: #" .. indices_str .. ") | ❌ Failed to fetch " .. failed_count)
                else
                    message.channel:send("✅ Added " .. #added_indices .. " OOC response(s) (Indices: #" .. indices_str .. ")")
                end
            else
                message.channel:send("❌ Failed to fetch any messages")
            end
        else
            print("No message IDs found")
            message.channel:send("Usage: `+ooc <message_id> [message_id] ...`")
        end
        return true
    end
    
    if message.content:match('^!ooc') then
        print("Ooc command matched: '" .. message.content .. "'")
        local index_str = message.content:match('^!ooc (%d+)$')
        if index_str then
            print("Index mode")
            local index = tonumber(index_str)
            if index and modules.ooc[index] then
                local guild_id = message.guild and message.guild.id or 'dm'
                local banned = load_banned(guild_id)
                if banned[index] then
                    message.channel:send("That ooc response is banned for this server.")
                else
                    local response = message.channel:send(modules.ooc[index])
                    add_to_map(response.id, index)
                    last_ooc[message.channel.id] = response.id
                end
            else
                message.channel:send("Invalid ooc index.")
            end
        elseif message.content == '!ooc banned' then
            print("Banned mode")
            print("Banned command detected")
            local guild_id = message.guild and message.guild.id or 'dm'
            local banned = load_banned(guild_id)
            local banned_list = {}
            for i, v in pairs(banned) do
                if v then
                    table.insert(banned_list, i)
                end
            end
            if #banned_list == 0 then
                message.channel:send("No banned ooc responses for this server.")
            else
                table.sort(banned_list)
                message.channel:send("Banned out-of-context responses: " .. table.concat(banned_list, ", "))
            end
        else
            print("Random mode")
            local guild_id = message.guild and message.guild.id or 'dm'
            local banned = load_banned(guild_id)
            
            -- Filter available indices
            local available = {}
            for i = 1, #modules.ooc do
                if not banned[i] then
                    table.insert(available, i)
                end
            end
            
            if #available == 0 then
                message.channel:send("No available ooc responses for this server.")
                return true
            end
            
            local selected = available[math.random(1, #available)]
            local response = message.channel:send(modules.ooc[selected])
            add_to_map(response.id, selected)
            last_ooc[message.channel.id] = response.id
        end
        return true
    elseif message.content:match('^%?ooc') then
        print("Search ooc command matched: '" .. message.content .. "'")
        local search = message.content:match('^%?ooc%s+(.+)$')
        if search then
            -- Apply search term replacements from config
            for find, replace in pairs(config.ooc_search_replacements) do
                search = search:gsub(find, replace)
            end
            print("Search term: '" .. search .. "'")
            local guild_id = message.guild and message.guild.id or 'dm'
            local banned = load_banned(guild_id)
            
            -- Find matching entries
            local matches = {}
            for i = 1, #modules.ooc do
                if not banned[i] and modules.ooc[i]:lower():find(search:lower(), 1, true) then
                    table.insert(matches, i)
                end
            end
            
            if #matches == 0 then
                message.channel:send("No matching ooc responses found for '" .. search .. "'.")
            else
                local selected = matches[math.random(1, #matches)]
                local response = message.channel:send(modules.ooc[selected])
                add_to_map(response.id, selected)
                last_ooc[message.channel.id] = response.id
            end
        else
            message.channel:send("Usage: `?ooc <search term>`")
        end
        return true
    elseif message.content:lower() == 'delete this' then
        print("Delete this detected")
        local target_id = message.reference and message.reference.messageId or last_ooc[message.channel.id]
        print("target_id: " .. tostring(target_id))
        if target_id then
            local index = ooc_message_map[target_id]
            if index then
                print("Index found: " .. index)
                local guild_id = message.guild and message.guild.id or 'dm'
                local banned = load_banned(guild_id)
                banned[index] = true
                save_banned(guild_id, banned)
                message.channel:send("OOC response #" .. index .. " has been banned for this server.")
                ooc_message_map[target_id] = nil  -- cleanup
                if last_ooc[message.channel.id] == target_id then
                    last_ooc[message.channel.id] = nil
                end
            else
                print("No index found for messageId: " .. target_id)
                message.channel:send("That doesn't appear to be a reply to an ooc message.")
            end
        else
            message.channel:send("No recent ooc message to delete.")
        end
        return true
    end
    return false
end