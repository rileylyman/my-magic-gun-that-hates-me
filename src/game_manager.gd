class_name GameManager
extends Node2D

@export var card_scene: PackedScene
@export var counter_scene: PackedScene
@export var debuff_icon_scene: PackedScene

@export_category("Sound Effects")

@export var battle_start_sfx: AudioStream
@export var card_draw_sfx: AudioStream
@export var card_select_sfx: AudioStream
@export var card_deselect_sfx: AudioStream
@export var sprint_start_sfx: AudioStream
@export var day_tick_sfx: AudioStream
@export var task_fire_sfx: AudioStream
@export var score_launch_sfx: AudioStream
@export var score_impact_sfx: AudioStream
@export var sprint_end_sfx: AudioStream
@export var card_discard_sfx: AudioStream
@export var enemy_defeated_sfx: AudioStream
@export var game_over_sfx: AudioStream
@export var stamp_trigger_sfx: AudioStream
@export var artifact_trigger_sfx: AudioStream

@export_category("Scene Flow")

@export var game_over_scene: PackedScene

@export_category("Tutorial")

@export var battle_tutorial: BattleTutorial

@export_category("Sound Settings")

@export var sfx_bus: StringName = &"Master"

@export_range(-40.0, 10.0, 0.5)
var sfx_volume_db: float = 0.0

@export_range(0.0, 0.25, 0.01)
var sfx_pitch_variation: float = 0.04

@export_range(0.1, 4.0, 0.01)
var task_fire_base_pitch: float = 1.0

@export_range(0.0, 1.0, 0.01)
var task_fire_pitch_step: float = 0.08

@export_range(0.1, 4.0, 0.01)
var task_fire_max_pitch: float = 2.0

@export_category("Battle Speed")

@export_range(0.1, 10.0, 0.1, "or_greater")
var base_battle_speed: float = 1.0

@export_range(0.0, 1.0, 0.01)
var sprint_speed_increase_per_trigger: float = 0.08

@export_range(1.0, 10.0, 0.1)
var max_sprint_speed_multiplier: float = 2.0

const artifact_icon_scene: PackedScene = preload(
	"res://src/artifact_icon.tscn"
)

const card_outline_scene: PackedScene = preload(
	"res://src/card_outline.tscn"
)

var counters: Array[Counter] = []
var active_counter: Counter
var active_counter_index: int = -1

var first_tick: bool = false
var is_ticking: bool = false
var battle_ended: bool = false

var previous_day_fired_cards: Array[Card] = []

var icons: Array[ArtifactIcon] = []
var chosen_outlines: Array[Control] = []
var debuff_icons: Array[DebuffIcon] = []

var drawpile: Array[Card] = []
var discard: Array[Card] = []
var hand: Array[Card] = []
var chosen: Array[Card] = []

var card_size: Vector2
var padding: Vector2 = Vector2(24, 24)

var _accum: float = 0.0
var _tick_trigger_sfx_index: int = 0
var _tick_trigger_sfx_active: bool = false
var _sprint_trigger_count: int = 0
var _pending_score_amount: int = 0


func _ready() -> void:
	Engine.time_scale = 1.0

	if GlobalManager.enemy == null:
		push_error("No current enemy is loaded.")
		return

	apply_battle_time_scale()
	play_sfx(battle_start_sfx)

	%SubmitButton.pressed.connect(
		on_start_round_pressed
	)

	%EnemyNameLabel.text = GlobalManager.enemy.name
	%EnemyTexture.texture = GlobalManager.enemy.enemy_texture

	%EncounterNLabel.text = (
		"Encounter "
		+ str(
			GlobalManager.defeated_enemy_count + 1
		)
	)

	for c in %HandPos.get_children():
		c.queue_free()

	for c in %ChosenPos.get_children():
		c.queue_free()

	for c in GlobalManager.deck:
		if c.get_parent() != null:
			c.get_parent().remove_child(c)

		c.prepare_for_battle()
		%DeckContainer.add_child(c)
		c.do_setup()
		drawpile.append(c)

	for c in %SprintHBox.get_children():
		c.queue_free()

	for i in range(
		GlobalManager.enemy.counter_values.size()
	):
		var counter: Counter = (
			counter_scene.instantiate()
			as Counter
		)

		counter.value = (
			GlobalManager.enemy.counter_values[i]
		)

		counter.seq = i + 1
		counter.active = false

		counters.append(counter)
		%SprintHBox.add_child(counter)

	for active_debuff in get_global_enemy_debuffs():
		active_debuff.debuff.battle_start_callback(
			self
		)

	load_artifacts()
	load_debuff_icons()
	
	drawpile.shuffle()

	if drawpile.is_empty():
		push_error("The deck is empty.")
		return

	card_size = drawpile[0].size

	%ScoreBar.max_score = GlobalManager.enemy.health
	%ScoreBar.curr_score = 0
	for a in GlobalManager.artifacts:
		await a.encounter_start_callback()
	await deal_hand()


