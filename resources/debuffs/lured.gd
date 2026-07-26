class_name Lured
extends EnemyDebuff


func counter_start_callback(
	_counter: Counter,
	state: TickState
) -> void:
	if state.gm == null or state.cards.is_empty():
		return

	var candidates: Array[Card] = []

	for card in GlobalManager.deck:
		if (
			card != null
			and card not in state.cards
		):
			candidates.append(card)

	if candidates.is_empty():
		return

	var replacement: Card = candidates.pick_random()
	var replaced_card: Card = state.cards[0]

	var chosen_index: int = (
		state.gm.chosen.find(replaced_card)
	)

	if chosen_index < 0:
		return

	var played_parent: Node = replaced_card.get_parent()
	var folder_parent: Node = replacement.get_parent()

	if played_parent == null or folder_parent == null:
		return

	if not replace_card_in_zone(
		state.gm,
		replacement,
		replaced_card
	):
		return

	state.gm.chosen[chosen_index] = replacement
	state.cards[0] = replacement

	played_parent.remove_child(replaced_card)
	folder_parent.remove_child(replacement)

	folder_parent.add_child(replaced_card)
	played_parent.add_child(replacement)

	replaced_card.curr = replaced_card.max_value
	replacement.curr = replacement.max_value

	replaced_card.show_damage = false
	replacement.show_damage = false

	state.gm.arrange_items()


func replace_card_in_zone(
	manager: GameManager,
	old_card: Card,
	new_card: Card
) -> bool:
	var hand_index: int = manager.hand.find(old_card)

	if hand_index >= 0:
		manager.hand[hand_index] = new_card
		return true

	var drawpile_index: int = (
		manager.drawpile.find(old_card)
	)

	if drawpile_index >= 0:
		manager.drawpile[drawpile_index] = new_card
		return true

	var discard_index: int = (
		manager.discard.find(old_card)
	)

	if discard_index >= 0:
		manager.discard[discard_index] = new_card
		return true

	return false
