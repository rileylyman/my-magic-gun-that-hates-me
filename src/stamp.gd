class_name Stamp
extends Node2D

@export var title: String
@export_multiline var description: String
@export var stamp_texture: Texture2D


func pre_tick_callback(_state: TickState) -> void:
	pass


func start_of_round_callback(_state: TickState) -> void:
	pass


func when_hit_callback(_state: TickState) -> void:
	pass
