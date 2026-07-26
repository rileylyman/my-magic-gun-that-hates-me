extends Artifact

var recovering_cards: Array[Card] = []


func encounter_start_callback() -> void:
	recovering_cards.clear()

	if false:
		await Engine.get_main_loop().process_frame


func hand_submit_callback(_state: TickState) -> void:
	recovering_cards.clear()

	if false:
		await Engine.get_main_loop().process_frame


func pre_tick_callback(state: TickState) -> void:
	var cards_to_check: Array[Card] = []
	cards_to_check.assign(recovering_cards)

	for card in cards_to_check:
		if (
			not is_instance_valid(card)
			or card not in state.cards
		):
			recovering_cards.erase(card)
			continue

		if card.curr >= card.max_value:
			card.curr = card.max_value
			recovering_cards.erase(card)
			continue

		card.curr = mini(
			card.curr + 2,
			card.max_value + 1
		)

	if false:
		await Engine.get_main_loop().process_frame


func post_tick_callback(state: TickState) -> void:
	if state.today_fired_cards.is_empty():
		return

	state.score *= 3

	for card in state.today_fired_cards:
		if card.max_value <= 0:
			continue

		card.curr = 1

		if card not in recovering_cards:
			recovering_cards.append(card)

	if state.gm != null:
		state.gm.play_artifact_trigger_sound()

	await shake("×3")
