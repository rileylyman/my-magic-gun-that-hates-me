extends Artifact
var hightar = 15
var lowtar = 5
var target = 10
var hits = 0
var hashit = false


func update_description() -> void:
	description = "After " + str(target) + " Cards deal Damage, multiply that Damage by " + str(target) + ". This target changes each Round."

func _ready() -> void:
	update_description()


func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		if c.curr <= 0:
			hits += 1
	if hits >= target and !hashit:
		if (state.score > 0):
			state.score *= target
			await shake("x" + str(target))
			hashit = true
	
	if state.days == 1:
		target = randi_range(lowtar, hightar)
		await shake()
		await shake(" New Target: " + str(target) + " ")
		update_description()

func hand_submit_callback(_state: TickState) -> void:
	hits = 0
	hashit = false
