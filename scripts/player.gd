extends CharacterBody2D

@onready var anim_sprite = $AnimatedSprite2D

const SPEED := 250.0
const GRAVITY := 1.25
const JUMP_VELOCITY := -300.0
const JUMP_EXT_VELOCITY := -30.0
const MAX_JUMP_TIME := 0.25

var jumpTimer := 0.0
var jumping := false



func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta * GRAVITY
	
	
	jumping = Input.is_action_pressed("jump") and jumpTimer < MAX_JUMP_TIME
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	if jumping:
		velocity.y += JUMP_EXT_VELOCITY * sqrt(jumpTimer / MAX_JUMP_TIME)
		jumpTimer += delta
	
	if not Input.is_action_pressed("jump"):
		jumpTimer = 0.0
	
	
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if direction == -1:
		anim_sprite.flip_h = true
	elif direction == 1:
		anim_sprite.flip_h = false
	
	if not is_on_floor():
		if velocity.y < 0:
			anim_sprite.play("jump_up")
		else:
			anim_sprite.play("jump_down")
	elif direction:
		anim_sprite.play("run")
	else:
		anim_sprite.play("idle")
	
	move_and_slide()
