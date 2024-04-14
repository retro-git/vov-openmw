local core = require('openmw.core')
local types = require('openmw.types')
local vfs = require('openmw.vfs')

local basePath = "Sound/Vo/AIV"
local curActor = nil

local function getActorSex(isMale)
	if isMale then return "m" else return "f" end
end

local function isPathValid(path)
	return vfs.fileExists(path)
end

local function constructVoicePath(race, sex, infoId, actorId, factionId, factionRank)
	local path = basePath
	if (race) then
		path = path .. "/" .. race
	else
		path = path .. "/creature"
	end
	if (sex) then
		path = path .. "/" .. sex
	end
	if (actorId) then
		path = path .. "/" .. actorId
	end
	if (factionId) then
		path = path .. "/" .. factionId
	end
	if (factionRank and factionRank >= 0) then
		path = path .. "/" .. factionRank
	end
	if (infoId) then
		path = path .. "/" .. infoId .. ".mp3"
	end
	return path
end

local function getVoicePath(race, sex, infoId, actorId, factionId, factionRank)
	-- Check the most specific path first.
	local primaryPath = constructVoicePath(race, sex, infoId, actorId, factionId, factionRank)
	if (isPathValid(primaryPath)) then return primaryPath end

	-- Find every possible fallback path.
	local secondaryPaths = {
		constructVoicePath(race, sex, infoId, actorId, factionId, nil),
		constructVoicePath(race, sex, infoId, actorId, nil, nil),
		constructVoicePath(race, sex, infoId, nil, factionId, factionRank),
		constructVoicePath(race, sex, infoId, nil, factionId, nil),
		constructVoicePath(race, sex, infoId, nil, nil, nil),
		constructVoicePath(nil, nil,  infoId, actorId, factionId, factionRank),
		constructVoicePath(nil, nil,  infoId, actorId, factionId, nil),
		constructVoicePath(nil, nil, infoId, actorId, nil, nil),
		constructVoicePath(nil, nil,  infoId, nil, factionId, factionRank),
		constructVoicePath(nil, nil,  infoId, nil, factionId, nil),
		constructVoicePath(nil, nil, infoId, nil, nil, nil)
	}

	-- Return the first path in the list that is valid.
	for ix, path in pairs(secondaryPaths) do
		if (isPathValid(path)) then
			return path
		end
	end

	-- If there's no line, return the most specific path for logging purposes.
	return primaryPath
end

return {
    engineHandlers = {
        onInfoGetText = function(actor, infoId)
            curActor = actor

            print("onInfoGetText: " .. infoId)
            local npc = types.NPC.record(actor)
            local sex = getActorSex(npc.isMale)
            local factions = types.NPC.getFactions(actor)
            local factionId = factions and factions[1]
            local factionRank = factionId and types.NPC.getFactionRank(actor, factionId)

            local path = getVoicePath(npc.race, sex, infoId, npc.id, factionId, factionRank)

            if (isPathValid(path)) then
                core.sound.stopSay(actor)
                core.sound.say(path, actor)
            else
                print("Voice file not found: " .. path)
            end
        end,

        onDialogueMenuClose = function()
            if (curActor) then
                core.sound.stopSay(curActor)
            end

            curActor = nil
        end
    }
}