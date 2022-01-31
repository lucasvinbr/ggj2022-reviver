---@type SoundSource
local musicSource = nil

---@type SoundSource
local flippedMusicSource = nil

local mainAudioFrequency = 22050

function SetupSound()

  -- Create music sound sources
  musicSource = Scene_:CreateComponent("SoundSource")
  flippedMusicSource = Scene_:CreateComponent("SoundSource")
  -- Set the sound type to music so that master volume control works correctly
  musicSource.soundType = SOUND_MUSIC
  flippedMusicSource.soundType = SOUND_MUSIC

  -- add listener to camera
  local listener = CameraNode:CreateComponent("SoundListener")
  audio:SetListener(listener)
end


function StartMusic()
  ---@type Sound
  local musicFile = cache:GetResource("Sound","Music/duality/gameplayv1.ogg")

  ---@type Sound
  local flipMusicFile = cache:GetResource("Sound","Music/duality/gameplayv2.ogg")

  musicFile.looped = true
  flipMusicFile.looped = true

  if not musicSource:IsPlaying() then
    musicSource:Play(musicFile)
  end

  if not flippedMusicSource:IsPlaying() then
    flippedMusicSource:Play(flipMusicFile)
  end

  musicSource:SetGain(0.63)
  flippedMusicSource:SetGain(0.63)

  FlipMusic(WorldIsFlipped)
end

function FlipMusic(isInFlippedWorld)

  if isInFlippedWorld then
    musicSource:SetGain(0.0)
    flippedMusicSource:SetGain(0.63)
  else
    musicSource:SetGain(0.63)
    flippedMusicSource:SetGain(0.0)
  end

end

function StopMusic()
  -- MusicSource:Stop()
  musicSource:Stop()
  flippedMusicSource:Stop()
end

function PlayOneShotSound(soundFilePath, gain, freqVariation)
  -- Get the sound resource
  local sound = cache:GetResource("Sound", soundFilePath)

  if sound ~= nil then
    -- Create a SoundSource component for playing the sound. The SoundSource component plays
    -- non-positional audio, so its 3D position in the scene does not matter. For positional sounds the
    -- SoundSource3D component would be used instead
    ---@type SoundSource
    local soundSource = Scene_:CreateComponent("SoundSource")
    soundSource:SetSoundType(SOUND_EFFECT)
    soundSource:SetAutoRemoveMode(REMOVE_COMPONENT)

    if gain == nil then
      gain = 1.0
    end

    if freqVariation == nil then
      freqVariation = 0.0
    end

    soundSource:Play(sound, Random(mainAudioFrequency - freqVariation, mainAudioFrequency + freqVariation), gain)

  end
end


function HandleSoundVolume(eventType, eventData)
  local newVolume = eventData["Value"]:GetFloat()
  audio:SetMasterGain(SOUND_EFFECT, newVolume)
end

function HandleMusicVolume(eventType, eventData)
  local newVolume = eventData["Value"]:GetFloat()
  audio:SetMasterGain(SOUND_MUSIC, newVolume)
end
