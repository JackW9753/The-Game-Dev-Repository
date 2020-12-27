extends StateMachine

func _ready():
	add_state("idle")
	add_state("run")
	add_state("jump")
	add_state("fall")
	add_state("wall_slide")
	add_state("die")
	call_deferred("set_state", states.idle)

func _input(event):
	if [states.idle, states.run].has(state):
		if Input.is_action_just_pressed("jump"):
			if parent.is_grounded || !parent.coyote_timer.is_stopped():
				parent.coyote_timer.stop()
				parent.motion.y = -parent.JUMPFORCE
	elif state == states.wall_slide:
		if Input.is_action_pressed("jump"):
			parent.wall_jump()
			set_state(states.jump)
	
	elif state == states.jump:
		pass

func _state_logic(delta):
	parent._update_move_direction()
	parent._update_wall_direction()
	if state != states.wall_slide:
		parent._handle_move_input()
	parent._apply_gravity(delta)
	if state == states.wall_slide:
		parent._cap_gravity_wall_slide()
		parent._handle_wall_slide_sticking()
	parent._apply_movement()
	if state == states.die:
		parent.motion.x = 0
		parent.motion.y = 0

func _get_transition(delta):
	match state:
		states.idle:
			if !parent.is_on_floor():
				if parent.motion.y < 0:
					return states.jump
				elif parent.motion.y > 0:
					return states.fall
			elif parent.motion.x < -40 or parent.motion.x > 40:
				return states.run
			elif parent.health <= 0:
				return states.die
		states.run:
			if !parent.is_on_floor():
				if parent.motion.y < 0:
					return states.jump
				elif parent.motion.y > 0:
					return states.fall
			elif parent.motion.x > -40 && parent.motion.x < 40:
				return states.idle
			elif parent.health <= 0:
				return states.die
		states.jump:
			if parent.wall_direction != 0 && parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.is_on_floor():
				return states.idle
			elif parent.motion.y >= 0:
				return states.fall
			elif parent.health <= 0:
				return states.die
		states.fall:
			if parent.wall_direction != 0 && parent.wall_slide_cooldown.is_stopped():
				return states.wall_slide
			elif parent.is_on_floor():
				return states.idle
			elif parent.motion.y < 0:
				return states.jump
			elif parent.health <= 0:
				return states.die
		states.wall_slide:
			if parent.is_on_floor():
				return states.idle
			elif parent.wall_direction == 0:
				return states.fall
			elif parent.health <= 0:
				return states.die
		states.die:
			if parent.health == 1:
				return states.idle
	
	return null

func _enter_state(new_state, old_state):
	match new_state:
		states.idle:
			parent.sprite_anim.play("Idle")
		states.run:
			parent.sprite_anim.play("Run")
		states.jump:
			parent.sprite_anim.play("Jump")
		states.fall:
			parent.sprite_anim.play("Fall")
		states.wall_slide:
			parent.sprite_anim.play("Wall_slide")
			parent.sprite_anim.scale.x = -parent.wall_direction
		states.die:
			parent.sprite_anim.play("Death")
			parent.death_timer.start()

func _exit_state(old_state, new_state):
	match old_state:
		states.wall_slide:
			parent.wall_slide_cooldown.start()

func _on_WallSlideStickyTimer_timeout():
	if state == states.wall_slide:
		set_state(states.fall)
