class_name Artifact
extends Node2D

enum ArtifactRarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY
}

@export var title: String
@export_multiline var description: String
@export var rarity: ArtifactRarity

func pre_tick_callback(_state: TickState) -> void:
	pass

func post_tick_callback(_state: TickState) -> void:
	pass
	
func hand_submit_callback(_state: TickState) -> void:
	pass
