class_name ScoreBar
extends Control

var max_score: int = 100
var curr_score: int = 0

func _process(_delta: float) -> void:
	%Score.text = "%s/%s" % [curr_score, max_score]
	$ProgressBar.value = curr_score
	$ProgressBar.max_value = max_score
