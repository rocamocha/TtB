return function(message)
    local coin = (math.random() > 0.5) and 1 or 2
    local opt = {
        [1] = function() message.channel:send("*sucks*") end,
        [2] = function() message.channel:send("*doesn't suck*") end
    }
    if string.sub(message.content, string.len(message.content) - 2) == '...' then
        opt[coin]()
        return true
    end
    return false
end