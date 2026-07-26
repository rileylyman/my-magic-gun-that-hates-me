class_name RewardScreen
extends Control

var all_artifacts: Array[Artifact] = []
const artifact_icon_scene: PackedScene = preload(
	"res://src/artifact_icon.tscn"
)

@export_category("Artifact Rarity Weights")

@export_range(0.0, 100.0, 0.01)
var common_weight: float = 60.0

@export_range(0.0, 100.0, 0.01)
var uncommon_weight: float = 25.0

@export_range(0.0, 100.0, 0.01)
var cursed_weight: float = 25.0

@export_range(0.0, 100.0, 0.01)
var rare_weight: float = 10.0

@export_range(0.0, 100.0, 0.01)
var legendary_weight: float = 5.0

@export_category("Card Rewards")

@export var default_card_value: int = 3
@export var possible_card_values: Array[TaskValueOption] = []

@export_range(0.0, 100.0, 0.1)
var stamp_chance: float = 20.0

@export var possible_card_stamps: Array[StampOption] = []

@export_range(0.0, 100.0, 0.1)
var cut_card_chance: float = 20.0

const cut_card_button_scene: PackedScene = preload(
	"res://src/cut_card_button.tscn"
)

@export_range(0.0, 100.0, 0.1)
var stamp_card_chance: float = 20.0

const stamp_card_button_scene: PackedScene = preload(
	"res://src/stamp_card_button.tscn"
)

@onready var left_shaker: TextureRect = %LeftEnemyShaker
@onready var right_shaker: TextureRect = %RightEnemyShaker

var _last_artifacts_snapshot: Array[Artifact] = GlobalManager.artifacts.duplicate()

var _has_bought_artifact := false
var _has_bought_card := false
var _card_reward_claimed := false

var _card_stamp_scenes: Dictionary = {}
var _all_icons: Array[ArtifactIcon] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_artifacts()
	setup_artifact_selectors()
	setup_card_selectors()
	shake_shakers()
	reload_our_artifacts()

	%ViewFullDeckButton.mouse_entered.connect(_on_view_full_deck_mouse_entered)
	%ViewFullDeckButton.mouse_exited.connect(_on_view_full_deck_mouse_exited)
	%ViewFullDeckButton.pressed.connect(_on_view_full_deck_pressed)
	%Deck.card_destroyed.connect(_on_deck_card_destroyed)
	%Deck.card_stamped.connect(_on_deck_card_stamped)
	%Deck.closed.connect(_on_deck_closed)


func _on_view_full_deck_mouse_entered() -> void:
	%ViewFullDeckButton.get_node("Tooltip").visible = true


func _on_view_full_deck_mouse_exited() -> void:
	%ViewFullDeckButton.get_node("Tooltip").visible = false


func _on_view_full_deck_pressed() -> void:
	%Deck.open()

func reload_our_artifacts() -> void:
	for a in %OurArtifactsContainer.get_children():
		_all_icons.erase(a)
		a.queue_free()

	for a in GlobalManager.artifacts:
		var icon := (
			artifact_icon_scene.instantiate()
			as ArtifactIcon
		)
		icon.show_buttons = true
		icon.artifact = a
		icon.sibling_icons = _all_icons
		_all_icons.append(icon)
		%OurArtifactsContainer.add_child(icon)

func _process(_delta: float) -> void:
	if GlobalManager.artifacts != _last_artifacts_snapshot:
		_last_artifacts_snapshot = GlobalManager.artifacts.duplicate()
		reload_our_artifacts()

	%ContinueButton.visible = (
		_has_bought_artifact
		and _has_bought_card
	)

	%AndLabel.visible = not (
		_has_bought_artifact
		or _has_bought_card
	)


func _on_continue_button_pressed() -> void:
	GlobalManager.enter_current_battle()

func shake_shakers() -> void:
	var dir = 1
	var left_orig_scale := left_shaker.scale
	var right_orig_scale := right_shaker.scale

	while true:
		await get_tree().create_timer(1.0).timeout
		left_shaker.rotation = dir * PI / 8
		right_shaker.rotation = - dir * PI / 8

		await get_tree().create_timer(0.5).timeout
		left_shaker.scale = left_orig_scale * 1.25
		right_shaker.scale = right_orig_scale * 1.25

		await get_tree().create_timer(0.5).timeout
		left_shaker.scale = left_orig_scale
		right_shaker.scale = right_orig_scale
		left_shaker.rotation = 0
		right_shaker.rotation = 0

		dir *= -1

