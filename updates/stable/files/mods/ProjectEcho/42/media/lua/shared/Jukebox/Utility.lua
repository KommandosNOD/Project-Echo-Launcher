require "Jukebox/Sound"
-- RM_ServerCompatPatch: TrueMusicJukebox Objects server guard
-- On a dedicated server this require currently fails in B42.21.
-- Skip only that failed server-side call; clients/SP keep the original require.
if not (isServer and isServer()) then
    require("Jukebox/Objects")
end

local Jukebox = {}

local JukeboxSound = require("Jukebox/Sound")

Jukebox.version = 7

Jukebox.translation = {
	playNow = getText("UI_TrueMusicJukebox_playNow"),
	playNext = getText("UI_TrueMusicJukebox_playNext"),
	playLast = getText("UI_TrueMusicJukebox_playLast"),
	viewPlaylist = getText("UI_TrueMusicJukebox_viewPlaylist"),
	viewQueue = getText("UI_TrueMusicJukebox_viewQueue"),
	lockQueue = getText("UI_TrueMusicJukebox_lockQueue"),
	unlockQueue = getText("UI_TrueMusicJukebox_unlockQueue"),
	nowPlaying = getText("UI_TrueMusicJukebox_nowPlaying"),
	turnOnJukebox = getText("UI_TrueMusicJukebox_turnOnJukebox"),
	turnOffJukebox = getText("UI_TrueMusicJukebox_turnOffJukebox"),
	setJukeboxVolume = getText("UI_TrueMusicJukebox_setJukeboxVolume"),
	jukeboxMainMenu = getText("UI_TrueMusicJukebox_jukeboxMainMenu"),
	playLoadedTracks = getText("UI_TrueMusicJukebox_playLoadedTracks"),
	shuffleLoadedTracks = getText("UI_TrueMusicJukebox_shuffleLoadedTracks"),
	playRandomTrack = getText("UI_TrueMusicJukebox_playRandomTrack"),
	replayCurrentTrack = getText("UI_TrueMusicJukebox_replayCurrentTrack"),
	replayLastTrack = getText("UI_TrueMusicJukebox_replayLastTrack"),
	skipCurrentTrack = getText("UI_TrueMusicJukebox_skipCurrentTrack"),
	showCurrentTrack = getText("UI_TrueMusicJukebox_showCurrentTrack"),
	ejectCurrentTrack = getText("UI_TrueMusicJukebox_ejectCurrentTrack"),
	ejectTrack = getText("UI_TrueMusicJukebox_ejectTrack"),
	dequeueTrack = getText("UI_TrueMusicJukebox_dequeueTrack"),
	statusReport = getText("UI_TrueMusicJukebox_statusReport"),
	portableJukeboxKeys = getText("UI_TrueMusicJukebox_portableJukeboxKeys"),
	enablePortableJukeboxKey = getText("UI_TrueMusicJukebox_enablePortableJukeboxKey"),
	disablePortableJukeboxKey = getText("UI_TrueMusicJukebox_disablePortableJukeboxKey"),
	renameJukebox = getText("UI_TrueMusicJukebox_renameJukebox"),
	grabManual = getText("UI_TrueMusicJukebox_grabManual"),
	extraTrueMusic = getText("UI_TrueMusicJukebox_extraTrueMusic"),
	everyTrack = getText("UI_TrueMusicJukebox_everyTrack"),
	extraTracks = getText("UI_TrueMusicJukebox_extraTracks"),
	uniqueTracks = getText("UI_TrueMusicJukebox_uniqueTracks"),

	renameKeyBelow = getText("UI_TrueMusicJukebox_feedback_renameKeyBelow"),
	cannotReadLoadedItem = getText("UI_TrueMusicJukebox_feedback_cannotReadLoadedItem"),
	isCurrentlyPlaying = getText("UI_TrueMusicJukebox_feedback_isCurrentlyPlaying"),
	willNeedGenerator = getText("UI_TrueMusicJukebox_feedback_willNeedGenerator"),
	noMusicInJukebox = getText("UI_TrueMusicJukebox_feedback_noMusicInJukebox"),
	unreachableJukebox = getText("UI_TrueMusicJukebox_feedback_unreachableJukebox"),
	restarting = getText("UI_TrueMusicJukebox_feedback_restarting"),
	playing = getText("UI_TrueMusicJukebox_feedback_playing"),
	skippedPriorSong = getText("UI_TrueMusicJukebox_feedback_skippedPriorSong"),
	queueLocked = getText("UI_TrueMusicJukebox_feedback_queueLocked"),
	queueUnlocked = getText("UI_TrueMusicJukebox_feedback_queueUnlocked"),
	removedFromQueue = getText("UI_TrueMusicJukebox_feedback_removedFromQueue"),
	songsNoLongerRemovedAutomatically = getText("UI_TrueMusicJukebox_feedback_songsNoLongerRemovedAutomatically"),
	songsRemovedAutomatically = getText("UI_TrueMusicJukebox_feedback_songsRemovedAutomatically"),
	shuffleToClearQueue = getText("UI_TrueMusicJukebox_feedback_shuffleToClearQueue"),
	randomlySelected = getText("UI_TrueMusicJukebox_feedback_randomlySelected"),
	trackWillPlayNow = getText("UI_TrueMusicJukebox_feedback_trackWillPlayNow"),
	allTracksShuffled = getText("UI_TrueMusicJukebox_feedback_allTracksShuffled"),
	movingTooFast = getText("UI_TrueMusicJukebox_feedback_movingTooFast"),
	changeModID = getText("UI_TrueMusicJukebox_feedback_changeModID"),
	cannotCloseThis = getText("UI_TrueMusicJukebox_feedback_cannotCloseThis"),

	jukeboxHero = getText("UI_TrueMusicJukebox_jukeboxHero"),
	jukeboxHeroTooltip = getText("UI_TrueMusicJukebox_jukeboxHero_tooltip"),

	pageTitle = getText("UI_TrueMusicJukebox_options_pageTitle"),

	mainVolume = getText("UI_TrueMusicJukebox_options_mainVolume"),
	mainVolumeTooltip = getText("UI_TrueMusicJukebox_options_mainVolume_tooltip"),
	mainVolumeBoost = getText("UI_TrueMusicJukebox_options_mainVolumeBoost"),
	mainVolumeBoostTooltip = getText("UI_TrueMusicJukebox_options_mainVolumeBoost_tooltip"),
	blockTrueMusicJukeboxSound = getText("UI_TrueMusicJukebox_options_blockTrueMusicJukeboxSound"),
	blockTrueMusicJukeboxSoundTooltip = getText("UI_TrueMusicJukebox_options_blockTrueMusicJukeboxSound_tooltip"),
	hideMenuIcons = getText("UI_TrueMusicJukebox_options_hideMenuIcons"),
	hideMenuIconsTooltip = getText("UI_TrueMusicJukebox_options_hideMenuIcons_tooltip"),
	hideTracklistFromContextMenu = getText("UI_TrueMusicJukebox_options_hideTracklistFromContextMenu"),
	hideTracklistFromContextMenuTooltip = getText("UI_TrueMusicJukebox_options_hideTracklistFromContextMenu_tooltip"),
	showEveryTrackInPortablePlaylist = getText("UI_TrueMusicJukebox_options_showEveryTrackInPortablePlaylist"),
	showEveryTrackInPortablePlaylistTooltip = getText("UI_TrueMusicJukebox_options_showEveryTrackInPortablePlaylist_tooltip"),
	showEveryTrackInJukeboxPlaylist = getText("UI_TrueMusicJukebox_options_showEveryTrackInJukeboxPlaylist"),
	showEveryTrackInJukeboxPlaylistTooltip = getText("UI_TrueMusicJukebox_options_showEveryTrackInJukeboxPlaylist_tooltip"),
	showEveryTrackInJukeboxQueue = getText("UI_TrueMusicJukebox_options_showEveryTrackInJukeboxQueue"),
	showEveryTrackInJukeboxQueueTooltip = getText("UI_TrueMusicJukebox_options_showEveryTrackInJukeboxQueue_tooltip"),
	threeDimensionalAudio = getText("UI_TrueMusicJukebox_options_threeDimensionalAudio"),
	threeDimensionalAudioTooltip = getText("UI_TrueMusicJukebox_options_threeDimensionalAudio_tooltip"),
	invertToggleIconFeedback = getText("UI_TrueMusicJukebox_options_invertToggleIconFeedback"),
	invertToggleIconFeedbackTooltip = getText("UI_TrueMusicJukebox_options_invertToggleIconFeedback_tooltip"),
	ignoreDistanceWhenPlayingOverride = getText("UI_TrueMusicJukebox_options_ignoreDistanceWhenPlayingOverride"),
	ignoreDistanceWhenPlayingOverrideTooltip = getText("UI_TrueMusicJukebox_options_ignoreDistanceWhenPlayingOverride_tooltip"),
	considerDistanceWhenPlayingOverride = getText("UI_TrueMusicJukebox_options_considerDistanceWhenPlayingOverride"),
	considerDistanceWhenPlayingOverrideTooltip = getText("UI_TrueMusicJukebox_options_considerDistanceWhenPlayingOverride_tooltip"),
	alwaysTellMyFriends = getText("UI_TrueMusicJukebox_options_alwaysTellMyFriends"),
	alwaysTellMyFriendsTooltip = getText("UI_TrueMusicJukebox_options_alwaysTellMyFriends_tooltip"),
	hideTransferAllTrueMusic = getText("UI_TrueMusicJukebox_options_hideTransferAllTrueMusic"),
	hideTransferAllTrueMusicTooltip = getText("UI_TrueMusicJukebox_options_hideTransferAllTrueMusic_tooltip"),
	dancingComesFirst = getText("UI_TrueMusicJukebox_options_dancingComesFirst"),
	dancingComesFirstTooltip = getText("UI_TrueMusicJukebox_options_dancingComesFirst_tooltip"),
	feedbackAccessibilityMode = getText("UI_TrueMusicJukebox_options_feedbackAccessibilityMode"),
	feedbackAccessibilityModeTooltip = getText("UI_TrueMusicJukebox_options_feedbackAccessibilityMode_tooltip"),
	accessibilityModeDisplayTime = getText("UI_TrueMusicJukebox_options_accessibilityModeDisplayTime"),
	accessibilityModeDisplayTimeTooltip = getText("UI_TrueMusicJukebox_options_accessibilityModeDisplayTime_tooltip"),
}

