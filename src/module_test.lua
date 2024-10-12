local interpret = require("shitty")
local text = [[[
setvar myVariable string Hello, world!
out myVariable]]

interpret()(text)