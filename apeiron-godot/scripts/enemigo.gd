extends Area2D

# ─── Stats base ───────────────────────────────────────────────────────────────
@export var acceleration: float   = 600.0
@export var max_speed: float      = 1800.0
@export var friction: float       = 0.0
@export var health: int           = 3
@export var damage: int           = 1

# ─── Predicción ───────────────────────────────────────────────────────────────
## Tiempo máximo de predicción (segundos). Más bajo = más reactivo, menos overshooting.
@export var max_predict_time: float = 1.0
## Tiempo de fallback si el solver geométrico falla
@export var fallback_predict_time: float = 0.35

# ─── Wobble (ruido de dirección) ─────────────────────────────────────────────
## Amplitud del wobble. Mantenlo bajo para que los enemigos sean precisos.
@export var wobble_strength: float = 0.06
## Frecuencia del wobble
@export var wobble_frequency: float = 1.8

# ─── Separación entre enemigos ────────────────────────────────────────────────
@export var separation_radius: float   = 130.0
## Peso RELATIVO de la separación (0=ignorar, 1=igual peso que la dirección de caza)
@export var separation_weight: float   = 0.45

# ─── Rage (cuando vida <= 50%) ────────────────────────────────────────────────
@export var rage_speed_mult: float = 1.5
@export var rage_accel_mult: float = 1.7

# ─── Rotación (spring) ────────────────────────────────────────────────────────
@export var rot_stiffness: float  = 20.0
@export var rot_damping: float    = 8.0
@export var rot_min_speed: float  = 80.0

# ─── Fase de aproximación ─────────────────────────────────────────────────────
## Distancia a la que el enemigo cambia a modo "embestida" directa
@export var ram_distance: float   = 200.0

# ─── Estado interno ───────────────────────────────────────────────────────────
var player: Node2D    = null
var velocity: Vector2 = Vector2.ZERO

var _wobble_phase: float    = 0.0
var _angular_vel: float     = 0.0
var _is_enraged: bool       = false

# Historial de velocidad del jugador para estimar aceleración
var _player_vel_history: Array[Vector2] = []
const HISTORY_SIZE := 4

func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	player = get_tree().get_first_node_in_group("player")
	_wobble_phase = randf_range(0.0, TAU)
	set_meta("max_health", health)

