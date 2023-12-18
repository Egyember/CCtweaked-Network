--constants
ID = "base" --must be 4 char
switchlikeMode = false --switching table
Switching = false
osloop = 1
port = 41
suportedREQs = "ECHO,SUPR"

-- finding modems and wraping them
modems = {}
perNames = peripheral.getNames()
for i = 1 , #perNames 1 do
	if peripheral.getType(perNames[i]) == "modem" then
		modems[#modems+1] = peripheral.wrap(perNames[i])
	end
end

--init modems
for i = 1, #modems, 1 do
	modems[i].open(port)
end

--init system alarm

osAlarmID = os.setAlarm(os.time() + osloop)

-- low level functions for networking
function doSwitching()
	print("not implemeted yet\n")
	--todo: implemetn it
end

function extractMainHeader(msg)
	local senderID = string.sub(massage, 1, 4)
	local targetID = string.sub(massage, 5, 8)
	local msgType = string.sub(massage, 10, 11)
	local msgBody = string.sub(massage, 12,-1)
	return senderID, targetID, msgType, msgBody
end

function mkMsg(msg, targetID, msgType)
	return ID .. targetID .. msgType .. msg
end

function send(msg)
	if switchlike == true then
		--not implemented yet
		return
	end
	for i = 1 , #modems, i do
		modems[i].transmit(port, port, msg)
	end
end

function request(msg,  senderID)
--handle requests (general header striped)	

	local msgID = string.sub(msg, 1,4)
	local msgType = string.sub(msg, 4,7)
	local msgBody = string.sub(msg, 7,-1)
	if msgType == "ECHO" then
		send(mkMsg(msgID .. msgBody, senderID, "A"))	
	elseif msgType == "SUPR" then
		send(mkMsg(msgID .. suportedREQs, senderID, "A"))	
	end
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
	local payload = string.format("%05d", math.floor(math.random*10000))

end

function lisenNet()
	while true do
		local event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
		massage = tostring(message)
		local senderID, targetID,  msgType, msgBody = extractMainHeader(massage)
		if targetID ~= ID then
			if Switching == false then
				goto continue_net
			end
			doSwitching()
			goto continue_net
		end
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
		::continue_net::
	end
end
function localruning()
	while true do
		local event, alarmIDret = os.pullEvent("alarm")
		if osAlarmID == alarmIDret then
			--main loop of the computer
			
		osAlarmID = os.setAlarm(os.time() + osloop)
		end
	end
end

parallel.waitForAll(lisenNet, localruning)
