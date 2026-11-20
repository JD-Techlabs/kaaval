extends Node
## Music + pooled SFX. Volumes and haptics follow the saved settings.

const SFX_VOICES: int = 10
const MIN_REPEAT_SECONDS: float = 0.045
const AUDIO_DIR: String = "res://assets/audio/"

var _streams: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _music_name: String = ""
var _last_played: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i: int in SFX_VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	add_child(_music)
	GameState.changed.connect(_apply_volumes)
	_apply_volumes()


func _stream(sound: String) -> AudioStream:
	if not _streams.has(sound):
		var path: String = AUDIO_DIR + sound + ".wav"
		_streams[sound] = load(path) if ResourceLoader.exists(path) else null
	return _streams[sound] as AudioStream


func play(sound: String, pitch: float = 1.0) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < MIN_REPEAT_SECONDS:
		return
	_last_played[sound] = now
	var stream: AudioStream = _stream(sound)
	if stream == null:
		return
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % SFX_VOICES
	voice.stream = stream
	voice.pitch_scale = pitch
	voice.play()


func play_music(sound: String) -> void:
	if sound == _music_name:
		return
	_music_name = sound
	var stream: AudioStreamWAV = _stream(sound) as AudioStreamWAV
	if stream == null:
		_music.stop()
		return
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length() * stream.mix_rate)
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_music_name = ""
	_music.stop()


func haptic(milliseconds: int = 25) -> void:
	if bool(GameState.setting("haptics")):
		Input.vibrate_handheld(milliseconds)


func _apply_volumes() -> void:
	var sfx: float = float(GameState.setting("sfx_volume"))
	var music: float = float(GameState.setting("music_volume"))
	for voice: AudioStreamPlayer in _voices:
		voice.volume_db = linear_to_db(maxf(sfx, 0.0001))
	_music.volume_db = linear_to_db(maxf(music * 0.6, 0.0001))
