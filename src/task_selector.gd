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
	"Choose a Task to receive a Stamp."

var reward_type: TaskRewardType
var generated_value: int
var generated_stamp_scene: PackedScene

var selected: bool = false

var _stylebox: StyleBoxFlat

signal pressed(selected: TaskSelector)


func _ready() -> void:
	_stylebox = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _stylebox)


func generate_reward() -> void:
	selected = false
	reward_type = generate_reward_type()
	generated_value = default_value
	generated_stamp_scene = null

	match reward_type:
		TaskRewardType.ADD_TASK:
			generated_value = generate_value()
			generated_stamp_scene = generate_stamp_scene()
			%Title.text = add_task_title
			%Desc.text = get_add_task_description()

		TaskRewardType.REMOVE_TASK:
			%Title.text = remove_task_title
			%Desc.text = remove_task_description

		TaskRewardType.STAMP_TASK:
			%Title.text = stamp_task_title
			%Desc.text = stamp_task_description


func generate_reward_type() -> TaskRewardType:
	var add_weight := maxf(add_task_weight, 0.0)
	var remove_weight := maxf(remove_task_weight, 0.0)
	var stamp_weight := maxf(stamp_task_weight, 0.0)

	var total_weight := (
		add_weight
		+ remove_weight
		+ stamp_weight
	)

	if total_weight <= 0.0:
		return TaskRewardType.ADD_TASK

	var roll := randf() * total_weight

	if roll < add_weight:
		return TaskRewardType.ADD_TASK

	roll -= add_weight

	if roll < remove_weight:
		return TaskRewardType.REMOVE_TASK

	return TaskRewardType.STAMP_TASK


func generate_value() -> int:
	var total_weight := 0.0

	for option in possible_values:
		if option != null:
			total_weight += maxf(option.weight, 0.0)

	if total_weight <= 0.0:
		return default_value

	var roll := randf() * total_weight

	for option in possible_values:
		if option == null or option.weight <= 0.0:
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.value

	return default_value


func generate_stamp_scene() -> PackedScene:
	var total_weight := 0.0

	for option in possible_stamps:
		if option != null:
			total_weight += maxf(option.weight, 0.0)

	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight

	for option in possible_stamps:
		if option == null or option.weight <= 0.0:
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.stamp_scene

	return null


func get_add_task_description() -> String:
	var result := "Add a Task with value %d." % generated_value

	if generated_stamp_scene != null:
		result += " This Task comes with a Stamp."
	else:
		result += " This Task has no Stamp."

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
			GlobalManager.open_task_selection(
				GlobalManager.TaskSelectionMode.STAMP_TASK
			)


func _process(_delta: float) -> void:
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
