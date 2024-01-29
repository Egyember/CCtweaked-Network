--constants
ID = "base" --must be 4 char
switching = false
switchingBlacklist = "" --IDs not to switch (to avoid switching loops mosty cased by ender modem and wireless modem)
port = 41
osloop = 1
suportedREQs = "ECHO,SUPR,SUPD"
suportedDOs = ""
if init ~=nil then
	dofile "init.lua"
end
