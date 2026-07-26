extends Control

@onready var grid_container: GridContainer = %GridContainer


func _ready() -> void:
	setup_cards()


func setup_cards() -> void:
	for child in grid_container.get_children():
		if child is Card:
			grid_container.remove_child(child)
			child.queue_free()

	for card in GlobalManager.deck:
		if card.get_parent() != null:
			card.get_parent().remove_child(card)

		card.prepare_for_task_grid()
		grid_container.add_child(card)
		card.do_setup()


func _exit_tree() -> void:
	if not is_instance_valid(grid_container):
		return

	for child in grid_container.get_children():
		if child is not Card:
			continue

		grid_container.remove_child(child)
		child.prepare_for_battle()
