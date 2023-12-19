--constants
ID = "base" --must be 4 char
switchlikeMode = false --switching table
Switching = false
port = 41
osloop = 1
suportedREQs = "ECHO,SUPR"

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
modems = {}
perNames = peripheral.getNames()
for i = 1 , #perNames, 1 do
	if peripheral.getType(perNames[i]) == "modem" then
		modems[#modems+1] = peripheral.wrap(perNames[i])
	end
end

--init modems
for i = 1, #modems, 1 do
	modems[i].open(port)
end

-- low level functions for networking
function doSwitching()
	print("not implemeted yet\n")
	--todo: implemetn it
end

function extractMainHeader(msg)
--	print("extractMainHeader called with " .. msg)
	local senderID = string.sub(msg, 1, 4)
	local targetID = string.sub(msg, 5, 8)
	local msgType = string.sub(msg, 9, 9)
	local msgBody = string.sub(msg, 10,-1)
	return senderID, targetID, msgType, msgBody
end

--todo input validation
function mkMsg(targetID, msgType, msg)
	return ID .. targetID .. msgType .. msg
end

function send(msg)
	if switchlike == true then
		--not implemented yet
		return
	end
	for i = 1 , #modems, 1 do
		modems[i].transmit(port, port, msg)
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
		send(mkMsg(senderID, "A", mkAns(msgID, msgBody)))	
	elseif msgType == "SUPR" then
		send(mkMsg(senderID, "A", mkAns(msgID, suportedREQs)))	
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
function answer(msg)
--handle answers (general header striped)	

end

function doing(msg) --do is reserver keyword
--handle do requests (general header striped)	

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
	send(mkMsg(targetID, "R", mkReq(msgID, "ECHO", payload)))
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
				doing(msgBody)
			elseif msgType == "S" then
				--handle set
				set(msgBody)
			end
		else
			if Switching == true then
				doSwitching()
			end
		end
	end
end
function localruning()
	while true do
			--main loop of the computer
		sleep(osloop)		
	end
end

parallel.waitForAll(lisenNet, localruning)