func is_tutorial_active() -> bool:
	return (
		battle_tutorial != null
		and is_instance_valid(battle_tutorial)
		and battle_tutorial.is_running
	)


func get_sprint_speed_multiplier() -> float:
	var maximum_speed: float = maxf(
		max_sprint_speed_multiplier,
		1.0
	)

	return minf(
		1.0
		+ float(_sprint_trigger_count)
		* sprint_speed_increase_per_trigger,
		maximum_speed
	)


func apply_battle_time_scale() -> void:
	var speed_multiplier: float = (
		maxf(base_battle_speed, 0.01)
		* get_sprint_speed_multiplier()
	)

	Engine.time_scale = maxf(
		speed_multiplier,
		0.01
	)


func begin_sprint_speed() -> void:
	_sprint_trigger_count = 0
	_accum = 0.0
	apply_battle_time_scale()


func advance_sprint_speed_from_trigger() -> void:
	if active_counter == null:
		return

	_sprint_trigger_count += 1
	apply_battle_time_scale()


func reset_sprint_speed() -> void:
	_sprint_trigger_count = 0
	_accum = 0.0
	apply_battle_time_scale()


func reset_engine_time_scale() -> void:
	_sprint_trigger_count = 0
	Engine.time_scale = 1.0


func play_sfx(
	stream: AudioStream,
	randomize_pitch: bool = false,
	pitch_scale: float = 1.0
) -> void:
	if stream == null:
		return

	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	var final_pitch: float = maxf(
		pitch_scale,
		0.01
	)

	player.stream = stream
	player.bus = sfx_bus
	player.volume_db = sfx_volume_db

	if randomize_pitch:
		var minimum_pitch: float = maxf(
			0.01,
			1.0 - sfx_pitch_variation
		)

		var maximum_pitch: float = (
			1.0 + sfx_pitch_variation
		)

		final_pitch *= randf_range(
			minimum_pitch,
			maximum_pitch
		)

	player.pitch_scale = final_pitch

	get_tree().root.add_child.call_deferred(player)
	player.finished.connect(player.queue_free)
	player.play.call_deferred()


func get_task_fire_pitch(
	fire_index: int
) -> float:
	var maximum_pitch: float = maxf(
		task_fire_base_pitch,
		task_fire_max_pitch
	)

	return minf(
		task_fire_base_pitch
		+ task_fire_pitch_step
		* float(fire_index),
		maximum_pitch
	)


func begin_tick_trigger_sfx_sequence() -> void:
	_tick_trigger_sfx_index = 0
	_tick_trigger_sfx_active = true


func end_tick_trigger_sfx_sequence() -> void:
	_tick_trigger_sfx_active = false
	_tick_trigger_sfx_index = 0


func play_next_tick_trigger_sound(
	stream: AudioStream
) -> void:
	if stream == null:
		return

	if not _tick_trigger_sfx_active:
		play_sfx(stream, true)
	else:
		var pitch_scale: float = get_task_fire_pitch(
			_tick_trigger_sfx_index
		)

		_tick_trigger_sfx_index += 1

		play_sfx(
			stream,
			false,
			pitch_scale
		)

	advance_sprint_speed_from_trigger()


func play_stamp_trigger_sound() -> void:
	play_sfx(stamp_trigger_sfx, true)


func play_artifact_trigger_sound() -> void:
	play_next_tick_trigger_sound(
		artifact_trigger_sfx
	)


