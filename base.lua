--constants
ID = "base" --must be 4 char
switching = false
switchingBlacklist = "" --IDs not to switch (to avoid switching loops mosty cased by ender modem and wireless modem)
port = 41
osloop = 1
suportedREQs = "ECHO,SUPR,SUPD"
suportedDOs = ""

--loading libs
dofile "stack.lua"

--init DO stack
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

-- low level functions for networking
switchingTable = {}
function addSwitchingTable(senderID, side)
	switchingTable[senderID] = side	
end

function doSwitching(side, targetID, msg)
	local targetSide = switchingTable[targetID]
	if targetSide == nil then
		for i = 1 , #modemSides do
			if modemSides[i] ~= side then
				modems[modemSides[i]].transmit(port, port, msg)
			end
		end
	elseif targetSide ~= side then
		print(targetSide)
		modems[targetSide].transmit(port, port, msg)
	end
end

function extractMainHeader(msg)
--	print("extractMainHeader called with " .. msg)
	local senderID = string.sub(msg, 1, 4)
	local targetID = string.sub(msg, 5, 8)
	local msgType = string.sub(msg, 9, 9)
	local msgBody = string.sub(msg, 10,-1)
	return senderID, targetID, msgType, msgBody
end

function makeSendMsg(targetID, msgType, msg)
	local massage = ID .. targetID .. msgType .. msg
	local targetSide = switchingTable[targetID]
	if targetSide == nil then
		for i = 1 , #modemSides do
			modems[modemSides[i]].transmit(port, port, massage)
		end
	else
		modems[targetSide].transmit(port, port, massage)
	end
end
		

function extractRequestHeader(msg)
	local msgID = string.sub(msg, 1,4)
	local msgType = string.sub(msg, 5,8)
	local msgBody = string.sub(msg, 9,-1)
	return msgID, msgType, msgBody
end

--todo input validation
function mkReq(msgID, msgType, msgBody)
	return msgID .. msgType .. msgBody
end

function request(msg,  senderID)
--handle requests (general header striped)	
	local msgID, msgType, msgBody = extractRequestHeader(msg)
	if msgType == "ECHO" then
		makeSendMsg(senderID, "A", mkAns(msgID, msgBody))
	elseif msgType == "SUPR" then
		makeSendMsg(senderID, "A", mkAns(msgID, suportedREQs))	
	elseif msgType == "SUPD" then
		makeSendMsg(senderID, "A", mkAns(msgID, suportedDOs))	
	end
end

function extractAnswerHeader(msg)
	local msgID = string.sub(msg, 1,4)
	local msgBody = string.sub(msg, 5, -1) 
	return msgID, msgBody
end

--todo input validation
function mkAns(msgID, msgBody)
	return msgID .. msgBody
end

function addDo(msg) --do is reserver keyword
--handle do requests (general header striped)
	doStack.push(msg)	
end

function set(msg)
--handle set requests (general header striped)	

end

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
			--do the tasks

		else
			sleep(10)
		end
	end
end

function localruning()
	while true do
			--main loop of the computer
		sleep(osloop)		
	end
end

parallel.waitForAll(lisenNet, localruning, doingTasks)
