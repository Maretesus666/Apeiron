extends Node

# Sistema de mejoras global que conecta clicker y juego

# Puntos
var clicker_points: int = 0
var game_points: int = 0

# Mejoras de la nave (compradas con puntos del clicker)
var ship_upgrades = {
	"max_speed": {"level": 0, "cost": 50, "value": 100},
	"acceleration": {"level": 0, "cost": 30, "value": 50},
	"max_health": {"level": 0, "cost": 100, "value": 1},
	"fire_rate": {"level": 0, "cost": 75, "value": 0.1}
}

# Mejoras del clicker (compradas con puntos del juego)
var clicker_upgrades = {
	"points_per_click": {"level": 0, "cost": 10, "value": 1},
	"auto_clicker_speed": {"level": 0, "cost": 25, "value": 1},
	"starting_bonus": {"level": 0, "cost": 50, "value": 10}
}

signal clicker_points_changed(new_points)
signal game_points_changed(new_points)
signal upgrade_purchased(upgrade_type, upgrade_id)

func _ready():
	load_data()

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

# Obtener costos
func get_ship_upgrade_cost(upgrade_id: String) -> int:
	if not upgrade_id in ship_upgrades:
		return 0
	var upgrade = ship_upgrades[upgrade_id]
	return upgrade["cost"] * (upgrade["level"] + 1)

func get_clicker_upgrade_cost(upgrade_id: String) -> int:
	if not upgrade_id in clicker_upgrades:
		return 0
	var upgrade = clicker_upgrades[upgrade_id]
	return upgrade["cost"] * (upgrade["level"] + 1)

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