func load_artifacts() -> void:
	%ArtifactCount.text = (
		"Relic Count "
		+ str(GlobalManager.artifacts.size())
		+ "/"
		+ str(GlobalManager.MAX_ARTIFACTS)
	)

	for a in %ArtifactHBox.get_children():
		a.queue_free()
	icons.clear()

	for a in GlobalManager.artifacts:
		var icon := (
			artifact_icon_scene.instantiate()
			as ArtifactIcon
		)

		icon.artifact = a
		icon.gm = self
		%ArtifactHBox.add_child(icon)
		icons.append(icon)
		a.game_repr = icon


func load_debuff_icons() -> void:
	for child in %DebuffsHBox.get_children():
		child.queue_free()

	debuff_icons.clear()

	var visible_debuffs := (
		get_visible_enemy_debuffs()
	)

	if visible_debuffs.is_empty():
		return

	if debuff_icon_scene == null:
		push_error("Debuff icon scene is not assigned.")
		return

	for active_debuff in visible_debuffs:
		if (
			active_debuff == null
			or active_debuff.debuff == null
		):
			continue

		var icon := (
			debuff_icon_scene.instantiate()
			as DebuffIcon
		)

		if icon == null:
			push_error(
				"Debuff icon scene root does not use DebuffIcon."
			)
			continue

		icon.debuff = active_debuff.debuff
		icon.gm = self
		active_debuff.debuff.game_repr = icon

		%DebuffsHBox.add_child(icon)
		debuff_icons.append(icon)


func _process(delta: float) -> void:
	if battle_ended:
		return

	arrange_items()

	if is_tutorial_active():
		%SubmitButton.disabled = true
		return

	if active_counter != null and not is_ticking:
		countdown_cards(delta)

	%SubmitButton.visible = (
		active_counter == null
		and chosen.size() > 0
	)

	%ScoreBar.max_score = GlobalManager.enemy.health

	%SubmitButton.disabled = (
		active_counter != null
		or chosen.size() < 1
	)

	check_battle_resolution()


func check_battle_resolution() -> void:
	if battle_ended:
		return

	if %ScoreBar.curr_score >= %ScoreBar.max_score:
		end_round()
		return

	if is_ticking or active_counter != null:
		return

	if has_remaining_sprints():
		return

	if _pending_score_amount > 0:
		return

	enter_game_over()


func has_remaining_sprints() -> bool:
	for counter in counters:
		if counter.value > 0:
			return true

	return false


func end_round() -> void:
	if battle_ended:
		return

	battle_ended = true
	previous_day_fired_cards.clear()

	reset_engine_time_scale()
	play_sfx(enemy_defeated_sfx)

	detach_all_cards_from_battle()

	GlobalManager.finish_current_battle()


func enter_game_over() -> void:
	if battle_ended:
		return

	if game_over_scene == null:
		push_error("Game over scene is not assigned.")
		return

	battle_ended = true
	previous_day_fired_cards.clear()

	reset_engine_time_scale()
	play_sfx(game_over_sfx)
	detach_all_cards_from_battle()

	get_tree().change_scene_to_packed(
		game_over_scene
	)


func detach_all_cards_from_battle() -> void:
	for card in GlobalManager.deck:
		if not is_instance_valid(card):
			continue

		if card.get_parent() != null:
			card.get_parent().remove_child(card)

		card.curr = card.max_value
		card.show_damage = false
		card.show_zero_on_damage = true
		card.rotation = 0.0
		card.scale = Vector2.ONE


func get_current_enemy_debuffs() -> Array[ActiveEnemyDebuff]:
	var result: Array[ActiveEnemyDebuff] = []

	if GlobalManager.enemy == null:
		return result

	for active_debuff in GlobalManager.enemy.active_debuffs:
		if active_debuff.applies_to_counter(
			active_counter_index
		):
			result.append(active_debuff)

	return result


func get_global_enemy_debuffs() -> Array[ActiveEnemyDebuff]:
	var result: Array[ActiveEnemyDebuff] = []

	if GlobalManager.enemy == null:
		return result

	for active_debuff in GlobalManager.enemy.active_debuffs:
		if (
			active_debuff != null
			and active_debuff.debuff != null
			and active_debuff.counter_index < 0
		):
			result.append(active_debuff)

	return result


func get_debuff_display_counter_index() -> int:
	if active_counter_index >= 0:
		return active_counter_index

	for i in range(counters.size()):
		if counters[i].value > 0:
			return i

	return -1


