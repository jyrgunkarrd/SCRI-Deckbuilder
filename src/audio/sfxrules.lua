local sfxrules = {}

local HOVER_SFX_PATH = "assets/audio/sfx/hover.wav"
local RESOURCE_MOVE_SFX_PATH = "assets/audio/sfx/resource_move.wav"
local RESOURCE_PLAY_SFX_PATH = "assets/audio/sfx/resource_play.wav"
local UNIT_PLAY_SFX_PATH = "assets/audio/sfx/unit_play.wav"
local PLAY_REJECT_SFX_PATH = "assets/audio/sfx/play_reject.wav"
local CHAR_SELECT_SFX_PATH = "assets/audio/sfx/char_select.wav"
local PHASE_END_SFX_PATH = "assets/audio/sfx/phase_end.wav"
local DICE_SFX_PATH = "assets/audio/sfx/dice.wav"
local ENGAGE_SFX_PATH = "assets/audio/sfx/engage.wav"
local PRELUDE_SFX_PATH = "assets/audio/sfx/prelude.wav"
local DAMAGE_SFX_PATH = "assets/audio/sfx/damage.wav"
local DESTROY_SFX_PATH = "assets/audio/sfx/destroy.wav"
local PROGRESS_SFX_PATH = "assets/audio/sfx/progress.wav"
local SABOTAGE_SFX_PATH = "assets/audio/sfx/sabotage.wav"
local INFLUENCE_SFX_PATH = "assets/audio/sfx/inf.wav"
local FLIP_SFX_PATH = "assets/audio/sfx/flip.wav"
local HUNT_SFX_PATH = "assets/audio/sfx/hunt.wav"

local hoverSource = nil
local resourceMoveSource = nil
local resourcePlaySource = nil
local unitPlaySource = nil
local playRejectSource = nil
local charSelectSource = nil
local phaseEndSource = nil
local diceSource = nil
local engageSource = nil
local preludeSource = nil
local damageSource = nil
local destroySource = nil
local progressSource = nil
local sabotageSource = nil
local influenceSource = nil
local flipSource = nil
local huntSource = nil

local function getHoverSource()
    if hoverSource ~= nil then
        return hoverSource
    end

    hoverSource = love.audio.newSource(HOVER_SFX_PATH, "static")
    return hoverSource
end

local function getResourceMoveSource()
    if resourceMoveSource ~= nil then
        return resourceMoveSource
    end

    resourceMoveSource = love.audio.newSource(RESOURCE_MOVE_SFX_PATH, "static")
    return resourceMoveSource
end

local function getResourcePlaySource()
    if resourcePlaySource ~= nil then
        return resourcePlaySource
    end

    resourcePlaySource = love.audio.newSource(RESOURCE_PLAY_SFX_PATH, "static")
    return resourcePlaySource
end

local function getUnitPlaySource()
    if unitPlaySource ~= nil then
        return unitPlaySource
    end

    unitPlaySource = love.audio.newSource(UNIT_PLAY_SFX_PATH, "static")
    return unitPlaySource
end

local function getPlayRejectSource()
    if playRejectSource ~= nil then
        return playRejectSource
    end

    playRejectSource = love.audio.newSource(PLAY_REJECT_SFX_PATH, "static")
    return playRejectSource
end

local function getCharSelectSource()
    if charSelectSource ~= nil then
        return charSelectSource
    end

    charSelectSource = love.audio.newSource(CHAR_SELECT_SFX_PATH, "static")
    return charSelectSource
end

local function getPhaseEndSource()
    if phaseEndSource ~= nil then
        return phaseEndSource
    end

    phaseEndSource = love.audio.newSource(PHASE_END_SFX_PATH, "static")
    return phaseEndSource
end

local function getDiceSource()
    if diceSource ~= nil then
        return diceSource
    end

    diceSource = love.audio.newSource(DICE_SFX_PATH, "static")
    return diceSource
end

local function getEngageSource()
    if engageSource ~= nil then
        return engageSource
    end

    engageSource = love.audio.newSource(ENGAGE_SFX_PATH, "static")
    return engageSource
end

local function getPreludeSource()
    if preludeSource ~= nil then
        return preludeSource
    end

    preludeSource = love.audio.newSource(PRELUDE_SFX_PATH, "static")
    return preludeSource
end

local function getDamageSource()
    if damageSource ~= nil then
        return damageSource
    end

    damageSource = love.audio.newSource(DAMAGE_SFX_PATH, "static")
    return damageSource
end

local function getDestroySource()
    if destroySource ~= nil then
        return destroySource
    end

    destroySource = love.audio.newSource(DESTROY_SFX_PATH, "static")
    return destroySource
end

local function getProgressSource()
    if progressSource ~= nil then
        return progressSource
    end

    progressSource = love.audio.newSource(PROGRESS_SFX_PATH, "static")
    return progressSource
end

local function getSabotageSource()
    if sabotageSource ~= nil then
        return sabotageSource
    end

    sabotageSource = love.audio.newSource(SABOTAGE_SFX_PATH, "static")
    return sabotageSource
end

local function getInfluenceSource()
    if influenceSource ~= nil then
        return influenceSource
    end

    influenceSource = love.audio.newSource(INFLUENCE_SFX_PATH, "static")
    return influenceSource
end

local function getFlipSource()
    if flipSource ~= nil then
        return flipSource
    end

    flipSource = love.audio.newSource(FLIP_SFX_PATH, "static")
    return flipSource
end

local function getHuntSource()
    if huntSource ~= nil then
        return huntSource
    end

    huntSource = love.audio.newSource(HUNT_SFX_PATH, "static")
    return huntSource
end

function sfxrules.playHover()
    local source = getHoverSource():clone()
    source:play()
end

function sfxrules.playResourceMove()
    local source = getResourceMoveSource():clone()
    source:play()
end

function sfxrules.playResourcePlay()
    local source = getResourcePlaySource():clone()
    source:play()
end

function sfxrules.playUnitPlay()
    local source = getUnitPlaySource():clone()
    source:play()
end

function sfxrules.playPlayReject()
    local source = getPlayRejectSource():clone()
    source:play()
end

function sfxrules.playCharSelect()
    local source = getCharSelectSource():clone()
    source:play()
end

function sfxrules.playPhaseEnd()
    local source = getPhaseEndSource():clone()
    source:play()
end

function sfxrules.playDice()
    local source = getDiceSource():clone()
    source:play()
end

function sfxrules.playEngage()
    local source = getEngageSource():clone()
    source:play()
end

function sfxrules.playPrelude()
    local source = getPreludeSource():clone()
    source:play()
end

function sfxrules.playDamage()
    local source = getDamageSource():clone()
    source:play()
end

function sfxrules.playDestroy()
    local source = getDestroySource():clone()
    source:play()
end

function sfxrules.playProgress()
    local source = getProgressSource():clone()
    source:play()
end

function sfxrules.playSabotage()
    local source = getSabotageSource():clone()
    source:play()
end

function sfxrules.playInfluence()
    local source = getInfluenceSource():clone()
    source:play()
end

function sfxrules.playFlip()
    local source = getFlipSource():clone()
    source:play()
end

function sfxrules.playHunt()
    local source = getHuntSource():clone()
    source:play()
end

return sfxrules
