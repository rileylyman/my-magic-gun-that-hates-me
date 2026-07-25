class_name TaskSelector
extends PanelContainer

enum TaskRewardType {
	ADD_TASK,
	REMOVE_TASK,
	STAMP_TASK
}

@export_category("Reward Type Weights")

@export_range(0.0, 100.0, 0.01, "or_greater")
var add_task_weight: float = 1.0

@export_range(0.0, 100.0, 0.01, "or_greater")
var remove_task_weight: float = 1.0

@export_range(0.0, 100.0, 0.01, "or_greater")
var stamp_task_weight: float = 1.0

@export_category("Add Task Generator")

@export var default_value: int = 3
@export var possible_values: Array[TaskValueOption] = []
@export var possible_stamps: Array[StampOption] = []

@export_category("Display")

@export var add_task_title: String = "Add Task"
@export var remove_task_title: String = "Remove Task"
@export var stamp_task_title: String = "Stamp Task"

@export_multiline var remove_task_description: String = \
	"Choose a Task to remove from your deck."

@export_multiline var stamp_task_description: String = \
	"Choose a Task to receive this Stamp."

var reward_type: TaskRewardType = TaskRewardType.ADD_TASK

var generated_value: int
var generated_stamp_scene: PackedScene

var selected: bool = false

var _stylebox: StyleBoxFlat

signal pressed(selected: TaskSelector)


func _ready() -> void:
	_stylebox = (
		get_theme_stylebox("panel").duplicate()
		as StyleBoxFlat
	)

	add_theme_stylebox_override(
		"panel",
		_stylebox
	)


func generate_reward(
	excluded_values: Array[int] = []
) -> void:
	selected = false
	reward_type = generate_reward_type()

	generated_value = default_value
	generated_stamp_scene = null

	if reward_type == TaskRewardType.ADD_TASK:
		var rolled_value: Variant = generate_value(
			excluded_values
		)

		if rolled_value == null:
			reward_type = generate_non_add_reward_type()
		else:
			generated_value = int(rolled_value)

	if reward_type == TaskRewardType.STAMP_TASK:
		generated_stamp_scene = generate_stamp_scene(
			false
		)

		if generated_stamp_scene == null:
			reward_type = TaskRewardType.REMOVE_TASK

	match reward_type:
		TaskRewardType.ADD_TASK:
			generated_stamp_scene = generate_stamp_scene(
				true
			)

			%Title.text = add_task_title
			%Desc.text = get_add_task_description()

		TaskRewardType.REMOVE_TASK:
			generated_stamp_scene = null
			%Title.text = remove_task_title
			%Desc.text = remove_task_description

		TaskRewardType.STAMP_TASK:
			%Title.text = stamp_task_title
			%Desc.text = get_stamp_task_description()


func generate_reward_type() -> TaskRewardType:
	var add_weight := maxf(add_task_weight, 0.0)

	var remove_weight := maxf(
		remove_task_weight,
		0.0
	)

	var stamp_weight := maxf(
		stamp_task_weight,
		0.0
	)

	var total_weight := (
		add_weight
		+ remove_weight
		+ stamp_weight
	)

	if total_weight <= 0.0:
		return TaskRewardType.ADD_TASK

	var roll := randf_range(0.0, total_weight)

	if roll < add_weight:
		return TaskRewardType.ADD_TASK

	roll -= add_weight

	if roll < remove_weight:
		return TaskRewardType.REMOVE_TASK

	return TaskRewardType.STAMP_TASK


func generate_non_add_reward_type() -> TaskRewardType:
	var remove_weight := maxf(
		remove_task_weight,
		0.0
	)

	var stamp_weight := maxf(
		stamp_task_weight,
		0.0
	)

	var total_weight := (
		remove_weight
		+ stamp_weight
	)

	if total_weight <= 0.0:
		return TaskRewardType.REMOVE_TASK

	var roll := randf_range(0.0, total_weight)

	if roll < remove_weight:
		return TaskRewardType.REMOVE_TASK

	return TaskRewardType.STAMP_TASK


func generate_value(
	excluded_values: Array[int] = []
) -> Variant:
	var total_weight := 0.0

	for option in possible_values:
		if (
			option == null
			or option.weight <= 0.0
			or option.value in excluded_values
		):
			continue

		total_weight += option.weight

	if total_weight <= 0.0:
		if default_value not in excluded_values:
			return default_value

		return null

	var roll := randf_range(0.0, total_weight)

	for option in possible_values:
		if (
			option == null
			or option.weight <= 0.0
			or option.value in excluded_values
		):
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.value

	return null


func generate_stamp_scene(
	allow_no_stamp: bool
) -> PackedScene:
	var total_weight := 0.0

	for option in possible_stamps:
		if option == null or option.weight <= 0.0:
			continue

		if (
			not allow_no_stamp
			and option.stamp_scene == null
		):
			continue

		total_weight += option.weight

	if total_weight <= 0.0:
		return null

	var roll := randf_range(0.0, total_weight)

	for option in possible_stamps:
		if option == null or option.weight <= 0.0:
			continue

		if (
			not allow_no_stamp
			and option.stamp_scene == null
		):
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.stamp_scene

	return null


func get_add_task_description() -> String:
	var result := (
		"Add a Task with value %d."
		% generated_value
	)

	if generated_stamp_scene == null:
		result += "\nNo Stamp."
		return result

	result += "\n" + get_stamp_text(
		generated_stamp_scene
	)

	return result


func get_stamp_task_description() -> String:
	var result := stamp_task_description

	if generated_stamp_scene != null:
		result += "\n" + get_stamp_text(
			generated_stamp_scene
		)

	return result


func get_stamp_text(stamp_scene: PackedScene) -> String:
	if stamp_scene == null:
		return "No Stamp"

	var preview_stamp := (
		stamp_scene.instantiate()
		as Stamp
	)

	if preview_stamp == null:
		return "Invalid Stamp"

	var result := "Stamp: " + preview_stamp.title

	if not preview_stamp.description.is_empty():
		result += "\n" + preview_stamp.description

	preview_stamp.free()

	return result


func apply_reward() -> void:
	match reward_type:
		TaskRewardType.ADD_TASK:
			GlobalManager.add_task(
				generated_value,
				generated_stamp_scene
			)

			GlobalManager.enter_current_battle()

		TaskRewardType.REMOVE_TASK:
			GlobalManager.open_task_selection(
				GlobalManager.TaskSelectionMode.REMOVE_TASK
			)

		TaskRewardType.STAMP_TASK:
			if generated_stamp_scene == null:
				push_error(
					"Stamp Task reward has no Stamp."
				)
				return

			GlobalManager.pending_stamp_scene = (
				generated_stamp_scene
			)

			GlobalManager.open_task_selection(
				GlobalManager.TaskSelectionMode.STAMP_TASK
			)


func _process(_delta: float) -> void:
	if _stylebox == null:
		return

	_stylebox.border_color = (
		Color(1, 1, 1, 1)
		if selected
		else Color(1, 1, 1, 0.33333334)
	)


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		pressed.emit(self)
