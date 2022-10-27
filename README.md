# lua-omegle

This is a very minimal wrapper over omegle's event system, to easily set up a bot in Lua.

I actually created this for myself several years before uploading this project. That's why it's a little bit messy. But it works well, and it should also be future-proof due to the fact that it indiscriminately captures omegle's incoming events and passes them to callbacks in a table provided by you.

# Dependencies

This is a Luvit project (https://luvit.io), so you [need to have Luvit installed on your system](https://luvit.io/install.html) to use it.

Requires `luvit/secure-socket` and `creationix/coro-http`. Via `lit`:

```
$ lit install luvit/secure-socket
$ lit install creationix/coro-http
```

Dependencies via `lit` are placed in the current working directory, so these commands must be run from inside the project root.

# Basic Example

Create your script in the same directory as this project, require `omegle.lua`, and execute your script with Luvit.

Let's say I have created an example script called `myscript.lua`:

```lua
omegle = require("./omegle.lua")

--instance a new chat without any interests
local conversation = omegle()

--print all incoming events to console
conversation.debug = true

--create handler for "gotMessage" event
conversation.callback.gotMessage = function(message)
	print("Stranger: " .. message)
	conversation.post("send", {msg = "you smell"})
	print("Replied to Stranger")
end
```

I can run the script (from the project directory):

```
$ luvit myscript.lua
```

The script will continue running and waiting for events until omegle closes the connection.

# Full Usage

Omegle's network model uses a long polling loop for incoming events, and specific URLs to POST for outgoing events. Everything you can do on omegle boils down to those two things. This project is therefore a very transparent wrapper over them.

## Starting a Conversation

When you call the root library object (e.g. `omegle()`) it begins a new chat and returns an object representing that chat. The chat object immediately begins listening for events. It is the server's responsibility to match you with a stranger, and will send the relevant events as matchmaking commences.

If you pass a table of interests to the root library object, e.g. `omegle{"fiction", "literature", "drama"}`, it will connect using those interests. Unlike the website, there is no timeout on this.

The chat object is good for a single conversation only, becoming obsolete when the chat has ended. All below examples will assume a chat object called `conversation`, as if `local conversation = omegle()`.

## Events

The server sends you events through the event loop, and your own events are sent to the server through a URL as POST requests. The way of handling both is simple.

### Receiving

You listen for specific events sent through the conversation for by adding them, by name, as functions to the `callback` member of the chat object, for example `conversation.callback.connected = function(...) --[[do stuff here]] end`.

Events are asynchronous. Every time an event is received, if a function with the same name as the event is present in that table, it will be called and values sent with the event will be passed as arguments, all strings.

The user [nuclear](https://github.com/nuclear) has reverse-engineered the most important events omegle sends, which can be found [here in this gist](https://gist.github.com/nucular/e19264af8d7fc8a26ece#events). As this project merely acts as a wrapper over omegle's event system, all the events documented in that gist apply.

### Sending

To send an event of your own, use the `post` function, for example `conversation.post("typing")` or `conversation.post("send", {msg = "abracadabra"})`. This directly translates as a POST request to [server].omegle.com/[event], with the "id" parameter automatically filled out, with an optional table for extra form data.

The events omegle is expecting through this channel have different names than the received events, so make sure to inspect nuclear's document closely to find the right ways to use this method. They're all documented underneath the section that details all the events; you can find them under the headings like "Send messages" and "Disconnect from the current chat".

## Other Functionality

The field `active` (e.g. `conversation.active`) will be true for as the chat is active; it becomes false when a request closes without yielding a new event, indicating either that a network error occurred, or that the chat is over. In either case, there is no way to reconnect the chat, and the object can be discarded.

In addition to above usage, the chat object has a boolean field called `debug`. If you set it to true, information about all incoming events will be printed to the console without needing to set a callback. Setting it (e.g. `conversation.debug = true`) can be useful for discovering new events, or to check whether the server is reporting why your chat won't connect to any strangers.

I always dislike when minimally-documented pet projects like this one don't include certain features in their readme, so while you are free to also inspect the source code if you want, I can guarantee that every feature this library exposes is completely explained above.