func get_visible_enemy_debuffs() -> Array[ActiveEnemyDebuff]:
	var result: Array[ActiveEnemyDebuff] = []

	if GlobalManager.enemy == null:
		return result

	var display_counter_index := (
		get_debuff_display_counter_index()
	)

	for active_debuff in GlobalManager.enemy.active_debuffs:
		if (
			active_debuff != null
			and active_debuff.applies_to_counter(
				display_counter_index
			)
		):
			result.append(active_debuff)

	return result


func countdown_cards(delta: float) -> void:
	if not consume_tick_interval(delta):
		return

	begin_tick_processing()

	var tick_state: TickState = create_tick_state()
	var active_debuffs: Array[ActiveEnemyDebuff] = (
		get_current_enemy_debuffs()
	)

	await run_tick_setup_phase(
		tick_state,
		active_debuffs
	)

	var score_label: SprintScore = await run_tick_damage_phase(
		tick_state
	)

	run_tick_debuff_phase(
		tick_state,
		active_debuffs
	)

	resolve_sprint_score(
		tick_state,
		score_label
	)
	await finish_tick_day(tick_state)
	end_tick_processing()


func run_tick_setup_phase(
	tick_state: TickState,
	active_debuffs: Array[ActiveEnemyDebuff]
) -> void:
	await run_first_tick_callbacks(tick_state)
	run_enemy_pre_tick_callbacks(
		tick_state,
		active_debuffs
	)
	await run_artifact_pre_tick_callbacks(tick_state)

	start_card_countdowns()
	await wait_for_card_animations(tick_state.cards)
	collect_firing_cards(tick_state)


func run_tick_damage_phase(
	tick_state: TickState
) -> SprintScore:
	var score_label: SprintScore = (
		await process_firing_cards(tick_state)
	)

	run_firing_stamp_callbacks(tick_state)
	await wait_for_card_animations(tick_state.cards)

	score_label = await run_artifact_post_tick_callbacks(
		tick_state,
		score_label
	)

	return score_label


func run_tick_debuff_phase(
	tick_state: TickState,
	active_debuffs: Array[ActiveEnemyDebuff]
) -> void:
	run_enemy_post_tick_callbacks(
		tick_state,
		active_debuffs
	)
	run_enemy_hit_callbacks(
		tick_state,
		active_debuffs
	)


func consume_tick_interval(delta: float) -> bool:
	_accum += delta * 3.0

	if _accum <= 1.0:
		return false

	_accum -= 1.0
	return true


func begin_tick_processing() -> void:
	is_ticking = true
	begin_tick_trigger_sfx_sequence()
	play_sfx(day_tick_sfx, true)


func end_tick_processing() -> void:
	end_tick_trigger_sfx_sequence()
	is_ticking = false


func create_tick_state() -> TickState:
	var tick_state: TickState = TickState.new()

	tick_state.gm = self
	tick_state.hand = hand
	tick_state.days = active_counter.value
	tick_state.previous_day_fired_cards.assign(
		previous_day_fired_cards
	)

	for c in chosen:
		tick_state.cards.append(c)
		c.show_damage = false
		c.show_zero_on_damage = true

	return tick_state


func run_first_tick_callbacks(
	tick_state: TickState
) -> void:
	if not first_tick:
		return

	for artifact in GlobalManager.artifacts:
		await artifact.hand_submit_callback(
			tick_state
		)

	first_tick = false


func run_enemy_pre_tick_callbacks(
	tick_state: TickState,
	active_debuffs: Array[ActiveEnemyDebuff]
) -> void:
	for active_debuff in active_debuffs:
		active_debuff.debuff.pre_tick_callback(
			tick_state
		)


func run_artifact_pre_tick_callbacks(
	tick_state: TickState
) -> void:
	for artifact in GlobalManager.artifacts:
		await artifact.pre_tick_callback(
			tick_state
		)


func start_card_countdowns() -> void:
	for card in chosen:
		card.curr -= 1
		card.shake()


func wait_for_card_animations(
	cards: Array[Card]
) -> void:
	for card in cards:
		if card.is_shaking:
			await card.shake_done


func collect_firing_cards(
	tick_state: TickState
) -> void:
	for card in tick_state.cards:
		if card.curr > 0:
			continue

		card.show_damage = true
		tick_state.should_fire = true
		tick_state.today_fired_cards.append(card)

	if tick_state.should_fire:
		tick_state.score = 1


