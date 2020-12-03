extends KinematicBody2D

const BULLET_SPEED = 10
var velocity = Vector2()
var collision = null

func setup(direction: Vector2) -> void:
	print("shooting projectile!")
	velocity.x = BULLET_SPEED
	velocity  = velocity * direction
	$bullet.flip_h = sign(direction.x) < 0
	
func _physics_process(delta: float) -> void:
	collision = move_and_collide(velocity)
	if collision != null:
		queue_free()

func _on_Notifier_screen_exited() -> void:
	print("oh my!")
	queue_free()
