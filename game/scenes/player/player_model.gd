extends CharacterBody2D

# Configurações do player

# variáveis
@export_category("Movimentação")
@export var MAX_SPEED = 300.0
@export var ACEL = 800
@export var JUMP_VELOCITY = -400.0
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@export_enum("double_jump", "glide", "climb") var ability

# colisores
@onready var left: Area2D = $left
@onready var right: Area2D = $right

# timers

var WALL_DETACH = 2

# estados

enum PlayerState {
	idle,
	walk,
	jump,
	falling,
	wall_slide
}

var state: PlayerState

# movimentação
var wall_slide_direction = 0 # -1 esquerda 1 direita

# habilidades



# Funções de física

func _ready():
	go_to_idle_state()

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		var max_fall = 400
		if state == PlayerState.wall_slide:
			max_fall = 200
		velocity.y = move_toward(velocity.y, max_fall, get_gravity().y*delta)
	
	var direction := Input.get_axis("ui_left", "ui_right")
	
	match state:
		PlayerState.idle:
			idle_state(delta, direction)
		PlayerState.walk:
			walk_state(delta, direction)
		PlayerState.jump:
			jump_state(delta, direction)
		PlayerState.falling:
			falling_state(delta, direction)
		PlayerState.wall_slide:
			wall_slide_state(delta, direction)

	move_and_slide()

# Funções de estado
# funções de IDA

func go_to_idle_state():
	state = PlayerState.idle
	animation.play("idle")
	return

func go_to_walk_state():
	state = PlayerState.walk
	animation.play("walk")
	return

func go_to_jump_state():
	state = PlayerState.jump
	animation.play("jump")
	velocity.y = JUMP_VELOCITY
	return

func go_to_falling_state():
	state = PlayerState.falling
	animation.play("fall")
	return

func go_to_wall_slide_state():
	state = PlayerState.wall_slide
	velocity.y = 0
	WALL_DETACH = 0.2
	animation.play("wall_jump")
	return

# funções de PERMANÊNCIA
func idle_state(delta: float, direction: int):
	get_movement(delta, direction)
	flip_sprite(direction)
	
	if Input.is_action_just_pressed("ui_accept") and can_jump():
		go_to_jump_state()
		return
	if velocity.x != 0:
		go_to_walk_state()
		return
	if velocity.y > 10:
		go_to_falling_state()
		return

func walk_state(delta: float, direction: int):
	
	get_movement(delta, direction)
	flip_sprite(direction)
	
	if Input.is_action_just_pressed("ui_accept") and can_jump():
		go_to_jump_state()
		return
	if velocity.x == 0:
		go_to_idle_state()
		return
	if velocity.y > 10:
		go_to_falling_state()
		return
	

func jump_state(delta: float, direction: int):
	
	get_movement(delta, direction)
	flip_sprite(direction)
	
	if Input.is_action_just_released("ui_accept"):
		if velocity.y < 0:
			velocity.y /= 2
	
	if velocity.y > 0:
		go_to_falling_state()
		return

func falling_state(delta: float, direction: int):
	get_movement(delta, direction)
	flip_sprite(direction)	
	
	if want_to_wall_slide(direction):
		go_to_wall_slide_state()
		return
	if is_on_floor():
		if velocity.x != 0:
			go_to_walk_state()
			return
		else:
			go_to_idle_state()
			return


func wall_slide_state(delta:float, direction: int):
	if Input.is_action_just_pressed("ui_accept"):
		wall_jump(delta, wall_slide_direction)
		go_to_jump_state()
		return
	
	if not is_on_wall() or (direction != 0 and wall_slide_direction != direction): # direção oposta
		WALL_DETACH -= delta
		
		if WALL_DETACH <= 0:
			velocity.x = MAX_SPEED * direction
			go_to_falling_state()
			return
	else:
		WALL_DETACH = 0.2
	
	if is_on_floor():
		if velocity.x != 0:
			go_to_walk_state()
			return
		else:
			go_to_idle_state()
			return

# funções de SAÍDA


# Funções úteis

func get_movement(delta: float, direction: int):
	if direction:
		velocity.x = move_toward(velocity.x, MAX_SPEED*direction, delta*ACEL)
	else:
		velocity.x = move_toward(velocity.x, 0, delta*ACEL)

func flip_sprite(direction: int):
	if direction > 0:
		animation.flip_h = false
	elif direction < 0:
		animation.flip_h = true
	return

func wall_jump(delta: float, direction: int):
	velocity.y = - (JUMP_VELOCITY/2)
	velocity.x = MAX_SPEED * -direction
	return

func want_to_wall_slide(direction: int):
	if is_on_wall() and direction:
		return true
	return false 

func can_jump():
	# alterar depois
	if is_on_floor():
		return true
	return false

func detect_left_collision(body: Node2D):
	wall_slide_direction = -1

func detect_right_collision(body: Node2D):
	wall_slide_direction = 1