func process_firing_cards(
	tick_state: TickState
) -> SprintScore:
	var score_label: SprintScore = null

	if not tick_state.should_fire:
		return score_label

	for card in tick_state.today_fired_cards:
		tick_state.score *= card.max_value

		play_next_tick_trigger_sound(
			task_fire_sfx
		)

		await card.bump()

		score_label = sync_sprint_score_label(
			tick_state,
			score_label
		)

	return score_label


func run_firing_stamp_callbacks(
	tick_state: TickState
) -> void:
	if not tick_state.should_fire:
		return

	for card in tick_state.today_fired_cards:
		if card.stamp == null:
			continue

		tick_state.current_card = card

		card.stamp.when_hit_callback(
			tick_state
		)

	tick_state.current_card = null


func run_artifact_post_tick_callbacks(
	tick_state: TickState,
	score_label: SprintScore
) -> SprintScore:
	for artifact in GlobalManager.artifacts:
		await artifact.post_tick_callback(
			tick_state
		)

		score_label = sync_sprint_score_label(
			tick_state,
			score_label
		)

	return score_label


func run_enemy_post_tick_callbacks(
	tick_state: TickState,
	active_debuffs: Array[ActiveEnemyDebuff]
) -> void:
	for active_debuff in active_debuffs:
		active_debuff.debuff.post_tick_callback(
			tick_state
		)


func run_enemy_hit_callbacks(
	tick_state: TickState,
	active_debuffs: Array[ActiveEnemyDebuff]
) -> void:
	if not tick_state.should_fire:
		return

	for active_debuff in active_debuffs:
		active_debuff.debuff.when_hit_callback(
			tick_state
		)


func tick_has_positive_score(
	tick_state: TickState
) -> bool:
	return (
		tick_state.score > 0
		or tick_state.bonus_score > 0
	)


func sync_sprint_score_label(
	tick_state: TickState,
	score_label: SprintScore
) -> SprintScore:
	if not tick_has_positive_score(tick_state):
		return score_label

	if score_label == null:
		return show_sprint_score(tick_state)

	update_sprint_score(
		tick_state,
		score_label
	)

	return score_label


func resolve_sprint_score(
	tick_state: TickState,
	score_label: SprintScore
) -> void:
	if tick_has_positive_score(tick_state):
		score_label = sync_sprint_score_label(
			tick_state,
			score_label
		)
		send_sprint_score_off(score_label)
		return

	fade_sprint_score_out(score_label)


func fade_sprint_score_out(
	score_label: SprintScore
) -> void:
	if score_label == null:
		return

	var tween: Tween = score_label.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		score_label,
		"modulate:a",
		0.0,
		0.4
	)

	tween.tween_callback(
		score_label.queue_free
	)


func finish_tick_day(
	tick_state: TickState
) -> void:
	previous_day_fired_cards.assign(
		tick_state.today_fired_cards
	)

	for card in chosen:
		if card.curr <= 0:
			card.curr = card.max_value

	active_counter.value -= 1

	if active_counter.value == 0:
		await finish_sprint()


func finish_sprint() -> void:
	active_counter.active = false
	active_counter = null
	active_counter_index = -1

	previous_day_fired_cards.clear()

	reset_sprint_speed()
	play_sfx(sprint_end_sfx)
	await discard_chosen()
	load_debuff_icons()


func show_sprint_score(
	tick_state: TickState
) -> SprintScore:
	var score_label := (
		%SprintScore.duplicate()
		as SprintScore
	)

	score_label.text = str(
		tick_state.score
		+ tick_state.bonus_score
	)

	score_label.visible = true
	add_child(score_label)

	score_label.global_position = (
		%SprintScore.global_position
	)

	score_label.shake()
	return score_label


func update_sprint_score(
	tick_state: TickState,
	score_label: SprintScore
) -> void:
	score_label.text = str(
		tick_state.score
		+ tick_state.bonus_score
	)
	score_label.shake()


func send_sprint_score_off(
	score_label: Label
) -> void:
	var score_amount: int = int(score_label.text)

	_pending_score_amount += score_amount
	play_sfx(score_launch_sfx, true)

	var tween := score_label.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_await(
		get_tree().create_timer(0.5).timeout
	)

	tween.tween_property(
		score_label,
		"global_position",
		%ScoreBar/ProgressBar.global_position
		+ Vector2(32, -32),
		0.75
	)

	tween.tween_callback(
		func():
			play_sfx(score_impact_sfx, true)
			_pending_score_amount = maxi(
				_pending_score_amount - score_amount,
				0
			)
			%ScoreBar.curr_score += score_amount
			score_label.queue_free()
	)


