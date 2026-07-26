extends Artifact

var multiplier := 1.0

func update_description() -> void:
	description = "Multiply all Damage by " + str(multiplier) + ". Every time two Cards reach 0 together, increase this multiplier by 0.2 permanently."

func _ready() -> void:
	update_description()

func post_tick_callback(state: TickState) -> void:
	

	var fired := 0

	for c in state.cards:
		if c.curr <= 0:
			fired += 1

	if fired >= 2:
		
		multiplier += 0.2
		await shake("+0.2 Mult")
		update_description()
		
	if(state.score>0&&multiplier!=1.0):
		state.score *= multiplier
		await shake("x"+str(multiplier))
