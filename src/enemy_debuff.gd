class_name EnemyDebuff
extends Resource

enum Scope {
	GLOBAL,
	SPRINT
}

@export var title: String
@export_multiline var description: String
@export var scope: Scope = Scope.GLOBAL


func battle_start_callback(_manager: GameManager) -> void:
	pass


func counter_start_callback(_counter: Counter) -> void:
	pass


func pre_tick_callback(_state: TickState) -> void:
	pass


func post_tick_callback(_state: TickState) -> void:
	pass


func when_hit_callback(_state: TickState) -> void:
	pass
