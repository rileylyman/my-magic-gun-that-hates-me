class_name BattleTutorial
extends Control

signal finished

@export var tutorial_panels: Array[Control] = []
@export var dim_background: ColorRect

var current_panel_index: int = -1
var is_running: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100

	if dim_background != null:
		dim_background.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)
		dim_background.visible = false

	for panel in tutorial_panels:
		if not is_instance_valid(panel):
			continue

		panel.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		set_descendants_mouse_filter_ignore(
			panel
		)

	hide_all_panels()

	is_running = false
	visible = false
	set_process_input(false)

	start_tutorial.call_deferred()


func start_tutorial() -> void:
	if GlobalManager.defeated_enemy_count != 0:
		return

	var first_panel_index := find_next_valid_panel(
		0
	)

	if first_panel_index < 0:
		push_error(
			"BattleTutorial has no valid tutorial panels."
		)
		return

	var canvas_layer := get_parent()

	if canvas_layer is CanvasLayer:
		canvas_layer.visible = true
		canvas_layer.layer = 100

	current_panel_index = first_panel_index
	is_running = true

	modulate = Color.WHITE
	self_modulate = Color.WHITE
	visible = true
	set_process_input(true)

	if dim_background != null:
		dim_background.visible = true

	move_to_front()
	show_current_panel()


func _input(event: InputEvent) -> void:
	if not is_running:
		return

	var should_advance := false

	if event is InputEventMouseButton:
		should_advance = (
			event.button_index
			== MOUSE_BUTTON_LEFT
			and event.pressed
		)

	elif event is InputEventScreenTouch:
		should_advance = event.pressed

	if not should_advance:
		return

	get_viewport().set_input_as_handled()
	show_next_panel()


func show_next_panel() -> void:
	hide_current_panel()

	current_panel_index = find_next_valid_panel(
		current_panel_index + 1
	)

	if current_panel_index < 0:
		finish_tutorial()
		return

	show_current_panel()


func show_current_panel() -> void:
	if (
		current_panel_index < 0
		or current_panel_index
		>= tutorial_panels.size()
	):
		finish_tutorial()
		return

	var panel := tutorial_panels[
		current_panel_index
	]

	if not is_instance_valid(panel):
		show_next_panel()
		return

	show_panel_ancestors(panel)

	panel.modulate = Color.WHITE
	panel.self_modulate = Color.WHITE
	panel.visible = true
	panel.move_to_front()
	panel.queue_redraw()


func hide_current_panel() -> void:
	if (
		current_panel_index < 0
		or current_panel_index
		>= tutorial_panels.size()
	):
		return

	var panel := tutorial_panels[
		current_panel_index
	]

	if is_instance_valid(panel):
		panel.visible = false


func find_next_valid_panel(
	start_index: int
) -> int:
	for index in range(
		start_index,
		tutorial_panels.size()
	):
		if is_instance_valid(
			tutorial_panels[index]
		):
			return index

	return -1


func show_panel_ancestors(
	panel: Control
) -> void:
	var ancestor := panel.get_parent()

	while ancestor != null:
		if ancestor is CanvasItem:
			ancestor.visible = true

		if ancestor == self:
			break

		ancestor = ancestor.get_parent()


func hide_all_panels() -> void:
	for panel in tutorial_panels:
		if is_instance_valid(panel):
			panel.visible = false


func finish_tutorial() -> void:
	hide_all_panels()

	if dim_background != null:
		dim_background.visible = false

	current_panel_index = -1
	is_running = false
	visible = false

	set_process_input(false)
	finished.emit()


func set_descendants_mouse_filter_ignore(
	node: Node
) -> void:
	for child in node.get_children():
		if child is Control:
			child.mouse_filter = (
				Control.MOUSE_FILTER_IGNORE
			)

		set_descendants_mouse_filter_ignore(
			child
		)