Jukebox.options = {
	hideMenuIcons = false,
	invertToggleIconFeedback = false,
	hideTracklistFromContextMenu = false,
	showEveryTrackInPortablePlaylist = false,
	showEveryTrackInJukeboxPlaylist = false,
	showEveryTrackInJukeboxQueue = false,
	threeDimensionalAudio = false,
	ignoreDistanceWhenPlayingOverride = false,
	considerDistanceWhenPlayingOverride = false,
	blockTrueMusicJukeboxSound = false,
	alwaysTellMyFriends = false,
	hideTransferAllTrueMusic = false,
	dancingComesFirst = false,
	requireMusicForLifestyleDance = false,
	feedbackAccessibilityMode = false,
	accessibilityModeDisplayTime = 4
}

-- Lifestyle Compatibility
Jukebox.volumeMutedForLifestyle = {}

-- For storing active jukebox data based on location keys as well as song data.
Jukebox.activeLocations = {}
Jukebox.activeTracks = {}
Jukebox.keyRing = {}

-- Default if not set by SandboxVars.
Jukebox.maxRange = 50

-- Number of batches for updating sound.
-- New jukeboxes are randomly assigned a batch number from 1 to batches (below).
-- OnTick, if the jukebox's batch number is up, it will update. This makes it so that
-- a server running 10 jukeboxes will not update them all on the same tick, but on unique ticks.
-- Running hundreds of jukeboxes would start to require more than one jukebox to update per tick, 
-- but this should be manageable within reason, and much more manageable than the alternative of 
-- updating every jukebox on the same tick.
Jukebox.batches = 10

-- Cycles from 1 - batches during updateSound.
Jukebox.batchIndex = Jukebox.batches

-- Arrays used for applying jukebox effects to players.
Jukebox.ticksSinceEffectsApplied = {}

-- Buffer to slow rate of recovering by listening to music.
-- Jukebox.ticksBeforeEffectsReapplied = 2000
Jukebox.ticksBeforeEffectsReapplied = 100

-- Table of dancing players.
Jukebox.dancing = {}

-- Transferring Playable True Music Tracks
Jukebox.unplayableTrueMusicItem = {
	["CassetteStack"] = true, ["CassetteBox"] = true, ["CassetteCache"] = true, ["BlankCassette"] = true,
	["VinylStack"] = true, ["VinylBox"] = true, ["VinylCache"] = true, ["BlankVinyl"] = true
}

-- Looting Playable True Music Tracks
Jukebox.blankTrueMusicItem = {
	["BlankCassette"] = true, ["BlankVinyl"] = true
}

-- Nonlinear volume magic.
Jukebox.volumes = {
	[1] = 0.00,
	[2] = 0.02,
	[3] = 0.07,
	[4] = 0.15,
	[5] = 0.25,
	[6] = 0.40,
	[7] = 0.50,
	[8] = 0.60,
	[9] = 0.70,
	[10] = 0.80,
	[11] = 0.90,
	[12] = 1.00
}

Jukebox.volumesIndex = {
	[Jukebox.volumes[1]] = 1,
	[Jukebox.volumes[2]] = 2,
	[Jukebox.volumes[3]] = 3,
	[Jukebox.volumes[4]] = 4,
	[Jukebox.volumes[5]] = 5,
	[Jukebox.volumes[6]] = 6,
	[Jukebox.volumes[7]] = 7,
	[Jukebox.volumes[8]] = 8,
	[Jukebox.volumes[9]] = 9,
	[Jukebox.volumes[10]] = 10,
	[Jukebox.volumes[11]] = 11,
	[Jukebox.volumes[12]] = 12
}

-- Client-Server Packet Commands

-- These are commands embedded in packets that won't be stored
-- in the jukeboxData referenced by said packets; they are used
-- to trigger events either clientside or serverside.
Jukebox.command = {
	afterSync = true,
	enqueue = true,
	dequeue = true,
	remove = true,
	increaseIndex = true,
	decreaseIndex = true,
	enqueueIndex = true,
	-- For Shuffling
	startIndex = true,
	shuffleJump = true,
	-- Last three exclusively for making generic commands unique.
	targetIndex = true,
	priorTrack = true,
	nextTrack = true 
}

-- Process results of sync commands. Needs to happen separately
-- on client and server to maximize speed.
Jukebox.process = function(jukeboxData, packet)

	if packet.remove then
		Jukebox.removeTrack(jukeboxData, packet.remove)
	end
	
	if packet.enqueue then
		Jukebox.enqueueTrack(jukeboxData, packet.enqueue, packet.enqueueIndex)
	elseif packet.dequeue then
		Jukebox.dequeueTrack(jukeboxData, packet.dequeue)
	end
	
	if packet.increaseIndex then
		Jukebox.increaseIndex(jukeboxData)
		if packet.afterSync and #jukeboxData.queue > 0 and not jukeboxData.queueLocked then
			local priorTrack = Jukebox.getPriorTrack(jukeboxData)
			Jukebox.dequeueTrack(jukeboxData, priorTrack)
		end
	elseif packet.decreaseIndex then
		Jukebox.decreaseIndex(jukeboxData)
	end
	
	return packet.afterSync

end

-- Time of Day Conversion Factor
Jukebox.realHoursPerDayIndex = {
	[1] = 0.25, [2] = 0.50, [3] = 1, [4] = 2, [5] = 3, 
	[6] = 4, [7] = 5, [8] = 6, [9] = 7, [10] = 8, [11] = 9, 
	[12] = 10, [13] = 11, [14] = 12, [15] = 12, [16] = 14, 
	[17] = 15, [19] = 16, [20] = 17, [21] = 18, [22] = 19, 
	[23] = 20, [24] = 21, [25] = 22, [26] = 23, [27] = 24
}

Jukebox.getTime = function() 
	return GameTime.getInstance():getTimeOfDay()
end

-- In this mod:
-- position => float x, y, z
-- location => floored { x, y, z } (as a table where [x] = floored x coordinate)
-- key => floored "x, y, z" (as a string with spaces)
Jukebox.dataToKey = function(jukeboxData)
	if not jukeboxData then return end

	local x = math.floor(jukeboxData.x)
	local y = math.floor(jukeboxData.y)
	local z = math.floor(jukeboxData.z)

	return x .. ", " .. y .. ", " .. z
end

Jukebox.squareToKey = function(square)
	if not square then return end

	local x = math.floor(square:getX())
	local y = math.floor(square:getY())
	local z = math.floor(square:getZ())

	return x .. ", " .. y .. ", " .. z
end

Jukebox.keyToLocation = function(key)
	if not key then return end

	local xyz = string.split(key, ", ")

	local x = tonumber(xyz[1])
	local y = tonumber(xyz[2])
	local z = tonumber(xyz[3])

	return { x = x, y = y, z = z } 
end

-- Icon Stuff

