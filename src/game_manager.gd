class_name GameManager
extends Node2D

@export var card_scene: PackedScene
@export var counter_scene: PackedScene

@export var deck_container: Node2D
@export var score_bar: ScoreBar
@export var start_round_button: Button

@export var hand_pos_node: Node2D
@export var chosen_pos_node: Node2D
@export var counter_pos_node: Node2D
@onready var hand_pos := hand_pos_node.position
@onready var chosen_pos := chosen_pos_node.position
@onready var counter_pos := counter_pos_node.position

var counters: Array[Counter] = []
var active_counter: Counter

var drawpile: Array[Card] = []
var discard: Array[Card] = []
var hand: Array[Card] = []
var chosen: Array[Card] = []

var card_size: Vector2
var padding: Vector2 = Vector2(10, 10)

var _accum := 0.0

func _ready() -> void:
	for c in GlobalManager.deck:
		c = c.duplicate()
		deck_container.add_child(c)
		drawpile.append(c)

	for v in GlobalManager.enemy.counter_values:
		var c = counter_scene.instantiate()
		c.value = v
		c.active = false
		counters.append(c)
		add_child(c)

	drawpile.shuffle()
	card_size = drawpile[0].size
	score_bar.max_score = GlobalManager.enemy.health
	score_bar.curr_score = 0
	deal_hand()

func _process(delta: float) -> void:
	arrange_items()
	if active_counter != null:
		countdown_cards(delta)
	score_bar.max_score = GlobalManager.enemy.health
	start_round_button.disabled = active_counter != null or chosen.size() < GlobalManager.spellslots

	if score_bar.curr_score >= score_bar.max_score:
		get_tree().change_scene_to_file("res://src/choose-artifact.tscn")

func countdown_cards(delta: float) -> void:
	_accum += delta * 2.0
	for c in hand:
		c.curr = c.max_value

	if _accum > 1.0:
		_accum -= 1.0
		var tick_state := TickState.new()
		for c in chosen:
			tick_state.cards.append(c)
			c.curr -= 1
			if c.curr == 0:
				c.curr = c.max_value
				tick_state.firing_cards.append(c)
		var to_add = 1 if tick_state.firing_cards.size() > 0 else 0
		for f in tick_state.firing_cards:
			to_add *= f.max_value
		tick_state.score = to_add

		for a in GlobalManager.artifacts:
			a.tick_callback(tick_state)
		score_bar.curr_score += to_add

		active_counter.value -= 1
		if active_counter.value == 0:
			active_counter.active = false
			active_counter = null
			discard_chosen()
	

func arrange_items() -> void:
	for c in drawpile:
		c.position = - card_size
	for c in discard:
		c.position = - card_size
	arrange_row(hand_pos, hand)
	arrange_row(chosen_pos, chosen)
	arrange_row(counter_pos, counters)

func arrange_row(center: Vector2, cards: Array) -> void:
	var width = (card_size.x + padding.x) * cards.size()
	var start = center - Vector2(width / 2, 0)
	for i in range(cards.size()):
		cards[i].position = start + Vector2(i * (card_size.x + padding.x), 0)

func discard_chosen() -> void:
	for c in chosen:
		discard.append(c)
	chosen.clear()
	deal_hand()

func deal_hand() -> void:
	for i in range(GlobalManager.handsize - hand.size()):
		if drawpile.size() > 0:
			var card = drawpile.pop_front()
			hand.append(card)
	
func on_card_clicked(card: Card) -> void:
	if card in hand and chosen.size() < GlobalManager.spellslots:
		hand.erase(card)
		chosen.append(card)
	elif card in chosen and active_counter == null:
		chosen.erase(card)
		hand.append(card)

func on_start_round_pressed() -> void:
	if active_counter != null:
		return
	for c in counters:
		if c.value > 0:
			active_counter = c
			c.active = true
			break
