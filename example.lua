local discordia = require('discordia')

client:on('ready', function() -- just printing in the cmd that we successfully ran the program and should be logged in
	print('Logged in as '..client.user.username)
end)

client:on('messageCreate', function(message)
	if message.content == 'samuel l jackson' then -- when someone types this exact message
		message.channel:send('muthafucka!') -- the bot will send 'muthafucka!' if it can see the channel and send messages
	end
end)

client:run('Bot PASTE_YOUR_BOT_TOKEN')