Jukebox.getIcon = function(optionTag)
	if Jukebox.options.hideMenuIcons then return end

	if optionTag == "Main Menu"  then
		return getTexture("media/ui/TrueMusicJukebox/machine.png")
	elseif optionTag == "Rename Jukebox" then
		return getTexture("media/ui/TrueMusicJukebox/rename.png")
	elseif optionTag == "On"  then
		if Jukebox.options.invertToggleIconFeedback then
			-- When the jukebox is able to be turned ON (meaning the jukebox is OFF), the image will be ON.
			return getTexture("media/ui/TrueMusicJukebox/on.png")
		else
			-- When the jukebox is able to be turned ON, the image (and jukebox) will be OFF.
			return getTexture("media/ui/TrueMusicJukebox/off.png")
		end
	elseif optionTag == "Off"  then
		if Jukebox.options.invertToggleIconFeedback then
			-- When the jukebox is able to be turned OFF (meaning the jukebox is ON), the image will be OFF.
			return getTexture("media/ui/TrueMusicJukebox/off.png")
		else
			-- When the jukebox is able to be turned OFF, the image (and jukebox) will be ON.
			return getTexture("media/ui/TrueMusicJukebox/on.png")
		end
	elseif optionTag == "Playlist"  then
		return getTexture("media/ui/TrueMusicJukebox/playlist.png")
	elseif optionTag == "Queue" then
		return getTexture("media/ui/TrueMusicJukebox/queue.png")
	elseif optionTag == "Locked Queue" then
		return getTexture("media/ui/TrueMusicJukebox/looping.png")
	elseif optionTag == "Volume" then
		return getTexture("media/ui/TrueMusicJukebox/volume.png")
	elseif optionTag == "Play Now" then
		return getTexture("media/ui/TrueMusicJukebox/now.png")
	elseif optionTag == "Play Next" then
		return getTexture("media/ui/TrueMusicJukebox/next.png")
	elseif optionTag == "Play Last" then
		return getTexture("media/ui/TrueMusicJukebox/last.png")
	elseif optionTag == "Lock Queue" then
		if Jukebox.options.invertToggleIconFeedback then
			return getTexture("media/ui/TrueMusicJukebox/unlockable.png")
		else
			return getTexture("media/ui/TrueMusicJukebox/lockable.png")
		end
	elseif optionTag == "Unlock Queue" then
		if Jukebox.options.invertToggleIconFeedback then
			return getTexture("media/ui/TrueMusicJukebox/lockable.png")
		else
			return getTexture("media/ui/TrueMusicJukebox/unlockable.png")
		end
	elseif optionTag == "Skip Current" then
		return getTexture("media/ui/TrueMusicJukebox/forward.png")
	elseif optionTag == "Replay Current" then
		return getTexture("media/ui/TrueMusicJukebox/replay.png")
	elseif optionTag == "Replay Last" then
		return getTexture("media/ui/TrueMusicJukebox/back.png")
	elseif optionTag == "Dequeue" then
		return getTexture("media/ui/TrueMusicJukebox/dequeue.png")
	elseif optionTag == "Random" then
		return getTexture("media/ui/TrueMusicJukebox/random.png")
	elseif optionTag == "Shuffle" then
		return getTexture("media/ui/TrueMusicJukebox/shuffle.png")
	elseif optionTag == "Enable Key" then
		if Jukebox.options.invertToggleIconFeedback then
			return getTexture("media/ui/TrueMusicJukebox/enabled.png")
		else
			return getTexture("media/ui/TrueMusicJukebox/disabled.png")
		end
	elseif optionTag == "Disable Key" then
		if Jukebox.options.invertToggleIconFeedback then
			return getTexture("media/ui/TrueMusicJukebox/disabled.png")
		else
			return getTexture("media/ui/TrueMusicJukebox/enabled.png")
		end
	elseif optionTag == "Check Track" then
		return getTexture("media/ui/TrueMusicJukebox/information.png")
	elseif optionTag == "Check Status" then
		return getTexture("media/ui/TrueMusicJukebox/status.png")
	elseif optionTag == "Eject Track" then
		return getTexture("media/ui/TrueMusicJukebox/eject.png")
	elseif optionTag == "Dance" then
		return getTexture("media/ui/TrueMusicJukebox/dance.png")
	end
end

----------------------------------

