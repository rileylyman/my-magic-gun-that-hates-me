class_name BoneSpurred
extends EnemyDebuff

var damage_reduction: float = 0.0

const REDUCTION_PER_TICK: float = 0.01
const MAX_DAMAGE_REDUCTION: float = 0.5


func battle_start_callback(
	_manager: GameManager
) -> void:
	damage_reduction = 0.0


func when_hit_callback(state: TickState) -> void:
	var total_damage: int = (
		state.score
		+ state.bonus_score
	)

	if total_damage <= 0:
		return

	var damage_multiplier: float = (
		1.0 - damage_reduction
	)

	var reduced_damage: int = roundi(
		float(total_damage)
		* damage_multiplier
	)

	state.score = reduced_damage
	state.bonus_score = 0

	if reduced_damage <= 0:
		return

	damage_reduction = minf(
		damage_reduction
		+ REDUCTION_PER_TICK,
		MAX_DAMAGE_REDUCTION
	)
