class_name Card
extends Control

@export var max_value: int = 5

@onready var curr := max_value

var show_damage := false
var is_shaking := false
var game_mgr: GameManager
var reward_mgr: RewardScreen

var stamp: Stamp
var has_stamp: bool

var show_zero_on_damage := true

var _scene_size: Vector2
var _scene_size_cached := false

signal pressed(card: Card)
signal mouse_enter()
signal mouse_exit()
signal shake_done


func _ready() -> void:
	cache_scene_size()
	apply_scene_size()
	do_setup()
	update_number_feature()


func cache_scene_size() -> void:
	if _scene_size_cached:
		return

	_scene_size = size
	_scene_size_cached = true


func apply_scene_size() -> void:
	cache_scene_size()

	custom_minimum_size = _scene_size
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	size = _scene_size


func prepare_for_task_grid() -> void:
	apply_scene_size()

	curr = max_value
	show_damage = false
	show_zero_on_damage = true
	is_shaking = false

	visible = true
	modulate = Color.WHITE
	rotation = 0
	scale = Vector2.ONE
	position = Vector2.ZERO

	update_number_feature()


func prepare_for_battle() -> void:
	apply_scene_size()

	curr = max_value
	show_damage = false
	show_zero_on_damage = true
	is_shaking = false

	visible = true
	modulate = Color.WHITE
	rotation = 0
	scale = Vector2.ONE
	position = Vector2.ZERO

	update_number_feature()


func do_setup() -> void:
	game_mgr = null
	reward_mgr = null

	var current_scene := get_tree().current_scene

	if current_scene == null:
		return

	var manager := current_scene.find_child(
		"GameManager",
		true,
		false
	)

	if manager is GameManager:
		game_mgr = manager

	if current_scene is RewardScreen:
		reward_mgr = current_scene


func _process(_delta: float) -> void:
	%TitleLabel.text = str(max_value)
	%ShootLabel.text = str(max_value)
	%CountdownLabel.text = str(curr)

	%ShootLabel.visible = false

	if show_damage:
		%CountdownLabel.text = (
			str(0)
			if show_zero_on_damage
			else str(max_value)
		)


func update_number_feature() -> void:
	var features := PackedStringArray()

	if max_value % 2 == 0:
		features.append("EVEN")
	else:
		features.append("ODD")

	if is_prime(max_value):
		features.append("PRIME")

	if is_perfect_square(max_value):
		features.append("SQUARED")

	%NumberFeature.text = " • ".join(features)
	update_stamp_display()


func update_stamp_display() -> void:
	has_stamp = stamp != null

	if not has_stamp:
		%Stamp.text = ""
		%StampTexture.texture = null
		%StampTexture.visible = false
		return

	%Stamp.text = stamp.description
	%StampTexture.texture = stamp.stamp_texture
	%StampTexture.visible = stamp.stamp_texture != null


func is_prime(number: int) -> bool:
	if number < 2:
		return false

	if number == 2:
		return true

	if number % 2 == 0:
		return false

	var divisor := 3

	while divisor * divisor <= number:
		if number % divisor == 0:
			return false

		divisor += 2

	return true


func is_perfect_square(number: int) -> bool:
	if number < 0:
		return false

	var root := int(sqrt(float(number)))

	return root * root == number


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		pressed.emit(self)

		if game_mgr != null:
			game_mgr.on_card_clicked(self)


func set_stamp(new_stamp: Stamp) -> void:
	if new_stamp == null:
		return

	if stamp != null:
		stamp.queue_free()

	stamp = new_stamp
	has_stamp = true
	add_child(stamp)
	update_stamp_display()


func clear_stamp() -> void:
	if stamp != null:
		stamp.queue_free()

	stamp = null
	has_stamp = false
	update_stamp_display()


func _on_mouse_entered() -> void:
	$Tooltip.visible = true


func _on_mouse_exited() -> void:
	$Tooltip.visible = false


func shake() -> void:
	is_shaking = true

	var curr_rot := rotation
	var curr_scale := scale

	var new_rotation := curr_rot + PI / 32
	var new_scale := scale * 1.05

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"rotation",
		new_rotation,
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		new_scale,
		0.1
	)

	await tween.finished

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"rotation",
		curr_rot,
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		curr_scale,
		0.1
	)

	await tween.finished

	rotation = curr_rot
	scale = curr_scale

	is_shaking = false
	shake_done.emit()


func bump() -> void:
	is_shaking = true

	var curr_pos := global_position
	var curr_scale := scale

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"global_position",
		curr_pos + Vector2(0, -16),
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		Vector2(0, scale.y),
		0.1
	)

	await tween.finished

	show_zero_on_damage = false

	tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"global_position",
		curr_pos,
		0.1
	)

	tween.tween_property(
		self,
		"scale",
		curr_scale,
		0.1
	)

	await tween.finished

	is_shaking = false
	shake_done.emit()
