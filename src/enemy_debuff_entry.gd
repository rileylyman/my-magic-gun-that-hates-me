class_name EnemyDebuffEntry
extends Resource

enum Scope {
	GLOBAL,
	SPRINT
}

@export var debuff: EnemyDebuff
@export var scope: Scope = Scope.GLOBAL

@export_range(1, 20, 1)
var sprint_number: int = 1
