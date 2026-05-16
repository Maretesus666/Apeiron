extends CharacterBody2D

@export var base_thrust_acceleration: float  = 600.0
@export var base_brake_strength: float       = 250.0
@export var base_lateral_strength: float     = 120.0
@export var base_max_speed: float            = 600.0
@export var damping: float                   = 0
@export var base_rotation_speed: float       = 8.0
@export var base_fire_rate: float            = 0.2
@export var base_max_health: int             = 5

@export var shoot_shake_amount: float    = 2.0
@export var shoot_shake_duration: float  = 0.08
@export var damage_shake_amount: float   = 10.0
@export var damage_shake_duration: float = 0.3

# Stats actuales (base + upgrades)
var thrust_acceleration: float
var lateral_strength: float
var max_speed: float
var rotation_speed: float
var max_health: int
var current_health: int
var fire_rate: float
var bullet_speed: float
var bullet_damage: int
var thrust_power: float
var lateral_agility: float

var fire_cooldown: float = 0.0
var is_shaking: bool     = false

var bullet := preload("res://scenes/bala.tscn")

@onready var puntoDisparo := $PuntoDisparo
@onready var sprite       := $Sprite2D
@onready var thruster_main: CPUParticles2D = $ThrusterParticles

var thruster_left:  CPUParticles2D
var thruster_right: CPUParticles2D

var _mobile: Node = null

signal health_changed(new_health, max_health)
signal player_died

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_apply_upgrades()
	current_health = max_health
	_setup_particles()
	health_changed.emit(current_health, max_health)
	await get_tree().process_frame
	_mobile = get_tree().get_first_node_in_group("mobile_controls")

func _apply_upgrades() -> void:
	# Aplicar todas las mejoras de nave
	max_speed = base_max_speed + UpgradeManager.get_ship_stat("max_speed")
	thrust_acceleration = base_thrust_acceleration + UpgradeManager.get_ship_stat("acceleration")
	max_health = base_max_health + int(UpgradeManager.get_ship_stat("max_health"))
	
	# Fire rate (reducir tiempo entre disparos)
	var fire_rate_bonus: float = UpgradeManager.get_ship_stat("fire_rate")
	fire_rate = maxf(0.05, base_fire_rate - fire_rate_bonus)
	
	# Nuevas mejoras
	bullet_speed = 1000.0 + UpgradeManager.get_ship_stat("bullet_speed")
	bullet_damage = 1 + int(UpgradeManager.get_ship_stat("bullet_damage"))
	thrust_power = base_thrust_acceleration + UpgradeManager.get_ship_stat("thrust_power")
	lateral_agility = base_lateral_strength + UpgradeManager.get_ship_stat("lateral_agility")
	rotation_speed = base_rotation_speed + UpgradeManager.get_ship_stat("rotation_speed")
	
	# Actualizar lateral strength con la mejora
	lateral_strength = lateral_agility

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	_handle_rotation(delta)
	_handle_movement(delta)
	_update_particles()
	
	var can_shoot: bool
	if ConfigManager.mobile_controls_enabled:
		can_shoot = _mobile != null and _mobile.shooting
	else:
		can_shoot = Input.is_action_pressed("shoot")
	
	if can_shoot and fire_cooldown <= 0.0:
		_shoot()

func _handle_rotation(delta: float) -> void:
	var target_angle: float
	if ConfigManager.mobile_controls_enabled and _mobile != null:
		if not _mobile.joy_active:
			return
		target_angle = _mobile.joy_angle
	else:
		target_angle = global_position.angle_to_point(get_global_mouse_position())
	
	# Usar rotation_speed con mejoras
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

const MAX_STEP_DISTANCE: float = 500.0

