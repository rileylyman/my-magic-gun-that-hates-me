class_name TaskReward
extends Node2D

@export var title: String
@export_multiline var description: String

enum TaskRewardType {
	ADD_TASK,
	REMOVE_TASK,
	STAMP_TASK
}

@export var type: TaskRewardType
@export var value: int = 3

@export var possible_values: Array[TaskValueOption] = []
@export var possible_stamps: Array[StampOption] = []


func selected() -> void:
	match type:
		TaskRewardType.ADD_TASK:
			var generated_value := generate_value()
			var generated_stamp_scene := generate_stamp_scene()

			GlobalManager.add_task(
				generated_value,
				generated_stamp_scene
			)

		TaskRewardType.REMOVE_TASK:
			GlobalManager.open_task_selection(
				GlobalManager.TaskSelectionMode.REMOVE_TASK
			)

		TaskRewardType.STAMP_TASK:
			GlobalManager.open_task_selection(
				GlobalManager.TaskSelectionMode.STAMP_TASK
			)


func generate_value() -> int:
	var total_weight := 0.0

	for option in possible_values:
		if option != null:
			total_weight += maxf(option.weight, 0.0)

	if total_weight <= 0.0:
		return value

	var roll := randf() * total_weight

	for option in possible_values:
		if option == null or option.weight <= 0.0:
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.value

	return value


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
