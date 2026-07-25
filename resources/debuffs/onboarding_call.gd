class_name OnboardingCall
extends EnemyDebuff

func when_hit_callback(
	state: TickState
) -> void:
	if state.days < 5:
		state.score *= 0
		state.bonus_score *= 0
