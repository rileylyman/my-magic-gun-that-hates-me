extends Artifact
var curses = 0

func post_tick_callback(state: TickState) -> void:
	state.score *= max(curses, 1)

func encounter_start_callback() -> void:
	curses = 0
	for a in GlobalManager.artifacts:
		if a.rarity == ArtifactRarity.CURSED:
			curses +=1
