class_name Ghosted
extends EnemyDebuff

var card_destroyed := false


func counter_start_callback(
	_counter: Counter,
	_state: TickState
) -> void:
	card_destroyed = false


func post_tick_callback(state: TickState) -> void:
	if card_destroyed or state.days != 1:
		return

	if state.gm == null or state.cards.is_empty():
		return

	var card_to_destroy: Card = state.cards[0]

	card_destroyed = true

	state.cards.erase(card_to_destroy)
	state.today_fired_cards.erase(card_to_destroy)

	state.gm.chosen.erase(card_to_destroy)
	state.gm.hand.erase(card_to_destroy)
	state.gm.drawpile.erase(card_to_destroy)
	state.gm.discard.erase(card_to_destroy)

	GlobalManager.deck.erase(card_to_destroy)

	if card_to_destroy.get_parent() != null:
		card_to_destroy.get_parent().remove_child(
			card_to_destroy
		)
	await shake(" Drowned! ")

	card_to_destroy.queue_free()