func _physics_process(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_apply_friction(delta)
		_smooth_rotation(delta)
		return

	_update_rage()
	_update_player_history()

	var eff_max_speed: float = max_speed * (rage_speed_mult if _is_enraged else 1.0)
	var eff_accel: float     = acceleration * (rage_accel_mult if _is_enraged else 1.0)

	# ── Dirección deseada ─────────────────────────────────────────────────────
	var desired_dir := _compute_direction(delta)

	# ── Aplicar aceleración ───────────────────────────────────────────────────
	velocity += desired_dir * eff_accel * delta

	# ── Clamp de velocidad ────────────────────────────────────────────────────
	var spd := velocity.length()
	if spd > eff_max_speed:
		velocity = velocity * (eff_max_speed / spd)

	global_position += velocity * delta
	_smooth_rotation(delta)

# ─── Dirección principal ──────────────────────────────────────────────────────

func _compute_direction(delta: float) -> Vector2:
	var player_vel := _get_player_velocity()
	var dist       := global_position.distance_to(player.global_position)

	# Modo embestida: cuando estamos cerca, apuntamos directo sin predicción
	var target_pos: Vector2
	if dist < ram_distance:
		target_pos = player.global_position
	else:
		target_pos = _solve_intercept(player_vel)

	var chase_dir := (target_pos - global_position).normalized()

	# ── Wobble ────────────────────────────────────────────────────────────────
	_wobble_phase += delta * wobble_frequency * TAU
	# El wobble se reduce conforme nos acercamos (más preciso cerca)
	var wobble_scale := clampf(dist / 800.0, 0.0, 1.0)
	chase_dir = chase_dir.rotated(sin(_wobble_phase) * wobble_strength * wobble_scale)

	# ── Separación ────────────────────────────────────────────────────────────
	var sep_dir := _compute_separation()
	if sep_dir.length() > 0.001:
		# Blend lineal: peso controlado por separation_weight
		chase_dir = chase_dir.lerp(sep_dir, separation_weight).normalized()

	return chase_dir

# ─── Intercept geométrico ─────────────────────────────────────────────────────
# Resuelve cuándo el enemigo (yendo a max_speed) alcanza al jugador
# (moviéndose a player_vel constante). Ecuación cuadrática en t.

func _solve_intercept(player_vel: Vector2) -> Vector2:
	var eff_speed: float = max_speed * (rage_speed_mult if _is_enraged else 1.0)
	# Usamos un promedio entre velocidad actual y max_speed para evitar
	# que el solver asuma teleportación instantánea de dirección
	var solver_speed: float = lerp(velocity.length(), eff_speed, 0.6)
	solver_speed = maxf(solver_speed, eff_speed * 0.4)

	var w: Vector2 = player.global_position - global_position

	# Cuadrática: |w + player_vel*t|² = (solver_speed*t)²
	var a: float = player_vel.dot(player_vel) - solver_speed * solver_speed
	var b: float = 2.0 * w.dot(player_vel)
	var c: float = w.dot(w)

	var t: float = -1.0

	if absf(a) < 0.5:
		# Caso casi-lineal
		if absf(b) > 0.5:
			t = -c / b
	else:
		var disc: float = b * b - 4.0 * a * c
		if disc >= 0.0:
			var sq: float = sqrt(disc)
			var t1: float = (-b - sq) / (2.0 * a)
			var t2: float = (-b + sq) / (2.0 * a)
			if t1 > 0.001 and t2 > 0.001:
				t = minf(t1, t2)
			elif t1 > 0.001:
				t = t1
			elif t2 > 0.001:
				t = t2

	if t > 0.001:
		# Incorporamos la estimación de aceleración del jugador para refinar
		var accel_est := _estimate_player_accel()
		t = minf(t, max_predict_time)
		return (player.global_position
			+ player_vel * t
			+ accel_est * 0.5 * t * t)
	else:
		# Fallback: predicción cinética simple
		return player.global_position + player_vel * fallback_predict_time

# ─── Historial de velocidad del jugador ───────────────────────────────────────

func _update_player_history() -> void:
	var vel := _get_player_velocity()
	_player_vel_history.push_back(vel)
	if _player_vel_history.size() > HISTORY_SIZE:
		_player_vel_history.pop_front()

func _get_player_velocity() -> Vector2:
	if "velocity" in player:
		return player.velocity
	if player.has_method("get_velocity"):
		return player.get_velocity()
	return Vector2.ZERO

func _estimate_player_accel() -> Vector2:
	if _player_vel_history.size() < 2:
		return Vector2.ZERO
	# Diferencia entre el sample más nuevo y el más viejo
	var dv := _player_vel_history[-1] - _player_vel_history[0]
	# No normalizar: queremos la magnitud real. Atenuar para no sobre-predecir.
	return dv * 0.3

# ─── Separación ───────────────────────────────────────────────────────────────

func _compute_separation() -> Vector2:
	var sep := Vector2.ZERO
	var count := 0
	for enemy_node in get_tree().get_nodes_in_group("enemies"):
		if enemy_node == self or not is_instance_valid(enemy_node):
			continue
		var diff: Vector2 = global_position - (enemy_node as Node2D).global_position
		var dist: float   = diff.length()
		if dist < separation_radius and dist > 0.001:
			# Fuerza inversamente proporcional a la distancia
			sep += diff.normalized() * (1.0 - dist / separation_radius)
			count += 1
	if count > 0 and sep.length() > 0.001:
		return sep.normalized()
	return Vector2.ZERO

# ─── Rage ─────────────────────────────────────────────────────────────────────

func _update_rage() -> void:
	var max_hp: int = get_meta("max_health", health)
	var was := _is_enraged
	_is_enraged = health <= max_hp / 2
	if _is_enraged and not was:
		modulate = Color(1.0, 0.45, 0.0)
		var tw := create_tween()
		tw.tween_property(self, "modulate", Color.WHITE, 0.4)

# ─── Fricción ─────────────────────────────────────────────────────────────────

func _apply_friction(delta: float) -> void:
	if friction <= 0.0:
		return
	if velocity.length() > friction * delta:
		velocity -= velocity.normalized() * friction * delta
	else:
		velocity = Vector2.ZERO

# ─── Rotación suave (spring) ──────────────────────────────────────────────────

func _smooth_rotation(delta: float) -> void:
	if velocity.length() < rot_min_speed:
		_angular_vel *= 0.8
		return
	var target: float  = velocity.angle()
	var error: float   = wrapf(target - rotation, -PI, PI)
	var force: float   = rot_stiffness * error - rot_damping * _angular_vel
	_angular_vel += force * delta
	rotation     += _angular_vel * delta

# ─── Daño / Muerte ────────────────────────────────────────────────────────────

func take_damage(amount: int) -> void:
	if not has_meta("max_health"):
		set_meta("max_health", health)
	health -= amount
	flash_effect()
	spawn_hit_particles()
	if health <= 0:
		die()

func die() -> void:
	spawn_death_particles()
	if ScoreManager:
		ScoreManager.add_score(10)
	queue_free()

# ─── Efectos visuales ─────────────────────────────────────────────────────────

func flash_effect() -> void:
	modulate = Color(1, 0.2, 0.2)
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(self) and not _is_enraged:
		modulate = Color.WHITE

func _make_particles(pos: Vector2, amount: int, lifetime: float,
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
	get_tree().root.add_child(p)
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(p):
		p.queue_free()

func spawn_hit_particles() -> void:
	_make_particles(global_position, 8, 0.5, 100, 220, 2, 4, Color(1, 0.3, 0.1))

func spawn_death_particles() -> void:
	_make_particles(global_position, 22, 0.9, 160, 340, 3, 7, Color(1, 0.5, 0))

# ─── Colisiones ───────────────────────────────────────────────────────────────

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		die()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullet"):
		take_damage(1)
		area.queue_free()
