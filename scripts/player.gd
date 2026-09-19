extends CharacterBody2D

signal died

@onready var anim_sprite := $AnimatedSprite2D
@onready var hurtbox := $Hurtbox
@onready var jump_counter := $JumpCounter
@onready var spawn_pos := global_position

const SPEED := 250.0
const GRAVITY := 1.25
const JUMP_VELOCITY := -300.0
const JUMP_EXT_VELOCITY := -30.0
const MAX_JUMP_TIME := 0.25
const COYOTE_TIME := 0.1

var jump_timer := 0.0
var coyote_timer := COYOTE_TIME
var jumped := false
var input := false
var extra_jumps := 0

func _process(delta: float) -> void:
	if extra_jumps:
		jump_counter.text = str(extra_jumps)
	else:
		jump_counter.text = ""

func _physics_process(delta: float) -> void:
	
	if not is_on_floor():
		velocity += get_gravity() * delta * GRAVITY
		coyote_timer += delta
	else:
		jumped = false
		coyote_timer = 0.0
	
	if Input.is_action_just_released("jump"):
		jumped = false
	
	if input and not jumped and Input.is_action_just_pressed("jump") and (coyote_timer <= COYOTE_TIME or extra_jumps > 0):
		if not coyote_timer <= COYOTE_TIME:
			extra_jumps -= 1
		velocity.y = JUMP_VELOCITY
		jumped = true
	
	if input and Input.is_action_pressed("jump") and jump_timer <= MAX_JUMP_TIME and jumped:
		velocity.y += JUMP_EXT_VELOCITY * sqrt(jump_timer / MAX_JUMP_TIME)
		jump_timer += delta
	
	if not Input.is_action_pressed("jump"):
		jump_timer = 0.0
	
	
	var direction := Input.get_axis("left", "right")
	if input and direction:
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
	
	if global_position.y >= 650:
		died.emit()
	
	if not input and is_on_floor():
		input = true


func _on_died() -> void:
	global_position = spawn_pos
	velocity = Vector2(0, 0)
	jump_timer = 0.0
	coyote_timer = COYOTE_TIME
	jumped = false
	input = false

func _on_hurtbox_body_entered(_body: Node2D) -> void:
	died.emit()
