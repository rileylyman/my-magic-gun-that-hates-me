class_name GameManager
extends Node2D

@export var card_scene: PackedScene
@export var counter_scene: PackedScene

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
@export var stamp_trigger_sfx: AudioStream
@export var artifact_trigger_sfx: AudioStream

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
var sprint_speed_increase_per_day: float = 0.08

@export_range(1.0, 10.0, 0.1)
var max_sprint_speed_multiplier: float = 2.0

const artifact_icon_scene: PackedScene = preload(
	"res://src/artifact_icon.tscn"
)

var counters: Array[Counter] = []
var active_counter: Counter
var active_counter_index: int = -1

var first_tick: bool = false
var is_ticking: bool = false
var battle_ended: bool = false

var previous_day_fired_cards: Array[Card] = []

var icons: Array[ArtifactIcon] = []

var drawpile: Array[Card] = []
var discard: Array[Card] = []
var hand: Array[Card] = []
var chosen: Array[Card] = []

var card_size: Vector2
var padding: Vector2 = Vector2(24, 24)

var _accum: float = 0.0
var _tick_trigger_sfx_index: int = 0
var _tick_trigger_sfx_active: bool = false
var _sprint_elapsed_days: int = 0


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

	for active_debuff in GlobalManager.enemy.active_debuffs:
		active_debuff.debuff.battle_start_callback(
			self
		)

	load_artifacts()
	
	drawpile.shuffle()

	if drawpile.is_empty():
		push_error("The deck is empty.")
		return

	card_size = drawpile[0].size

	%ScoreBar.max_score = GlobalManager.enemy.health
	%ScoreBar.curr_score = 0
	for a in GlobalManager.artifacts:
		await a.encounter_start_callback()
	deal_hand()


func get_sprint_speed_multiplier() -> float:
	var maximum_speed: float = maxf(
		max_sprint_speed_multiplier,
		1.0
	)

	return minf(
		1.0
		+ float(_sprint_elapsed_days)
		* sprint_speed_increase_per_day,
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
	_sprint_elapsed_days = 0
	_accum = 0.0
	apply_battle_time_scale()


func advance_sprint_speed() -> void:
	_sprint_elapsed_days += 1
	apply_battle_time_scale()


func reset_sprint_speed() -> void:
	_sprint_elapsed_days = 0
	_accum = 0.0
	apply_battle_time_scale()


func reset_engine_time_scale() -> void:
	_sprint_elapsed_days = 0
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

	get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


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
	if not _tick_trigger_sfx_active:
		play_sfx(stream, true)
		return

	var pitch_scale: float = get_task_fire_pitch(
		_tick_trigger_sfx_index
	)

	_tick_trigger_sfx_index += 1

	play_sfx(
		stream,
		false,
		pitch_scale
	)


func play_stamp_trigger_sound() -> void:
	play_sfx(stamp_trigger_sfx, true)


func play_artifact_trigger_sound() -> void:
	play_next_tick_trigger_sound(
		artifact_trigger_sfx
	)


func load_artifacts() -> void:
	for a in %ArtifactHBox.get_children():
		a.queue_free()

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


func _process(delta: float) -> void:
	if battle_ended:
		return

	arrange_items()

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

	if %ScoreBar.curr_score >= %ScoreBar.max_score:
		end_round()


func end_round() -> void:
	if battle_ended:
		return

	battle_ended = true
	previous_day_fired_cards.clear()

	reset_engine_time_scale()
	play_sfx(enemy_defeated_sfx)

	for c in hand:
		%HandPos.remove_child(c)
		%DeckContainer.add_child(c)

	for c in chosen:
		%ChosenPos.remove_child(c)
		%DeckContainer.add_child(c)

	for child in %DeckContainer.get_children():
		var card := child as Card

		if card == null:
			continue

		%DeckContainer.remove_child(card)
		card.curr = card.max_value
		card.show_damage = false

	GlobalManager.finish_current_battle()


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
	finish_tick_day(tick_state)
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
		finish_sprint()
	else:
		advance_sprint_speed()


func finish_sprint() -> void:
	active_counter.active = false
	active_counter = null
	active_counter_index = -1

	previous_day_fired_cards.clear()

	reset_sprint_speed()
	play_sfx(sprint_end_sfx)
	discard_chosen()


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
			%ScoreBar.curr_score += score_amount
			score_label.queue_free()
	)


func arrange_items() -> void:
	for c in drawpile:
		c.position = - card_size

	for c in discard:
		c.position = - card_size

	for c in GlobalManager.deck:
		c.apply_scene_size()
		c.scale = Vector2.ONE

	arrange_row(hand, 0.75, Vector2(-8, 0))
	arrange_row(chosen)


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


func arrange_row(
	cards: Array,
	new_scale: float = 1.0,
	custom_padding: Vector2 = padding
) -> void:
	var width := (
		(card_size.x + custom_padding.x)
		* cards.size()
		* new_scale
		- custom_padding.x
		* new_scale
	)

	var start_x: float = - width / 2.0

	for i in range(cards.size()):
		if cards[i].is_shaking:
			continue

		cards[i].apply_scene_size()

		cards[i].position = Vector2(
			start_x
			+i
			* (card_size.x + custom_padding.x)
			* new_scale,
			0
		)

		cards[i].rotation = 0
		cards[i].scale = Vector2.ONE * new_scale


func discard_chosen() -> void:
	var discarded_any: bool = not chosen.is_empty()

	for c in chosen:
		c.curr = c.max_value
		c.show_damage = false
		discard.append(c)

		%ChosenPos.remove_child(c)
		%DeckContainer.add_child(c)

	chosen.clear()

	if discarded_any:
		play_sfx(card_discard_sfx, true)

	deal_hand()

func add_to_hand(card) -> void:
	hand.append(card)
	%DeckContainer.remove_child(card)
	%HandPos.add_child(card)

func deal_hand() -> void:
	var drew_card: bool = false

	for _i in range(
		GlobalManager.handsize - hand.size()
	):
		if drawpile.size() > 0:
			var card: Card = (
				drawpile.pop_front()
				as Card
			)

			hand.append(card)
			%DeckContainer.remove_child(card)
			%HandPos.add_child(card)
			drew_card = true

	if drew_card:
		play_sfx(card_draw_sfx, true)


func on_card_clicked(card: Card) -> void:
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

		begin_sprint_speed()
		play_sfx(sprint_start_sfx)

		for active_debuff in get_current_enemy_debuffs():
			active_debuff.debuff.counter_start_callback(
				active_counter
			)

		var start_state := TickState.new()

		start_state.gm = self
		start_state.hand = hand
		start_state.days = active_counter.value
		start_state.max_days = active_counter.value
		start_state.cards.assign(chosen)

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
