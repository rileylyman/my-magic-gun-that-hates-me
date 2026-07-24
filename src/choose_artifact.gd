extends Control

enum RewardScreen {
	NONE,
	ARTIFACT,
	TASK
}

var all_artifacts: Array[Artifact] = []

var selected_artifact: ArtifactSelector
var selected_task: TaskSelector

var current_screen: RewardScreen = RewardScreen.NONE

@export var done_button: Button

@export var all_rewards: Container
@export var artifact_rewards: Container
@export var task_rewards: Container


func _ready() -> void:
	all_rewards.visible = true
	artifact_rewards.visible = false
	task_rewards.visible = false
	done_button.disabled = true

	if not %ChooseTask.pressed.is_connected(show_task_rewards):
		%ChooseTask.pressed.connect(show_task_rewards)

	if not %ChooseArtifact.pressed.is_connected(show_artifact_rewards):
		%ChooseArtifact.pressed.connect(show_artifact_rewards)

	load_artifacts()
	setup_artifact_selectors()
	setup_task_selectors()


func load_artifacts() -> void:
	var search_dir := "res://resources/artifacts/"

	for file in DirAccess.get_files_at(search_dir):
		if file.ends_with("uid"):
			continue

		var res = load(search_dir + file)

		if res == null or not res.has_method("instantiate"):
			continue

		var artifact = res.instantiate()

		if artifact is Artifact:
			all_artifacts.append(artifact)
		else:
			artifact.free()


func setup_artifact_selectors() -> void:
	if all_artifacts.is_empty():
		return

	for selector in %ArtifactContainer.get_children():
		if selector is not ArtifactSelector:
			continue

		selector.set_artifact(
			all_artifacts[
				randi_range(0, all_artifacts.size() - 1)
			]
		)

		if not selector.pressed.is_connected(
			on_artifact_selected
		):
			selector.pressed.connect(on_artifact_selected)


func setup_task_selectors() -> void:
	for selector in %TaskContainer.get_children():
		if selector is not TaskSelector:
			continue

		if not selector.pressed.is_connected(
			on_task_selected
		):
			selector.pressed.connect(on_task_selected)


func show_artifact_rewards() -> void:
	current_screen = RewardScreen.ARTIFACT
	selected_artifact = null
	selected_task = null

	all_rewards.visible = false
	artifact_rewards.visible = true
	task_rewards.visible = false

	for selector in %ArtifactContainer.get_children():
		if selector is ArtifactSelector:
			selector.selected = false


func show_task_rewards() -> void:
	current_screen = RewardScreen.TASK
	selected_artifact = null
	selected_task = null

	all_rewards.visible = false
	artifact_rewards.visible = false
	task_rewards.visible = true

	for selector in %TaskContainer.get_children():
		if selector is TaskSelector:
			selector.generate_reward()


func on_artifact_selected(selected: ArtifactSelector) -> void:
	for selector in %ArtifactContainer.get_children():
		if selector is ArtifactSelector:
			selector.selected = false

	selected.selected = true
	selected_artifact = selected


func on_task_selected(selected: TaskSelector) -> void:
	for selector in %TaskContainer.get_children():
		if selector is TaskSelector:
			selector.selected = false

	selected.selected = true
	selected_task = selected


func _process(_delta: float) -> void:
	match current_screen:
		RewardScreen.ARTIFACT:
			done_button.disabled = selected_artifact == null

		RewardScreen.TASK:
			done_button.disabled = selected_task == null

		RewardScreen.NONE:
			done_button.disabled = true


func on_done() -> void:
	match current_screen:
		RewardScreen.ARTIFACT:
			if selected_artifact == null:
				return

			GlobalManager.artifacts.append(
				selected_artifact.artifact
			)
			GlobalManager.enter_current_battle()

		RewardScreen.TASK:
			if selected_task == null:
				return

			selected_task.apply_reward()
