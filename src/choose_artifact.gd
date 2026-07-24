extends Control

var all_artifacts: Array[Artifact] = []

var selected_artifact: ArtifactSelector
var selected_task: TaskSelector

var artifact_passed := false
var task_passed := false

@export var done_button: Button
@export var pass_artifact_button: Button
@export var pass_task_button: Button

@export_category("Artifact Rarity Weights")

@export_range(0.0, 100.0, 0.01)
var common_weight: float = 60.0

@export_range(0.0, 100.0, 0.01)
var uncommon_weight: float = 25.0

@export_range(0.0, 100.0, 0.01)
var rare_weight: float = 10.0

@export_range(0.0, 100.0, 0.01)
var legendary_weight: float = 5.0


func _ready() -> void:
	done_button.disabled = true

	pass_artifact_button.text = "PASS"
	pass_task_button.text = "PASS"

	if not pass_artifact_button.pressed.is_connected(
		on_pass_artifact_pressed
	):
		pass_artifact_button.pressed.connect(
			on_pass_artifact_pressed
		)

	if not pass_task_button.pressed.is_connected(
		on_pass_task_pressed
	):
		pass_task_button.pressed.connect(
			on_pass_task_pressed
		)

	load_artifacts()
	setup_artifact_selectors()
	setup_task_selectors()
	generate_task_rewards()
	update_continue_button()


func load_artifacts() -> void:
	var search_dir := "res://resources/artifacts/"

	for file in DirAccess.get_files_at(search_dir):
		if file.ends_with(".uid"):
			continue

		var res = load(search_dir + file)

		if res == null or not res.has_method("instantiate"):
			continue

		var artifact = res.instantiate()

		if artifact is not Artifact:
			artifact.free()
			continue

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

	for selector in %ArtifactContainer.get_children():
		if selector is not ArtifactSelector:
			continue

		selector.selected = false

		var artifact := take_weighted_artifact(candidates)

		if artifact == null:
			selector.visible = false
			continue

		selector.visible = true
		selector.set_artifact(artifact)

		if not selector.pressed.is_connected(
			on_artifact_selected
		):
			selector.pressed.connect(
				on_artifact_selected
			)


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

		Artifact.ArtifactRarity.RARE:
			return maxf(rare_weight, 0.0)

		Artifact.ArtifactRarity.LEGENDARY:
			return maxf(legendary_weight, 0.0)

	return 0.0


func setup_task_selectors() -> void:
	for selector in %TaskContainer.get_children():
		if selector is not TaskSelector:
			continue

		selector.selected = false

		if not selector.pressed.is_connected(
			on_task_selected
		):
			selector.pressed.connect(
				on_task_selected
			)


func generate_task_rewards() -> void:
	for selector in %TaskContainer.get_children():
		if selector is TaskSelector:
			selector.generate_reward()


func on_artifact_selected(
	selected: ArtifactSelector
) -> void:
	for selector in %ArtifactContainer.get_children():
		if selector is ArtifactSelector:
			selector.selected = false

	selected.selected = true
	selected_artifact = selected
	artifact_passed = false
	pass_artifact_button.text = "PASS"

	update_continue_button()


func on_task_selected(selected: TaskSelector) -> void:
	for selector in %TaskContainer.get_children():
		if selector is TaskSelector:
			selector.selected = false

	selected.selected = true
	selected_task = selected
	task_passed = false
	pass_task_button.text = "PASS"

	update_continue_button()


func on_pass_artifact_pressed() -> void:
	selected_artifact = null
	artifact_passed = true
	pass_artifact_button.text = "PASSED"

	for selector in %ArtifactContainer.get_children():
		if selector is ArtifactSelector:
			selector.selected = false

	update_continue_button()


func on_pass_task_pressed() -> void:
	selected_task = null
	task_passed = true
	pass_task_button.text = "PASSED"

	for selector in %TaskContainer.get_children():
		if selector is TaskSelector:
			selector.selected = false

	update_continue_button()


func update_continue_button() -> void:
	var artifact_decided := (
		selected_artifact != null
		or artifact_passed
	)

	var task_decided := (
		selected_task != null
		or task_passed
	)

	done_button.disabled = not (
		artifact_decided
		and task_decided
	)


func on_done() -> void:
	var artifact_decided := (
		selected_artifact != null
		or artifact_passed
	)

	var task_decided := (
		selected_task != null
		or task_passed
	)

	if not artifact_decided or not task_decided:
		return

	if selected_artifact != null:
		GlobalManager.artifacts.append(
			selected_artifact.artifact
		)

	if selected_task != null:
		selected_task.apply_reward()
	else:
		GlobalManager.enter_current_battle()
