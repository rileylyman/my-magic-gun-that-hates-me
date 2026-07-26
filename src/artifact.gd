class_name Artifact
extends Node2D

enum ArtifactRarity {
	COMMON,
	UNCOMMON,
	CURSED,
	RARE,
	LEGENDARY
}

@export var title: String
@export_multiline var description: String
@export var rarity: ArtifactRarity
@export var icon: Texture = preload("res://art/artifact_icons/13Purple Box.png")

var game_repr: ArtifactIcon = null

# if false blocks to suppress not awaitable warnings
func pre_tick_callback(_state: TickState) -> void:
	if false:
		await Engine.get_main_loop().process_frame

func post_tick_callback(_state: TickState) -> void:
	if false:
		await Engine.get_main_loop().process_frame
	
func hand_submit_callback(_state: TickState) -> void:
	if false:
		await Engine.get_main_loop().process_frame

func shake(show_text: String = "") -> void:
	if game_repr != null:
		await game_repr.shake(show_text, true)

func shake_no_sound(show_text: String = "") -> void:
	if game_repr != null:
		await game_repr.shake(show_text, false)
		
func encounter_start_callback() -> void:
	if false:
		await Engine.get_main_loop().process_frame
