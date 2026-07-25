extends Control

var all_artifacts: Array[Artifact] = []

@onready var artifact_template_button: Button = %AddArtifactTemplateButton
@onready var artifact_container: VBoxContainer = artifact_template_button.get_parent()

func _ready() -> void:
	visible = false
	artifact_container.remove_child(artifact_template_button)

	load_artifacts()
	for artifact in all_artifacts:
		var b = artifact_template_button.duplicate()
		b.visible = true
		b.text = artifact.name
		b.pressed.connect(func():
			GlobalManager.artifacts.append(artifact)
			b.queue_free()

			var gmgr: GameManager = get_tree().current_scene.find_child("GameManager")
			if gmgr != null:
				gmgr.load_artifacts()
		)
		artifact_container.add_child(b)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		visible = !visible
		move_to_front()

func _on_kill_current_enemy_pressed() -> void:
	var game_mgr = get_tree().current_scene.find_child("GameManager")
	if game_mgr != null:
		game_mgr.kill_enemy_early_for_debug()


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

		all_artifacts.append(artifact)
