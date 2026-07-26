extends Artifact

var multiplier := 1.0

func update_description() -> void:
	description = "Multiply all Damage by " + str(multiplier) + ". Each Tick when no Card deals Damage, increase this multiplier by 0.01 permanently."

func _ready() -> void:
	update_description()

func post_tick_callback(state: TickState) -> void:
	

	var fired := 0

	for c in state.cards:
		if c.curr <= 0:
			fired += 1

	if fired == 0:
		multiplier += 0.02
		update_description()
		await shake("+0.02 Mult")
		
	if(state.score>0&&multiplier!=1.0):
		state.score *= multiplier
		await shake("x"+str(multiplier))
