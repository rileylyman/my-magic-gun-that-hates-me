extends Stamp

@export var value_change: int = 1

func start_of_round_callback(state: TickState) -> void:
	if state.source_card == null:
		return

	var source_index := state.cards.find(
		state.source_card
	)

	if source_index < 0:
		return

	change_card_at_index(
		state,
		source_index - 1
	)

	change_card_at_index(
		state,
		source_index + 1
	)


func change_card_at_index(
	state: TickState,
	index: int
) -> void:
	if index < 0 or index >= state.cards.size():
		return

	var card: Card = state.cards[index]

	card.max_value = maxi(
		1,
		card.max_value + value_change
	)

	card.curr = card.max_value
	card.update_number_feature()