Jukebox.addBatchedKey = function(key, batch)
	if not (key and batch) then return end

	local keyData = Jukebox.batchedKeyData[batch]

	if not keyData[key] then 
		keyData[key] = true -- location is now in the table
		keyData[#keyData + 1] = key
	end
end

Jukebox.removeBatchedKey = function(key, batch, index)
	if not (key and batch) then return end

	local keyData = Jukebox.batchedKeyData[batch]

	if keyData[key] then
		if index and keyData[index] == key then
			table.remove(keyData, index)
			keyData[key] = nil
			return
		end

		for index, value in ipairs(keyData) do
			if value == key then
				table.remove(keyData, index)
				keyData[key] = nil
				return
			end
		end 
	end
end
----------------------------------

Jukebox.initializeTimeVariables = function()
	if Jukebox.timeVariablesInitialized then return end

	Jukebox.timeVariablesInitialized = true

	-- Initialize realHoursPerDay
	Jukebox.realHoursPerDay = Jukebox.realHoursPerDayIndex[SandboxVars.DayLength]

	Jukebox.oneRealHalfSecond = (1 / 7200) * (24 / Jukebox.realHoursPerDay)
end

Jukebox.initializeKeyRing = function(player)
	if not player then return end

	local playerModData = player and player:getModData()

	playerModData.TrueMusicJukebox = playerModData.TrueMusicJukebox or {}
	
	playerModData.TrueMusicJukebox.keyRing = playerModData.TrueMusicJukebox.keyRing or {}
end

Jukebox.beginActiveTracks = function()
	if Jukebox.requestedActiveTracks then return end
	-- Initialize max range based on sandbox options.
	Jukebox.maxRange = SandboxVars.TrueMusicJukebox and SandboxVars.TrueMusicJukebox.maxRange or Jukebox.maxRange

	Jukebox.initializeTimeVariables()

	local JukeboxFeedback = require("Jukebox/Feedback")

	Jukebox.feedback = JukeboxFeedback:new(0, 60, { r = 0, g = 0, b = 0, a = 1 })

	-- Requests missing locations; updateSound will handle them eventually.
	if SandboxVars.TrueMusicJukebox.requestJukeboxDataOnConnect then
		-- Any player on this client is fine.
		sendClientCommand(getPlayer(), "TrueMusicJukebox", "request", {})
	else
		-- Skips this process.
		Jukebox.activeLocationsLoaded = true 
	end

	Jukebox.requestedActiveTracks = true
end

Jukebox.awaitClientCommandAbility = function(playerIndex, player)
	Jukebox.waitTicks = (Jukebox.waitTicks and (Jukebox.waitTicks - 1)) or 5

	if Jukebox.waitTicks == 5 then
		Jukebox.readSettings() -- Grab main volume settings and set variables appropriately.
		if isClient() then Jukebox.initializeKeyRing(player) end
		Events.OnTick.Add(Jukebox.awaitClientCommandAbility)
	elseif Jukebox.waitTicks == 0 then
		Jukebox.waitTicks = nil
		Events.OnTick.Remove(Jukebox.awaitClientCommandAbility)
		Jukebox.beginActiveTracks()
	end

	if not player then return end

	Jukebox.ticksSinceEffectsApplied[playerIndex] = Jukebox.ticksBeforeEffectsReapplied

	local playerStaticWeight = player:getModData().TrueMusicJukebox and player:getModData().TrueMusicJukebox.staticWeight

	if SandboxVars.TrueMusicJukebox.enableStaticPlayerHealth then
		
		if not playerStaticWeight then
			player:getModData().TrueMusicJukebox = player:getModData().TrueMusicJukebox or {}
			player:getModData().TrueMusicJukebox.staticWeight = player:getNutrition():getWeight()
		end
		
		if not Jukebox.staticHealthEventActivated then 
			Jukebox.staticHealthEventActivated = true
			Events.EveryDays.Add(Jukebox.applyStaticHealth)
		end

	elseif playerStaticWeight and not SandboxVars.TrueMusicJukebox.enableStaticPlayerHealth then
		-- Reset static weight to allow people to gain or lose weight again.
		player:getModData().TrueMusicJukebox.staticWeight = nil
	end
end

Events.OnCreatePlayer.Add(Jukebox.awaitClientCommandAbility)

Jukebox.processClientsideLocationData = function()
	if not isClient() then -- We're in singleplayer.
		Jukebox.keyRing = ModData.getOrCreate("Jukebox.keyRing")	
	end

	Jukebox.batchedKeyData = {}

	for index = 1, Jukebox.batches do
		Jukebox.batchedKeyData[index] = {}
	end
end

if not isServer() then Events.OnInitGlobalModData.Add(Jukebox.processClientsideLocationData) end

-- Checking for Game Sounds

Jukebox.getSoundFile = function(itemType)
	return itemType and GameSounds.getSound(itemType) and GameSounds.getSound(itemType):getRandomClip():getFile()
end

-- Jukebox Remote Key Management

Jukebox.addJukeboxKey = function(key, keyRing)
	Jukebox.removeJukeboxKey(key, keyRing)
	
	keyRing[key] = "Jukebox at " .. key

	table.insert(keyRing, key)
end

Jukebox.removeJukeboxKey = function(key, keyRing)
	if not keyRing[key] then return end

	for index, value in ipairs(keyRing) do
		if value == key then
			table.remove(keyRing, index)

			keyRing[key] = nil

			return index
		end
	end
end

Jukebox.getPortableKeys = function(player)
    if isClient() then
        Jukebox.initializeKeyRing(player)
        return player:getModData().TrueMusicJukebox.keyRing
    else
        return Jukebox.keyRing
    end
end

-- Track Utility Functions

Jukebox.itemTypeContains = function(item, name)
	name = string.lower(name)

    local simplifiedElementName = string.lower(item:getType()):gsub("%s+", ""):gsub("%-+","")

    -- :gsub("%s+", "") removes spaces from the string if it has any to remove and returns result.
    local elementHasGivenName = string.find(simplifiedElementName, name) ~= nil
   
    return elementHasGivenName
end

Jukebox.playableCassetteOrVinyl = function(item)
    return (Jukebox.itemTypeContains(item, "Cassette") or Jukebox.itemTypeContains(item, "Vinyl")) and 
		string.sub(item:getType(), 0, 2) ~= "TC" and not Jukebox.unplayableTrueMusicItem[item:getType()]
end

Jukebox.isOrHasCassetteOrVinyl = function(item)
    return (Jukebox.itemTypeContains(item, "Cassette") or Jukebox.itemTypeContains(item, "Vinyl")) and 
		string.sub(item:getType(), 0, 2) ~= "TC" and not Jukebox.blankTrueMusicItem[item:getType()]
end

Jukebox.prettyName = function(displayName)
	-- Example: Cassette - Michael Cassette - My Name Is Michael Cassette
	prettyName = displayName:gsub("Vinyl %-", "", 1) -- Remove first instance of the word Vinyl followed by a hyphen.
	prettyName = prettyName:gsub("Cassette %-", "", 1) -- Remove first instance of the word Cassette followed by a hyphen.
	prettyName = prettyName:gsub("Vinyl", "", 1) -- Remove first instance of the word Vinyl (if no "Vinyl -" found, this will be found).
	prettyName = prettyName:gsub("Cassette", "", 1) -- Remove first instance of the word Cassette (same as above for cassettes).
	prettyName = prettyName:gsub("^%s*(.-)%s*$", "%1") -- Remove leading and trailing whitespace.
	return prettyName --> Michael Cassette - My Name Is Michael Cassette
end

Jukebox.increaseIndex = function(jukeboxData)
	if #jukeboxData.queue > 0 then
		jukeboxData.queueIndex = jukeboxData.queueIndex % #jukeboxData.queue + 1
	else
		jukeboxData.playlistIndex = jukeboxData.playlistIndex % #jukeboxData.playlist + 1
	end
end

Jukebox.decreaseIndex = function(jukeboxData)
	if #jukeboxData.queue > 0 then
		jukeboxData.queueIndex = jukeboxData.queueIndex - 1 == 0 and #jukeboxData.queue or jukeboxData.queueIndex - 1
	else
		jukeboxData.playlistIndex = jukeboxData.playlistIndex - 1 == 0 and #jukeboxData.playlist or jukeboxData.playlistIndex - 1
	end
end

Jukebox.enqueueTrack = function(jukeboxData, trackType, index)
	local shift = Jukebox.dequeueTrack(jukeboxData, trackType) -- Always dequeue before enqueueing; never queue same track twice.
	
	index = index and index + shift or nil

	jukeboxData.queue[trackType] = true
	
	if index then
		table.insert(jukeboxData.queue, index, trackType)
	else
		table.insert(jukeboxData.queue, trackType)
	end
end

Jukebox.dequeueTrack = function(jukeboxData, trackType)
	local shift = 0
	if jukeboxData.queue[trackType] then
		jukeboxData.queue[trackType] = nil
		for index = 1, #jukeboxData.queue do
			if jukeboxData.queue[index] == trackType then
				if index < jukeboxData.queueIndex then
					jukeboxData.queueIndex = jukeboxData.queueIndex - 1
					shift = -1
				end
				table.remove(jukeboxData.queue, index)
				return shift
			end
		end
	end
	return shift
end

-- Add track to current playlist
Jukebox.insertTrack = function(jukeboxData, trackType, trackName, trackIndex) 
    local playlist = jukeboxData.playlist 

	trackIndex = trackIndex or (#playlist + 1)

	table.insert(jukeboxData.playlist, trackIndex, trackType)

	jukeboxData.playlist[trackType] = true

	-- Used to convert types to full names.

	if not trackName then return end

	jukeboxData.titles[trackType] = Jukebox.prettyName(trackName)
end

-- Remove trackType from playlist
Jukebox.removeTrack = function(jukeboxData, trackType)
    local playlist = jukeboxData.playlist
    if not (playlist and playlist[trackType]) then return end -- The playlist for this jukebox has never been created, or track isn't loaded.

	local currentPlaylistIndex = Jukebox.getPlaylistIndex(jukeboxData, trackType)
	local currentTrack = Jukebox.getCurrentTrack(jukeboxData)
    for playlistIndex, value in ipairs(playlist) do
        if value == trackType then
			jukeboxData.inventorySize = jukeboxData.inventorySize - 1 -- Attempt to avoid needless reset.

			local skipNeeded = false
			local shift = 0

			Jukebox.dequeueTrack(jukeboxData, trackType)
			
            table.remove(playlist, playlistIndex)

			playlist[trackType] = nil

			if playlistIndex < currentPlaylistIndex then 
				-- Tracks just shifted; fix current playlistIndex.
				-- currentIndex must be at least 2, or else this will not happen.
				jukeboxData.playlistIndex = currentPlaylistIndex - 1
			end

			if #jukeboxData.playlist == 0 then
				local key = Jukebox.dataToKey(jukeboxData)
				if Jukebox.activeTracks[key] and Jukebox.activeTracks[key].sound then
					Jukebox.activeTracks[key].sound:stop()
					Jukebox.activeTracks[key] = nil
				end
				if jukeboxData.on then
					local square = getSquare(jukeboxData.x, jukeboxData.y, jukeboxData.z)
					if square then square:playSound("LightSwitch") end
					jukeboxData.on = false
				end
				jukeboxData.hasPlayableTracks = false
			end

            return #jukeboxData.queue > 0 and queueIndex or playlistIndex
        end
    end
end

Jukebox.clearQueue = function(jukeboxData)

	if not jukeboxData then return end

	jukeboxData.queue = {}
	jukeboxData.queueIndex = 0

end

-------------------------
-- Last, Current, Next --
-------------------------
Jukebox.getPriorIndex = function(jukeboxData)
	local currentIndex = #jukeboxData.queue > 0 and jukeboxData.queueIndex or jukeboxData.playlistIndex
	local lastIndex = #jukeboxData.queue > 0 and #jukeboxData.queue or #jukeboxData.playlist
	return currentIndex - 1 == 0 and lastIndex or currentIndex - 1
end
Jukebox.getCurrentIndex = function(jukeboxData)
	local currentIndex = #jukeboxData.queue > 0 and jukeboxData.queueIndex or jukeboxData.playlistIndex
	return currentIndex
end
Jukebox.getNextIndex = function(jukeboxData)
	local currentIndex = #jukeboxData.queue > 0 and jukeboxData.queueIndex or jukeboxData.playlistIndex
	local size = #jukeboxData.queue > 0 and #jukeboxData.queue or #jukeboxData.playlist
	return (currentIndex % size) + 1
end
Jukebox.getPriorTrack = function(jukeboxData)
	local tracklist = #jukeboxData.queue > 0 and jukeboxData.queue or jukeboxData.playlist
	return tracklist[Jukebox.getPriorIndex(jukeboxData)]
end
Jukebox.getCurrentTrack = function(jukeboxData)
	local tracklist = #jukeboxData.queue > 0 and jukeboxData.queue or jukeboxData.playlist
	return tracklist[Jukebox.getCurrentIndex(jukeboxData)]
end
Jukebox.getNextTrack = function(jukeboxData)
	local tracklist = #jukeboxData.queue > 0 and jukeboxData.queue or jukeboxData.playlist
	return tracklist[Jukebox.getNextIndex(jukeboxData)]
end
Jukebox.getPriorTitle = function(jukeboxData)
	return jukeboxData.titles[Jukebox.getPriorTrack(jukeboxData)]
end
Jukebox.getCurrentTitle = function(jukeboxData)
	return jukeboxData.titles[Jukebox.getCurrentTrack(jukeboxData)]
end
Jukebox.getNextTitle = function(jukeboxData)
	return jukeboxData.titles[Jukebox.getNextTrack(jukeboxData)]
end
Jukebox.getPlaylistIndex = function(jukeboxData, trackType)
	if not (jukeboxData and trackType) then return end

	local array = jukeboxData.playlist

	if not array then return end

	if #array > 0 then
		for index, value in ipairs(array) do
			if value == trackType then return index end
		end
	end
end
Jukebox.getQueueIndex = function(jukeboxData, trackType)
	if not (jukeboxData and trackType) then return end

	local array = jukeboxData.queue

	if not array then return end

	if #array > 0 then
		for index, value in ipairs(array) do
			if value == trackType then return index end
		end
	end
end
Jukebox.getIndex = function(jukeboxData, trackType)
	if not (jukeboxData and trackType) then return end

	local array = #jukeboxData.queue > 0 and jukeboxData.queue or jukeboxData.playlist

	if not array then return end

	if #array > 0 then
		for index, value in ipairs(array) do
			if value == trackType then return index end
		end
	end
end

Jukebox.random = function(max)
    return ZombRand(max) + 1
end

Jukebox.shuffle = function(jukeboxData, packet)

	if not jukeboxData then return {} end

	local shuffleJump = packet.shuffleJump

	local startIndex = packet.startIndex

	local currentIndex = startIndex

	local currentTrack = Jukebox.getCurrentTrack(jukeboxData)

	local playlist = jukeboxData.playlist

	local playlistShuffled = {}
	
	while #playlist > 0 do
		playlistShuffled[#playlistShuffled + 1] = playlist[currentIndex]
		table.remove(playlist, currentIndex)
		if #playlist == 0 then break end
		local nextIndex = (currentIndex + shuffleJump) % #playlist + 1
        while #playlist > 5 and math.abs(nextIndex - currentIndex) < 3 do
            nextIndex = nextIndex % #playlist + 1
        end
		currentIndex = nextIndex
	end

	jukeboxData.playlist = playlistShuffled

	if jukeboxData.queueLocked then
		local queue = jukeboxData.queue

		local queueShuffled = {}

		-- Reduce to something that fits in queue. Jump size can stay the same.
		currentIndex = #queue > 0 and currentIndex % #queue + 1 or "trash" 
		
		while #queue > 0 do
			queueShuffled[#queueShuffled + 1] = queue[currentIndex]
			queueShuffled[queue[currentIndex]] = true
			table.remove(queue, currentIndex)
			if #queue == 0 then break end
			local nextIndex = (currentIndex + shuffleJump) % #queue + 1
			while #queue > 5 and math.abs(nextIndex - currentIndex) < 3 do
				nextIndex = nextIndex % #queue + 1
			end
			currentIndex = nextIndex
		end

		jukeboxData.queue = queueShuffled
	else
		Jukebox.clearQueue(jukeboxData)
	end

	if currentTrack then
		local newIndex = Jukebox.getIndex(jukeboxData, currentTrack) or 1
		
		if #jukeboxData.queue > 0 then
			jukeboxData.queueIndex = newIndex
			jukeboxData.playlistIndex = 1
		else
			jukeboxData.queueIndex = 0
			jukeboxData.playlistIndex = newIndex
		end
	end

end

Jukebox.initializePlaylist = function(jukebox, jukeboxData)

	local jukeboxItems = jukebox:getItemContainer():getItems()

	local key = Jukebox.dataToKey(jukeboxData)

	-- Making sure hasPlayableTracks is true will prevent this from spamming
	-- the network with transmit calls; clients will do this exactly once each at most before
	-- data will hopefully be synced. Some clients may never do this if another client fixes
	-- their data by network transfer before this event triggers.
	if jukeboxData.hasPlayableTracks and (not jukeboxItems or jukeboxItems:size() == 0) then 
		jukeboxData.playlist = {}
		jukeboxData.playlistIndex = 1
		jukeboxData.queue = {}
		jukeboxData.queueIndex = 0
		jukeboxData.inventorySize = 0
		jukeboxData.hasPlayableTracks = false

		sendClientCommand("TrueMusicJukebox", "sync", {
			key = key, hasPlayableTracks = jukeboxData.hasPlayableTracks, inventorySize = jukeboxData.inventorySize,
			playlist = jukeboxData.playlist, playlistIndex = jukeboxData.playlistIndex, 
			queue = jukeboxData.queue, queueIndex = jukeboxData.queueIndex
		})
		return 
	end

	-- If this playlist has the right size, we assume we're good; otherwise we recreate it now.
	if jukeboxData.inventorySize == jukeboxItems:size() and jukeboxData.version == Jukebox.version then 
		return true
	else
		local tracksRequiringRequeue = {}

		local currentTrack = Jukebox.getCurrentTrack(jukeboxData)

		jukeboxData.playlist = {}
		jukeboxData.playlistIndex = 1
		jukeboxData.inventorySize = 0
		jukeboxData.hasPlayableTracks = false

		local loaded = {}
		-- Save titles so we can pass them without complex objects from server to client.
		for index = 1, jukeboxItems:size() do
			local item = jukeboxItems:get(index - 1)
			if item and item.getType and item.getDisplayName and 
			   Jukebox.getSoundFile(item:getType()) and not loaded[item:getType()] then
				loaded[item:getType()] = true
				if jukeboxData.queue[item:getType()] then
					tracksRequiringRequeue[#tracksRequiringRequeue + 1] = item:getType()
				end
				Jukebox.insertTrack(jukeboxData, item:getType(), item:getDisplayName())
				if (not jukeboxData.hasPlayableTracks) and Jukebox.getSoundFile(item:getType()) then
					jukeboxData.hasPlayableTracks = true
				end
			end
		end

		jukeboxData.queue = {}

		for index, trackType in ipairs(tracksRequiringRequeue) do
			Jukebox.enqueueTrack(jukeboxData, trackType)
		end

		if currentTrack and loaded[currentTrack] then
			jukeboxData.playlistIndex = Jukebox.getPlaylistIndex(jukeboxData, currentTrack) or 1 -- Just in case.
			jukeboxData.queueIndex = Jukebox.getQueueIndex(jukeboxData, currentTrack) or 1 -- Just in case.
		end

		if #jukeboxData.queue == 0 then 
			jukeboxData.queueIndex = 0 
		end

		jukeboxData.inventorySize = jukeboxItems:size()
	end

	sendClientCommand("TrueMusicJukebox", "sync", {
		key = key, hasPlayableTracks = jukeboxData.hasPlayableTracks, inventorySize = jukeboxData.inventorySize,
		titles = jukeboxData.titles, playlist = jukeboxData.playlist, playlistIndex = jukeboxData.playlistIndex, 
		queue = jukeboxData.queue, queueIndex = jukeboxData.queueIndex
	})

	return true
end

Jukebox.playSound = function(jukeboxData, trackType, playNow, beginMuted)
	if not (jukeboxData and trackType) then return end

	local key = Jukebox.dataToKey(jukeboxData)

	local bail = false

	if Jukebox.activeTracks[key] then 
		-- elapsed is used for stutter-start prevention.
		if playNow and Jukebox.activeTracks[key].elapsed > 9 or not Jukebox.activeTracks[key].sound:isPlaying() then
			Jukebox.activeTracks[key].sound:stop()
		else 
			bail = true
		end
	end

	if bail then return end

	local player = getPlayer() -- Just needs to be any local player with a valid location.

	if player and player:getX() then
		jukeboxData.player = {
			x = math.floor(player:getX()),
			y = math.floor(player:getY()),
			z = math.floor(player:getZ())
		}
	else return end
	
	-- We get this every time because it may change and it doesn't take long.
	-- In the future, we could use a global variable here and a Mod Options update
	-- function, but that's micro-optimization in Burryaga's stupid opinion.
	local threeDimensionalAudio = (SandboxVars.TrueMusicJukebox and SandboxVars.TrueMusicJukebox.forceThreeDimensionalAudio) or Jukebox.options.threeDimensionalAudio
	
	local sound = JukeboxSound:new(Jukebox.maxRange, Jukebox.options.threeDimensionalAudio)

	sound.priorThreeDimensionalAudioState = threeDimensionalAudio

	if threeDimensionalAudio then
		sound:setPosition(jukeboxData.x, jukeboxData.y, jukeboxData.z)
	else
		sound:setPosition(jukeboxData.player.x, jukeboxData.player.y, jukeboxData.player.z)
	end

	if beginMuted then
		sound:setVolume(0, Jukebox.maxRange)
	else
		sound:setVolume(jukeboxData.volume, Jukebox.getDistance(jukeboxData, SandboxVars.TrueMusicJukebox and 
			(SandboxVars.TrueMusicJukebox.enableJukeboxTherapy or SandboxVars.TrueMusicJukebox.enableJukeboxNutrition)))
	end

	sound:set3D(threeDimensionalAudio)

	if not Jukebox.options.blockTrueMusicJukeboxSound then 
		sound:play(trackType)
	end
	
	Jukebox.activeTracks[key] = {
		sound = sound,
		trackType = trackType,
		x = jukeboxData.x,
		y = jukeboxData.y,
		z = jukeboxData.z,
		player = jukeboxData.player,
		batch = jukeboxData.batch,
		elapsed = 0
	}
	
	Jukebox.activeLocations[key] = jukeboxData
	Jukebox.addBatchedKey(key, jukeboxData.batch)
	
	return Jukebox.activeTracks[key]
end

-- Jukebox Player Effects

Jukebox.applyEffects = function(player)
    	local jukeboxVars = SandboxVars.TrueMusicJukebox
	local playerIndex = player:getPlayerNum()
	local multiplier = Jukebox.dancing[playerIndex] and jukeboxVars and jukeboxVars.jukeboxTrueDancingMultiplier or 1
	local playerStats = player:getStats()

	if jukeboxVars.enableJukeboxTherapy then
		if playerStats:get(CharacterStat.UNHAPPINESS) > 0 then
			local currentUnhappiness = playerStats:get(CharacterStat.UNHAPPINESS)
			local newUnhappiness = math.max(0, currentUnhappiness - (jukeboxVars.jukeboxHappinessRecovery * multiplier))
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "UNHAPPINESS", amount = newUnhappiness})
			else
				playerStats:set(CharacterStat.UNHAPPINESS, newUnhappiness)
			end
		end

		if playerStats:get(CharacterStat.BOREDOM) > 0 then
			local currentBoredom = playerStats:get(CharacterStat.BOREDOM)
			local newBoredom = math.max(0, currentBoredom - (jukeboxVars.jukeboxBoredomRecovery * multiplier))
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "BOREDOM", amount = newBoredom})
			else
				playerStats:set(CharacterStat.BOREDOM, newBoredom)
			end
		end

		if playerStats:get(CharacterStat.STRESS) > 0 then
			local currentStress = playerStats:get(CharacterStat.STRESS)
			local realStressChange = jukeboxVars.jukeboxStressRecovery / 100
			local newStress = math.max(0, currentStress - (realStressChange * multiplier))
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "STRESS", amount = newStress})
			else
				playerStats:set(CharacterStat.STRESS, newStress)
			end
		end

		--if playerStats:getStressFromCigarettes() > 0 then
		--	local currentStressFromCigarettes = playerStats:getStressFromCigarettes()
		--	local realStressFromCigarettesChange = jukeboxVars.jukeboxStressRecovery / 100
		--	local newStressFromCigarettes = math.max(0, currentStressFromCigarettes - (realStressFromCigarettesChange * multiplier))
		--	playerStats:setStressFromCigarettes(newStressFromCigarettes)
		--end

		if playerStats:get(CharacterStat.ANGER) > 0 then
			local currentAnger = playerStats:get(CharacterStat.ANGER)
			local realAngerChange = jukeboxVars.jukeboxAngerRecovery / 100
			local newAnger = math.max(0, currentAnger - (realAngerChange * multiplier))
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "ANGER", amount = newAnger})
			else
				playerStats:set(CharacterStat.ANGER, newAnger)
			end
		end

		--if playerStats:getFear() > 0 then
		--	local currentFear = playerStats:getFear()
		--	local realFearChange = jukeboxVars.jukeboxFearRecovery / 100
		--	local newFear = math.max(0, currentFear - (realFearChange * multiplier))
		--	playerStats:setFear(newFear)
		--end

		if playerStats:get(CharacterStat.PANIC) > 0 then
			local currentPanic = playerStats:get(CharacterStat.PANIC)
			local newPanic = math.max(0, currentPanic - (jukeboxVars.jukeboxPanicRecovery * multiplier))
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "PANIC", amount = newPanic})
			else
				playerStats:set(CharacterStat.PANIC, newPanic)
			end
		end

		if playerStats:get(CharacterStat.FATIGUE) > 0 then
			local currentFatigue = playerStats:get(CharacterStat.FATIGUE)
			local realFatigueChange = jukeboxVars.jukeboxFatigueRecovery / 100
			local newFatigue = math.max(0, currentFatigue - (realFatigueChange * multiplier))
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "FATIGUE", amount = newFatigue})
			else
				playerStats:set(CharacterStat.FATIGUE, newFatigue)
			end
		end
	end

	if jukeboxVars.enableJukeboxNutrition then
		if playerStats:get(CharacterStat.HUNGER) > 0 then
			local currentHunger = playerStats:get(CharacterStat.HUNGER)
			local realHungerChange = jukeboxVars.jukeboxHungerRecovery / 100
			local newHunger = math.max(0, currentHunger - realHungerChange)
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "HUNGER", amount = newHunger})
			else
				playerStats:set(CharacterStat.HUNGER, newHunger)
			end
		end

		if playerStats:get(CharacterStat.THIRST) > 0 then
			local currentThirst = playerStats:get(CharacterStat.THIRST)
			local realThirstChange = jukeboxVars.jukeboxThirstRecovery / 100
			local newThirst = math.max(0, currentThirst - realThirstChange)
			if isClient() then
				sendClientCommand(getPlayer(), "TrueMusicJukebox", "SetStat", {stat = "THIRST", amount = newThirst})
			else
				playerStats:set(CharacterStat.THIRST, newThirst)
			end
		end
		
		local playerNutrition = player:getNutrition()

		local currentCalories = playerNutrition:getCalories()
		local currentCarbohydrates = playerNutrition:getCarbohydrates()
		local currentProteins = playerNutrition:getProteins()
		local currentLipids = playerNutrition:getLipids()
		
		local newCalories = currentCalories + jukeboxVars.jukeboxCalorieRecovery
		local newCarbohydrates = currentCarbohydrates + jukeboxVars.jukeboxCarbohydrateRecovery
		local newProteins = currentProteins + jukeboxVars.jukeboxProteinRecovery
		local newLipids = currentLipids + jukeboxVars.jukeboxLipidRecovery

		if isClient() then
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Calories", amount = newCalories})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Carbohydrates", amount = newCarbohydrates})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Proteins", amount = newProteins})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Lipids", amount = newLipids})
		else
			playerNutrition:setCalories(newCalories)
			playerNutrition:setCarbohydrates(newCarbohydrates)
			playerNutrition:setProteins(newProteins)
			playerNutrition:setLipids(newLipids)
		end
	end
