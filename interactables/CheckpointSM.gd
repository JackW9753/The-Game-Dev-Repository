extends StateMachine

var player_has_entered

func _ready():
	add_state("inactive")
	add_state("active")
	call_deferred("set_state", states.inactive)
	print(state)

func _get_transition(delta):
	match state:
		states.inactive:
			if player_has_entered == true:
				return states.active
		states.active:
			if player_has_entered == false:
				return states.inactive

func _enter_state(new_state, old_state):
	match new_state:
		states.inactive:
			parent.sprite_anim.play("Inactive")
		states.active:
			parent.sprite_anim.play("Active")

func _on_PlayerDetection_body_entered(body):
	player_has_entered == false
	if body.name == "Player":
		player_has_entered == true
