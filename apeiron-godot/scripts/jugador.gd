extends CharacterBody2D

# ─── Movimiento ───────────────────────────────────────────────────────────────
@export var thrust_acceleration: float  = 400.0
@export var brake_strength: float       = 25000.0
@export var lateral_strength: float     = 1200.0
@export var max_speed: float            = 50000.0
@export var damping: float              = 0

# ─── Apuntado ─────────────────────────────────────────────────────────────────
@export var rotation_speed: float       = 8.0

# ─── Combate ──────────────────────────────────────────────────────────────────
@export var base_fire_rate: float       = 0.2
@export var base_max_health: int        = 5

# ─── Shake ────────────────────────────────────────────────────────────────────
@export var shoot_shake_amount: float    = 2.0
@export var shoot_shake_duration: float  = 0.08
@export var damage_shake_amount: float   = 10.0
@export var damage_shake_duration: float = 0.3

# ─── Runtime ──────────────────────────────────────────────────────────────────
var max_health: int
var current_health: int
var fire_rate: float
var fire_cooldown: float = 0.0
var is_shaking: bool     = false

var bullet := preload("res://scenes/bala.tscn")

@onready var puntoDisparo := $PuntoDisparo
@onready var sprite       := $Sprite2D
@onready var thruster_main: CPUParticles2D = $ThrusterParticles

var thruster_left:  CPUParticles2D
var thruster_right: CPUParticles2D

signal health_changed(new_health, max_health)
signal player_died

func _ready() -> void:
	_apply_upgrades()
	current_health = max_health
	_setup_particles()
	health_changed.emit(current_health, max_health)

func _apply_upgrades() -> void:
	max_speed  = max_speed + UpgradeManager.get_ship_stat("max_speed")
	max_health = base_max_health + int(UpgradeManager.get_ship_stat("max_health"))
	var fire_rate_bonus: float = UpgradeManager.get_ship_stat("fire_rate")
	fire_rate = maxf(0.05, base_fire_rate - fire_rate_bonus)

func _physics_process(delta: float) -> void:
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	_handle_rotation(delta)
	_handle_movement(delta)
	_update_particles()
	if Input.is_action_pressed("shoot") and fire_cooldown <= 0.0:
		_shoot()

# ─── Rotación ─────────────────────────────────────────────────────────────────
func _handle_rotation(delta: float) -> void:
	var target_angle := global_position.angle_to_point(get_global_mouse_position()) + PI
	rotation = lerp_angle(rotation, target_angle, rotation_speed * delta)

# ─── Movimiento ───────────────────────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
	var right: Vector2   = Vector2.DOWN.rotated(rotation)

	if Input.is_action_pressed("move_up"):
		var accel: float = thrust_acceleration + UpgradeManager.get_ship_stat("acceleration")
		velocity += forward * accel * delta

	if Input.is_action_pressed("move_down"):
		if velocity.length() > 10.0:
			velocity -= velocity.normalized() * brake_strength * delta
		else:
			velocity = Vector2.ZERO

	if Input.is_action_pressed("move_left"):
		velocity -= right * lateral_strength * delta
	if Input.is_action_pressed("move_right"):
		velocity += right * lateral_strength * delta

	# Boost: W + A + D simultáneamente da un empuje extra hacia adelante
	if (Input.is_action_pressed("move_up") and
			Input.is_action_pressed("move_left") and
			Input.is_action_pressed("move_right")):
		var boost_accel: float = thrust_acceleration + UpgradeManager.get_ship_stat("acceleration")
		velocity += forward * boost_accel * 0.6 * delta

	var has_input: bool = (
		Input.is_action_pressed("move_up") or
		Input.is_action_pressed("move_down") or
		Input.is_action_pressed("move_left") or
		Input.is_action_pressed("move_right")
	)
	if not has_input:
		velocity = velocity.lerp(Vector2.ZERO, damping * delta)

	var spd: float = velocity.length()
	if spd > max_speed:
		velocity = velocity * (max_speed / spd)

	move_and_slide()

# ─── Disparo ──────────────────────────────────────────────────────────────────
func _shoot() -> void:
	fire_cooldown = fire_rate
	var newBullet := bullet.instantiate()
	newBullet.global_position = puntoDisparo.global_position
	if newBullet.has_method("initialize"):
		newBullet.initialize(velocity, rotation)
	else:
		newBullet.rotation = rotation
	get_parent().add_child(newBullet)
	apply_shake(shoot_shake_amount, shoot_shake_duration)

# ─── Daño / Muerte ────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	current_health -= amount
	health_changed.emit(current_health, max_health)
	spawn_damage_particles()
	flash_damage()
	apply_shake(damage_shake_amount, damage_shake_duration)
	if current_health <= 0:
		die()

func die() -> void:
	spawn_death_particles()
	player_died.emit()
	queue_free()

