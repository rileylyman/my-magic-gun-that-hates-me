class_name EnemyDebuff
extends Resource

@export var title: String
@export_multiline var description: String
@export var icon: Texture = preload("res://art/enemy_debuffs/debuff_amber2.png")

var game_repr: DebuffIcon = null


func shake(show_text: String = "") -> void:
	if game_repr != null:
		await game_repr.shake(show_text, true)


func shake_no_sound(show_text: String = "") -> void:
	if game_repr != null:
		await game_repr.shake(show_text, false)


func battle_start_callback(
	_manager: GameManager
) -> void:
	pass


func counter_start_callback(
	_counter: Counter,
	_state: TickState
) -> void:
	pass


func pre_tick_callback(
	_state: TickState
) -> void:
	pass


func post_tick_callback(
	_state: TickState
) -> void:
	pass


func when_hit_callback(
	_state: TickState
) -> void:
	pass
