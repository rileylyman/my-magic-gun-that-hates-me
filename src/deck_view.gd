extends Control

signal closed

@export var use_duplicate_cards: bool = false

const card_scene: PackedScene = preload("res://src/card.tscn")

@onready var grid_container: GridContainer = %GridContainer

var _original_parents: Dictionary = {}


func _ready() -> void:
	%SkipArtifactsButton.pressed.connect(close)
	setup_cards()


func open() -> void:
	setup_cards()
	visible = true


func close() -> void:
	restore_cards()
	visible = false
	closed.emit()


func setup_cards() -> void:
	for child in grid_container.get_children():
		if child is Card:
			grid_container.remove_child(child)
			child.queue_free()

	_original_parents.clear()

	for card in GlobalManager.deck:
		var display_card: Card = card

		if use_duplicate_cards:
			display_card = make_duplicate_card(card)
		else:
			_original_parents[card] = card.get_parent()

			if card.get_parent() != null:
				card.get_parent().remove_child(card)

		display_card.apply_scene_size()
		display_card.rotation = 0
		display_card.scale = Vector2.ONE
		display_card.position = Vector2.ZERO
		display_card.visible = true

		grid_container.add_child(display_card)

		if use_duplicate_cards:
			display_card.do_setup()


func make_duplicate_card(card: Card) -> Card:
	var display_card := card_scene.instantiate() as Card

	display_card.max_value = card.max_value
	display_card.curr = card.curr
	display_card.show_damage = card.show_damage
	display_card.show_zero_on_damage = card.show_zero_on_damage

	if card.has_stamp:
		display_card.set_stamp(card.stamp.duplicate())

	return display_card


func restore_cards() -> void:
	if use_duplicate_cards:
		for child in grid_container.get_children():
			if child is Card:
				grid_container.remove_child(child)
				child.queue_free()

		return

	for card in _original_parents:
		if not is_instance_valid(card):
			continue

		if card.get_parent() == grid_container:
			grid_container.remove_child(card)

		var original_parent: Node = _original_parents[card]

		if original_parent != null and is_instance_valid(original_parent):
			original_parent.add_child(card)

	_original_parents.clear()


func _exit_tree() -> void:
	restore_cards()