end

Jukebox.applyStaticHealth = function()		
	for playerIndex = 0, getNumActivePlayers() - 1 do repeat
		local player = getSpecificPlayer(playerIndex)
		
		if not (player and player:isAlive()) then break end

		local playerNutrition = player:getNutrition()
		local currentCalories = playerNutrition:getCalories()
		local currentCarbohydrates = playerNutrition:getCarbohydrates()
		local currentProteins = playerNutrition:getProteins()
		local currentLipids = playerNutrition:getLipids()

		local newCalories = math.min(math.max(currentCalories, 1500), 1700)
		local newCarbohydrates = math.min(math.max(currentCarbohydrates, 220), 300)
		local newProteins = math.min(math.max(currentProteins, 220), 300)
		local newLipids = math.min(math.max(currentLipids, 220), 300)
		local newWeight = player:getModData().TrueMusicJukebox.staticWeight

		if isClient() then
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Calories", amount = newCalories})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Carbohydrates", amount = newCarbohydrates})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Proteins", amount = newProteins})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Lipids", amount = newLipids})
			sendClientCommand(getPlayer(), "TrueMusicJukebox", "Nutrition", {stat = "Weight", amount = newWeight})
		else
			playerNutrition:setCalories(newCalories)
			playerNutrition:setCarbohydrates(newCarbohydrates)
			playerNutrition:setProteins(newProteins)
			playerNutrition:setLipids(newLipids)
			playerNutrition:setWeight(newWeight)
		end
	until true end
