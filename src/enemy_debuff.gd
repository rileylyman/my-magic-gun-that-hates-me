class_name EnemyDebuff
extends Resource

@export var title: String
@export_multiline var description: String


func battle_start_callback(
	_manager: GameManager
) -> void:
	pass


func counter_start_callback(
	_counter: Counter
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
