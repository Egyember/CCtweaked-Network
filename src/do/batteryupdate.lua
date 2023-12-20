local fueldir = "down"
local numberOfBatterys = 6 --[0:9]

local function getBatteryData()
	local perNames = peripheral.getNames()
	local cap = 0
	local maxcap = 0
	for i = 1, #perNames do
		local type1, type2 = peripheral.getType(perNames[i])
		if  type2 == "energy_storage" then
			cap = cap + peripheral.call(perNames[i], "getEnergy")
			maxcap = maxcap + peripheral.call(perNames[i], "getEnergyCapacity")
		end
	end
	return cap , maxcap
end

local function refuel()
	if fueldir == "down" then
		turtle.suckDown()
	elseif fueldir == "up" then
		turtle.suckUp()
	end
	turtle.refuel()
end

local function sampleEnergy()
	if turtle.getFuelLevel() < 1000 then
		refuel()
	end
	local capSum = 0
	local maxcapSum = 0
	local lastsuc
	for i = 1, numberOfBatterys do
		local cap , maxcap = getBatteryData()
		capSum = capSum + cap
		maxcapSum = maxcapSum + maxcap
		turtle.forward()
		lastsuc = turtle.forward()
	end
	--returning home
	local homeDist = numberOfBatterys *2
	if not lastsuc then
		homeDist = homeDist-1
	end
	for i = 1, homeDist do
		turtle.back()
	end
	return capSum, maxcapSum
end
charge, maxCharge = sampleEnergy()

