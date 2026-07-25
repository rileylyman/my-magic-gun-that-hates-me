extends Artifact

var multiplier := 1.0

func update_description() -> void:
	description = "Multiply all Damage by " + str(multiplier) + ". Each Day where a Task fires alone, improve this multiplier by 0.2 permanently."

func _ready() -> void:
	update_description()

func post_tick_callback(state: TickState) -> void:
	state.score *= multiplier

	var fired := 0

	for c in state.cards:
		if c.curr <= 0:
			fired += 1

	if fired == 1:
		multiplier += 0.2
		update_description()
