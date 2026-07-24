class_name EnemyResource
extends Resource

@export var name: String
@export var health: int
@export var counter_values: Array[int]

@export_category("Debuffs")

@export_range(0, 20, 1)
var min_debuffs: int = 0

@export_range(0, 20, 1)
var max_debuffs: int = 0

@export var debuff_pool: Array[EnemyDebuffOption] = []

var active_debuffs: Array[ActiveEnemyDebuff] = []


func roll_debuffs() -> void:
	active_debuffs.clear()

	if debuff_pool.is_empty():
		return

	var candidates: Array[EnemyDebuffOption] = []
	candidates.assign(debuff_pool)

	var minimum := clampi(
		min_debuffs,
		0,
		candidates.size()
	)

	var maximum := clampi(
		max_debuffs,
		minimum,
		candidates.size()
	)

	var amount := randi_range(minimum, maximum)

	for _i in range(amount):
		var option := take_weighted_debuff(candidates)

		if option == null:
			break

		var debuff_copy := option.debuff.duplicate(true) as EnemyDebuff

		if debuff_copy == null:
			continue

		var active_debuff := ActiveEnemyDebuff.new()
		active_debuff.debuff = debuff_copy

		if debuff_copy.scope == EnemyDebuff.Scope.SPRINT:
			active_debuff.counter_index = choose_counter_index(
				option.possible_counter_indices
			)

			if active_debuff.counter_index < 0:
				continue

		active_debuffs.append(active_debuff)


func take_weighted_debuff(
	candidates: Array[EnemyDebuffOption]
) -> EnemyDebuffOption:
	var total_weight := 0.0

	for option in candidates:
		if option == null or option.debuff == null:
			continue

		total_weight += maxf(option.weight, 0.0)

	if total_weight <= 0.0:
		return null

	var roll := randf_range(0.0, total_weight)

	for option in candidates:
		if (
			option == null
			or option.debuff == null
			or option.weight <= 0.0
		):
			continue

		roll -= option.weight

		if roll <= 0.0:
			candidates.erase(option)
			return option

	return null


func choose_counter_index(
	possible_indices: Array[int]
) -> int:
	if counter_values.is_empty():
		return -1

	var valid_indices: Array[int] = []

	for index in possible_indices:
		if (
			index >= 0
			and index < counter_values.size()
			and index not in valid_indices
		):
			valid_indices.append(index)

	if valid_indices.is_empty():
		return randi_range(
			0,
			counter_values.size() - 1
		)

	return valid_indices.pick_random()
