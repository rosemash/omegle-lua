local web = require("./request.lua")
local json = require("json")
local querystring = require("querystring")

math.randomseed(os.time()) --for generateRandomId and for selecting a sevrer

local function generateRandomId()
	local charset = {"A","B","C","D","E","F","G","H","J","K","L","M","N","P","Q","R","S","T","U","V","W","X","Y","Z","2","3","4","5","6","7","8","9"}
	return ("........"):gsub(".", function()
		return charset[math.random(1, #charset)]
	end)
end

return function(interests)
	local chatPost --function to be
	local chat_object = {
		post = function(location, data)
			if chatPost ~= nil then
				return chatPost(location, querystring.stringify(data))
			else
				error("not ready", 2)
			end
		end;
		debug = false;
		callback = {};
		alive = true;
	}
	local function handleEvent(data)
		if chat_object.debug then
			print(json.encode(data))
		end
		if chat_object.callback[data[1]] then
			chat_object.callback[data[1]](unpack(data, 2)) --{name, data1, data2, ...}
		end
	end
	local chat = coroutine.create(function()
                local servers = json.decode(assert(web.get("https://chatserv.omegle.com/status")))
                local available_servers, antinude_servers = servers.servers, servers.antinudeservers
                local verification_server = ("https://%s/"):format(antinude_servers[math.random(1, #antinude_servers)])
                local chat_server = ("https://%s.omegle.com/"):format(available_servers[math.random(1, #available_servers)])
                print(("Getting code from %s..."):format(verification_server))
                local check = assert(web.post(verification_server .. "check"))
                print(check)
                print(("Connecting to %s..."):format(chat_server))
                local client_info = json.decode(assert(web.post(chat_server .. ("start?caps=recaptcha2,t3&firstevents=1&spid=&randid=%s&cc=%s%s&lang=en"):format(
                        generateRandomId(),
                        check,
                        interests ~= nil and "&topics=" .. json.encode(interests) or ""
                ))))
		print("Listening for events...")
		chatPost = function(location, data)
			return web.post(chat_server .. location, ("id=%s"):format(client_info.clientID) .. (data and "&" .. data or ""))
		end
		if client_info.events then
			for _, event in pairs(client_info.events) do
				handleEvent(event)
			end
		end
		while true do
			local events = json.decode(assert(chatPost("events")))
			if events ~= nil then
				for _, event in pairs(events) do
					handleEvent(event)
				end
			else
				break --if no events, the chat is probably over
			end
		end
		chat_object.alive = false
	end)
	assert(coroutine.resume(chat))
	return chat_object
end
