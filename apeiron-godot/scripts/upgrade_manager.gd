extends Node

# Sistema de mejoras global que conecta clicker y juego

# Puntos
var clicker_points: int = 0
var game_points: int = 0

# Mejoras de la nave (compradas con puntos del clicker)
var ship_upgrades = {
	"max_speed": {"level": 0, "cost": 50, "value": 100, "desc": "Velocidad máxima"},
	"acceleration": {"level": 0, "cost": 30, "value": 50, "desc": "Aceleración"},
	"max_health": {"level": 0, "cost": 100, "value": 1, "desc": "Vida máxima"},
	"fire_rate": {"level": 0, "cost": 75, "value": 0.02, "desc": "Cadencia de disparo"},
	"bullet_speed": {"level": 0, "cost": 40, "value": 150, "desc": "Velocidad de balas"},
	"bullet_damage": {"level": 0, "cost": 60, "value": 1, "desc": "Daño de balas"},
	"thrust_power": {"level": 0, "cost": 45, "value": 200, "desc": "Potencia de empuje"},
	"lateral_agility": {"level": 0, "cost": 35, "value": 100, "desc": "Agilidad lateral"},
	"rotation_speed": {"level": 0, "cost": 25, "value": 1, "desc": "Velocidad de rotación"}
}

# Mejoras del clicker (compradas con puntos del juego)
var clicker_upgrades = {
	"points_per_click": {"level": 0, "cost": 10, "value": 1, "desc": "Puntos por click"},
	"auto_clicker_speed": {"level": 0, "cost": 25, "value": 0.5, "desc": "Velocidad auto-click"},
	"click_multiplier": {"level": 0, "cost": 50, "value": 0.1, "desc": "Multiplicador de clicks"},
	"passive_income": {"level": 0, "cost": 75, "value": 2, "desc": "Generación pasiva/seg"},
	"critical_chance": {"level": 0, "cost": 100, "value": 5, "desc": "Probabilidad crítico %"},
	"critical_multiplier": {"level": 0, "cost": 150, "value": 0.5, "desc": "Multiplicador crítico"},
	"combo_bonus": {"level": 0, "cost": 60, "value": 0.05, "desc": "Bonificación por combo"},
	"bulk_clicks": {"level": 0, "cost": 200, "value": 1, "desc": "Clicks múltiples"}
}

signal clicker_points_changed(new_points)
signal game_points_changed(new_points)
signal upgrade_purchased(upgrade_type, upgrade_id)

# Timer para passive income
var passive_timer: float = 0.0

func _ready():
	load_data()

func _process(delta: float) -> void:
	# Passive income del clicker
	var passive := get_clicker_stat("passive_income")
	if passive > 0:
		passive_timer += delta
		if passive_timer >= 1.0:
			passive_timer = 0.0
			add_clicker_points(int(passive))

# Agregar puntos
func add_clicker_points(amount: int):
	clicker_points += amount
	clicker_points_changed.emit(clicker_points)
	save_data()

func add_game_points(amount: int):
	game_points += amount
	game_points_changed.emit(game_points)
	save_data()

# Comprar mejoras de nave (con puntos del clicker)
func buy_ship_upgrade(upgrade_id: String) -> bool:
	if not upgrade_id in ship_upgrades:
		return false
	
	var upgrade = ship_upgrades[upgrade_id]
	var cost = get_ship_upgrade_cost(upgrade_id)
	
	if clicker_points >= cost:
		clicker_points -= cost
		upgrade["level"] += 1
		clicker_points_changed.emit(clicker_points)
		upgrade_purchased.emit("ship", upgrade_id)
		save_data()
		return true
	return false

# Comprar mejoras de clicker (con puntos del juego)
func buy_clicker_upgrade(upgrade_id: String) -> bool:
	if not upgrade_id in clicker_upgrades:
		return false
	
	var upgrade = clicker_upgrades[upgrade_id]
	var cost = get_clicker_upgrade_cost(upgrade_id)
	
	if game_points >= cost:
		game_points -= cost
		upgrade["level"] += 1
		game_points_changed.emit(game_points)
		upgrade_purchased.emit("clicker", upgrade_id)
		save_data()
		return true
	return false

# Obtener costos (escalan exponencialmente)
func get_ship_upgrade_cost(upgrade_id: String) -> int:
	if not upgrade_id in ship_upgrades:
		return 0
	var upgrade = ship_upgrades[upgrade_id]
	return int(upgrade["cost"] * pow(1.15, upgrade["level"]))

func get_clicker_upgrade_cost(upgrade_id: String) -> int:
	if not upgrade_id in clicker_upgrades:
		return 0
	var upgrade = clicker_upgrades[upgrade_id]
	return int(upgrade["cost"] * pow(1.15, upgrade["level"]))

# Obtener valores de mejoras
func get_ship_stat(stat_id: String) -> float:
	if not stat_id in ship_upgrades:
		return 0.0
	var upgrade = ship_upgrades[stat_id]
	return upgrade["level"] * upgrade["value"]

func get_clicker_stat(stat_id: String) -> float:
	if not stat_id in clicker_upgrades:
		return 0.0
	var upgrade = clicker_upgrades[stat_id]
	return upgrade["level"] * upgrade["value"]

# Guardar/Cargar
func save_data():
	var save_data = {
		"clicker_points": clicker_points,
		"game_points": game_points,
		"ship_upgrades": ship_upgrades,
		"clicker_upgrades": clicker_upgrades
	}
	
	var file = FileAccess.open("user://upgrades.save", FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_data():
	if not FileAccess.file_exists("user://upgrades.save"):
		return
	
	var file = FileAccess.open("user://upgrades.save", FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		if save_data:
			clicker_points = save_data.get("clicker_points", 0)
			game_points = save_data.get("game_points", 0)
			ship_upgrades = save_data.get("ship_upgrades", ship_upgrades)
			clicker_upgrades = save_data.get("clicker_upgrades", clicker_upgrades)

func reset_all_data():
	clicker_points = 0
	game_points = 0
	for upgrade in ship_upgrades.values():
		upgrade["level"] = 0
	for upgrade in clicker_upgrades.values():
		upgrade["level"] = 0
	save_data()
