local http = require("coro-http")

local headers = { --these headers were copied from a real firefox omegle request to make your bot look more legitimate; might not be important
	{"Content-type", "application/x-www-form-urlencoded; charset=utf-8"};
	{"User-Agent", "Mozilla/5.0 (X11; Linux x86_64; rv:93.0) Gecko/20100101 Firefox/93.0"};
}

local function makeRequest(method, url, data)
	local res, body = http.request(method, url, headers, data)
	if res.code == 200 then
		return body
	else
		return nil, ("HTTP not-OK: %s (%s)"):format(tostring(res.code), tostring(res.reason)), body
	end
end

return {
	get = function(url)
		return makeRequest("GET", url)
	end;
	post = function(url, data)
		return makeRequest("POST", url, data)
	end;
}
