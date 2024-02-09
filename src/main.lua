network = require("mcnet")
network:init()
network.ID ="FUEL"
function lisenNet()
    network:lisenNet()
end
function doingTask()
    network:doingTasks()
end
parallel.waitForAll(lisenNet, doingTask)
