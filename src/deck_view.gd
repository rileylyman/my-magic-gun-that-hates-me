extends Control

enum Mode { NONE, DESTROY, STAMP }

signal closed
signal card_destroyed
signal card_stamped

@export var use_duplicate_cards: bool = false

const card_scene: PackedScene = preload("res://src/card.tscn")

@onready var grid_container: GridContainer = %GridContainer

var _original_parents: Dictionary = {}
var _duplicate_originals: Dictionary = {}
var _mode: Mode = Mode.NONE
var _stamp_scene: PackedScene = null


func _ready() -> void:
	%SkipArtifactsButton.pressed.connect(close)
	setup_cards()


func open() -> void:
	_mode = Mode.NONE
	%DestroyPrompt.visible = false
	%StampPrompt.visible = false
	setup_cards()
	visible = true


func open_for_destroy() -> void:
	_mode = Mode.DESTROY
	%DestroyPrompt.visible = true
	%StampPrompt.visible = false
	setup_cards()
	visible = true


func open_for_stamp(stamp_scene: PackedScene) -> void:
	_mode = Mode.STAMP
	_stamp_scene = stamp_scene
	%StampPrompt.visible = true
	%DestroyPrompt.visible = false

	var preview := stamp_scene.instantiate() as Stamp

	if preview != null:
		%StampPromptDesc.text = "%s: %s" % [preview.title, preview.description]
		preview.free()

	setup_cards()
	visible = true


func close() -> void:
	restore_cards()
	_mode = Mode.NONE
	%DestroyPrompt.visible = false
	%StampPrompt.visible = false
	visible = false
	closed.emit()


func setup_cards() -> void:
	for child in grid_container.get_children():
		if child is Card:
			grid_container.remove_child(child)
			child.queue_free()

	_original_parents.clear()
	_duplicate_originals.clear()

	for card in GlobalManager.deck:
		var display_card: Card = card

		if use_duplicate_cards:
			display_card = make_duplicate_card(card)
			_duplicate_originals[display_card] = card
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

		if not display_card.pressed.is_connected(on_card_pressed):
			display_card.pressed.connect(on_card_pressed)


func make_duplicate_card(card: Card) -> Card:
	var display_card := card_scene.instantiate() as Card

	display_card.max_value = card.max_value
	display_card.curr = card.curr
	display_card.show_damage = card.show_damage
	display_card.show_zero_on_damage = card.show_zero_on_damage

	if card.has_stamp:
		display_card.set_stamp(card.stamp.duplicate())

	return display_card


func on_card_pressed(card: Card) -> void:
	match _mode:
		Mode.DESTROY:
			destroy_card(card)
		Mode.STAMP:
			stamp_card(card)


func destroy_card(display_card: Card) -> void:
	_mode = Mode.NONE
	%DestroyPrompt.visible = false

	var original_card: Card = _duplicate_originals.get(
		display_card,
		display_card
	)

	GlobalManager.deck.erase(original_card)
	_original_parents.erase(original_card)
	_duplicate_originals.erase(display_card)

	var tween := create_tween()
	tween.tween_property(
		display_card,
		"scale",
		Vector2.ZERO,
		0.25
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tween.finished

	display_card.queue_free()

	if original_card != display_card and is_instance_valid(original_card):
		original_card.queue_free()

	card_destroyed.emit()


func stamp_card(display_card: Card) -> void:
	_mode = Mode.NONE

	var original_card: Card = _duplicate_originals.get(
		display_card,
		display_card
	)

	var real_stamp := _stamp_scene.instantiate() as Stamp

	if real_stamp != null:
		original_card.set_stamp(real_stamp)

	if display_card != original_card:
		var preview_stamp := _stamp_scene.instantiate() as Stamp

		if preview_stamp != null:
			display_card.set_stamp(preview_stamp)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(
		display_card,
		"scale",
		Vector2(1.15, 1.15),
		0.15
	).set_ease(Tween.EASE_OUT)

	tween.chain().tween_property(
		display_card,
		"scale",
		Vector2.ONE,
		0.15
	).set_ease(Tween.EASE_IN)

	await tween.finished

	card_stamped.emit()


func restore_cards() -> void:
	if use_duplicate_cards:
		for child in grid_container.get_children():
			if child is Card:
				grid_container.remove_child(child)
				child.queue_free()

		_duplicate_originals.clear()
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
