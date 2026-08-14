extends CharacterBody2D

# Configurações do player

# variáveis
@export_category("Movimentação")
@export var MAX_SPEED : float = 300.0
@export var ACEL : float = 800
@export var FRICTION : float = 800
@export var MOMENTUM_CONSERVATION : float = 300
@export var JUMP_VELOCITY : float = -400.0
@export var GRAVITY : float = 500
@export var MAX_FALL_SPEED : float = 400
@export var MAX_WALL_SLIDE_SPEED : float = 200
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@export_enum("dash", "float", "climb", "slide") var ability
# 0 = dash, 1 = float, 2 = climb, 3 = slide
# colisores
@onready var left: Area2D = $left
@onready var right: Area2D = $right
@onready var up: RayCast2D = $up
@onready var colission: CollisionShape2D = $Colission
@onready var rightcollision: CollisionShape2D = $right/rightcollision
@onready var leftcollision: CollisionShape2D = $left/leftcollision


# timers
@export_category("General Timers")
@export var WALL_DETACH : float
var wall_timer : float
@export var COYOTE_TIME : float
var coyote_timer : float

# estados

enum PlayerState {
	idle,
	walk,
	jump,
	falling,
	wall_slide,
	dash,
	slide
}

var state: PlayerState

# wall jump
var wall_slide_direction = 0 # -1 esquerda 1 direita

# habilidades

# dash 
@export_category("Dash")
@export var DASH_POWER : float = 200
@export var DASH_TIME : float = 0.5
var dash_timer : float
var has_dash : bool = true
var dash_direction : Vector2

# slide
@export_category("Slide")
@export var SLIDE_POWER : float = 300
@export var SLIDE_TIME : float = 0.2
var slide_timer : float
var slide_direction : int
var can_slide : bool = true
var can_float : bool = true

# Funções de física

func _ready():
	go_to_idle_state()

func _physics_process(delta: float) -> void:

	if affected_by_gravity():
		var max_fall = MAX_FALL_SPEED
		if state == PlayerState.wall_slide:
			max_fall = MAX_WALL_SLIDE_SPEED
		velocity.y = move_toward(velocity.y, max_fall, GRAVITY*delta)
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		has_dash = true
	
	var direction := Input.get_axis("left", "right")
	
	if use_dash(): #o dash pode ser utilizado em qualquer estado
		go_to_dash_state()
	
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
		PlayerState.dash:
			dash_state(delta, direction)
		PlayerState.slide:
			slide_state(delta, direction)
	
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
	wall_timer = WALL_DETACH
	animation.play("wall_jump")
	return

func go_to_dash_state():
	state = PlayerState.dash
	animation.play('dash')
	has_dash = false
	dash_timer = DASH_TIME
	dash_direction = Input.get_vector("left", "right", "up", "down")
	dash_direction = dash_direction.normalized()
	if dash_direction == Vector2.ZERO:
		dash_direction = Vector2.UP
	velocity = DASH_POWER * dash_direction
	if dash_direction == Vector2.UP: 
		# não é a forma ideial de resolver mas é oq tem
		velocity *= 0.7
	
	return

func go_to_slide_state(direction: int):
	state = PlayerState.slide
	animation.play("slide")
	low_hitbox()
	slide_direction = direction
	velocity.x = SLIDE_POWER*direction
	slide_timer = SLIDE_TIME
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
	if not is_on_floor():
		if coyote_timer > 0:
			coyote_timer -= delta
			
			if coyote_timer < 0:
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
	if use_slide():
		go_to_slide_state(direction)
		return
	if not is_on_floor():
		if coyote_timer > 0:
			coyote_timer -= delta
			
			if coyote_timer < 0:
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
		wall_timer -= delta
		
		if wall_timer <= 0:
			velocity.x = MAX_SPEED * direction
			go_to_falling_state()
			return
	else:
		wall_timer = WALL_DETACH
	
	if is_on_floor():
		if velocity.x != 0:
			go_to_walk_state()
			return
		else:
			go_to_idle_state()
			return

func dash_state(delta:float, direction: int):
	dash_timer -= delta
	
	if want_to_wall_slide(direction):
		go_to_wall_slide_state()
		return
	
	if dash_timer < 0:
		
		if is_on_floor():
			if velocity.x != 0:
				go_to_walk_state()
				return
			else:
				go_to_idle_state()
				return
		
		go_to_falling_state()
		return
	else:
		velocity += DASH_POWER * dash_direction * delta

func slide_state(delta:float, direction: int):
	slide_timer -= delta
	
	if slide_timer < 0 and not up.is_colliding():
		normal_hitbox()
		if is_on_floor():
			if velocity.x != 0:
				go_to_walk_state()
				return
			else:
				go_to_idle_state()
				return
		
		go_to_falling_state()
		return
	else:
		if slide_timer > 0:
			velocity.x += delta * slide_direction * SLIDE_POWER
		if Input.is_action_just_pressed("jump") and not up.is_colliding():
			velocity.x += slide_direction * 50 # impulso para momentum
			normal_hitbox()
			go_to_jump_state()
			return
		

# funções de SAÍDA


# Funções úteis

func get_movement(delta: float, direction: int):
	var target_speed = MAX_SPEED * direction
	var current_accel = ACEL 
	
	if not is_on_floor():
		if direction == 0:
			current_accel = MOMENTUM_CONSERVATION
		
		elif sign(velocity.x) == direction and abs(velocity.x) > MAX_SPEED:
			current_accel = MOMENTUM_CONSERVATION
		
	velocity.x = move_toward(velocity.x, target_speed, delta * current_accel)

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
	if is_on_floor() or coyote_timer > 0:
		return true
	return false

func use_dash() -> bool:
	if ability == 0 and has_dash and Input.is_action_just_pressed('use_ability'):
		return true
	return false
			

func use_slide() -> bool:
	if ability == 3 and Input.is_action_just_pressed('use_ability'):
		return true
	return false

func affected_by_gravity() -> bool:
	if not is_on_floor() and state != PlayerState.dash:
		return true
	return false

func low_hitbox() -> void:
	leftcollision.shape.size.y = 13
	leftcollision.position.y = 8
	rightcollision.shape.size.y = 13
	rightcollision.position.y = 8
	colission.shape.size.y = 13
	colission.position.y = 8
	return

func normal_hitbox() -> void:
	leftcollision.shape.size.y = 33.5
	leftcollision.position.y = -0.5
	rightcollision.shape.size.y = 33.5
	rightcollision.position.y = -0.5
	colission.shape.size.y = 33.5
	colission.position.y = -0.5
	return
	

func detect_left_collision(body: Node2D):
	wall_slide_direction = -1

func detect_right_collision(body: Node2D):
	wall_slide_direction = 1

func is_alive():
	return true #mudar dps com as condicoes futuras
