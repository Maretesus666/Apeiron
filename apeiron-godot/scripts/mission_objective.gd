extends Area2D

signal objective_reached

# Distancias base — se escalan según velocidad del jugador y apuesta
@export var min_distance: float = 3000.0
@export var max_distance: float = 8000.0

func _ready() -> void:
	add_to_group("objective")
	_place_randomly()

func _place_randomly() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# ── Factor de velocidad ──────────────────────────────────────────────────
	# Cuanto más rápida es la nave, más lejos hay que ir (escala lineal).
	var base_speed     := 600.0
	var player_max_spd := base_speed + UpgradeManager.get_ship_stat("max_speed")
	var speed_factor   := player_max_spd / base_speed   # 1.0 sin mejoras, >1 con ellas

	# ── Factor de apuesta ────────────────────────────────────────────────────
	# Mayor apuesta → objetivo más lejano.
	# Usamos la apuesta como fracción del total de puntos que tenía el jugador
	# antes de apostar (bet_points + puntos actuales).
	var bet_factor := 1.0
	if UpgradeManager.is_mission_active and UpgradeManager.bet_points > 0:
		var total_pts: int = UpgradeManager.clicker_points + UpgradeManager.bet_points
		if total_pts > 0:
			var bet_ratio: float = float(UpgradeManager.bet_points) / (float(total_pts)/2)
			# bet_ratio va de 0 a 1 → distancia escala de 1× a 3×
			bet_factor = 1.0 + bet_ratio * 2.0

	# ── Distancia final ──────────────────────────────────────────────────────
	var effective_min := min_distance * speed_factor * bet_factor
	var effective_max := max_distance * speed_factor * bet_factor

	var angle    := randf() * TAU
	var distance := randf_range(effective_min, effective_max)
	global_position = player.global_position + Vector2(cos(angle), sin(angle)) * distance

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		objective_reached.emit()
		UpgradeManager.complete_mission()
		queue_free()
