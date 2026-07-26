class_name ArtifactIcon
extends Control

@export var show_buttons := true
@export var buy_on_click := false

var artifact: Artifact = Artifact.new()
var gm: GameManager
var sibling_icons: Array[ArtifactIcon] = []

var _stylebox: StyleBoxFlat

signal on_buy

func _ready() -> void:
	%Title.text = artifact.title
	%Desc.text = artifact.description
	%Rarity.text = Artifact.ArtifactRarity.keys()[artifact.rarity]
	$Tooltip.visible = false
	$TextureRect.texture = artifact.icon
	%ShakeTextContainer.top_level = true

	_stylebox = %RarityBg.get_theme_stylebox("panel").duplicate()
	%RarityBg.add_theme_stylebox_override("panel", _stylebox)

func force_tooltip_above() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	# var tooltip_height: float = $Tooltip.size.y * $Tooltip.scale.y

	# $Tooltip.top_level = true
	# $Tooltip.global_position = global_position + Vector2(0, -tooltip_height)

func _process(_delta: float) -> void:
	%Title.text = artifact.title
	%Desc.text = artifact.description
	%Rarity.text = Artifact.ArtifactRarity.keys()[artifact.rarity]

	%ButtonContainer.visible = show_buttons

	match artifact.rarity:
		Artifact.ArtifactRarity.COMMON:
			_stylebox.bg_color = Color(0xc68338ff)
		Artifact.ArtifactRarity.UNCOMMON:
			_stylebox.bg_color = Color(0x819e73ff)
		Artifact.ArtifactRarity.CURSED:
			_stylebox.bg_color = Color(0x4034a8ff)
		Artifact.ArtifactRarity.RARE:
			_stylebox.bg_color = Color(0x5f77bfff)
		Artifact.ArtifactRarity.LEGENDARY:
			_stylebox.bg_color = Color(0xa14b22ff)
	
	if $Tooltip.visible:
		var rect = get_global_rect()
		rect = rect.merge($Tooltip.get_global_rect())
		if not rect.has_point(get_viewport().get_mouse_position()):
			$Tooltip.visible = false
			$TextureRect.scale = Vector2(1, 1)

	if $Tooltip.visible:
		var others: Array[ArtifactIcon] = (
			gm.icons if gm != null else sibling_icons
		)

		for a in others:
			if a != self and a != null and a.get_node("Tooltip").visible:
				$Tooltip.visible = false
				$TextureRect.scale = Vector2(1, 1)
				break
	

func _on_mouse_entered() -> void:
	$Tooltip.visible = true
	$TextureRect.scale = Vector2(1.5, 1.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if buy_on_click:
				$Tooltip.visible = false
				$TextureRect.scale = Vector2(1, 1)
				on_buy.emit()

func shake(show_text: String, play_sound: bool)-> void:

	var curr_rot := rotation
	var curr_scale := scale

	var new_rotation := curr_rot + PI / 16
	var new_scale := scale * 1.25

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		self,
		"rotation",
		new_rotation,
		0.15
	)

	tween.tween_property(
		self,
		"scale",
		new_scale,
		0.15
	)

	await tween.finished
	if show_text != "":
		if play_sound:
			gm.play_artifact_trigger_sound()
		%ShakeText.text = show_text
		%ShakeTextContainer.visible = true
		%ShakeTextContainer.global_position = global_position + Vector2(0, 48)

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

	var f = func():
		await get_tree().create_timer(0.5).timeout
		%ShakeTextContainer.visible = false
	f.call()


func _on_go_left_pressed() -> void:
	move_order(-1)


func _on_go_right_pressed() -> void:
	move_order(1)

func move_order(off: int) -> void:
	var idx = GlobalManager.artifacts.find(artifact)
	var new_idx := clampi(idx + off, 0, GlobalManager.artifacts.size() - 1)
	if new_idx == idx:
		return

	GlobalManager.artifacts.remove_at(idx)
	GlobalManager.artifacts.insert(new_idx, artifact)

	if gm != null:
		gm.load_artifacts()


func _on_discard_pressed() -> void:
	GlobalManager.artifacts.erase(artifact)

	if gm != null:
		gm.load_artifacts()
