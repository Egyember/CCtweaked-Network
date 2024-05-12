network = require("mcnet")
network:init()
network.ID = "TEMP" --must be unique
osloop = 1 -- some number

function main()
	--localy runing code
	while true do
		sleep(osloop)
	end
end

function lisen()
	network:lisenNet() --main enty of the network lib
end

function doing()
	network:doingTasks() --optional required for the "do" protocol to work
end

parallel.waitForAny(lisen, doing, main)
