extends KinematicBody2D

signal health_updated(health)
signal killed()

const UP = Vector2(0,-1)
const GRAVITY = 20
const MAXFALLSPEED = 180
const MAXSPEED = 60
const JUMPFORCE = 325
const ACCEL = 15
const FLOOR_NORMAL = Vector2.UP
const SLOPE_STOP = 16
const WALL_JUMP_MOTION = Vector2(160, -320)
const TYPE = "player"

onready var left_wall_raycasts = $WallRaycasts/LeftWallRaycasts
onready var right_wall_raycasts =  $WallRaycasts/RightWallRaycasts
onready var ground_raycasts = $GroundRaycasts
onready var sprite_anim = $AnimatedSprite
onready var wall_slide_cooldown = $WallSlideCooldown
onready var wall_slide_sticky_timer = $WallSlideStickyTimer
onready var coyote_timer = $CoyoteTimer
onready var death_timer = $DeathTimer
onready var player = self
onready var health = max_health

export (float) var max_health = 1 setget _set_health

var motion = Vector2()
var wall_direction = 1
var move_direction = 1
var is_grounded
var spawn_point = Vector2(0, -71) # coordinates of your initial spawn point

func _handle_wall_slide_sticking():
	if move_direction != 0 && move_direction != wall_direction:
		if wall_slide_sticky_timer.is_stopped():
			wall_slide_sticky_timer.start()
		else:
			wall_slide_sticky_timer.stop()

func wall_jump():
	var wall_jump_motion = WALL_JUMP_MOTION
	wall_jump_motion.x *= -wall_direction
	motion = wall_jump_motion

func _check_is_grounded():
	for raycast in ground_raycasts.get_children():
		if raycast.is_colliding():
			return true

func _update_wall_direction():
	var is_near_wall_left = _check_is_valid_wall(left_wall_raycasts)
	var is_near_wall_right = _check_is_valid_wall(right_wall_raycasts)
	
	if is_near_wall_left && is_near_wall_right:
		wall_direction = move_direction
	else:
		wall_direction = -int(is_near_wall_left) + int(is_near_wall_right)

func _check_is_valid_wall(wall_raycasts):
	for raycast in wall_raycasts.get_children():
		if raycast.is_colliding():
			var dot = acos(Vector2.UP.dot(raycast.get_collision_normal()))
			if dot > PI * 0.35 && dot < PI * 0.55:
				return true
	return false

func _physics_process(delta):
	_handle_move_input()
	is_grounded = _check_is_grounded()
	if Input.is_action_pressed("die"):
		damage(1)

func _apply_gravity(delta):
	motion.y += GRAVITY
	if motion.y > MAXFALLSPEED:
		motion.y = MAXFALLSPEED

func _cap_gravity_wall_slide():
	var max_motion = 80
	motion.y = min(motion.y, max_motion)

func _apply_movement():
	if move_direction != 0:
		sprite_anim.scale.x = move_direction
	
	if move_direction == 1:
		motion.x += ACCEL
	elif move_direction == -1:
		motion.x -= ACCEL
	
	motion.y = move_and_slide(motion,UP,SLOPE_STOP).y
	#motion.y = move_and_slide(motion,FLOOR_NORMAL,true).y

func _update_move_direction():
	move_direction = -int(Input.is_action_pressed("left")) + int(Input.is_action_pressed("right"))
	
func _handle_move_input():
	motion.x = clamp(motion.x,-MAXSPEED,MAXSPEED)
	motion.x = lerp(motion.x,MAXSPEED * move_direction,0.2)

func _set_health(value):
	var prev_health = health
	health = clamp(value,0,max_health)
	if health != prev_health:
		emit_signal("health_updated", health)
		if health <= 0:
			death_timer.start()
			emit_signal("killed")

func damage(amount):
	_set_health(health - amount)

func _on_HitBox_body_entered(body):
	if body.name == "DangerTileMap":
		damage(1)
	elif body.name == "Checkpoint":
		damage(1)

func _on_DeathTimer_timeout():
	position = spawn_point
	health = 1
