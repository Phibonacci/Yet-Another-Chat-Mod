local AVoice = {}

local Phonemes = {
    A = {
        'AIR',
        'AI',
        'AR',
        'A'
    },
    B = {
        'B'
    },
    C = {
        'CH',
        'C'
    },
    D = {
        'D'
    },
    E = {
        'ERE',
        'EE',
        'ER',
        'E'
    },
    F = {
        'F'
    },
    G = {
        'G'
    },
    H = {
        'H'
    },
    I = {
        'IS',
        'IR',
        'I'
    },
    J = {
        'J'
    },
    K = {
        'K'
    },
    L = {
        'L'
    },
    M = {
        'M'
    },
    N = {
        'NG',
        'N'
    },
    O = {
        'OOR',
        'OO',
        'OW',
        'OY',
        'O'
    },
    P = {
        'P'
    },
    Q = {
        'Q'
    },
    R = {
        'R'
    },
    S = {
        'SH',
        'S'
    },
    T = {
        'TH',
        'T'
    },
    U = {
        'UP',
        'U'
    },
    V = {
        'V'
    },
    W = {
        'W'
    },
    X = {
        'X '
    },
    Y = {
        'Y'
    },
    Z = {
        'Z'
    },
}

local function GetPhoneme(nextLetters)
    local firstLetter = nextLetters:sub(1, 1)
    local letterPhonemes = Phonemes[firstLetter]
    if letterPhonemes == nil then
        return nil
    end
    for _, phoneme in pairs(letterPhonemes) do
        if #nextLetters >= #phoneme and nextLetters:match('^' .. phoneme) then
            return phoneme
        end
    end
    return nil
end

function AVoice:GetSoundPathFromPhoneme(phoneme, isFirstWordLetter, soundPrefix)
    local filePhoneme
    if phoneme == 'K' or phoneme == 'Q' then
        filePhoneme = 'C'
    elseif phoneme == 'Y' and isFirstWordLetter then
        filePhoneme = 'YStart'
    else
        filePhoneme = phoneme
    end

    return soundPrefix .. filePhoneme
end

function AVoice:subscribe()
    if self.event then
        return
    end
    self.event = function()
        self:update()
    end
    Events.OnTick.Add(self.event)
end

function AVoice:unsubscribe()
    if self.event == nil then
        return
    end
    Events.OnTick.Remove(self.event)
    self.event = nil
end

local MAX_PITCH_VARIATION = 0.05
local MIN_PITCH_VARIATION = -0.05
function AVoice:update()
    if self.nextSoundTableIndex > self.soundTableSize then
        return
    end
    local soundCanBePlayed = true
    local soundPlayed = false
    while soundCanBePlayed and self.nextSoundTableIndex <= self.soundTableSize do
        local currentTime = Calendar.getInstance():getTimeInMillis()
        local nextSound = self.soundTable[self.nextSoundTableIndex]
        if currentTime - self.startingTime < nextSound.time then
            soundCanBePlayed = false
        else
            if nextSound.sound ~= nil and soundPlayed == false then
                self.soundEmitter = getWorld():getFreeEmitter()

                -- Is object already a square or a player? We don't care, they both have getX/Y/Z, we get the square anyway.
                local square = getSquare(self.object:getX(), self.object:getY(), self.object:getZ())

                self.soundId = self.soundEmitter:playSoundImpl(nextSound.sound, square)

                -- If it's a character and the one played by the client then we don't want to hear the sound from only one side
                if self.object.getUsername ~= nil and self.object:getUsername() == getPlayer():getUsername() then
                    self.soundEmitter:set3D(self.soundId, false)
                end

                local updatePitchVariation = (ZombRand(80) - 40) / 1000
                self.pitchVariation = math.min(
                    math.max(self.pitchVariation + updatePitchVariation, MIN_PITCH_VARIATION),
                    MAX_PITCH_VARIATION)
                self.soundEmitter:setPitch(self.soundId, self.pitch + self.pitchVariation)
                soundPlayed = true
            end
            self.nextSoundTableIndex = self.nextSoundTableIndex + 1
        end
    end
end

local function isPunctuationMark(letter)
    return letter == ','
        or letter == '.'
        or letter == '!'
        or letter == '?'
        or letter == ':'
end

function AVoice:createSoundTable(soundPrefix)
    local isFirstWordLetter = true
    local soundTable = {}
    local size = 0
    local index = 1
    local messageSize = #self.message
    local time = 0
    while index <= messageSize do
        local soundFile = nil
        local firstLetter = self.message:sub(index, index)
        if firstLetter == ' ' then
            index = index + 1
            isFirstWordLetter = true
            time = time + 10
        elseif isPunctuationMark(firstLetter) then
            index = index + 1
            isFirstWordLetter = true
            time = time + self.phonemeDuration
        else
            local nextLetters = self.message:sub(index)
            local phoneme = GetPhoneme(nextLetters)
            if phoneme == nil then
                index = index + 1
                isFirstWordLetter = true
            else
                soundFile = self:GetSoundPathFromPhoneme(phoneme, isFirstWordLetter, soundPrefix)
                isFirstWordLetter = false
                if #phoneme == 1 or phoneme == 'OO' then
                    local identicalLetters = nextLetters:match('^(' .. phoneme:sub(1, 1) .. '+)')
                    assert(identicalLetters ~= nil,
                        'failure: identicalLetters should never be null at this point for phoneme "' ..
                        phoneme .. '" and nextLetters "' .. nextLetters .. '"')
                    index = index + #identicalLetters
                else
                    index = index + #phoneme
                end
            end
        end
        if soundFile ~= nil then
            table.insert(soundTable, {
                time = time,
                sound = soundFile,
            })
            size = size + 1
            time = time + self.phonemeDuration
        end
    end
    return soundTable, size
end

function AVoice:new(message, object, soundPrefix, voicePitch)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.message = message:upper()
    o.object = object
    o.pitch = voicePitch
    o.pitchVariation = 0
    o.soundEmitter = nil
    o.soundId = nil
    o.phonemeDuration = 95
    o.soundTable, o.soundTableSize = o:createSoundTable(soundPrefix)
    o.nextSoundTableIndex = 1
    o.startingTime = Calendar.getInstance():getTimeInMillis()
    return o
end

return AVoice
