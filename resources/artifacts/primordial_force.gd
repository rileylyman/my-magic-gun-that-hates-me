extends Artifact

func post_tick_callback(state: TickState) -> void:
	for c in state.cards:
		for i in state.cards:
			if c.max_value != i.max_value and is_prime(c.max_value) and is_prime(i.max_value):
				state.score *= (i.max_value + c.max_value)


func is_prime(number: int) -> bool:
	if number <= 1:
		return false
	if number == 2:
		return true
	if number % 2 == 0:
		return false
		
	var i := 3
	while i * i <= number:
		if number % i == 0:
			return false
		i += 2
		
	return true
