local network = {}
function network:init()
	--global veriabels self:ID = "base" --must be 4 char
	self.switching = false
	self.switchingBlacklist = "" --IDs not to switch (to avoid switching loops mosty cased by ender modem and wireless modem)
	self.port = 41
	self.osloop = 1
	self.suportedREQs = "ECHO,SUPR,SUPD,DOIN"
	self.suportedDOs = ""
	self.switchingTable = {}
	self.debug = false
	self.doing = true -- true at startup 
	self.context = {} --costume data stored in the network object for requests
	self.keys = {} -- setable variables over the network

	--init DO stack
	do
		local files = fs.list("/do")
		for i = 1, table.getn(files) do
			if i == 1 then
				self.suportedDOs = self.suportedDOs .. string.sub(files[i],1,-5)
			else
				self.suportedDOs = self.suportedDOs .. "," .. string.sub(files[i],1,-5)
			end
		end
		print("suportedDOs: " .. self.suportedDOs)
	end

	--init requests
	do
		local files = fs.list("/req")
		for i = 1, table.getn(files) do
			self.suportedREQs = self.suportedREQs .. "," .. string.sub(files[i],1,-5)
		end
		print("suportedREQs: " .. self.suportedREQs)
	end

	-- finding modems and wraping them
	do
		self.modems = {}
		self.modemSides = {}
		local perNames = peripheral.getNames()
		for i = 1 , #perNames, 1 do
			if peripheral.getType(perNames[i]) == "modem" then
				self.modemSides[#self.modemSides +1] = perNames[i]
			end
		end
		for i = 1, #self.modemSides do
			self.modems[self.modemSides[i]] = peripheral.wrap(self.modemSides[i])
		end
		--init modems
		for i = 1, #self.modemSides do
			self.modems[self.modemSides[i]].open(self.port)
		end
	end
	--do stack init
	self.doStack = {}

	function self.doStack:push(item)
		table.insert(self, item) 
	end

	function self.doStack:pop()
		return table.remove(self)
	end

	-- request id generation
	self.lastReqID = 0
	function self:getReqID()
		if self.lastReqID == 9999 then
			self.lastReqID = 0
			return "0000"
		end
		self.lastReqID = self.lastReqID + 1
		return string.format("%04d", self.lastReqID)
	end

	function self:addSwitchingTable(senderID, side)
		self.switchingTable[senderID] = side	
	end

	function self:doSwitching(side, targetID, msg)
		local targetSide = self.switchingTable[targetID]
		if targetSide == nil then
			for i = 1 , #self.modemSides do
				if self.modemSides[i] ~= side then
					self.modems[self.modemSides[i]].transmit(self.port, self.port, msg)
				end
			end
		elseif targetSide ~= side then
			print(targetSide)
			self.modems[targetSide].transmit(self.port, self.port, msg)
		end
	end

	function self:extractMainHeader(msg)
		--print("extractMainHeader called with " .. msg)
		local senderID = string.sub(msg, 1, 4)
		local targetID = string.sub(msg, 5, 8)
		local msgType = string.sub(msg, 9, 9)
		local msgBody = string.sub(msg, 10,-1)
		return senderID, targetID, msgType, msgBody
	end


	function self:makeSendMsg(targetID, msgType, msg)
		local massage = self.ID .. targetID .. msgType .. msg
		local targetSide = self.switchingTable[targetID]
		if self.debug then
			print("targetID: " .. targetID)
			print("msgType: " .. msgType )
			print("msg: " .. msg)
			if targetSide ~= nil then
				print("targetSide: " .. targetSide)
			else
				print("targetSide: nil")
			end
		end
		if targetSide == nil then
			for i = 1 , #self.modemSides do
				self.modems[self.modemSides[i]].transmit(self.port, self.port, massage)
			end
		else
			self.modems[targetSide].transmit(self.port, self.port, massage)
		end
	end

	function self:extractRequestHeader(msg)
		local msgID = string.sub(msg, 1,4)
		local msgType = string.sub(msg, 5,8)
		local msgBody = string.sub(msg, 9,-1)
		return msgID, msgType, msgBody
	end

	--todo input validation
	function self:mkReq(msgID, msgType, msgBody)
		if msgBody == nil then
			msgBody = ""
		end
		return msgID .. msgType .. msgBody
	end

	function self:request(msg,  senderID)
		--handle requests (general header striped)	
		--todo: refactor into a table for performance
		local msgID, msgType, msgBody = self:extractRequestHeader(msg)
		if self.debug then
			print("msgID: " .. msgID .. "\nmsgType: " .. msgType .. "\nmsgBody: " .. msgBody)
		end
		if msgType == "ECHO" then
			self:makeSendMsg(senderID, "A", self:mkAns(msgID, msgBody))
		elseif msgType == "SUPR" then
			self:makeSendMsg(senderID, "A", self:mkAns(msgID, self.suportedREQs))	
		elseif msgType == "SUPD" then
			self:makeSendMsg(senderID, "A", self:mkAns(msgID, self.suportedDOs))	
		elseif msgType == "DOIN" then
			self:makeSendMsg(senderID, "A", self:mkAns(msgID, tostring(self.doing)))	
		else
			if msgType ~= nil then --costum requests
				local PATH = "/req/".. msgType ..".lua"--do the tasks
				if fs.exists(PATH) then
					local userFucntion = dofile(PATH)
					self:makeSendMsg(senderID, "A", self:mkAns(msgID, userFucntion[msgType](msgBody, self.context)))	
				else
					print("request don't exits " .. PATH)
				end
			end
		end
	end

	function self:extractAnswerHeader(msg)
		local msgID = string.sub(msg, 1,4)
		local msgBody = string.sub(msg, 5, -1) 
		return msgID, msgBody
	end

	--todo input validation
	function self:mkAns(msgID, msgBody)
		return msgID .. msgBody
	end

	function self:addDo(msg)
		self.doStack:push(msg)	
	end

	function self:setValue(msg)
		if msg == nil then
			return 
		end
		--key:value;key2:value2
		local function split (inputstr, sep) --https://stackoverflow.com/questions/1426954/split-string-in-lua
			if sep == nil then
				sep = "%s"
			end
			local t={}
			for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
				table.insert(t, str)
			end
			return t
		end
		local pair = split(msg, ";")
		for i,v in iparis(pair) do
			local t = split(v, ":")
			self.keys[t[i]] = t[2]
		end
	end

	function self:getValue(key)
		return self.keys[key]
	end

	function self:lisenNet()
		while true do
			local event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
			if self.debug then
				print("got msg: " .. massage)
			end
			local senderID, targetID,  msgType, msgBody = self:extractMainHeader(massage)
			self:addSwitchingTable(senderID, side)
			if targetID == self.ID then
				if msgType == "R" then
					--handle requests
					self:request(msgBody, senderID)
				elseif msgType == "D" then
					--handle do
					self:addDo(msgBody)
				elseif msgType == "S" then
					--handle set
					self:setvalue(msgBody)
				end
			else
				if self.switching == true then
					if not string.find(self.switchingBlacklist, senderID)then
						self:doSwitching(side, targetID, massage)
					end
				end
			end
		end
	end

	function self:doingTasks()
		while true do
			local task = self.doStack:pop()
			if task ~= nil then
				self.doing = true
				local PATH = "/do/".. task ..".lua"--do the tasks
				if fs.exists(PATH) then
					local userFucntion = dofile(PATH)
					userFucntion[task](self.context)
				else
					print("task don't exits " .. PATH)
				end
			else
				self.doing = false
				sleep(10)
			end
		end
	end

	function self:requestAllInOne(targetID, reqType, payload)
		if payload == nil then
			payload = ""
		end
		local msgID = self:getReqID()
		self:makeSendMsg(targetID, "R",self:mkReq(msgID, reqType, payload))
		local retMsgID, retMsgBody, distance = nil
		repeat
			local event , side, channel, replyChannel, massage
			event , side, channel, replyChannel, massage, distance = os.pullEvent("modem_message")
			local senderID, targetID, msgType, msgBody = self:extractMainHeader(massage)
			if targetID == self.ID and msgType == "A" then
				retMsgID, retMsgBody = self:extractAnswerHeader(msgBody)
			end
		until(msgID == retMsgID)
		return retMsgBody, distance
	end

	function self:ping(targetID)
		--generating payload
		local payload = string.format("%05d", math.floor(math.random()*10000))
		--sending ping
		print("sending ping")
		local retMsgBody, distance = nil
		local function pinging()
			retMsgBody, distance = self:requestAllInOne(targetID, "ECHO", payload)
		end
		local function sleep5()
			sleep(5)
			print("timeout")
		end
		parallel.waitForAny(pinging, sleep5)
		if payload == retMsgBody then
			print("succsesfull ping")
			return true, distance
		end
		print("corrup return / bug")
		return false, -1
	end

end

return network
