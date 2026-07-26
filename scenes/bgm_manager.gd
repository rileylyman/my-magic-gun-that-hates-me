extends Node

@export_category("Music")

@export var bgm_stream: AudioStream
@export var autoplay: bool = true
@export var music_bus: StringName = &"Music"

@export_range(-40.0, 6.0, 0.1)
var base_volume_db: float = -8.0

@export_category("Loop Variation")

@export_range(0.0, 0.05, 0.001)
var pitch_variation: float = 0.008

@export_range(0.0, 3.0, 0.1)
var volume_variation_db: float = 0.5

@export_category("Fade")

@export_range(0.0, 5.0, 0.1)
var initial_fade_in_duration: float = 1.0

@export var bgm_player: AudioStreamPlayer

var _runtime_stream: AudioStream
var _fade_tween: Tween
var _rng := RandomNumberGenerator.new()

var _should_play: bool = false
var _loop_index: int = 0
var _target_volume_db: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()

	bgm_player.process_mode = (
		Node.PROCESS_MODE_ALWAYS
	)
	bgm_player.bus = music_bus

	if not bgm_player.finished.is_connected(
		on_bgm_finished
	):
		bgm_player.finished.connect(
			on_bgm_finished
		)

	if autoplay:
		play_bgm()


func play_bgm(
	new_stream: AudioStream = null
) -> void:
	if new_stream != null:
		bgm_stream = new_stream

	if bgm_stream == null:
		push_error("BGM stream is not assigned.")
		return

	kill_fade_tween()
	bgm_player.stop()

	_runtime_stream = create_runtime_stream(
		bgm_stream
	)

	bgm_player.stream = _runtime_stream

	_should_play = true
	_loop_index = 0

	start_next_loop(true)


func stop_bgm(
	fade_duration: float = 0.5
) -> void:
	_should_play = false
	kill_fade_tween()

	if not bgm_player.playing:
		return

	if fade_duration <= 0.0:
		bgm_player.stop()
		return

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(
		Tween.TWEEN_PAUSE_PROCESS
	)

	_fade_tween.tween_property(
		bgm_player,
		"volume_db",
		-80.0,
		fade_duration
	)

	_fade_tween.tween_callback(
		bgm_player.stop
	)


func pause_bgm() -> void:
	bgm_player.stream_paused = true


func resume_bgm() -> void:
	if bgm_player.stream == null:
		play_bgm()
		return

	bgm_player.stream_paused = false


func set_volume_db(
	new_volume_db: float
) -> void:
	base_volume_db = new_volume_db
	_target_volume_db = new_volume_db
	bgm_player.volume_db = new_volume_db


func on_bgm_finished() -> void:
	if not _should_play:
		return

	start_next_loop(false)


func start_next_loop(
	is_first_loop: bool
) -> void:
	if (
		not _should_play
		or _runtime_stream == null
	):
		return

	apply_loop_variation()

	if (
		is_first_loop
		and initial_fade_in_duration > 0.0
	):
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = (
			_target_volume_db
		)

	bgm_player.play()

	if (
		is_first_loop
		and initial_fade_in_duration > 0.0
	):
		kill_fade_tween()

		_fade_tween = create_tween()
		_fade_tween.set_pause_mode(
			Tween.TWEEN_PAUSE_PROCESS
		)

		_fade_tween.tween_property(
			bgm_player,
			"volume_db",
			_target_volume_db,
			initial_fade_in_duration
		)


func apply_loop_variation() -> void:
	if _loop_index == 0:
		bgm_player.pitch_scale = 1.0
		_target_volume_db = base_volume_db
		_loop_index += 1
		return

	var direction := 1.0

	if _loop_index % 2 == 0:
		direction = -1.0

	var pitch_amount := _rng.randf_range(
		pitch_variation * 0.4,
		pitch_variation
	)

	var volume_amount := _rng.randf_range(
		volume_variation_db * 0.4,
		volume_variation_db
	)

	bgm_player.pitch_scale = maxf(
		0.01,
		1.0 + direction * pitch_amount
	)

	_target_volume_db = (
		base_volume_db
		+ direction
		* volume_amount
	)

	_loop_index += 1


func create_runtime_stream(
	source_stream: AudioStream
) -> AudioStream:
	var stream_copy := (
		source_stream.duplicate(true)
		as AudioStream
	)

	if stream_copy is AudioStreamOggVorbis:
		stream_copy.loop = false

	elif stream_copy is AudioStreamMP3:
		stream_copy.loop = false

	elif stream_copy is AudioStreamWAV:
		stream_copy.loop_mode = (
			AudioStreamWAV.LOOP_DISABLED
		)

	return stream_copy


func kill_fade_tween() -> void:
	if (
		_fade_tween != null
		and _fade_tween.is_valid()
	):
		_fade_tween.kill()

	_fade_tween = null
