local interpret = require("shitty")
local a = fs.open("helloworld.why","r")
local text = a.readAll()
a.close()

interpret()(text)