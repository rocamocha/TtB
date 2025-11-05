local TtB_triggers = {'^'}
for i = 1, 100 do
    TtB_triggers[#TtB_triggers+1] = TtB_triggers[i]..'^'
end

return function(message, modules)
    for _, v in ipairs(TtB_triggers) do
        if message.content == v then
            local function generate_ttb()
                local num_descriptors = math.random(1, 8)
                -- Use the first num_descriptors types in order
                local selected = {}
                for i = 1, num_descriptors do
                    selected[i] = i
                end
                -- Build the phrase
                local phrase = ""
                for _, idx in ipairs(selected) do
                    local word_bank = modules.descriptors[idx]
                    local word = word_bank[math.random(1, #word_bank)]
                    phrase = phrase .. word .. ' '
                end
                local noun = modules.noun[math.random(1, #modules.noun)]
                return phrase .. noun .. '.'
            end
            local ender = math.random(1, 100) < 5 and "TOTSUGEKI!" or generate_ttb()
            message.channel:send("^ That's the beauty of "..ender)
            return true
        end
    end
    return false
end