end

Jukebox.cancelDanceBonus = function()
	local dancersRemaining = false

	for playerIndex = 0, getNumActivePlayers() - 1 do repeat
		
		local player = getSpecificPlayer(playerIndex)
		
		if Jukebox.dancing[playerIndex] then dancersRemaining = true end
		
		if player:isDoingActionThatCanBeCancelled() then break end -- because dance is ongoing.
		
		Jukebox.dancing[playerIndex] = false
	until true end
	
	if not dancersRemaining then
		Events.OnTick.Remove(Jukebox.cancelDanceBonus)
	end
end

-- Check whether track loaded into jukebox.

Jukebox.hasLoaded = function(container, trackType) 
	return container and trackType and container:getItemFromType(trackType) and true or false
end

-- Distance Functions

Jukebox.getDistanceToPlayer = function(jukeboxData, player)
	local xDifferenceSquared = (player:getX() - jukeboxData.x) ^ 2
	local yDifferenceSquared = (player:getY() - jukeboxData.y) ^ 2
	local zDifferenceSquared = (player:getZ() - jukeboxData.z) ^ 2

	return math.sqrt(xDifferenceSquared + yDifferenceSquared + zDifferenceSquared)
end

Jukebox.getDistance = function(jukeboxData, triggerJukeboxPlayerEffects)
	if SandboxVars.TrueMusicJukebox and (SandboxVars.TrueMusicJukebox.enableJukeboxTherapy or SandboxVars.TrueMusicJukebox.enableJukeboxNutrition) then
		triggerJukeboxPlayerEffects = true
	end

	local distance = 0
	local activePlayersFound = 0

	for playerIndex = 0, getNumActivePlayers() do repeat
				
		local player = getSpecificPlayer(playerIndex)

		if not player then break end

		activePlayersFound = activePlayersFound + 1
		
		-- Distance is average of all local players. 
		-- Sound will be loudest if both players are
		-- near the jukebox.

		local distanceToThisPlayer = Jukebox.getDistanceToPlayer(jukeboxData, player)

		if triggerJukeboxPlayerEffects and distanceToThisPlayer < Jukebox.maxRange and Jukebox.ticksSinceEffectsApplied[playerIndex] == Jukebox.ticksBeforeEffectsReapplied then
			Jukebox.ticksSinceEffectsApplied[playerIndex] = 0 -- Must get back to Jukebox.ticksBeforeEffectsReapplied before we can fire this again.
			Jukebox.applyEffects(player)
		elseif SandboxVars.TrueMusicJukebox and SandboxVars.TrueMusicJukebox.enableJukeboxTherapy then
			Jukebox.ticksSinceEffectsApplied[playerIndex] = math.min(Jukebox.ticksSinceEffectsApplied[playerIndex] + 1, Jukebox.ticksBeforeEffectsReapplied)
		end

		distance = distance + distanceToThisPlayer

	until true end

	-- Mute sound if no players can be found.
	if activePlayersFound < 1 then 
		distance = Jukebox.maxRange 
	else
		distance = distance / activePlayersFound
	end

	return distance
end

Jukebox.replace = function(jukebox)
	local key = Jukebox.squareToKey(jukebox:getSquare())

	-- If value is not true, then it is either nil or a table.
	Jukebox.activeLocations[key] = (Jukebox.activeLocations[key] ~= true and Jukebox.activeLocations[key]) or {}

	local jukeboxData = Jukebox.activeLocations[key]

	if jukeboxData.version ~= Jukebox.version or not jukebox:getContainer() then
		local square = jukebox:getSquare()
		local spriteName = jukebox:getSprite():getName()
		local index = jukebox:getObjectIndex()

		if not jukebox:getContainer() then -- Otherwise, it's already an evolved jukebox.
			if isClient() then
				local x = square:getX()
				local y = square:getY()
				local z = square:getZ()
				local packet = {x = x, y = y, z = z}

				sendClientCommand("TrueMusicJukebox", "ReplaceJukebox", packet)
			else
				sledgeDestroy(jukebox)
				jukebox:getSquare():transmitRemoveItemFromSquare(jukebox)

				jukebox = IsoThumpable.new(getCell(), square, spriteName, false, ISWoodenContainer:new(spriteName, nil))
				jukebox:setIsContainer(true)
				jukebox:getContainer():setType("jukebox")

				-- Our capacity goes to eleventy
				jukebox:getContainer():setCapacity(100)

				square:transmitAddObjectToSquare(jukebox, index)
				square:transmitModdata()

				-- New jukebox, new mod data.
				-- jukeboxData = jukebox:getModData()
				Jukebox.activeLocations[key] = {}

				jukeboxData = Jukebox.activeLocations[key]	
			end
		end

		jukeboxData.key = key
		
		jukeboxData.x = math.floor(jukebox:getX())
		jukeboxData.y = math.floor(jukebox:getY())
		jukeboxData.z = math.floor(jukebox:getZ())	

		-- See Jukebox/Utility.lua
		-- batchIndex changes OnTick, so Jukebox
		-- will be assigned a somewhat unpredictable index
		-- between 1 and batches (the max number of batches).
		-- This is better than starting at 1, because then when
		-- Jukeboxes sync between clients on play, it is highly
		-- unlikely they will all stack up in batch 1 (i.e.,
		-- in the same batch, thus defeating the purpose of batches).
		jukeboxData.batch = Jukebox.batchIndex

		-- jukeboxData.tick = 0

		jukeboxData.on = false
		
		-- jukeboxData.currentIndex = 1
		jukeboxData.volume = Jukebox.volumes[6]

		jukeboxData.hasPlayableTracks = false

		-- Number of Items Loaded Into Jukebox
		jukeboxData.inventorySize = 0

		-- Types
		jukeboxData.playlist = {}
		-- Index of Playlist
		jukeboxData.playlistIndex = 1
		-- Queue
		jukeboxData.queue = jukeboxData.queue or {} --> Preserves old queue
		-- Index of Queue
		jukeboxData.queueIndex = #jukeboxData.queue > 0 and 1 or 0

		-- Queue Mode
		jukeboxData.queueLocked = false

		-- Get Pretty Title of Type
		-- Never needs to be reordered or adjusted because
		-- once there is a stored pretty name for a given type (i.e., 
		-- for a given track id), that track's pretty name
		-- can be recovered from its type no matter the order of the
		-- playlist; we don't even need to care if titles get
		-- removed from Jukebox because space used here is trivial. 
		jukeboxData.titles = jukeboxData.titles or {}

		-- Used to force updates on existing jukeboxes.
		jukeboxData.version = Jukebox.version

		-- ModData.transmit("Jukebox.activeLocations")

		sendClientCommand("TrueMusicJukebox", "transmit", {[key] = jukeboxData})
	end

	return jukebox
