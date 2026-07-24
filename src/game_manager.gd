class_name GameManager
extends Node2D

@export var card_scene: PackedScene
@export var counter_scene: PackedScene
const artifact_icon_scene: PackedScene = preload("res://src/artifact_icon.tscn")

var counters: Array[Counter] = []
var active_counter: Counter
var first_tick
var icons: Array[ArtifactIcon] = []

var drawpile: Array[Card] = []
var discard: Array[Card] = []
var hand: Array[Card] = []
var chosen: Array[Card] = []

var card_size: Vector2
var padding: Vector2 = Vector2(24, 24)

var _accum := 0.0
var battle_ended := false

func _ready() -> void:
	if GlobalManager.enemy == null:
		push_error("No current enemy is loaded.")
		return

	%SubmitButton.pressed.connect(on_start_round_pressed)
	%EnemyNameLabel.text = GlobalManager.enemy.name
	%EncounterNLabel.text = "Encounter " + str(GlobalManager.defeated_enemy_count + 1)

	for c in %HandPos.get_children():
		c.queue_free()
	for c in %ChosenPos.get_children():
		c.queue_free()

	for c in GlobalManager.deck:
		%DeckContainer.add_child(c)
		c.do_setup()
		drawpile.append(c)

	for c in %SprintHBox.get_children():
		c.queue_free()
	for v in GlobalManager.enemy.counter_values:
		var c = counter_scene.instantiate()
		c.value = v
		c.active = false
		counters.append(c)
		%SprintHBox.add_child(c)

	for a in %ArtifactHBox.get_children():
		a.queue_free()
	for a in GlobalManager.artifacts:
		var icon = artifact_icon_scene.instantiate()
		icon.artifact = a
		%ArtifactHBox.add_child(icon)
		icons.append(icon)

	drawpile.shuffle()

	if drawpile.is_empty():
		push_error("The deck is empty.")
		return

	card_size = drawpile[0].size
	%ScoreBar.max_score = GlobalManager.enemy.health
	%ScoreBar.curr_score = 0
	deal_hand()


func _process(delta: float) -> void:
	if battle_ended:
		return

	arrange_items()

	if active_counter != null:
		countdown_cards(delta)

	%SubmitButton.visible = active_counter == null

	%ScoreBar.max_score = GlobalManager.enemy.health
	%SubmitButton.disabled = active_counter != null or chosen.size() < 1

	if %ScoreBar.curr_score >= %ScoreBar.max_score:
		end_round()


func end_round() -> void:
	if battle_ended:
		return

	battle_ended = true

	for c in hand:
		%HandPos.remove_child(c)
		%DeckContainer.add_child(c)
	for c in chosen:
		%ChosenPos.remove_child(c)
		%DeckContainer.add_child(c)

	for c in %DeckContainer.get_children():
		%DeckContainer.remove_child(c)
		c.curr = c.max_value
		c.show_damage = false
	GlobalManager.finish_current_battle()

func countdown_cards(delta: float) -> void:
	_accum += delta * 2.0
	
	if _accum > 1.0:
		_accum -= 1.0
		var tick_state := TickState.new()
		tick_state.hand = hand
		tick_state.days = active_counter.value
		for c in chosen:
			tick_state.cards.append(c)
			c.show_damage = false
		
		if first_tick:
			for a in GlobalManager.artifacts:
				a.hand_submit_callback(tick_state)
			first_tick = false
		for a in GlobalManager.artifacts:
			a.pre_tick_callback(tick_state)

		for c in chosen:
			c.curr -= 1

		for c in tick_state.cards:
			if c.curr <= 0:
				tick_state.should_fire = true
				tick_state.score = 1
				break

		if tick_state.should_fire:
			for c in tick_state.cards:
				if c.curr <= 0:
					tick_state.score *= c.max_value

		for a in GlobalManager.artifacts:
			a.post_tick_callback(tick_state)

		if tick_state.score > 0 or tick_state.bonus_score > 0:
			var s = %SprintScore.duplicate()
			s.text = str(tick_state.score + tick_state.bonus_score)
			s.visible = true
			add_child(s)
			s.global_position = %SprintScore.global_position
			var t = s.create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
			t.tween_await(get_tree().create_timer(0.5).timeout)
			t.tween_property(s, "global_position", %ScoreBar/ProgressBar.global_position + Vector2(32, -32), 0.75)
			t.tween_callback(func():
				s.queue_free()
				%ScoreBar.curr_score += tick_state.score + tick_state.bonus_score
			)

		for c in chosen:
			if c.curr <= 0:
				c.curr = c.max_value
				c.show_damage = true

		active_counter.value -= 1

		if active_counter.value == 0:
			active_counter.active = false
			active_counter = null
			# %ScoreBar.curr_score += _sprint_score
			discard_chosen()


func arrange_items() -> void:
	for c in drawpile:
		c.position = - card_size
	for c in discard:
		c.position = - card_size

	for c in GlobalManager.deck:
		c.scale = Vector2.ONE
	arrange_row(%HandPos.global_position, hand, 0.75)
	arrange_row(%ChosenPos.global_position, chosen)


func arrange_row(center: Vector2, cards: Array, new_scale: float = 1.0) -> void:
	var width = (card_size.x + padding.x) * cards.size() * new_scale - padding.x * new_scale
	var start = center - Vector2(width / 2, 0)

	for i in range(cards.size()):
		cards[i].global_position = start + Vector2(i * (card_size.x + padding.x) * new_scale, 0)
		cards[i].scale = Vector2.ONE * new_scale


func discard_chosen() -> void:
	for c in chosen:
		c.curr = c.max_value
		c.show_damage = false
		discard.append(c)
		%ChosenPos.remove_child(c)
		%DeckContainer.add_child(c)

	chosen.clear()
	deal_hand()


func deal_hand() -> void:
	for i in range(GlobalManager.handsize - hand.size()):
		if drawpile.size() > 0:
			var card = drawpile.pop_front()
			hand.append(card)
			%DeckContainer.remove_child(card)
			%HandPos.add_child(card)


func on_card_clicked(card: Card) -> void:
	if card in hand and chosen.size() < GlobalManager.spellslots and active_counter == null:
		hand.erase(card)
		chosen.append(card)
		%HandPos.remove_child(card)
		%ChosenPos.add_child(card)
	elif card in chosen and active_counter == null:
		chosen.erase(card)
		hand.append(card)
		%ChosenPos.remove_child(card)
		%HandPos.add_child(card)


func on_start_round_pressed() -> void:
	if active_counter != null:
		return
	first_tick = true
	
	for c in counters:
		if c.value > 0:
			active_counter = c
			c.active = true
			break


func kill_enemy_early_for_debug() -> void:
	%ScoreBar.curr_score = %ScoreBar.max_score
