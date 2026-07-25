class_name ArtifactIcon
extends Control

var artifact: Artifact

func _ready() -> void:
	%Title.text = artifact.name
	%Desc.text = artifact.description
	$Tooltip.visible = false
	$TextureRect.texture = artifact.icon

func _on_mouse_entered() -> void:
	$Tooltip.visible = true


func _on_mouse_exited() -> void:
	$Tooltip.visible = false
