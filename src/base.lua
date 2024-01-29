dofile "globalVariable.lua"
--loading libs
dofile "stack.lua"

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
			--main loop of the computer
		sleep(osloop)		
	end
end

parallel.waitForAll(lisenNet, localruning, doingTasks)
