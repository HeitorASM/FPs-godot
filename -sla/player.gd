extends CharacterBody3D

const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002
const DOUBLE_JUMP_MULTIPLIER = 0.8

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = WALK_SPEED
var can_double_jump = false
var has_double_jumped = false

@onready var neck := $neck
@onready var camera := $neck/Camera3D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			# Rotaciona o pescoço (e todo o personagem) no eixo Y
			rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			# Rotaciona apenas a câmera no eixo X para inclinar
			camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
		# Permite double jump apenas se não estiver no chão e ainda não pulou duas vezes
		if Input.is_action_just_pressed("ui_accept") and can_double_jump and not has_double_jumped:
			velocity.y = JUMP_VELOCITY * DOUBLE_JUMP_MULTIPLIER
			has_double_jumped = true
	else:
		# Reset do double jump quando toca no chão
		can_double_jump = false
		has_double_jumped = false
	
	# Pulo normal
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		can_double_jump = true
	
	# Sistema de corrida
	if Input.is_action_pressed("sprint"):
		current_speed = RUN_SPEED
	else:
		current_speed = WALK_SPEED

	# Movimento
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