end

-- Only called by getEvolvedJukebox, so square must exist.
Jukebox.getVanillaMachine = function(square)
	local objects = square:getObjects()
	for index = 1, objects:size() - 1 do
		local thisObject = objects:get(index)
		local sprite = thisObject:getSprite()
		if sprite then
			local properties = sprite:getProperties()
			if properties:get("CustomName") == "Jukebox" then
				return thisObject
			end
		end
	end
end

Jukebox.getEvolvedJukebox = function(square)
	if not square then return end
    local jukebox = Jukebox.getVanillaMachine(square)

    if jukebox then
        return Jukebox.replace(jukebox)
    end
end

Jukebox.playAtThisRange = function(distance)
	return (SandboxVars.TrueMusicJukebox and SandboxVars.TrueMusicJukebox.ignoreDistanceWhenPlaying and 
			not Jukebox.options.considerDistanceWhenPlayingOverride) or distance < Jukebox.maxRange or
		   Jukebox.options.ignoreDistanceWhenPlayingOverride
end

Jukebox.powerProblems = function(square)
	return square and not SandboxVars.TrueMusicJukebox.disablePowerRequirement and 
		not ((SandboxVars.AllowExteriorGenerator and square:haveElectricity()) or (SandboxVars.ElecShutModifier > -1 
		and GameTime:getInstance():getNightsSurvived() < SandboxVars.ElecShutModifier and not square:isOutside()))
end

Jukebox.silentForLocals = true

Jukebox.consecutiveSilentBatches = 0

