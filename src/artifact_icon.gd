class_name ArtifactIcon
extends Control

var artifact: Artifact

func _ready() -> void:
	$ArtifactSelector.set_artifact(artifact)
	$ArtifactSelector.visible = false

func _on_mouse_entered() -> void:
	$ArtifactSelector.visible = true


func _on_mouse_exited() -> void:
	$ArtifactSelector.visible = false