# ─── Shake ────────────────────────────────────────────────────────────────────
func apply_shake(amount: float, duration: float) -> void:
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

# ─── Partículas de daño / muerte ─────────────────────────────────────────────
func spawn_damage_particles() -> void:
	_make_burst(global_position, 18, 0.6, 130, 280, 2.5, 5.0, Color(1, 0.2, 0.2))

func spawn_death_particles() -> void:
	_make_burst(global_position, 45, 1.3, 200, 450, 4.0, 9.0, Color(1, 0.45, 0))

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

# ─── Setup de partículas ──────────────────────────────────────────────────────
# La nave apunta hacia Vector2.RIGHT (eje X local).
# "Detrás" en espacio local = X negativa → direction = Vector2(-1, 0)
# local_coords = true hace que todo se mueva con la rotación de la nave.
# Las posiciones son en píxeles locales; la nave mide ~54px (radio colisión 27px).

func _setup_particles() -> void:

	# ── Thruster principal — sale del centro trasero de la nave ───────────────
	thruster_main.emitting               = false
	thruster_main.local_coords           = true        # ← rota con la nave
	thruster_main.amount                 = 30
	thruster_main.lifetime               = 0.38
	thruster_main.emission_shape         = CPUParticles2D.EMISSION_SHAPE_SPHERE
	thruster_main.emission_sphere_radius = 3.5
	thruster_main.direction              = Vector2(-1, 0)  # atrás en local
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
	# Posición: detrás del sprite (X negativa = cola de la nave)
	thruster_main.position               = Vector2(-22, 0)

	# ── Thruster lateral izquierdo — costado superior (Y negativa en local) ──
	# Al presionar A expulsa hacia afuera: dirección -Y local (hacia arriba)
	thruster_left = _make_lateral_thruster(
		Vector2(0, 28),   # costado izquierdo de la nave
		Vector2(-0.5, 1)     # sale perpendicular hacia afuera (izquierda)
	)
	add_child(thruster_left)

	# ── Thruster lateral derecho — costado inferior (Y positiva en local) ────
	# Al presionar D expulsa hacia afuera: dirección +Y local (hacia abajo)
	thruster_right = _make_lateral_thruster(
		Vector2(0, -28),    # costado derecho de la nave
		Vector2(-0.5, -1)      # sale perpendicular hacia afuera (derecha)
	)
	add_child(thruster_right)

func _make_lateral_thruster(offset: Vector2, local_dir: Vector2) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting               = false
	p.local_coords           = true          # ← rota con la nave
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

# ─── Update de partículas ─────────────────────────────────────────────────────
# Con local_coords=true las direcciones son locales → no hay que calcular
# vectores rotados manualmente. Solo actualizamos intensidad y emitting.

func _update_particles() -> void:
	var spd: float       = velocity.length()
	var intensity: float = clampf(spd / max_speed, 0.0, 1.0)

	var pressing_w: bool = Input.is_action_pressed("move_up")
	var pressing_a: bool = Input.is_action_pressed("move_left")
	var pressing_d: bool = Input.is_action_pressed("move_right")

	# ── Thruster principal — sin inclinación, siempre recto hacia atrás ─────
	thruster_main.emitting             = pressing_w
	if pressing_w:
		thruster_main.direction            = Vector2(-1.0, 0.0)
		thruster_main.initial_velocity_min = 200.0 + 220.0 * intensity
		thruster_main.initial_velocity_max = 320.0 + 340.0 * intensity
		thruster_main.scale_amount_min     = 2.0  + 2.5  * intensity
		thruster_main.scale_amount_max     = 4.5  + 5.0  * intensity
		thruster_main.lifetime             = 0.28 + 0.22 * intensity

	# ── Thrusters laterales — se activan con A/D siempre, con o sin W ────────
	var boost_active: bool = pressing_w and pressing_a and pressing_d
	thruster_left.emitting  = pressing_a
	if pressing_a:
		# Intensidad mayor durante el boost
		var boost_mult: float = 1.5 if boost_active else 1.0
		thruster_left.initial_velocity_min = (120.0 + 100.0 * intensity) * boost_mult
		thruster_left.initial_velocity_max = (200.0 + 140.0 * intensity) * boost_mult
		thruster_left.scale_amount_min     = 1.5 + (1.0 if boost_active else 0.0)
		thruster_left.scale_amount_max     = 3.0 + (1.5 if boost_active else 0.0)

	thruster_right.emitting = pressing_d
	if pressing_d:
		var boost_mult: float = 1.5 if boost_active else 1.0
		thruster_right.initial_velocity_min = (120.0 + 100.0 * intensity) * boost_mult
		thruster_right.initial_velocity_max = (200.0 + 140.0 * intensity) * boost_mult
		thruster_right.scale_amount_min     = 1.5 + (1.0 if boost_active else 0.0)
		thruster_right.scale_amount_max     = 3.0 + (1.5 if boost_active else 0.0)
