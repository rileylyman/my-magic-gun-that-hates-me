extends TextureButton

var _base_position: Vector2

func _ready() -> void:
	_base_position = position
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_mouse_entered() -> void:
	position = _base_position + Vector2(0, -32)
	self_modulate = Color(0.6, 0.6, 0.6, 1.0)
	%Tooltip.visible = true


func _on_mouse_exited() -> void:
	position = _base_position
	self_modulate = Color.WHITE
	%Tooltip.visible = false
