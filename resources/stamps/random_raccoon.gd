extends Stamp

@export var minimum_value: int = 2
@export var maximum_value: int = 10


func when_hit_callback(state: TickState) -> void:
	var source_card := state.current_card

	if source_card == null:
		return

	state.score *= 4

	var lower_value := mini(
		minimum_value,
		maximum_value
	)

	var upper_value := maxi(
		minimum_value,
		maximum_value
	)

	var new_value := randi_range(
		lower_value,
		upper_value
	)

	if upper_value > lower_value:
		while new_value == source_card.max_value:
			new_value = randi_range(
				lower_value,
				upper_value
			)

	source_card.max_value = new_value
	source_card.update_number_feature()
