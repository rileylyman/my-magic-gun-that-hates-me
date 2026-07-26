extends Artifact

var temporary_copies: Array[Card] = []


func encounter_start_callback() -> void:
	temporary_copies.clear()

	if false:
		await Engine.get_main_loop().process_frame


func hand_submit_callback(state: TickState) -> void:
	if state.cards.size() != 1:
		return

	var temporary_copy := create_temporary_copy(
		state.cards[0],
		state
	)

	if temporary_copy == null:
		return

	temporary_copies.append(temporary_copy)

	await shake("COPY")


func post_tick_callback(state: TickState) -> void:
	if (
		state.days == 1
		and not temporary_copies.is_empty()
	):
		var cleanup_callable := Callable(
			self,
			"cleanup_temporary_copies"
		).bind(state.gm)

		cleanup_callable.call_deferred()

	if false:
		await Engine.get_main_loop().process_frame


func create_temporary_copy(
	source_card: Card,
	state: TickState
) -> Card:
	if state.gm == null:
		return null

	if state.gm.card_scene == null:
		push_error("GameManager card_scene is not assigned.")
		return null

	var chosen_position := (
		state.gm.get_node_or_null("%ChosenPos")
	)

	if chosen_position == null:
		push_error("ChosenPos could not be found.")
		return null

	var temporary_copy := (
		state.gm.card_scene.instantiate()
		as Card
	)

	if temporary_copy == null:
		push_error("Card scene root does not use Card.")
		return null

	temporary_copy.max_value = source_card.max_value

	chosen_position.add_child(temporary_copy)

	temporary_copy.curr = source_card.curr
	temporary_copy.prepare_for_battle()
	temporary_copy.curr = source_card.curr
	temporary_copy.do_setup()

	if source_card.stamp != null:
		var copied_stamp := (
			source_card.stamp.duplicate()
			as Stamp
		)

		if copied_stamp != null:
			temporary_copy.set_stamp(copied_stamp)

	state.gm.chosen.append(temporary_copy)
	state.cards.append(temporary_copy)

	state.gm.arrange_items()

	return temporary_copy


func cleanup_temporary_copies(
	manager: GameManager
) -> void:
	if not is_instance_valid(manager):
		temporary_copies.clear()
		return

	for temporary_copy in temporary_copies:
		if not is_instance_valid(temporary_copy):
			continue

		manager.chosen.erase(temporary_copy)
		manager.hand.erase(temporary_copy)
		manager.drawpile.erase(temporary_copy)
		manager.discard.erase(temporary_copy)

		GlobalManager.deck.erase(temporary_copy)

		if temporary_copy.get_parent() != null:
			temporary_copy.get_parent().remove_child(
				temporary_copy
			)

		temporary_copy.queue_free()

	temporary_copies.clear()
