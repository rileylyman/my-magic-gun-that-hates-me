extends Artifact

func post_tick_callback(state: TickState) -> void:
	var fired := []

	for c in state.cards:
		if c.curr <= 0:
			fired.append(c)

	if fired.size() < 2:
		return

	var a = fired[0]
	var b = fired[1]

	if (
		a.max_value != b.max_value
		and is_prime(a.max_value)
		and is_prime(b.max_value)
	):
		state.score *= (a.max_value + b.max_value)
		await shake("x" + str(a.max_value + b.max_value))


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
