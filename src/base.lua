--constants
ID = "base" --must be 4 char
switching = false
switchingBlacklist = "" --IDs not to switch (to avoid switching loops mosty cased by ender modem and wireless modem)
port = 41
osloop = 1
suportedREQs = "ECHO,SUPR,SUPD,REPB"
suportedDOs = ""
numberOfBatterys = 2

--global veribales
battery = {}
for i=1 , numberOfBatterys do
	battery[i] = {}
	battery[i].max = 0
	battery[i].current = 0
end

--loading libs
dofile "stack.lua"

--init DO stack
do
	local files = fs.list("/do")
	for i = 1, table.getn(files) do
		if i == 1 then
			suportedDOs = suportedDOs .. string.sub(files[i],1,-5)
		else
			suportedDOs = suportedDOs .. "," .. string.sub(files[i],1,-5)
		end
	end
	print("suportedDOs: " .. suportedDOs)
end
doStack = stack

-- request id generation
lastReqID = 0
function getReqId()
	if lastReqID == 9999 then
		lastReqID = 0
		return "0000"
	end
	lastReqID = lastReqID + 1
	return string.format("%04d", lastReqID)
end


-- finding modems and wraping them
do
	modems = {}
	modemSides = {}
	local perNames = peripheral.getNames()
	for i = 1 , #perNames, 1 do
		if peripheral.getType(perNames[i]) == "modem" then
			modemSides[#modemSides +1] = perNames[i]
		end
	end
	for i = 1, #modemSides do
		modems[modemSides[i]] = peripheral.wrap(modemSides[i])
	end
	--init modems
	for i = 1, #modemSides do
		modems[modemSides[i]].open(port)
	end
end

dofile "lowLevelNetwork.lua"
--high level functions for networking (for example: ping)
function ping(targetID)
	--generating payload
	local payload = string.format("%05d", math.floor(math.random()*10000))
	local msgID = getReqId()
	--sending ping
	print("sending ping")
	makeSendMsg(targetID, "R", mkReq(msgID, "ECHO", payload))
	--waiting for return
	local retMsgID, retMsgBody = nil
	repeat
		local event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
		local senderID, targetID, msgType, msgBody = extractMainHeader(massage)
		if targetID == ID and msgType == "A" then
			retMsgID, retMsgBody = extractAnswerHeader(msgBody)
		end
	until(msgID == retMsgID)
	if payload == retMsgBody then
		print("succsesfull ping")
	else
		print("corrup return / bug")
	end
end

function batteryUpdate(targetID)
	makeSendMsg(targetID, "D", "batteryUpdate")
	local retMsgBody = nil
	repeat
		sleep(10)
		--waiting for return
		local retMsgID = nil
		repeat
			local msgID = getReqId()
			makeSendMsg(targetID, "R", mkReq(msgID, "DOIN", ""))
			local event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
			local senderID, targetID, msgType, msgBody = extractMainHeader(massage)
			if targetID == ID and msgType == "A" then
				retMsgID, retMsgBody = extractAnswerHeader(msgBody)
			end
		until(msgID == retMsgID)
	until(retMsgBody == "false")
end

function lisenNet()
	while true do
		local event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
		local senderID, targetID,  msgType, msgBody = extractMainHeader(massage)
		addSwitchingTable(senderID, side)
		if targetID == ID then
			if msgType == "R" then
				--handle requests
				request(msgBody, senderID)
		--[[	this shoud be handeled elsewhere
			elseif msgType == "A" then
				--handle answers
				answer(string.sub(massage, 12,-1))

		]]--
			elseif msgType == "D" then
				--handle do
				addDo(msgBody)
			elseif msgType == "S" then
				--handle set
				set(msgBody)
			end
		else
			if switching == true then
				if not string.find(switchingBlacklist, senderID)then
					doSwitching(side, targetID, massage)
				end
			end
		end
	end
end

function doingTasks()
	while true do
		local task = doStack.pop()
		if task ~= nil then
			local PATH = "/do/".. task ..".lua"--do the tasks
			if fs.exists(PATH) then
				dofile(PATH)
			else
				print("task don't exits " .. PATH)
			end
		else
			sleep(10)
		end
	end
end

function localruning()
	while true do
		local function batteryUpdate1()
			batteryUpdate("BAT1")
		end
		local function batteryUpdate2()
			batteryUpdate("BAT2")
		end
		parallel.waitForAll(batteryUpdate1, batteryUpdate2)
		local function getBatteryStatus(targetID)	
			local msgID = getReqId()
			makeSendMsg(targetID, "R", mkReq(msgID, "BATS"))
			
			--waiting for return
			local retMsgID, retMsgBody = nil
			repeat
				local event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
				local senderID, targetID, msgType, msgBody = extractMainHeader(massage)
				if targetID == ID and msgType == "A" then
					retMsgID, retMsgBody = extractAnswerHeader(msgBody)
				end
			until(msgID == retMsgID)
			local current = tonumber(string.sub(retMsgBody, 1, 10))
			local max = tonumber(string.sub(retMsgBody, 11, -1))
			return current, max
		end
		
		for i=1 , numberOfBatterys do
			battery[i].current, battery[i].max = getBatteryStatus("BAT" .. tostring(i))
		end
		sleep(osloop)		
	end
end

parallel.waitForAll(lisenNet, localruning, doingTasks)
