extends Control

var all_artifacts: Array[Artifact] = []
var selected_artifact: ArtifactSelector

@export var done_button: Button


func _ready() -> void:
	var search_dir = "res://resources/artifacts/"

	for file in DirAccess.get_files_at(search_dir):
		if file.ends_with("uid"):
			continue

		var res = load(search_dir + file)

		if res != null and res.has_method("instantiate") and res.instantiate() is Artifact:
			all_artifacts.append(res.instantiate())

	for selector in %ArtifactContainer.get_children():
		selector.set_artifact(all_artifacts[randi_range(0, all_artifacts.size() - 1)])
		selector.pressed.connect(func(selected):
			for s in %ArtifactContainer.get_children():
				s.selected = false
			selected.selected = true
			selected_artifact = selected
		)


func _process(_delta: float) -> void:
	done_button.disabled = selected_artifact == null


func on_done() -> void:
	if selected_artifact == null:
		return

	GlobalManager.artifacts.append(selected_artifact.artifact)
	GlobalManager.enter_current_battle()
