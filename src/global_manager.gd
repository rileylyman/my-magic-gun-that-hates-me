extends Node2D

const card_scene: PackedScene = preload("res://src/card.tscn")

@export_category("Enemy Progression")

@export var enemy_order: Array[EnemyResource] = []

@export_range(0.01, 10.0, 0.01, "or_greater")
var enemy_health_multiplier: float = 1.2

enum TaskSelectionMode {
	NONE,
	REMOVE_TASK,
	STAMP_TASK
}

@export var battle_scene: PackedScene
@export var choose_artifact_scene: PackedScene
@export var win_scene: PackedScene
@export var all_tasks_scene: PackedScene

var task_selection_mode: TaskSelectionMode = TaskSelectionMode.NONE

var deck: Array[Card] = []
var artifacts: Array[Artifact] = []

var defeated_enemy_count: int = 0
var enemy: EnemyResource = preload("res://resources/enemies/enemy1.tres")

var spellslots: int:
	get:
		return 3 + artifacts.filter(func(a): return a is ExtraSlot).size()

var handsize : int:
	get:
		return 2 * GlobalManager.artifacts.filter(func(a): return a is ExtraHand).size() + 5



func _ready() -> void:
	create_starting_deck()


func create_starting_deck() -> void:
	for i in range(3, 8 + 1):
		for _j in range(2):
			add_task(i)

func add_task(
	task_value: int,
	stamp_scene: PackedScene = null
) -> Card:
	var task := card_scene.instantiate() as Card

	if task == null:
		push_error("Task scene root does not use the Task class.")
		return null

	task.max_value = task_value

	if stamp_scene != null:
		var generated_stamp := stamp_scene.instantiate() as Stamp

		if generated_stamp == null:
			push_error("Stamp scene root does not use the Stamp class.")
		else:
			task.set_stamp(generated_stamp)

	deck.append(task)

	return task


func open_task_selection(mode: TaskSelectionMode) -> void:
	task_selection_mode = mode

	if all_tasks_scene == null:
		push_error("All-tasks scene is not assigned.")
		return

	get_tree().change_scene_to_packed(all_tasks_scene)


func finish_task_selection() -> void:
	task_selection_mode = TaskSelectionMode.NONE

func load_current_enemy() -> bool:
	if defeated_enemy_count >= enemy_order.size():
		enemy = null
		return false

	var enemy_template := enemy_order[defeated_enemy_count]

	if enemy_template == null:
		push_error(
			"Enemy order index %d does not have an EnemyResource."
			% defeated_enemy_count
		)
		enemy = null
		return false

	enemy = enemy_template.duplicate(true) as EnemyResource

	var health_multiplier := pow(
		enemy_health_multiplier,
		defeated_enemy_count
	)

	enemy.health = maxi(
		1,
		roundi(enemy.health * health_multiplier)
	)

	return true


func enter_current_battle() -> void:
	if not load_current_enemy():
		enter_win_scene()
		return

	if battle_scene == null:
		push_error("Battle scene is not assigned.")
		return

	get_tree().change_scene_to_packed(battle_scene)


func finish_current_battle() -> void:
	defeated_enemy_count += 1
	enemy = null

	if defeated_enemy_count >= enemy_order.size():
		enter_win_scene()
		return

	if choose_artifact_scene == null:
		push_error("Choose artifact scene is not assigned.")
		return

	get_tree().change_scene_to_packed(choose_artifact_scene)


func enter_win_scene() -> void:
	enemy = null

	if win_scene == null:
		push_error("Win scene is not assigned.")
		return

	get_tree().change_scene_to_packed(win_scene)


func has_current_enemy() -> bool:
	return enemy != null


func reset_run() -> void:
	defeated_enemy_count = 0
	enemy = null
