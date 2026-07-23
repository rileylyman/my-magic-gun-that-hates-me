extends CharacterBody2D


const TILE_SIZE := 32
var move_pressed := false


func _physics_process(_delta: float) -> void:
	velocity = Vector2.ZERO

	var inp := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if not move_pressed and inp != Vector2.ZERO:
		var movement := TILE_SIZE * inp
		var collision = move_and_collide(movement, true)
		if collision == null:
			position += movement
		move_pressed = true
	elif inp == Vector2.ZERO:
		move_pressed = false
