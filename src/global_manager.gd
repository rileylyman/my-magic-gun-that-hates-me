extends Node2D

const card_scene: PackedScene = preload("res://src/card.tscn")

var deck: Array[Card]
var artifacts: Array[Artifact]
var enemy: EnemyResource = preload("res://resources/enemies/enemy1.tres")

var spellslots: int:
	get:
		return 3 + GlobalManager.artifacts.filter(func(a): return a is ExtraSlot).size()

var handsize := 5

func _ready() -> void:
	for i in range(3, 8 + 1):
		for _j in range(2):
			var c = card_scene.instantiate()
			c.max_value = i
			deck.append(c)