func arrange_items() -> void:
	for c in drawpile:
		if c.is_shaking or c.is_dealing:
			continue

		c.position = - card_size

	for c in discard:
		if c.is_shaking or c.is_dealing:
			continue

		c.position = - card_size

	for c in GlobalManager.deck:
		if c.is_dealing:
			continue

		c.apply_scene_size()
		c.scale = Vector2.ONE

	arrange_row(hand, 0.75, Vector2(-8, 0))
	arrange_chosen_row()


func arrange_fan_row(
	cards: Array[Card],
	overlap: float = 0.5,
	max_fan_angle: float = PI / 16,
	arc_height: float = 14.0
) -> void:
	var card_count: int = cards.size()

	if card_count == 0:
		return

	var spacing: float = (
		card_size.x
		* (1.0 - overlap)
	)

	var width: float = spacing * (card_count - 1)
	var start_x: float = - width / 2.0
	var middle: float = (card_count - 1) / 2.0

	for i in range(card_count):
		if cards[i].is_shaking:
			continue

		cards[i].apply_scene_size()

		var offset_from_middle: float = (
			float(i) - middle
		)

		var normalized_offset: float = 0.0

		if middle > 0.0:
			normalized_offset = (
				offset_from_middle
				/ middle
			)

		cards[i].position = Vector2(
			start_x + i * spacing,
			arc_height
			* normalized_offset
			* normalized_offset
		)

		cards[i].rotation = (
			normalized_offset
			* max_fan_angle
		)

		cards[i].scale = Vector2.ONE


func get_row_position(
	index: int,
	total: int,
	new_scale: float = 1.0,
	custom_padding: Vector2 = padding
) -> Vector2:
	var width := (
		(card_size.x + custom_padding.x)
		* total
		* new_scale
		- custom_padding.x
		* new_scale
	)

	var start_x: float = - width / 2.0

	return Vector2(
		start_x
		+ index
		* (card_size.x + custom_padding.x)
		* new_scale,
		0
	)


func arrange_row(
	cards: Array,
	new_scale: float = 1.0,
	custom_padding: Vector2 = padding
) -> void:
	for i in range(cards.size()):
		if cards[i].is_shaking or cards[i].is_dealing:
			continue

		cards[i].apply_scene_size()

		cards[i].position = get_row_position(
			i,
			cards.size(),
			new_scale,
			custom_padding
		)

		cards[i].rotation = 0
		cards[i].scale = Vector2.ONE * new_scale


func arrange_chosen_row() -> void:
	var total_slots: int = maxi(GlobalManager.spellslots, chosen.size())
	ensure_chosen_outlines(total_slots)

	var width := (
		(card_size.x + padding.x)
		* total_slots
		- padding.x
	)

	var start_x: float = - width / 2.0

	for i in range(chosen_outlines.size()):
		chosen_outlines[i].visible = i >= chosen.size()
		chosen_outlines[i].custom_minimum_size = card_size
		chosen_outlines[i].size = card_size

		chosen_outlines[i].position = Vector2(
			start_x
			+ i
			* (card_size.x + padding.x),
			0
		)

	for i in range(chosen.size()):
		if chosen[i].is_shaking or chosen[i].is_dealing:
			continue

		chosen[i].apply_scene_size()

		chosen[i].position = Vector2(
			start_x
			+ i
			* (card_size.x + padding.x),
			0
		)

		chosen[i].rotation = 0
		chosen[i].scale = Vector2.ONE


func ensure_chosen_outlines(total: int) -> void:
	while chosen_outlines.size() < total:
		var outline := (
			card_outline_scene.instantiate()
			as Control
		)

		# outline.z_index = -1
		outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
		%ChosenPos.add_child(outline)
		chosen_outlines.append(outline)

	while chosen_outlines.size() > total:
		var outline: Control = chosen_outlines.pop_back()
		outline.queue_free()


