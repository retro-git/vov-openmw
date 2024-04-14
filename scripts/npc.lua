local self = require('openmw.self')
local core = require('openmw.core')

local function onNewDialogueLine(data)
    local path = data.path
    core.sound.stopSay(self)
    core.sound.say(path, self)
end

local function onExitDialogue()
    core.sound.stopSay(self)
end

return {
    eventHandlers = {
        NewDialogueLine = onNewDialogueLine,
        ExitDialogue = onExitDialogue
    }
}