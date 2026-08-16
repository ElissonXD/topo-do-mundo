class_name PlayerModel extends CharacterBody2D

# Configurações do player

# inicialização dos controles
@export_category("Controles")
@export_enum("1", "2", "3", "4") var control_schema = '1';
var left_control : String;
var right_control : String;
var down_control : String;
var up_control : String;
var jump_control : String;
var ability_control : String;

# variáveis
@export_category("Movimentação")
@export var MAX_SPEED : float = 250.0
@export var ACEL : float = 1000
@export var FRICTION : float = 800
@export var MOMENTUM_CONSERVATION : float = 300
@export var JUMP_VELOCITY : float = -250.0
@export var GRAVITY : float = 1000
@export var MAX_FALL_SPEED : float = 600
@export var MAX_WALL_SLIDE_SPEED : float = 300
@onready var animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
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
@export var WALL_DETACH : float = 0.1
var wall_timer : float
@export var COYOTE_TIME : float = 0.1
var coyote_timer : float
@export var HURT_TIME : float = 0.3
var hurt_timer : float
@export var IFRAMES : float = 1.5
var iframes_timer : float

# estados

enum PlayerState {
	idle,
	walk,
	jump,
	falling,
	wall_slide,
	hurt,
	dash,
	slide
}

var state: PlayerState

# wall jump
var wall_slide_direction = 0 # -1 esquerda 1 direita

# habilidades

# dash 
@export_category("Dash")
@export var DASH_POWER : float = 350
@export var DASH_TIME : float = 0.1
var dash_timer : float
var has_dash : bool = true
var dash_direction : Vector2

# slide
@export_category("Slide")
@export var SLIDE_POWER : float = 400
@export var SLIDE_TIME : float = 0.2
var slide_timer : float
var slide_direction : int
var can_slide : bool = true
var can_float : bool = true

# Funções de física

func _ready():
	left_control = 'left_' + control_schema;
	right_control = 'right_' + control_schema;
	down_control = 'down_' + control_schema;
	up_control = 'up_' + control_schema;
	jump_control = 'jump_' + control_schema;
	ability_control = 'use_ability_' + control_schema;
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
	
	var direction := Input.get_axis(left_control, right_control)
	
	if iframes_timer > 0: # invencivel em qualquer estado
		iframes_timer -= delta
		
		if iframes_timer <= 0:
			animation_player.stop()
	
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
		PlayerState.hurt:
			hurt_state(delta, direction)
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

func go_to_hurt_state():
	state = PlayerState.hurt
	animation.play('hurt')
	normal_hitbox()
	hurt_timer = HURT_TIME
	return

func go_to_dash_state():
	state = PlayerState.dash
	animation.play('dash')
	has_dash = false
	dash_timer = DASH_TIME
	dash_direction = Input.get_vector(left_control, right_control, 
	up_control, down_control)
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
	
	if Input.is_action_just_pressed(jump_control) and can_jump():
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
	
	if Input.is_action_just_pressed(jump_control) and can_jump():
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
	
	if Input.is_action_just_released(jump_control):
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
	if Input.is_action_just_pressed(jump_control):
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

func hurt_state(delta:float, direction:int):
	# nesse estado ele nao vai poder se mover, apenas sendo
	# refém do knockback
	get_movement(delta, 0)
	
	hurt_timer -= delta
	
	if hurt_timer <= 0:
		coyote_timer = COYOTE_TIME # dando uma chance de pular
		iframes_timer = IFRAMES # evitar ser molestado
		animation_player.play("invencible")
		if velocity.x != 0:
			go_to_walk_state()
			return
		else:
			go_to_idle_state()
			return
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
		if Input.is_action_just_pressed(jump_control) and not up.is_colliding():
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
	if ability == 0 and has_dash and Input.is_action_just_pressed(ability_control):
		return true
	return false
			

func use_slide() -> bool:
	if ability == 3 and Input.is_action_just_pressed(ability_control):
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

func apply_knockback(body: Node2D) -> void:
	
	var vector_direction = (body.global_position - global_position).normalized()
	
	vector_direction.y = clamp(vector_direction.y, -0.5, -0.25)
	vector_direction.normalized()
	
	body.velocity = vector_direction * SLIDE_POWER
	return
	
func detect_left_collision(body: Node2D):
	wall_slide_direction = -1
	
	# certo, vou utilizar isso como um detector de ataque do slide
	# aproveito e já armazeno a direção do chute
	
	if state == PlayerState.slide and not up.is_colliding():
		if body.is_in_group("Player") and body != self: # será player
			if body.iframes_timer <= 0:
				apply_knockback(body)
				body.go_to_hurt_state();

func detect_right_collision(body: Node2D):
	wall_slide_direction = 1
	
	if state == PlayerState.slide and not up.is_colliding():
		if body.is_in_group("Player") and body != self: # será player
			if body.iframes_timer <= 0:
				apply_knockback(body)
				body.go_to_hurt_state();

func is_alive():
	return true #mudar dps com as condicoes futuras
