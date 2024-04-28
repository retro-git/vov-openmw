local core = require('openmw.core')
local types = require('openmw.types')
local vfs = require('openmw.vfs')
local self = require('openmw.self')

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
			if types.NPC.objectIsInstance(actor) == false and types.Creature.objectIsInstance(actor) == false then return end

			curActor = actor

			local actorId = nil
			local race = nil
			local sex = nil
			local factionId = nil
			local factionRank = nil

			if types.NPC.objectIsInstance(actor) then
				local npc = types.NPC.record(actor)
				actorId = npc.id
				race = npc.race
				sex = getActorSex(npc.isMale)
				local factions = types.NPC.getFactions(actor)
				factionId = factions and factions[1]
				factionRank = factionId and types.NPC.getFactionRank(self, factionId)

				if (factionRank == 0 or factionRank == nil)
				then
					factionRank = nil
				else 
					factionRank = factionRank - 1
				end
			elseif types.Creature.objectIsInstance(actor) then
				local creature = types.Creature.record(actor)
				actorId = creature.id
			end

            local path = getVoicePath(race, sex, infoId, actorId, factionId, factionRank)

            if (isPathValid(path)) then
                actor:sendEvent("NewDialogueLine", {path = path})
				print("Voice file: " .. path)
            else
                print("Voice file not found: " .. infoId .. ".mp3")
				actor:sendEvent("ExitDialogue")
            end
        end,
    },

    eventHandlers = {
        UiModeChanged = function(data)
            if data.oldMode == "Dialogue" and curActor ~= nil then
                print(curActor:sendEvent("ExitDialogue"))
            end
        end,
    }
}