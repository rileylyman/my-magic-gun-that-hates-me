extends Control


func _ready() -> void:
	%ViewFullDeckButton.mouse_entered.connect(_on_view_full_deck_mouse_entered)
	%ViewFullDeckButton.mouse_exited.connect(_on_view_full_deck_mouse_exited)
	%ViewFullDeckButton.pressed.connect(_on_view_full_deck_pressed)


func _on_view_full_deck_mouse_entered() -> void:
	%ViewFullDeckButton.get_node("Tooltip").visible = true


func _on_view_full_deck_mouse_exited() -> void:
	%ViewFullDeckButton.get_node("Tooltip").visible = false


func _on_view_full_deck_pressed() -> void:
	%Deck.open()


func _process(_delta: float) -> void:
	# print(get_viewport().gui_get_hovered_control())
	pass
