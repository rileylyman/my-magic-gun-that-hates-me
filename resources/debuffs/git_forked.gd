class_name GitForked
extends EnemyDebuff

func when_hit_callback(state: TickState) -> void:
	for card in state.cards:
		if card.curr == 3:
			state.score = 0
			return
