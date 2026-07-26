extends TextureButton

const stamp_button_textures: Dictionary = {
	"adder": preload("res://art/Stamp_adder.png"),
	"lupine": preload("res://art/Stamp_lupine.png"),
	"newt": preload("res://art/Stamp_Newt.png"),
	"possum": preload("res://art/Stamp_possum.png"),
	"raccoon": preload("res://art/Stamp_raccoon.png"),
	"squirrel": preload("res://art/Stamp_squirrel.png"),
}

var stamp_scene: PackedScene
var _base_position: Vector2


func _ready() -> void:
	_base_position = position
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_stamp_scene(scene: PackedScene) -> void:
	stamp_scene = scene

	var path := scene.resource_path.to_lower()

	for keyword in stamp_button_textures:
		if path.contains(keyword):
			texture_normal = stamp_button_textures[keyword]
			break

	var preview := scene.instantiate() as Stamp

	if preview != null:
		%Desc.text = "%s: %s" % [preview.title, preview.description]
		preview.free()


func _on_mouse_entered() -> void:
	position = _base_position + Vector2(0, -32)
	self_modulate = Color(0.6, 0.6, 0.6, 1.0)
	%Tooltip.visible = true


func _on_mouse_exited() -> void:
	position = _base_position
	self_modulate = Color.WHITE
	%Tooltip.visible = false
