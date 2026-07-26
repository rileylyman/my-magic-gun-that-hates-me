class_name RewardScreen
extends Control

var all_artifacts: Array[Artifact] = []
const artifact_icon_scene: PackedScene = preload(
	"res://src/artifact_icon.tscn"
)

@export_category("Artifact Rarity Weights")

@export_range(0.0, 100.0, 0.01)
var common_weight: float = 60.0

@export_range(0.0, 100.0, 0.01)
var uncommon_weight: float = 25.0

@export_range(0.0, 100.0, 0.01)
var cursed_weight: float = 25.0

@export_range(0.0, 100.0, 0.01)
var rare_weight: float = 10.0

@export_range(0.0, 100.0, 0.01)
var legendary_weight: float = 5.0

@onready var left_shaker: TextureRect = %LeftEnemyShaker
@onready var right_shaker: TextureRect = %RightEnemyShaker

@onready var artifacts_length: int = GlobalManager.artifacts.size()

var _has_bought_artifact := false
var _has_bought_card := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_artifacts()
	setup_artifact_selectors()
	shake_shakers()
	reload_our_artifacts()

func reload_our_artifacts() -> void:
	for a in %OurArtifactsContainer.get_children():
		a.queue_free()

	for a in GlobalManager.artifacts:
		var icon := (
			artifact_icon_scene.instantiate()
			as ArtifactIcon
		)
		icon.show_buttons = false
		icon.artifact = a
		%OurArtifactsContainer.add_child(icon)

func _process(_delta: float) -> void:
	if GlobalManager.artifacts.size() != artifacts_length:
		artifacts_length = GlobalManager.artifacts.size()
		reload_our_artifacts()

func shake_shakers() -> void:
	var dir = 1
	var left_orig_scale := left_shaker.scale
	var right_orig_scale := right_shaker.scale

	while true:
		await get_tree().create_timer(1.0).timeout
		left_shaker.rotation = dir * PI / 8
		right_shaker.rotation = - dir * PI / 8

		await get_tree().create_timer(0.5).timeout
		left_shaker.scale = left_orig_scale * 1.25
		right_shaker.scale = right_orig_scale * 1.25

		await get_tree().create_timer(0.5).timeout
		left_shaker.scale = left_orig_scale
		right_shaker.scale = right_orig_scale
		left_shaker.rotation = 0
		right_shaker.rotation = 0

		dir *= -1

func load_artifacts() -> void:
	var search_dir := "res://resources/artifacts/"

	for file in DirAccess.get_files_at(search_dir):
		if file.ends_with(".uid"):
			continue

		var scene := (
			load(search_dir + file)
			as PackedScene
		)

		if scene == null:
			continue

		var artifact_instance: Node = scene.instantiate()

		if artifact_instance is not Artifact:
			artifact_instance.free()
			continue

		var artifact := artifact_instance as Artifact

		if player_has_artifact(artifact):
			artifact.free()
			continue

		all_artifacts.append(artifact)

func player_has_artifact(candidate: Artifact) -> bool:
	for owned_artifact in GlobalManager.artifacts:
		if owned_artifact == null:
			continue

		if (
			not candidate.scene_file_path.is_empty()
			and candidate.scene_file_path
			== owned_artifact.scene_file_path
		):
			return true

	return false


func setup_artifact_selectors() -> void:
	var candidates: Array[Artifact] = []
	candidates.assign(all_artifacts)

	for a in %ArtifactContainer.get_children():
		var artifact: Artifact = (
			take_weighted_artifact(candidates)
		)

		if artifact == null:
			a.visible = false
			continue

		a.visible = true
		a.artifact = artifact
		a._ready()
		a.force_tooltip_above()
		a.on_buy.connect(func():
			if _has_bought_artifact:
				return

			_has_bought_artifact = true
			await a.shake(" Yay! ", false)
			await get_tree().create_timer(0.5).timeout
			GlobalManager.artifacts.append(artifact)
			go_away_artifacts()
		)

		# if not a.pressed.is_connected(
		# 	on_artifact_selected
		# ):
		# 	a.pressed.connect(
		# 		on_artifact_selected
		# 	)


func _on_skip_artifacts_button_pressed() -> void:
	_has_bought_artifact = true
	var i = 0
	for a in %ArtifactContainer.get_children():
		i += 1
		if i == %ArtifactContainer.get_child_count():
			await a.shake(" Aw ", false)
			await get_tree().create_timer(0.25).timeout
		else:
			a.shake(" Aw ", false)
	go_away_artifacts()


func go_away_artifacts() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(%ArtifactControl, "position:x", -1000, 1.0)


func take_weighted_artifact(
	candidates: Array[Artifact]
) -> Artifact:
	var total_weight := 0.0

	for artifact in candidates:
		total_weight += get_artifact_weight(artifact)

	if total_weight <= 0.0:
		return null

	var roll := randf_range(0.0, total_weight)

	for artifact in candidates:
		var weight := get_artifact_weight(artifact)

		if weight <= 0.0:
			continue

		roll -= weight

		if roll <= 0.0:
			candidates.erase(artifact)
			return artifact

	return null


func get_artifact_weight(artifact: Artifact) -> float:
	match artifact.rarity:
		Artifact.ArtifactRarity.COMMON:
			return maxf(common_weight, 0.0)

		Artifact.ArtifactRarity.UNCOMMON:
			return maxf(uncommon_weight, 0.0)

		Artifact.ArtifactRarity.CURSED:
			return maxf(cursed_weight, 0.0)

		Artifact.ArtifactRarity.RARE:
			return maxf(rare_weight, 0.0)

		Artifact.ArtifactRarity.LEGENDARY:
			return maxf(legendary_weight, 0.0)

	return 0.0


func generate_task_rewards() -> void:
	var used_add_task_values: Array[int] = []

	for selector in %TaskContainer.get_children():
		if selector is not TaskSelector:
			continue

		selector.generate_reward(
			used_add_task_values
		)

		if (
			selector.reward_type
			== TaskSelector.TaskRewardType.ADD_TASK
		):
			used_add_task_values.append(
				selector.generated_value
			)
