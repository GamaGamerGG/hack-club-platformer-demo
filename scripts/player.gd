extends CharacterBody2D


const SPEED := 300.0
const JUMP_VELOCITY := -300.0
const JUMP_EXT_VELOCITY := -25.0
const MAX_JUMP_TIME := 0.25

var jumpTimer := 0.0



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if (Input.is_action_pressed("ui_accept") && jumpTimer < MAX_JUMP_TIME):
		velocity.y += JUMP_EXT_VELOCITY * sqrt(jumpTimer / MAX_JUMP_TIME)
		jumpTimer += delta
	
	if (!Input.is_action_pressed("ui_accept")):
		jumpTimer = 0.0
	
	
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	move_and_slide()
