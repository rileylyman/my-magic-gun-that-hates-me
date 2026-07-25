class_name EnemyResource
extends Resource

@export var name: String
@export var health: int
@export var counter_values: Array[int]

@export_category("Debuffs")

@export var debuffs: Array[EnemyDebuffEntry] = []

var active_debuffs: Array[ActiveEnemyDebuff] = []


func prepare_debuffs() -> void:
	active_debuffs.clear()

	for entry in debuffs:
		if entry == null or entry.debuff == null:
			continue

		var debuff_copy: EnemyDebuff = (
			entry.debuff.duplicate(true)
			as EnemyDebuff
		)

		if debuff_copy == null:
			continue

		var active_debuff: ActiveEnemyDebuff = (
			ActiveEnemyDebuff.new()
		)

		active_debuff.debuff = debuff_copy

		if (
			entry.scope
			== EnemyDebuffEntry.Scope.SPRINT
		):
			var counter_index: int = (
				entry.sprint_number - 1
			)

			if (
				counter_index < 0
				or counter_index
				>= counter_values.size()
			):
				push_warning(
					(
						"Enemy %s has debuff %s "
						+ "assigned to invalid "
						+ "Sprint %d."
					)
					% [
						name,
						debuff_copy.title,
						entry.sprint_number
					]
				)
				continue

			active_debuff.counter_index = (
				counter_index
			)

		active_debuffs.append(active_debuff)


func roll_debuffs() -> void:
	prepare_debuffs()
