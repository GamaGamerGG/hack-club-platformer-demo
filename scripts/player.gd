extends CharacterBody2D

signal died

@onready var camera := get_parent().get_node("Camera2D")
@onready var anim_sprite := $AnimatedSprite2D
@onready var hurtbox := $Hurtbox
@onready var healbox := $Healbox
@onready var winbox := $Winbox
@onready var jump_counter := $JumpCounter
@onready var tilemap = get_parent().get_node("TileMapLayer")
@onready var spawn_pos := global_position
@onready var healbox_ssh : Vector2 = get_node("Healbox").get_node("CollisionShape2D").shape.size / 2.0

const SPEED := 250.0
const GRAVITY := 1.25
const JUMP_VELOCITY := -250.0
const JUMP_EXT_VELOCITY := -25.0
const MAX_JUMP_TIME := 0.25
const COYOTE_TIME := 0.1

var jump_timer := 0.0
var coyote_timer := COYOTE_TIME
var jumped := false
var input := false
var locked := false
var extra_jumps := 0
var picking_up := false

var level := -2
var spawns := [Vector2(80.0, 160.0), Vector2(2260.0, 550.0)]
var winning := false

func _ready() -> void:
	died.emit(false)

func _process(delta: float) -> void:
	if extra_jumps:
		jump_counter.text = str(extra_jumps)
	else:
		jump_counter.text = ""

func _physics_process(delta: float) -> void:
	
	if not is_on_floor() and not locked:
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
	
	if not locked:
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
	
	if global_position.y >= 666:
		died.emit()
	
	if not input and is_on_floor() and not locked:
		input = true


func _on_died(_play_anim := true) -> void:
	if not locked:
		velocity = Vector2(0, 0)
		input = false
		locked = true
		if _play_anim:
			anim_sprite.play("death")
			await anim_sprite.animation_looped
		global_position = spawns[level + 2]
		winning = false
		velocity = Vector2(0, 0)
		jump_timer = 0.0
		coyote_timer = COYOTE_TIME
		extra_jumps = 0
		tilemap.reset_pickups.emit()
		jumped = false
		locked = false

func _on_hurtbox_body_entered(_body: Node2D) -> void:
	died.emit()

func _on_healbox_body_entered(_body: Node2D) -> void:
	if not picking_up:
		picking_up = true
		var corners = [
			healbox.get_node("CollisionShape2D").global_position + Vector2(-healbox_ssh.x, -healbox_ssh.y),
			healbox.get_node("CollisionShape2D").global_position + Vector2(-healbox_ssh.x, healbox_ssh.y),
			healbox.get_node("CollisionShape2D").global_position + Vector2(healbox_ssh.x, -healbox_ssh.y),
			healbox.get_node("CollisionShape2D").global_position + Vector2(healbox_ssh.x, healbox_ssh.y)
		]
		for c in corners:
			var corner = tilemap.to_local(c)
			if tilemap.is_pickup(corner):
				extra_jumps = max(extra_jumps, tilemap.get_cell_atlas_coords(tilemap.local_to_map(corner)).x + 1)
				tilemap.queue_pickup(corner)
				picking_up = false
				return
		picking_up = false


func _on_winbox_body_entered(body: Node2D) -> void:
	if not winning:
		winning = true
		level += 1
		camera.get_node("LevelLabel").text = str(level)
		camera.global_position.x += 1200
		died.emit(false)