Jukebox.updateSound = function()
	if not Jukebox.activeLocationsLoaded then return end --> True Music Jukebox has not yet initialized properly.

	if Jukebox.options.blockTrueMusicJukeboxSound then return end

	Jukebox.batchIndex = (Jukebox.batchIndex % Jukebox.batches) + 1

	local threeDimensionalAudio = (SandboxVars.TrueMusicJukebox and 
		SandboxVars.TrueMusicJukebox.forceThreeDimensionalAudio) or Jukebox.options.threeDimensionalAudio

	local keyData = Jukebox.batchedKeyData[Jukebox.batchIndex]
	
	local silentBatch = true

	-- For each jukebox that is playing music in this batch...
	for index = #keyData, 1, -1 do repeat
		local key = keyData[index]
		local jukeboxData = key and Jukebox.activeLocations[key]

		if not jukeboxData then break end -- Something wonky; maybe transitioning.
	
		-- Destroy deprecated Jukebox data.
		if jukeboxData == true then 
			Jukebox.activeLocations[key] = nil
			sendClientCommand("TrueMusicJukebox", "clear", {[key] = true})
			break
		end

		local location = Jukebox.keyToLocation(key)

		local square = getSquare(location.x, location.y, location.z)

		local jukebox = square and Jukebox.getEvolvedJukebox(square)
	
		if square and not jukebox then --> Jukebox moved, destroy active location.
			Jukebox.activeLocations[key] = nil
			Jukebox.removeBatchedKey(key, jukeboxData.batch, index)
			sendClientCommand("TrueMusicJukebox", "clear", {[key] = true, x = location.x, y = location.y, z = location.z})
			break
		end

		if jukebox then 
			Jukebox.initializePlaylist(jukebox, jukeboxData)
		end

		local activeTrack = Jukebox.activeTracks[key]

		if activeTrack then
			activeTrack.elapsed = activeTrack.elapsed + 1
		end

		local sound = activeTrack and activeTrack.sound

		if not jukeboxData.on then
			if sound then
				sound:stop()
				Jukebox.activeTracks[key] = nil
			end
			break 
		end

		local powerProblems = Jukebox.powerProblems(square)

		if jukeboxData.on and powerProblems then
			jukeboxData.on = false
			if activeTrack then
				activeTrack.sound:stop()
				Jukebox.activeTracks[key] = nil
			end
			break
		end

		local playlist = jukeboxData.playlist

		local distance = Jukebox.getDistance(jukeboxData)

		local withinAudibleRange = Jukebox.playAtThisRange(distance)

		if (not activeTrack) and jukeboxData.on and (#playlist > 0) and withinAudibleRange then
			-- A sound was never initialized on this location for this client.
			-- Would presumably result from joining server far away from an
			-- active jukebox, thus preventing it from getting logged in this
			-- client's activeTracks object. If we detect a jukebox at a location
			-- we expect to be playing something, let's try to make that happen.

			Jukebox.playSound(jukeboxData, Jukebox.getCurrentTrack(jukeboxData))

			break
		end
		
		local readyForNextTrack = activeTrack and jukeboxData.on and #playlist > 0 and withinAudibleRange 

		if not sound then break end

		-- Toggle 3D Audio Safely at Long Range
		if sound.priorThreeDimensionalAudioState ~= threeDimensionalAudio then
			sound:set3D(threeDimensionalAudio)
			if threeDimensionalAudio then
				sound:setPosition(jukeboxData.x, jukeboxData.y, jukeboxData.z)
			else
				sound:setPosition(jukeboxData.player.x, jukeboxData.player.y, jukeboxData.player.z)
				if not square then
					sound:play(Jukebox.getCurrentTrack(jukeboxData)) -- Need to replay this sound to make it audible.
				end
			end
		end

		sound.priorThreeDimensionalAudioState = threeDimensionalAudio
		
		sound:tick()
		
		if sound:isPlaying() then
			if jukebox and not Jukebox.hasLoaded(jukebox:getContainer(), sound:getSoundType()) then
				if #jukeboxData.playlist == 0 then
					Jukebox.activeTracks[key].sound:stop()
					Jukebox.activeTracks[key] = nil
				elseif not sound.changing then
					-- This variable is set when a command has been issued to the server
					-- and the client is awaiting the completion of said command to reduce
					-- spamming server with pointless requests. 
					sound.changing = true

					local nextIndex = Jukebox.getNextIndex(jukeboxData)
					-- Letting server handle skip will utilize jukebox tick to prevent
					-- double-skipping after tracks in playlist end.
					sendClientCommand("TrueMusicJukebox", "sync", {key = key, increaseIndex = true, targetIndex = nextIndex, afterSync = "skip"})
				end
				break
			end

			if sound:getVolume() ~= jukeboxData.volume or 
			   sound:getLastDistance() ~= distance then
				if jukebox and jukeboxData.volume > 0 and Jukebox.enabledLifestyleIntegrations and Jukebox.muteLifestyle then 
					Jukebox.muteLifestyle(jukebox)
				end

				sound:setVolume(jukeboxData.volume, distance)
			end

			if sound.audibleVolume > 0 then
				silentBatch = false
			end

			if jukebox and SandboxVars.TrueMusicJukebox and SandboxVars.TrueMusicJukebox.jukeboxesAttractZombies then
				-- Pulling too many zombies to one location crashes the server hard. This should reduce this issue when using massive ranges.
				local maxRangeAdjustedForServerSafety = math.min(sound.zombieRange, SandboxVars.TrueMusicJukebox.maxZombieRange)
				addSound(jukebox, jukebox:getX(), jukebox:getY(), jukebox:getZ(), maxRangeAdjustedForServerSafety, maxRangeAdjustedForServerSafety)
			end
		elseif readyForNextTrack and not sound.changing then
			-- Letting server handle skip will utilize jukebox tick to prevent
			-- double-skipping after tracks in playlist end.
			sound.changing = true

			local nextIndex = Jukebox.getNextIndex(jukeboxData)

			sendClientCommand("TrueMusicJukebox", "sync", {key = key, increaseIndex = true, targetIndex = nextIndex, afterSync = "skip"})
		end
	until true end

	if silentBatch then
		Jukebox.consecutiveSilentBatches = Jukebox.consecutiveSilentBatches + 1
		if Jukebox.consecutiveSilentBatches > Jukebox.batches then
			Jukebox.silentForLocals = true
		end
	else
		Jukebox.consecutiveSilentBatches = 0
		Jukebox.silentForLocals = nil
	end
end

if not isServer() then Events.OnTickEvenPaused.Add(Jukebox.updateSound) end

Jukebox.updateActiveJukeboxVolumes = function()
	for key, jukeboxData in pairs(Jukebox.activeLocations) do repeat
		local activeTrack = Jukebox.activeTracks[key]

		sound = jukeboxData and activeTrack and activeTrack.sound

		if not sound then break end
		
		local distance = Jukebox.getDistance(jukeboxData)

		sound:setVolume(jukeboxData.volume, distance)

		sound:tick()
	until true end
end

-- Function for checking whether joypad player is active safely from Wookiee Gamepad Support.

Jukebox.getJoypadData = function(playerIndex)

    if not playerIndex then playerIndex = 0 end

    return JoypadState.players[playerIndex + 1]

end

Jukebox.isJoypadDisconnected = function(playerIndex) 
	local controller = JoypadState.controllers[playerIndex]
	if not controller then return end
	local joypadData = controller.joypad
	if not joypadData then return end
	if joypadData.disconnectedUI then return true end
end

-- Function for helping people read jukebox feedback if the Say font is too small for them.

Jukebox.reportMessage = function(player, message)
	if not (player and message and player:isAlive()) then return end

	-- This code may look weird, but it's correct.
	-- We don't want to show alt text and singleplayer Say text,
	-- but we might show alt text and still shout.
	if Jukebox.feedback and Jukebox.options.feedbackAccessibilityMode then
		Jukebox.feedback:show(message)
	elseif not Jukebox.options.alwaysTellMyFriends then
		player:Say(message)
	end

	if Jukebox.options.alwaysTellMyFriends then
		player:SayShout(message)
	end
end

-- Options Page Management

Jukebox.boolean = { 
    ["true"] = true, 
    ["false"] = false
}

Jukebox.trim = function(input)
	local output = input:gsub("%s+", "")
	return output
end

Jukebox.hasSymbol = function(input, symbol)
	local output = input:find(symbol)
	return output
end

Jukebox.initializeOptionVariables = function()
	JukeboxSound.mainVolumeSelected = JukeboxSound.mainVolumeSelected or JukeboxSound.mainVolumeSelectedDefault
	JukeboxSound.mainVolume = JukeboxSound.mainVolume or 1

	JukeboxSound.mainVolumeBoostSelected = JukeboxSound.mainVolumeBoostSelected or JukeboxSound.mainVolumeBoostSelectedDefault
	JukeboxSound.mainVolumeBoost = JukeboxSound.mainVolumeBoost or 1
end

Jukebox.optionsLoaded = {}

Jukebox.readTrueMusicJukeboxOptions = function(file, line)
    -- Useful constants.
    local name = 1
    local value = 2

	local latest = false
	
	while line and Jukebox.hasSymbol(line, "=") do
		local setting = string.split(line, "=")

		local settingName = Jukebox.trim(setting[name])
		local settingValue = Jukebox.trim(setting[value])

		if not Jukebox.optionsLoaded[settingName] then
			if settingName == "accessibilityModeDisplayTime" then
				Jukebox.options[settingName] = tonumber(settingValue)
			else
				Jukebox.options[settingName] = Jukebox.boolean[settingValue]
				if settingName == "blockTrueMusicJukeboxSound" then
					latest = true
				end
			end
		end

		Jukebox.optionsLoaded[settingName] = true
		
		line = file:readLine()
	end

	if latest then --> assume the settings have been written before
		return "Mod Options Transcended"
	end
end

Jukebox.inheritModOptions = function()
    -- Useful constants.
    local name = 1
    local value = 2
    
    local file = getFileReader("mods_options.ini", true)
    
    if not file then return	end

	local line = file:readLine()

	while line and Jukebox.trim(line) ~= "[TrueMusicJukebox]" do
		line = file:readLine()
	end

	line = line and file:readLine()

	Jukebox.readTrueMusicJukeboxOptions(file, line)

	file:close()
end

Jukebox.writeSettings = function()
	Jukebox.initializeOptionVariables()

	local file = getFileWriter("TrueMusicJukebox.ini", true, false)

    if not file then return end

    file:write("# { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }\n")
    file:write("MainVolume = " .. JukeboxSound.mainVolumeSelected .. "\n")

    file:write("# { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }\n")
    file:write("MainVolumeBoost = " .. JukeboxSound.mainVolumeBoostSelected .. "\n")
	
    file:write("# True Music Jukebox Mod Options\n")
	file:write("hideMenuIcons = " .. tostring(Jukebox.options.hideMenuIcons) .. "\n")
	file:write("invertToggleIconFeedback = " .. tostring(Jukebox.options.invertToggleIconFeedback) .. "\n")
	file:write("hideTracklistFromContextMenu = " .. tostring(Jukebox.options.hideTracklistFromContextMenu) .. "\n")
	file:write("showEveryTrackInPortablePlaylist = " .. tostring(Jukebox.options.showEveryTrackInPortablePlaylist) .. "\n")
	file:write("showEveryTrackInJukeboxPlaylist = " .. tostring(Jukebox.options.showEveryTrackInJukeboxPlaylist) .. "\n")
	file:write("showEveryTrackInJukeboxQueue = " .. tostring(Jukebox.options.showEveryTrackInJukeboxQueue) .. "\n")
	file:write("threeDimensionalAudio = " .. tostring(Jukebox.options.threeDimensionalAudio) .. "\n")
	file:write("ignoreDistanceWhenPlayingOverride = " .. tostring(Jukebox.options.ignoreDistanceWhenPlayingOverride) .. "\n")
	file:write("considerDistanceWhenPlayingOverride = " .. tostring(Jukebox.options.considerDistanceWhenPlayingOverride) .. "\n")
	file:write("blockTrueMusicJukeboxSound = " .. tostring(Jukebox.options.blockTrueMusicJukeboxSound) .. "\n")
	file:write("alwaysTellMyFriends = " .. tostring(Jukebox.options.alwaysTellMyFriends) .. "\n")
	file:write("hideTransferAllTrueMusic = " .. tostring(Jukebox.options.hideTransferAllTrueMusic) .. "\n")
	file:write("dancingComesFirst = " .. tostring(Jukebox.options.dancingComesFirst) .. "\n")
	file:write("requireMusicForLifestyleDance = " .. tostring(Jukebox.options.requireMusicForLifestyleDance) .. "\n")
	file:write("feedbackAccessibilityMode = " .. tostring(Jukebox.options.feedbackAccessibilityMode) .. "\n")
	file:write("accessibilityModeDisplayTime = " .. tostring(Jukebox.options.accessibilityModeDisplayTime) .. "\n")

    file:close()
end

Jukebox.readSettings = function()
    -- Useful constants.
    local name = 1
    local value = 2
    
    local file = getFileReader("TrueMusicJukebox.ini", true)
    
    if not file then 
		Jukebox.writeSettings() 
        return 
    end

    -- Function breaks into another below if file does not yet have data.
    -- The remaining lines will not be nil if the first one has data unless
    -- someone decides to intentionally bork their own config manually,
    -- but we check them anyway for good practice.

    local line = file:readLine()

    if line == nil then 
		file:close()
		return Jukebox.writeSettings()
	else
		-- Skip immediately past the comment line.
		line = file:readLine()
		if line == nil then
			-- No line for next setting.
			file:close()
			return Jukebox.writeSettings()
		end
	end

    local setting = string.split(line, "=")

    if Jukebox.trim(setting[name]) == "MainVolume" and tonumber(Jukebox.trim(setting[value])) then
		 -- Bound from 0 to 11. Nice try, hacker! /sarcasm
        JukeboxSound.mainVolumeSelected = math.floor(math.min(math.max(tonumber(setting[value]), 0), 11))
		JukeboxSound.mainVolume = JukeboxSound.mainVolumeSelected / JukeboxSound.mainVolumeDivisor
	else 
		file:close()
		return Jukebox.writeSettings()
	end

    if not file:readLine() then 
		file:close()
		return Jukebox.writeSettings()
	else
		-- Skip immediately past the comment line.
		line = file:readLine()
		if line == nil then
			-- No line for next setting.
			file:close()
			return Jukebox.writeSettings()
		end
	end

	setting = string.split(line, "=")

    if Jukebox.trim(setting[name]) == "MainVolumeBoost" and tonumber(Jukebox.trim(setting[value])) then
		 -- Bound from 0 to 11. Nice try, hacker! /sarcasm
        JukeboxSound.mainVolumeBoostSelected = math.floor(math.min(math.max(tonumber(setting[value]), 0), 11))
		JukeboxSound.mainVolumeBoost = JukeboxSound.getMainVolumeBoost()
	else 
		file:close()
		return Jukebox.writeSettings()
	end

	if not file:readLine() then 
		file:close()
		return Jukebox.writeSettings()
	else
		-- Skip immediately past the comment line.
		line = file:readLine()
		if line == nil then
			-- No line for next setting.
			file:close()
			return Jukebox.writeSettings()
		end
	end

	if Jukebox.readTrueMusicJukeboxOptions(file, line) == "Mod Options Transcended" then
		Jukebox.transcendedModOptions = true
	else
		Jukebox.inheritModOptions()
		Jukebox.writeSettings()
	end

	file:close()
end

if not getActivatedMods():contains("DerivedObjectModuleExtractor") then
	-- Internal implementation of DOME for those not running it.
	
	Jukebox.DOME = {}

	Jukebox.DOME.BaseObject = {}

	Jukebox.DOME.BaseObject.derive = ISBaseObject.derive

	Jukebox.DOME.modules = {}

	function ISBaseObject:derive(type)
		local module = Jukebox.DOME.BaseObject.derive(self, type)
		Jukebox.DOME.modules[type] = module
		return module
	end

	Jukebox.DOME.require = function(type)
		return Jukebox.DOME.modules[type]
	end
end

return Jukebox
