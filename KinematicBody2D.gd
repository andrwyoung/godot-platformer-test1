extends KinematicBody2D
class_name Player

const UP = Vector2(0, -1)
const GRAVITY = 2000.0
const MAX_FALL = 600.0
const RUN_SPEED = 350.0
const RUN_ACCEL = 0.4
const RUN_DECEL = 0.15

const DASH_SPEED = 1000.0
const DASH_ACCEL = 0.5
const DASH_TIME = 0.07
const DASH_DECCEL = 0.1
const DASH_PAUSE = 0.05
const DASH_COOLDOWN = 0.3

const DOUBLE_JUMPS = 1
const JUMP_SPEED = 650.0
const JUMP_CUT = 0.5
const COYOTE_TIME = 0.5
const GROUND_TIME = 0.1

const WALL_JUMP = Vector2(-500, -600)
const WALL_JUMP_TIME = 0.1
const WALL_JUMP_PAUSE = 0.25
const WALL_JUMP_ACCEL = 0.4

const DEFAULT_GRAVITY = 1.0
const FALL_GRAVITY = 1.2
const FAST_FALL = 2.0

export var camera_cutoff = 800

var velocity = Vector2(0, 0)
var dir = Vector2(0, 0)
var gravity_scale = DEFAULT_GRAVITY
var coyote_timer = 0.0
var ground_timer = 0.0

var dash_timer = -DASH_COOLDOWN
var dash = true # dash refresh when touching floor
var dash_mode = false

var walljump_timer = 0
var walljump_mode = false
var walldirection = 0
var jumps = DOUBLE_JUMPS
var face_direction = 1

var spawn_point = Vector2()

var Bullet := preload("res://Bullet.tscn")

func _ready() -> void:
	$Camera2D.limit_bottom = camera_cutoff
	spawn_point = position

func _physics_process(delta: float) -> void:
	# first deal with x axis
	ground_timer = max(ground_timer - delta, 0)
	dash_timer = max(dash_timer - delta, -DASH_COOLDOWN)
	if !dash_mode and !walljump_mode:
		dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
		dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
		
		if dir.x != 0:
			face_direction = dir.x
			velocity.x = lerp(velocity.x, RUN_SPEED * dir.x, RUN_ACCEL)
#			velocity.x = min(RUN_SPEED, abs(velocity.x + RUN_ACCEL * x_dir)) * x_dir
			$Sprite.flip_h = sign(dir.x) < 0
			$Sprite.play("Run")
		else:
			$Sprite.play("Idle")
			velocity.x = lerp(velocity.x, 0, RUN_DECEL)
		#	velocity.x = 0
		if Input.is_action_just_pressed("dash") and dash and dash_timer <= -DASH_COOLDOWN:
			init_dash();
			
			
			
		# then deal with y axis
		apply_gravity(delta)
		if is_on_floor():
			coyote_timer = COYOTE_TIME
			gravity_scale = DEFAULT_GRAVITY
			dash = true
			jumps = DOUBLE_JUMPS
			
			if ground_timer > 0:
				print("ground time!")
				jump()
				ground_timer = 0
			elif Input.is_action_just_pressed("jump"):
				jump()
		elif is_on_wall():	# notice floor takes precedence over floor
#			jumps = DOUBLE_JUMPS
			for i in get_slide_count():
				var collision = get_slide_collision(i)
				if  collision.position.x > position.x:
					walldirection = 1
				else: 
					walldirection = -1
				
			
			if Input.is_action_just_pressed("jump"):
				walljump()
#			if ground_timer > 0:
#				print("ground time wall!")
#				walljump()
#				ground_timer = 0
		else:
			coyote_timer = max(coyote_timer - delta, 0)
			if Input.is_action_just_pressed("jump"):
				if coyote_timer > 0:
					print("coyote jump")
					jump()
				elif jumps > 0:
					jump()
					jumps -= 1
				else: ground_timer = GROUND_TIME
			
			
			if velocity.y < 0:
				$Sprite.play("Jump")
				if Input.is_action_just_released("jump"):
					velocity.y *= JUMP_CUT
	#				gravity_scale = FALL_GRAVITY
			else:
				$Sprite.play("Fall")
		
		if Input.is_action_just_pressed("shoot"):
			shoot()
		
		
	elif dash_mode: 
		if dash_timer < 0: 
			dash_mode = false
		elif dash_timer < DASH_PAUSE:
			velocity = lerp(velocity, Vector2(0, 0), DASH_DECCEL)
		else:
			velocity = lerp(velocity, DASH_SPEED * dir.normalized(), DASH_ACCEL)
	else: # dash_mode and walljump_mode mutually exclusive
		walljump_timer = max(walljump_timer - delta, 0)
		if walljump_timer <= 0:
			walljump_mode = false
		elif walljump_timer < WALL_JUMP_PAUSE:
#			velocity = lerp(velocity, Vector2(0, 0), DASH_DECCEL)
			apply_gravity(delta)
		else:
			velocity = lerp(velocity, WALL_JUMP * Vector2(walldirection, 1), WALL_JUMP_ACCEL)
	
#	print(velocity.x, ", ", velocity.y)
	velocity = move_and_slide(velocity, UP)
	
	
func apply_gravity(delta: float) -> void:
	velocity.y = min(velocity.y + GRAVITY * delta, MAX_FALL)
	
func jump() -> void:
	coyote_timer = 0
	velocity.y = -JUMP_SPEED
	
func shoot() -> void:
	var bullet = Bullet.instance()
	bullet.setup(Vector2(face_direction, 0))
	bullet.position = position
	bullet.position.y += 5
	bullet.position.x += 10 * face_direction
#	bullet.add_to_group("Projectile")
	get_parent().add_child(bullet)

func init_dash() -> void:
	coyote_timer = 0  # prevent initial jump
	dash = false
	dash_mode = true
	velocity.y = 0
	dash_timer = DASH_TIME + DASH_PAUSE

func walljump() -> void:
	print("wall jump")
	coyote_timer = 0
	walljump_mode = true
	walljump_timer = WALL_JUMP_TIME + WALL_JUMP_PAUSE

func _on_VisibilityNotifier2D_screen_exited() -> void:
	print("player off. reloading")
	print(position)
	position = spawn_point