func _handle_movement(delta: float) -> void:
	if ConfigManager.mobile_controls_enabled and _mobile != null:
		var joy: Vector2 = _mobile.movement
		if joy.length() > 0.05:
			# Usar thrust_power en lugar de acceleration básica
			velocity += joy * thrust_power * delta
		var spd: float = velocity.length()
		if spd > max_speed:
			velocity = velocity * (max_speed / spd)
		_substep_move(delta)
		return

	var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
	var right: Vector2   = Vector2.DOWN.rotated(rotation)

	var pressing_w: bool = Input.is_action_pressed("move_up")
	var pressing_s: bool = Input.is_action_pressed("move_down")
	var pressing_a: bool = Input.is_action_pressed("move_left")
	var pressing_d: bool = Input.is_action_pressed("move_right")

	if pressing_w:
		# Usar thrust_power mejorada
		velocity += forward * thrust_power * delta
	if pressing_s:
		if velocity.length() > 10.0:
			velocity -= velocity.normalized() * base_brake_strength * delta
		else:
			velocity = Vector2.ZERO
	if pressing_a:
		# Usar lateral_agility mejorada
		velocity -= right * lateral_strength * delta
	if pressing_d:
		velocity += right * lateral_strength * delta
	if pressing_w and pressing_a and pressing_d:
		# Boost con thrust_power
		velocity += forward * thrust_power * 0.6 * delta

	var has_input: bool = pressing_w or pressing_s or pressing_a or pressing_d
	if not has_input:
		velocity = velocity.lerp(Vector2.ZERO, damping * delta)

	var spd: float = velocity.length()
	if spd > max_speed:
		velocity = velocity * (max_speed / spd)

	_substep_move(delta)

func _substep_move(delta: float) -> void:
	var distance_this_frame: float = velocity.length() * delta
	var steps: int = max(1, int(ceil(distance_this_frame / MAX_STEP_DISTANCE)))
	var sub_delta: float = delta / float(steps)

	for _i in range(steps):
		move_and_slide()

func _shoot() -> void:
	fire_cooldown = fire_rate
	var newBullet := bullet.instantiate()
	newBullet.global_position = puntoDisparo.global_position
	
	# Pasar velocidad mejorada y daño como metadata
	if newBullet.has_method("initialize"):
		newBullet.initialize(velocity, rotation)
	else:
		newBullet.rotation = rotation
	
	# Aplicar bullet_speed mejorada
	if "base_speed" in newBullet:
		newBullet.base_speed = bullet_speed
	
	# Pasar daño mejorado
	newBullet.set_meta("damage", bullet_damage)
	
	get_parent().add_child(newBullet)
	apply_shake(shoot_shake_amount, shoot_shake_duration)

func take_damage(amount: int) -> void:
	current_health -= amount
	health_changed.emit(current_health, max_health)
	spawn_damage_particles()
	flash_damage()
	apply_shake(damage_shake_amount, damage_shake_duration)
	Input.vibrate_handheld(80)
	if current_health <= 0:
		die()

func die() -> void:
	spawn_death_particles()
	player_died.emit()
	queue_free()

func apply_shake(amount: float, duration: float) -> void:
	if not ConfigManager.screenshake_enabled:
		return
	if is_shaking:
		return
	is_shaking = true
	var original_pos: Vector2 = sprite.position
	var timer := 0.0
	while timer < duration:
		sprite.position = original_pos + Vector2(
			randf_range(-amount, amount),
			randf_range(-amount, amount)
		)
		timer += get_process_delta_time()
		await get_tree().process_frame
	sprite.position = original_pos
	is_shaking = false

func flash_damage() -> void:
	sprite.modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		sprite.modulate = Color.WHITE

func spawn_damage_particles() -> void:
	_make_burst(global_position, 18, 0.6, 20, 28, 2.5, 5.0, Color(1, 0.2, 0.2))

func spawn_death_particles() -> void:
	_make_burst(global_position, 45, 1.3, 30, 45, 4.0, 9.0, Color(1, 0.45, 0))

func _make_burst(pos: Vector2, amount: int, lifetime: float,
		vel_min: float, vel_max: float,
		scale_min: float, scale_max: float,
		color: Color) -> void:
	var p := CPUParticles2D.new()
	p.global_position      = pos
	p.emitting             = true
	p.one_shot             = true
	p.amount               = amount
	p.lifetime             = lifetime
	p.explosiveness        = 1.0
	p.spread               = 180
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.scale_amount_min     = scale_min
	p.scale_amount_max     = scale_max
	p.color                = color
	p.gravity              = Vector2.ZERO
	get_tree().root.add_child(p)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(p):
		p.queue_free()