func discard_chosen() -> void:
	var discarding: Array[Card] = chosen.duplicate()
	var discarded_any: bool = not discarding.is_empty()

	for c in discarding:
		c.curr = c.max_value
		c.show_damage = false

	chosen.clear()

	for c in discarding:
		discard.append(c)

		var start_global: Vector2 = c.global_position

		%ChosenPos.remove_child(c)
		%DeckContainer.add_child(c)

		c.global_position = start_global
		c.is_dealing = true

	if discarded_any:
		play_sfx(card_discard_sfx, true)

	await get_tree().create_timer(0.25).timeout

	for c in discarding:
		await animate_card_discard(c)

	await deal_hand()


func animate_card_discard(card: Card) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		card,
		"position",
		- card_size,
		0.3
	)

	tween.tween_property(
		card,
		"rotation",
		card.rotation + PI / 10,
		0.3
	)

	tween.tween_property(
		card,
		"scale",
		Vector2.ONE * 0.6,
		0.3
	)

	await tween.finished

	card.is_dealing = false
	card.rotation = 0
	card.scale = Vector2.ONE


func add_to_hand(card) -> void:
	hand.append(card)
	%HandPos.add_child(card)

func reshuffle_discard_into_drawpile() -> void:
	drawpile.append_array(discard)
	discard.clear()
	drawpile.shuffle()


func deal_hand() -> void:
	var drawn_cards: Array[Card] = []

	for _i in range(
		GlobalManager.handsize - hand.size()
	):
		if drawpile.is_empty() and not discard.is_empty():
			reshuffle_discard_into_drawpile()

		if drawpile.size() > 0:
			var card: Card = (
				drawpile.pop_front()
				as Card
			)

			var start_global: Vector2 = card.global_position

			hand.append(card)
			%DeckContainer.remove_child(card)
			%HandPos.add_child(card)
			card.global_position = start_global
			card.is_dealing = true

			drawn_cards.append(card)

	if drawn_cards.is_empty():
		return

	for card in drawn_cards:
		play_sfx(card_draw_sfx, true)

		await animate_card_deal(
			card,
			hand.find(card),
			hand.size()
		)


func animate_card_deal(
	card: Card,
	index: int,
	total: int
) -> void:
	card.apply_scene_size()
	card.rotation = randf_range(-0.15, 0.15)
	card.scale = Vector2.ONE * 0.6

	var target: Vector2 = get_row_position(
		index,
		total,
		0.75,
		Vector2(-8, 0)
	)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		card,
		"position",
		target,
		0.3
	)

	tween.tween_property(
		card,
		"rotation",
		0.0,
		0.3
	)

	tween.tween_property(
		card,
		"scale",
		Vector2.ONE * 0.75,
		0.3
	)

	await tween.finished

	card.is_dealing = false
	card.rotation = 0
	card.scale = Vector2.ONE * 0.75


func on_card_clicked(card: Card) -> void:
	if is_tutorial_active():
		return

	if (
		card in hand
		and chosen.size() < GlobalManager.spellslots
		and active_counter == null
	):
		hand.erase(card)
		chosen.append(card)

		%HandPos.remove_child(card)
		%ChosenPos.add_child(card)

		play_sfx(card_select_sfx, true)

	elif card in chosen and active_counter == null:
		chosen.erase(card)
		hand.append(card)

		%ChosenPos.remove_child(card)
		%HandPos.add_child(card)

		play_sfx(card_deselect_sfx, true)


func on_start_round_pressed() -> void:
	if is_tutorial_active():
		return

	if active_counter != null:
		return

	first_tick = true
	previous_day_fired_cards.clear()

	for i in range(counters.size()):
		var counter: Counter = counters[i]

		if counter.value <= 0:
			continue

		active_counter = counter
		active_counter_index = i
		counter.active = true
		load_debuff_icons()

		begin_sprint_speed()
		play_sfx(sprint_start_sfx)

		var start_state := TickState.new()

		start_state.gm = self
		start_state.hand = hand
		start_state.days = active_counter.value
		start_state.max_days = active_counter.value
		start_state.cards.assign(chosen)

		for active_debuff in get_current_enemy_debuffs():
			active_debuff.debuff.counter_start_callback(
				active_counter,
				start_state
			)

		for card in start_state.cards:
			if card.stamp == null:
				continue

			start_state.current_card = card

			card.stamp.start_of_round_callback(
				start_state
			)

		start_state.current_card = null

		break


func kill_enemy_early_for_debug() -> void:
	%ScoreBar.curr_score = %ScoreBar.max_score


func _exit_tree() -> void:
	reset_engine_time_scale()
