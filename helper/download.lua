shell.run("wget https://github.com/Egyember/CCtweaked-Network/raw/turtle(battery)/src/base.lua")
shell.run("wget https://github.com/Egyember/CCtweaked-Network/raw/turtle(battery)/src/stack.lua")
shell.run("wget https://github.com/Egyember/CCtweaked-Network/raw/turtle(battery)/src/startup.lua")
fs.makeDir("/do")
shell.run("wget https://github.com/Egyember/CCtweaked-Network/raw/turtle(battery)/src/do/batteryUpdate.lua")
shell.run("mv batteryupdate.lua /do/")
shell.run("wget https://github.com/Egyember/CCtweaked-Network/raw/turtle(battery)/src/do/returnHome.lua")
shell.run("mv returnHome.lua /do/")