func _setup_particles() -> void:
	thruster_main.emitting               = false
	thruster_main.local_coords           = true
	thruster_main.amount                 = 30
	thruster_main.lifetime               = 0.38
	thruster_main.emission_shape         = CPUParticles2D.EMISSION_SHAPE_SPHERE
	thruster_main.emission_sphere_radius = 3.5
	thruster_main.direction              = Vector2(-1, 0)
	thruster_main.spread                 = 12.0
	thruster_main.gravity                = Vector2.ZERO
	thruster_main.initial_velocity_min   = 240.0
	thruster_main.initial_velocity_max   = 360.0
	thruster_main.scale_amount_min       = 2.5
	thruster_main.scale_amount_max       = 5.5
	thruster_main.color                  = Color(1.0, 0.55, 0.1, 1.0)
	thruster_main.color_ramp             = _make_gradient([
		Color(1.0, 0.95, 0.5, 1.0),
		Color(1.0, 0.45, 0.05, 0.8),
		Color(0.6, 0.1, 0.0, 0.3),
		Color(0.0, 0.0, 0.0, 0.0)
	])
	thruster_main.position = Vector2(-22, 0)

	thruster_left  = _make_lateral_thruster(Vector2(0,  28), Vector2(-0.5,  1).normalized())
	thruster_right = _make_lateral_thruster(Vector2(0, -28), Vector2(-0.5, -1).normalized())
	add_child(thruster_left)
	add_child(thruster_right)

func _make_lateral_thruster(offset: Vector2, local_dir: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting               = false
	p.local_coords           = true
	p.amount                 = 14
	p.lifetime               = 0.22
	p.emission_shape         = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 2.0
	p.direction              = local_dir
	p.spread                 = 18.0
	p.gravity                = Vector2.ZERO
	p.initial_velocity_min   = 140.0
	p.initial_velocity_max   = 220.0
	p.scale_amount_min       = 1.5
	p.scale_amount_max       = 3.0
	p.color                  = Color(0.3, 0.75, 1.0, 1.0)
	p.color_ramp             = _make_gradient([
		Color(0.7, 0.95, 1.0, 1.0),
		Color(0.2, 0.55, 1.0, 0.6),
		Color(0.0, 0.1, 0.4, 0.0)
	])
	p.position = offset
	return p

func _make_gradient(colors: Array) -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray(colors)
	var offsets: PackedFloat32Array = []
	for i in colors.size():
		offsets.append(float(i) / float(colors.size() - 1))
	g.offsets = offsets
	return g

func _update_particles() -> void:
	var spd: float       = velocity.length()
	var intensity: float = clampf(spd / max_speed, 0.0, 1.0)

	var joy: Vector2 = Vector2.ZERO
	if _mobile != null:
		joy = _mobile.movement

	var pressing_w: bool = Input.is_action_pressed("move_up")    or joy.y < -0.1
	var pressing_a: bool = Input.is_action_pressed("move_left")  or joy.x < -0.1
	var pressing_d: bool = Input.is_action_pressed("move_right") or joy.x >  0.1

	thruster_main.emitting = pressing_w
	if pressing_w:
		thruster_main.direction            = Vector2(-1.0, 0.0)
		thruster_main.initial_velocity_min = 200.0 + 220.0 * intensity
		thruster_main.initial_velocity_max = 320.0 + 340.0 * intensity
		thruster_main.scale_amount_min     = 2.0  + 2.5  * intensity
		thruster_main.scale_amount_max     = 4.5  + 5.0  * intensity
		thruster_main.lifetime             = 0.28 + 0.22 * intensity

	var boost_active: bool = pressing_w and pressing_a and pressing_d
	thruster_left.emitting  = pressing_a
	thruster_right.emitting = pressing_d

	if pressing_a:
		var bm: float = 1.5 if boost_active else 1.0
		thruster_left.initial_velocity_min = (120.0 + 100.0 * intensity) * bm
		thruster_left.initial_velocity_max = (200.0 + 140.0 * intensity) * bm
		thruster_left.scale_amount_min     = 1.5 + (1.0 if boost_active else 0.0)
		thruster_left.scale_amount_max     = 3.0 + (1.5 if boost_active else 0.0)
	if pressing_d:
		var bm: float = 1.5 if boost_active else 1.0
		thruster_right.initial_velocity_min = (120.0 + 100.0 * intensity) * bm
		thruster_right.initial_velocity_max = (200.0 + 140.0 * intensity) * bm
		thruster_right.scale_amount_min     = 1.5 + (1.0 if boost_active else 0.0)
		thruster_right.scale_amount_max     = 3.0 + (1.5 if boost_active else 0.0)
