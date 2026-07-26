class_name OnboardingCall
extends EnemyDebuff


func when_hit_callback(
	state: TickState
) -> void:
	if state.days > 5:
		return

	state.score = roundi(
		float(state.score) * 0.5
	)

	state.bonus_score = roundi(
		float(state.bonus_score) * 0.5
	)
	
	await shake(" Onboarded! ")
