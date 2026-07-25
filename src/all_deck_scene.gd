class_name AllTasksScreen
extends Control

signal closed

var selected_card: Card
var opened_as_overlay := false

@export var view_return_scene: PackedScene


func _ready() -> void:
	%BackButton.pressed.connect(on_back_pressed)
	%CancelButton.pressed.connect(on_cancel_pressed)
	%ConfirmButton.pressed.connect(on_confirm_pressed)

	%SelectedTaskLabel.text = ""

	setup_mode()
	setup_cards()
	update_buttons()


func setup_mode() -> void:
	match GlobalManager.task_selection_mode:
		GlobalManager.TaskSelectionMode.NONE:
			%ScreenTitle.text = "All Tasks"
			%StampPreviewContainer.visible = false
			%ConfirmButton.visible = false
			%CancelButton.visible = false
			%BackButton.visible = true

		GlobalManager.TaskSelectionMode.REMOVE_TASK:
			%ScreenTitle.text = "Remove a Task"
			%StampPreviewContainer.visible = false
			%ConfirmButton.visible = true
			%ConfirmButton.text = "REMOVE"
			%CancelButton.visible = true
			%CancelButton.text = "CANCEL"
			%BackButton.visible = false

		GlobalManager.TaskSelectionMode.STAMP_TASK:
			%ScreenTitle.text = "Stamp a Task"
			%StampPreviewContainer.visible = true
			%ConfirmButton.visible = true
			%ConfirmButton.text = "STAMP"
			%CancelButton.visible = true
			%CancelButton.text = "CANCEL"
			%BackButton.visible = false

			setup_stamp_preview()


func setup_cards() -> void:
	for child in %TaskGridContainer.get_children():
		if child is Card:
			%TaskGridContainer.remove_child(child)

	for card in GlobalManager.deck:
		if card.get_parent() != null:
			card.get_parent().remove_child(card)

		card.prepare_for_task_grid()
		%TaskGridContainer.add_child(card)
		card.do_setup()

		if not card.pressed.is_connected(on_card_pressed):
			card.pressed.connect(on_card_pressed)

	%TaskGridContainer.queue_sort()

	%TaskCountLabel.text = str(GlobalManager.deck.size())
	%EmptyDeckLabel.visible = GlobalManager.deck.is_empty()


func setup_stamp_preview() -> void:
	%StampName.text = ""
	%StampDescription.text = ""

	if GlobalManager.pending_stamp_scene == null:
		%StampName.text = "No Stamp"
		return

	var stamp := (
		GlobalManager.pending_stamp_scene.instantiate()
		as Stamp
	)

	if stamp == null:
		%StampName.text = "Invalid Stamp"
		return

	%StampName.text = stamp.title
	%StampDescription.text = stamp.description

	stamp.free()


func on_card_pressed(card: Card) -> void:
	if (
		GlobalManager.task_selection_mode
		== GlobalManager.TaskSelectionMode.NONE
	):
		return

	selected_card = card

	for deck_card in GlobalManager.deck:
		deck_card.modulate = (
			Color(0.7, 1.0, 0.7, 1.0)
			if deck_card == selected_card
			else Color.WHITE
		)

	%SelectedTaskLabel.text = (
		"Selected Task: "
		+ str(selected_card.max_value)
	)

	update_buttons()


func update_buttons() -> void:
	%ConfirmButton.disabled = selected_card == null

	if (
		GlobalManager.task_selection_mode
		== GlobalManager.TaskSelectionMode.STAMP_TASK
		and GlobalManager.pending_stamp_scene == null
	):
		%ConfirmButton.disabled = true


func on_confirm_pressed() -> void:
	if selected_card == null:
		return

	match GlobalManager.task_selection_mode:
		GlobalManager.TaskSelectionMode.REMOVE_TASK:
			remove_selected_card()

		GlobalManager.TaskSelectionMode.STAMP_TASK:
			stamp_selected_card()


func remove_selected_card() -> void:
	var card_to_remove := selected_card

	selected_card = null
	GlobalManager.deck.erase(card_to_remove)

	if card_to_remove.get_parent() != null:
		card_to_remove.get_parent().remove_child(
			card_to_remove
		)

	card_to_remove.free()

	finish_task_action()


func stamp_selected_card() -> void:
	if GlobalManager.pending_stamp_scene == null:
		return

	var new_stamp := (
		GlobalManager.pending_stamp_scene.instantiate()
		as Stamp
	)

	if new_stamp == null:
		push_error(
			"Pending Stamp scene root does not use Stamp."
		)
		return

	selected_card.set_stamp(new_stamp)
	selected_card = null

	finish_task_action()


func finish_task_action() -> void:
	detach_cards()
	GlobalManager.finish_task_selection()
	GlobalManager.enter_current_battle()


func on_cancel_pressed() -> void:
	detach_cards()
	GlobalManager.finish_task_selection()
	GlobalManager.enter_current_battle()


func on_back_pressed() -> void:
	detach_cards()

	if opened_as_overlay:
		closed.emit()
		queue_free()
		return

	if view_return_scene == null:
		push_error("View return scene is not assigned.")
		return

	get_tree().change_scene_to_packed(
		view_return_scene
	)


func detach_cards() -> void:
	if %TaskGridContainer != null:
		if not is_instance_valid(%TaskGridContainer):
			return

	for child in %TaskGridContainer.get_children():
		if child is Card:
			%TaskGridContainer.remove_child(child)
			child.prepare_for_battle()


func open_as_overlay() -> void:
	opened_as_overlay = true
	z_index = 100
	mouse_filter = Control.MOUSE_FILTER_STOP

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


func _exit_tree() -> void:
	detach_cards()
