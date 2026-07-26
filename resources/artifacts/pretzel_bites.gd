extends Artifact
var working = true

func hand_submit_callback(state: TickState) -> void:
	working = true


func post_tick_callback(state: TickState) -> void:
	if state.cards[-1].curr <= 0:
		if(working==true):
			shake(" Yummy! ")
			working = false
	
	if working:
		state.score += state.cards[-1].curr 
		await shake("+"+str(state.cards[-1].curr))
	
