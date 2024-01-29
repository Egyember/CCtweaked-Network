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
	if msgBody == nil then
		msgBody = ""
	end
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

