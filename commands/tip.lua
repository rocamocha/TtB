return function(message, modules, admins)
    -- +tip addition command (admin only) - usage: +tip <message_id> or +tip <text>
    local tip_prefix = message.content:lower():match('^%+tip%s+')
    if tip_prefix and admins and admins[message.author.id] then
        local content_after = message.content:sub(6) -- Remove "+tip "

        local entry_parts = {}

        -- Check if it's a message ID (digits only)
        local message_id = content_after:match('^(%d+)$')
        if message_id then
            -- Fetch message by ID
            local target_message = message.channel:getMessage(message_id)
            if target_message then
                -- Add text content if it exists
                if target_message.content and target_message.content ~= "" then
                    table.insert(entry_parts, target_message.content)
                end

                -- Add media links if they exist
                if target_message.attachments and #target_message.attachments > 0 then
                    for _, attachment in ipairs(target_message.attachments) do
                        if attachment.url then
                            table.insert(entry_parts, attachment.url)
                        end
                    end
                end
            else
                message.channel:send("❌ Could not find message with ID: " .. message_id)
                return true
            end
        else
            -- Use the text directly
            if content_after and content_after ~= "" then
                table.insert(entry_parts, content_after)
            else
                message.channel:send("Usage: `+tip <message_id>` or `+tip <text>`")
                return true
            end
        end

        -- Only add if we have content
        if #entry_parts > 0 then
            local file = io.open('responses/tip.lua', 'r')
            if not file then
                message.channel:send("Error: Could not open responses/tip.lua")
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

            max_index = max_index + 1
            local combined_content = table.concat(entry_parts, " | ")
            local escaped = combined_content:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n')

            -- Insert before the closing brace
            local last_entry_end = content:find('%]%s*=%s*"[^"]*"%s*\n')
            if last_entry_end then
                last_entry_end = content:find('\n', last_entry_end)
            end
            local before_brace = content:sub(1, last_entry_end or -2)
            before_brace = before_brace:gsub('%s+$', '')
            local new_entry = ',\n    [' .. max_index .. '] = "' .. escaped .. '"'
            content = before_brace .. new_entry .. '\n}'

            file = io.open('responses/tip.lua', 'w')
            file:write(content)
            file:close()

            local reload = require('util.reload')
            reload.reload('tip', modules)
            message.channel:send("✅ Added tip #" .. max_index)
        else
            message.channel:send("❌ No content to add")
        end
        return true
    end

    -- !tip command
    if message.content:match('^!tip') then
        local index_str = message.content:match('^!tip (%d+)$')
        if index_str then
            -- Specific index
            local index = tonumber(index_str)
            if index and modules.tip[index] then
                message.channel:send(modules.tip[index])
            else
                message.channel:send("Invalid tip index.")
            end
        else
            -- Random tip
            if #modules.tip > 0 then
                local selected = math.random(1, #modules.tip)
                message.channel:send(modules.tip[selected])
            else
                message.channel:send("No tips available.")
            end
        end
        return true
    end

    return false
end