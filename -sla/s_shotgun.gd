extends Node3D

signal ammo_changed(current, max)

@export var damage: int = 50
@export var range: float = 15.0
@export var fire_rate: float = 1.0
@export var pellets: int = 8
@export var spread_angle: float = 12.0

@export var recoil_distance: float = 0.3
@export var recoil_duration: float = 0.08
@export var return_duration: float = 0.15

@export var max_ammo: int = 6
var current_ammo: int = 6
@export var reload_time: float = 1.5

@onready var muzzle_flash := $MuzzleFlash
@onready var shotgun_model := $ShotgunModel
@onready var audio_player := $AudioPlayer

var can_fire: bool = true
var is_reloading: bool = false
var is_recoiling: bool = false
var original_position: Vector3
var fire_timer: Timer
var reload_timer: Timer
var muzzle_flash_timer: Timer

# Referências para a interface
@onready var ammo_label: Label
@onready var reload_label: Label

func _ready():
	original_position = transform.origin
	_setup_timers()
	_setup_muzzle_flash()
	_setup_audio()
	current_ammo = max_ammo
	

func _setup_timers():
	fire_timer = Timer.new()
	fire_timer.wait_time = 1.0 / fire_rate
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

	reload_timer = Timer.new()
	reload_timer.wait_time = reload_time
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	add_child(reload_timer)

	muzzle_flash_timer = Timer.new()
	muzzle_flash_timer.wait_time = 0.07
	muzzle_flash_timer.one_shot = true
	muzzle_flash_timer.timeout.connect(_hide_muzzle_flash)
	add_child(muzzle_flash_timer)

func _setup_muzzle_flash():
	if muzzle_flash:
		if muzzle_flash is GPUParticles3D:
			_configure_particles_muzzle_flash()
		elif muzzle_flash is MeshInstance3D:
			_configure_mesh_muzzle_flash()

func _configure_particles_muzzle_flash():
	var particles = muzzle_flash as GPUParticles3D
	particles.emitting = false
	particles.one_shot = true
	particles.lifetime = 0.15
	particles.amount = 15
	particles.explosiveness = 0.9

func _configure_mesh_muzzle_flash():
	if muzzle_flash is MeshInstance3D:
		muzzle_flash.visible = false

func _setup_audio():
	if not audio_player:
		audio_player = AudioStreamPlayer3D.new()
		audio_player.name = "AudioPlayer"
		add_child(audio_player)


# Função principal de input - detecta clique do mouse
func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()
		# Opcional: adicionar recarga com botão direito
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			start_reload()

func shoot():
	if not can_fire or is_reloading or is_recoiling or current_ammo <= 0:
		return

	current_ammo -= 1
	can_fire = false
	fire_timer.start()
	_show_muzzle_flash()
	_play_shot_sound()
	_start_recoil_animation()

	for i in range(pellets):
		var pellet_direction = _get_pellet_direction()
		_fire_pellet(pellet_direction)

	print("Tiros restantes: ", current_ammo, "/", max_ammo)
	emit_signal("ammo_changed", current_ammo, max_ammo)
	

	if current_ammo <= 0:
		start_reload()

func start_reload():
	if is_reloading or current_ammo >= max_ammo:
		return
	is_reloading = true
	_play_reload_sound()
	reload_timer.start()
	

func _get_pellet_direction() -> Vector3:
	var base_direction = -global_transform.basis.z
	var spread_rad = deg_to_rad(spread_angle)
	var random_angle = randf() * TAU
	var random_spread = randf() * spread_rad
	var x = sin(random_angle) * random_spread
	var y = cos(random_angle) * random_spread
	return base_direction.rotated(global_transform.basis.x, x).rotated(global_transform.basis.y, y)

func _fire_pellet(direction: Vector3):
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = global_transform.origin
	query.to = global_transform.origin + direction * range

	var owner_node = get_owner()
	if owner_node:
		query.exclude = [owner_node]

	var result = space_state.intersect_ray(query)
	if result:
		_handle_hit(result)

func _handle_hit(result: Dictionary):
	print("Atingiu: ", result.collider.name, " em ", result.position)
	if result.collider.has_method("take_damage"):
		result.collider.take_damage(damage / pellets)
	elif result.collider is RigidBody3D:
		var force_direction = (result.position - global_transform.origin).normalized()
		result.collider.apply_impulse(force_direction * (damage * 0.1))

func _show_muzzle_flash():
	if muzzle_flash:
		if muzzle_flash is GPUParticles3D:
			muzzle_flash.emitting = true
		else:
			muzzle_flash.visible = true
		muzzle_flash_timer.start()

func _hide_muzzle_flash():
	if muzzle_flash:
		if muzzle_flash is GPUParticles3D:
			muzzle_flash.emitting = false
		else:
			muzzle_flash.visible = false

func _play_shot_sound():
	if audio_player:
		# audio_player.stream = load("res://sounds/shotgun_fire.wav")
		audio_player.play()
		print("BANG!")

func _play_reload_sound():
	if audio_player:
		# audio_player.stream = load("res://sounds/shotgun_reload.wav")
		print("CLICK-CLACK!")

func _start_recoil_animation():
	is_recoiling = true
	var forward = transform.basis.z.normalized()
	var recoil_target = original_position - forward * recoil_distance

	var t = create_tween()
	t.tween_property(self, "transform:origin", recoil_target, recoil_duration).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "transform:origin", original_position, return_duration).set_delay(recoil_duration).set_ease(Tween.EASE_IN)
	t.finished.connect(_on_recoil_finished)

func _on_recoil_finished():
	is_recoiling = false

func _on_fire_timer_timeout():
	can_fire = true

func _on_reload_timer_timeout():
	current_ammo = max_ammo
	is_reloading = false
	print("Recarga completa! ", current_ammo, "/", max_ammo)
	emit_signal("ammo_changed", current_ammo, max_ammo)
	

func get_ammo_info() -> Dictionary:
	return {"current": current_ammo, "max": max_ammo, "is_reloading": is_reloading}

func can_shoot() -> bool:
	return can_fire and not is_reloading and not is_recoiling and current_ammo > 0
