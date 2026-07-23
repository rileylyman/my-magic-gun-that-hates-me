class_name ArtifactSelector
extends PanelContainer

var artifact: Artifact = Artifact.new()
var selected: bool = false

var _stylebox: StyleBoxFlat

signal pressed(selected: ArtifactSelector)

func _ready() -> void:
	_stylebox = get_theme_stylebox("panel").duplicate()
	add_theme_stylebox_override("panel", _stylebox)

func set_artifact(a: Artifact) -> void:
	artifact = a
	%Title.text = a.title
	%Desc.text = a.description

func _process(_delta: float) -> void:
	_stylebox.border_color = Color(1, 1, 1, 1) if selected else Color(1, 1, 1, 0.33333334)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		pressed.emit(self)