func load_artifacts() -> void:
	var search_dir := "res://resources/artifacts/"

	for file in DirAccess.get_files_at(search_dir):
		if file.ends_with(".uid"):
			continue

		var scene := (
			load(search_dir + file)
			as PackedScene
		)

		if scene == null:
			continue

		var artifact_instance: Node = scene.instantiate()

		if artifact_instance is not Artifact:
			artifact_instance.free()
			continue

		var artifact := artifact_instance as Artifact

		if player_has_artifact(artifact):
			artifact.free()
			continue

		all_artifacts.append(artifact)

func player_has_artifact(candidate: Artifact) -> bool:
	for owned_artifact in GlobalManager.artifacts:
		if owned_artifact == null:
			continue

		if (
			not candidate.scene_file_path.is_empty()
			and candidate.scene_file_path
			== owned_artifact.scene_file_path
		):
			return true

	return false


func setup_artifact_selectors() -> void:
	var candidates: Array[Artifact] = []
	candidates.assign(all_artifacts)

	for a in %ArtifactContainer.get_children():
		var artifact: Artifact = (
			take_weighted_artifact(candidates)
		)

		if artifact == null:
			a.visible = false
			continue

		a.visible = true
		a.artifact = artifact
		a.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		a.base_icon_scale = 1.5
		a.hover_icon_scale = 2.0
		a.sibling_icons = _all_icons
		_all_icons.append(a)
		a._ready()
		a.force_tooltip_above()
		a.on_buy.connect(func():
			if _has_bought_artifact:
				return

			if not GlobalManager.add_artifact(artifact):
				await a.shake(" No room! ", false)
				return

			_has_bought_artifact = true
			await a.shake(" Yay! ", false)
			await get_tree().create_timer(0.5).timeout
			go_away_artifacts()
		)

		# if not a.pressed.is_connected(
		# 	on_artifact_selected
		# ):
		# 	a.pressed.connect(
		# 		on_artifact_selected
		# 	)


func _on_skip_artifacts_button_pressed() -> void:
	_has_bought_artifact = true
	var i = 0
	for a in %ArtifactContainer.get_children():
		i += 1
		if i == %ArtifactContainer.get_child_count():
			await a.shake(" Aw ", false)
			await get_tree().create_timer(0.25).timeout
		else:
			a.shake(" Aw ", false)
	go_away_artifacts()


func go_away_artifacts() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(%ArtifactControl, "position:x", -1000, 1.0)


func take_weighted_artifact(
	candidates: Array[Artifact]
) -> Artifact:
	var total_weight := 0.0

	for artifact in candidates:
		total_weight += get_artifact_weight(artifact)

	if total_weight <= 0.0:
		return null

	var roll := randf_range(0.0, total_weight)

	for artifact in candidates:
		var weight := get_artifact_weight(artifact)

		if weight <= 0.0:
			continue

		roll -= weight

		if roll <= 0.0:
			candidates.erase(artifact)
			return artifact

	return null


func get_artifact_weight(artifact: Artifact) -> float:
	match artifact.rarity:
		Artifact.ArtifactRarity.COMMON:
			return maxf(common_weight, 0.0)

		Artifact.ArtifactRarity.UNCOMMON:
			return maxf(uncommon_weight, 0.0)

		Artifact.ArtifactRarity.CURSED:
			return maxf(cursed_weight, 0.0)

		Artifact.ArtifactRarity.RARE:
			return maxf(rare_weight, 0.0)

		Artifact.ArtifactRarity.LEGENDARY:
			return maxf(legendary_weight, 0.0)

	return 0.0


