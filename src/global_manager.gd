extends Node2D

const card_scene: PackedScene = preload("res://src/card.tscn")
const MAX_ARTIFACTS: int = 5

@export_category("Enemy Progression")

@export var enemy_order: Array[EnemyResource] = []
@export var Challenge_enemy_order: Array[EnemyResource] = []

@export_category("Artifacts")

@export var artifact_scenes: Array[PackedScene] = []

@export_range(0.01, 10.0, 0.01, "or_greater")
var enemy_health_multiplier: float = 1.2

enum TaskSelectionMode {
	NONE,
	REMOVE_TASK,
	STAMP_TASK
}

@export var battle_scene: PackedScene
@export var reward_scene: PackedScene
@export var win_scene: PackedScene
@export var all_tasks_scene: PackedScene
@export var main_menu_scene: PackedScene

var last_defeated_enemy: EnemyResource = null

var pending_stamp_scene: PackedScene

var task_selection_mode: TaskSelectionMode = TaskSelectionMode.NONE

var deck: Array[Card] = []
var artifacts: Array[Artifact] = []

var defeated_enemy_count: int = 0
var enemy: EnemyResource = preload(
	"res://resources/enemies/enemy1.tres"
)

var spellslots: int:
	get:
		return (
			3
			+ artifacts.filter(
				func(a): return a is ExtraSlot
			).size()
		)

var handsize: int:
	get:
		return (
			2
			* artifacts.filter(
				func(a): return a is ExtraHand
			).size() + 5
		)

func _challenge_mode() -> void:
	enemy_order = Challenge_enemy_order

func _ready() -> void:
	create_starting_deck()

var decklista = [3, 3, 4, 4, 5, 6, 7, 7, 8, 9, 10]
var decklistb = [3, 4, 5, 5, 6, 7, 7, 8, 9]
func create_starting_deck() -> void:
	#for i in range(3, 8 + 1):
		#for _j in range(2):
			#add_task(i)
	#this is tester deck spot
	for i in decklistb:
		add_task(i)


func add_task(
	task_value: int,
	stamp_scene: PackedScene = null
) -> Card:
	var task := card_scene.instantiate() as Card

	if task == null:
		push_error(
			"Task scene root does not use the Card class."
		)
		return null

	task.max_value = task_value

	if stamp_scene != null:
		var generated_stamp := (
			stamp_scene.instantiate()
			as Stamp
		)

		if generated_stamp == null:
			push_error(
				"Stamp scene root does not use the Stamp class."
			)
		else:
			task.set_stamp(generated_stamp)

	deck.append(task)

	return task


func add_artifact(
	artifact: Artifact
) -> bool:
	if artifact == null:
		return false

	if artifacts.size() >= MAX_ARTIFACTS:
		return false

	artifacts.append(artifact)
	return true


func can_add_artifact() -> bool:
	return artifacts.size() < MAX_ARTIFACTS


func open_task_selection(
	mode: TaskSelectionMode
) -> void:
	task_selection_mode = mode

	if all_tasks_scene == null:
		push_error("All-tasks scene is not assigned.")
		return

	get_tree().change_scene_to_packed(
		all_tasks_scene
	)


func finish_task_selection() -> void:
	task_selection_mode = TaskSelectionMode.NONE
	pending_stamp_scene = null


func load_current_enemy() -> bool:
	if defeated_enemy_count >= enemy_order.size():
		enemy = null
		return false

	var enemy_template := (
		enemy_order[defeated_enemy_count]
	)

	if enemy_template == null:
		push_error(
			"Enemy order index %d does not have an EnemyResource."
			% defeated_enemy_count
		)

		enemy = null
		return false

	enemy = (
		enemy_template.duplicate(true)
		as EnemyResource
	)

	var health_multiplier := pow(
		enemy_health_multiplier,
		defeated_enemy_count
	)

	enemy.health = maxi(
		1,
		roundi(
			enemy.health
			* health_multiplier
		)
	)

	enemy.roll_debuffs()

	return true


func enter_current_battle() -> void:
	if not load_current_enemy():
		enter_win_scene()
		return

	if battle_scene == null:
		push_error("Battle scene is not assigned.")
		return

	get_tree().change_scene_to_packed(
		battle_scene
	)


func finish_current_battle() -> void:
	last_defeated_enemy = enemy
	defeated_enemy_count += 1
	enemy = null

	if defeated_enemy_count >= enemy_order.size():
		enter_win_scene()
		return

	if reward_scene == null:
		push_error(
			"Reward scene is not assigned."
		)
		return

	get_tree().change_scene_to_packed(
		reward_scene
	)


func enter_win_scene() -> void:
	enemy = null

	if win_scene == null:
		push_error("Win scene is not assigned.")
		return

	get_tree().change_scene_to_packed(
		win_scene
	)


func has_current_enemy() -> bool:
	return enemy != null


func reset_run() -> void:
	defeated_enemy_count = 0
	enemy = null
