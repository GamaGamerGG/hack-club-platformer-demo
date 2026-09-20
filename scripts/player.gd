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

@onready var audio_player_jump := get_parent().get_node("Camera2D").get_node("AudioPlayer1")
@onready var audio_player_death := get_parent().get_node("Camera2D").get_node("AudioPlayer2")
@onready var audio_player_pickup := get_parent().get_node("Camera2D").get_node("AudioPlayer3")
@onready var audio_player_win := get_parent().get_node("Camera2D").get_node("AudioPlayer4")

var alt_bg = preload('res://assets/orig_big_alt.png')

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

#var level := -1
var level := 16
var spawns := [
Vector2(80.0, 160.0), Vector2(2260.0, 550.0), 
Vector2(2520.0, 500.0), Vector2(3720.0, 280.0), Vector2(4960.0, 580.0), Vector2(6960.0, 140.0), Vector2(7800.0, 560.0),
Vector2(8530.0, 350.0), Vector2(9820.0, 580.0), Vector2(11880.0, 330.0), Vector2(12350.0, 310.0), Vector2(14280.0, 580.0),
Vector2(14550.0, 540.0), Vector2(16200.0, 560.0), Vector2(17860.0, 90.0), Vector2(18170.0, 190.0), Vector2(20180.0, 410.0),
Vector2(20520.0, 100.0), Vector2(21670.0, 590.0),
Vector2(23870.0, 90.0)
]
var winning := false

func _ready() -> void:
	camera.global_position.x = 575.0 + 1200.0 * (level + 1)
	camera.get_node("LevelLabel").text = str(level)
	died.emit(false)
	if level == 17:
		camera.get_node("OrigBig").texture = alt_bg

func _process(_delta: float) -> void:
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
		audio_player_jump.play()
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
		tilemap.reset_pickups.emit()
		if _play_anim:
			audio_player_death.play()
			anim_sprite.play("death")
			await anim_sprite.animation_looped
		global_position = spawns[level + 1]
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
			healbox.get_node("CollisionShape2D").global_position + Vector2(healbox_ssh.x, healbox_ssh.y),
			healbox.get_node("CollisionShape2D").global_position + Vector2(0, -healbox_ssh.y),
			healbox.get_node("CollisionShape2D").global_position + Vector2(0, healbox_ssh.y),
			healbox.get_node("CollisionShape2D").global_position + Vector2(healbox_ssh.x, 0),
			healbox.get_node("CollisionShape2D").global_position + Vector2(healbox_ssh.x, 0)
		]
		for c in corners:
			var corner = tilemap.to_local(c)
			if tilemap.is_pickup(corner):
				audio_player_pickup.play()
				extra_jumps = max(extra_jumps, tilemap.get_cell_atlas_coords(tilemap.local_to_map(corner)).x + 1)
				tilemap.queue_pickup(corner)
				picking_up = false
				return
		picking_up = false


func _on_winbox_body_entered(_body: Node2D) -> void:
	if not winning:
		audio_player_win.play()
		winning = true
		level += 1
		if level == 17:
			camera.get_node("OrigBig").texture = alt_bg
		camera.get_node("LevelLabel").text = str(level)
		camera.global_position.x += 1200
		died.emit(false)
