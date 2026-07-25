class_name ArtifactIcon
extends Control

var artifact: Artifact

var _stylebox: StyleBoxFlat

func _ready() -> void:
	%Title.text = artifact.title
	%Desc.text = artifact.description
	%Rarity.text = Artifact.ArtifactRarity.keys()[artifact.rarity]
	$Tooltip.visible = false
	$TextureRect.texture = artifact.icon
	%ShakeTextContainer.top_level = true

	_stylebox = %RarityBg.get_theme_stylebox("panel").duplicate()
	%RarityBg.add_theme_stylebox_override("panel", _stylebox)

func _process(_delta: float) -> void:
	%Title.text = artifact.title
	%Desc.text = artifact.description
	%Rarity.text = Artifact.ArtifactRarity.keys()[artifact.rarity]
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

func _on_mouse_entered() -> void:
	$Tooltip.visible = true


func _on_mouse_exited() -> void:
	$Tooltip.visible = false

func shake(show_text: String = "") -> void:

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
		%GameManager.play_artifact_trigger_sound()
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
