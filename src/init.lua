
init = true
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

