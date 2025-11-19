extends CharacterBody3D

const WALK_SPEED = 5.0
const RUN_SPEED = 10.0
const JUMP_VELOCITY = 6.5
const MOUSE_SENSITIVITY = 0.003
const DOUBLE_JUMP_MULTIPLIER = 1.5
const ACCELERATION = 10.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed = WALK_SPEED
var can_double_jump = false
var has_double_jumped = false

@onready var neck: Node3D = $neck
@onready var camera: Camera3D = $neck/Camera3D
@onready var shotgun: Node = $neck/Camera3D/Shotgun

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	# Captura/libera mouse com ESC
	if event.is_action_pressed("ui_cancel"):
		toggle_mouse_capture()
	
	# Disparo e recarga
	if event is InputEventMouseButton and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event.pressed:
			match event.button_index:
				MOUSE_BUTTON_LEFT:  # Disparar
					if shotgun and shotgun.has_method("shoot"):
						shotgun.shoot()
				MOUSE_BUTTON_RIGHT:  # Recarregar
					if shotgun and shotgun.has_method("start_reload"):
						shotgun.start_reload()
	
	# Rotação da câmera
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		handle_camera_rotation(event)

func handle_camera_rotation(event: InputEventMouseMotion) -> void:
	# Rotação horizontal (personagem)
	rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
	
	# Rotação vertical (câmera)
	camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
	
	# Limitar ângulo vertical
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	handle_gravity_and_jump(delta)
	handle_movement(delta)
	update_hud()

func handle_gravity_and_jump(delta: float) -> void:
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y -= gravity * delta
		
		# Double jump
		if Input.is_action_just_pressed("ui_accept") and can_double_jump and not has_double_jumped:
			velocity.y = JUMP_VELOCITY * DOUBLE_JUMP_MULTIPLIER
			has_double_jumped = true
	else:
		# Resetar pulos quando no chão
		can_double_jump = false
		has_double_jumped = false
	
	# Pulo normal
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		can_double_jump = true

func handle_movement(delta: float) -> void:
	# Velocidade (sprint)
	current_speed = RUN_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	
	# Direção do input - CORREÇÃO AQUI
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	
	# Direção relativa à câmera - CORREÇÃO PRINCIPAL
	var direction = Vector3.ZERO
	if input_dir.length() > 0:
		# Usar a direção forward da câmera corretamente
		var cam_forward = -camera.global_transform.basis.z
		var cam_right = camera.global_transform.basis.x
		
		# W (forward) = frente, S (back) = trás
		direction = (cam_forward * input_dir.y) + (cam_right * input_dir.x)
		direction.y = 0
		direction = direction.normalized()
	
	# Suavizar movimento
	var target_velocity = direction * current_speed
	velocity.x = lerp(velocity.x, target_velocity.x, ACCELERATION * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, ACCELERATION * delta)
	
	move_and_slide()

func update_hud() -> void:
	# Atualizar HUD de munição
	if shotgun and shotgun.has_method("get_ammo_info"):
		var ammo = shotgun.get_ammo_info()
		if has_node("HUD"):
			var hud = $HUD
			if hud.has_method("update_ammo"):
				hud.update_ammo(ammo.current, ammo.max)