func setup_card_selectors() -> void:
	var used_values: Array[int] = []

	var card_nodes: Array[Card] = []

	for child in %CardControl.get_children():
		if child is Card:
			card_nodes.append(child)

	var available_indices: Array[int] = []

	for i in range(card_nodes.size()):
		available_indices.append(i)

	available_indices.shuffle()

	var cut_card_index := -1

	if (
		not available_indices.is_empty()
		and randf_range(0.0, 100.0) <= cut_card_chance
	):
		cut_card_index = available_indices.pop_back()

	var stamp_card_index := -1
	var stamp_card_scene: PackedScene = null

	if (
		not available_indices.is_empty()
		and randf_range(0.0, 100.0) <= stamp_card_chance
	):
		stamp_card_scene = pick_weighted_stamp_scene()

		if stamp_card_scene != null:
			stamp_card_index = available_indices.pop_back()

	for i in range(card_nodes.size()):
		var card := card_nodes[i]

		if i == cut_card_index:
			card.visible = false
			setup_cut_card_button(card.position)
			continue

		if i == stamp_card_index:
			card.visible = false
			setup_stamp_card_button(card.position, stamp_card_scene)
			continue

		var value := generate_card_value(used_values)
		used_values.append(value)

		var stamp_scene := generate_card_stamp_scene()
		_card_stamp_scenes[card] = stamp_scene

		var original_position: Vector2 = card.position

		card.max_value = value

		if stamp_scene != null:
			var stamp := stamp_scene.instantiate() as Stamp

			if stamp != null:
				card.set_stamp(stamp)

		card.prepare_for_task_grid()
		card.do_setup()
		card.can_buy = true
		card.position = original_position

		if not card.pressed.is_connected(on_card_selected):
			card.pressed.connect(on_card_selected)


func setup_cut_card_button(at_position: Vector2) -> void:
	var button := cut_card_button_scene.instantiate() as TextureButton

	button.position = at_position
	%CardControl.add_child(button)
	button.pressed.connect(_on_cut_card_button_pressed)


func setup_stamp_card_button(at_position: Vector2, stamp_scene: PackedScene) -> void:
	var button := stamp_card_button_scene.instantiate() as TextureButton

	button.position = at_position
	%CardControl.add_child(button)
	button.set_stamp_scene(stamp_scene)
	button.pressed.connect(func(): _on_stamp_card_button_pressed(stamp_scene))


func _on_cut_card_button_pressed() -> void:
	%Deck.open_for_destroy()


func _on_stamp_card_button_pressed(stamp_scene: PackedScene) -> void:
	%Deck.open_for_stamp(stamp_scene)


func _on_deck_card_destroyed() -> void:
	_card_reward_claimed = true


func _on_deck_card_stamped() -> void:
	_card_reward_claimed = true


func _on_deck_closed() -> void:
	if not _card_reward_claimed:
		return

	_card_reward_claimed = false

	if _has_bought_card:
		return

	_has_bought_card = true
	go_away_cards()


func generate_card_value(excluded_values: Array[int]) -> int:
	var total_weight := 0.0

	for option in possible_card_values:
		if (
			option == null
			or option.weight <= 0.0
			or option.value in excluded_values
		):
			continue

		total_weight += option.weight

	if total_weight <= 0.0:
		return default_card_value

	var roll := randf_range(0.0, total_weight)

	for option in possible_card_values:
		if (
			option == null
			or option.weight <= 0.0
			or option.value in excluded_values
		):
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.value

	return default_card_value


func generate_card_stamp_scene() -> PackedScene:
	if randf_range(0.0, 100.0) > stamp_chance:
		return null

	return pick_weighted_stamp_scene()


func pick_weighted_stamp_scene() -> PackedScene:
	var total_weight := 0.0

	for option in possible_card_stamps:
		if (
			option == null
			or option.weight <= 0.0
			or option.stamp_scene == null
		):
			continue

		total_weight += option.weight

	if total_weight <= 0.0:
		return null

	var roll := randf_range(0.0, total_weight)

	for option in possible_card_stamps:
		if (
			option == null
			or option.weight <= 0.0
			or option.stamp_scene == null
		):
			continue

		roll -= option.weight

		if roll <= 0.0:
			return option.stamp_scene

	return null


func on_card_selected(card: Card) -> void:
	if _has_bought_card:
		return

	_has_bought_card = true

	var stamp_scene: PackedScene = _card_stamp_scenes.get(card)

	GlobalManager.add_task(card.max_value, stamp_scene)

	await card.shake()
	await get_tree().create_timer(0.5).timeout
	go_away_cards()


func _on_skip_cards_button_pressed() -> void:
	_has_bought_card = true
	go_away_cards()


func go_away_cards() -> void:
	var t = create_tween().set_ease(Tween.EASE_IN)
	t.tween_property(%CardControl, "position:x", 3000, 1.0)
