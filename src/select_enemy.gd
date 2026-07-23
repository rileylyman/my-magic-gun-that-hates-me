extends Control

@onready var button: Button = %TemplateButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	button.visible = false
	var search_dir = "res://resources/enemies/"
	for file in DirAccess.get_files_at(search_dir):
		var res = load(search_dir + file)
		var b = button.duplicate()
		%EnemyList.add_child(b)
		b.visible = true
		b.text = res.name + ": " + str(res.health) + " hp (" + file + ")"
		b.pressed.connect(func():
			GlobalManager.enemy = res
			get_tree().change_scene_to_file("res://src/card-prototype.tscn")
		)
