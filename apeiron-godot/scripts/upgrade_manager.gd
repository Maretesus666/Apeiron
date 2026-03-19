extends Node

# Sistema de mejoras global que conecta clicker y juego

# Puntos
var clicker_points: int = 0
var game_points: int = 0

# Mejoras de la nave (compradas con puntos del clicker)
var ship_upgrades = {
	"max_speed": {"level": 0, "cost": 50, "value": 100, "desc": "Velocidad máxima", "max_level": 999},
	"acceleration": {"level": 0, "cost": 30, "value": 50, "desc": "Aceleración", "max_level": 999},
	"max_health": {"level": 0, "cost": 100, "value": 1, "desc": "Vida máxima", "max_level": 22},
	"fire_rate": {"level": 0, "cost": 75, "value": 0.02, "desc": "Cadencia de disparo", "max_level": 999},
	"bullet_speed": {"level": 0, "cost": 40, "value": 150, "desc": "Velocidad de balas", "max_level": 999},
	"bullet_damage": {"level": 0, "cost": 60, "value": 1, "desc": "Daño de balas", "max_level": 999},
	"thrust_power": {"level": 0, "cost": 45, "value": 200, "desc": "Potencia de empuje", "max_level": 999},
	"lateral_agility": {"level": 0, "cost": 35, "value": 100, "desc": "Agilidad lateral", "max_level": 999},
	"rotation_speed": {"level": 0, "cost": 25, "value": 1, "desc": "Velocidad de rotación", "max_level": 999}
}

# Mejoras del clicker (compradas con puntos del juego)
var clicker_upgrades = {
	"points_per_click": {"level": 0, "cost": 10, "value": 1, "desc": "Puntos por click", "max_level": 999},
	"auto_clicker_speed": {"level": 0, "cost": 25, "value": 0.5, "desc": "Velocidad auto-click", "max_level": 999},
	"click_multiplier": {"level": 0, "cost": 50, "value": 0.1, "desc": "Multiplicador de clicks", "max_level": 999},
	"passive_income": {"level": 0, "cost": 75, "value": 2, "desc": "Generación pasiva/seg", "max_level": 999},
	"critical_chance": {"level": 0, "cost": 100, "value": 5, "desc": "Probabilidad crítico %", "max_level": 999},
	"critical_multiplier": {"level": 0, "cost": 150, "value": 0.5, "desc": "Multiplicador crítico", "max_level": 999},
	"combo_bonus": {"level": 0, "cost": 60, "value": 0.05, "desc": "Bonificación por combo", "max_level": 999},
	"bulk_clicks": {"level": 0, "cost": 200, "value": 1, "desc": "Clicks múltiples", "max_level": 3}
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
	var max_level = upgrade.get("max_level", 999)
	
	# Verificar si ya alcanzó el nivel máximo
	if upgrade["level"] >= max_level:
		return false
	
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
	var max_level = upgrade.get("max_level", 999)
	
	# Verificar si ya alcanzó el nivel máximo
	if upgrade["level"] >= max_level:
		return false
	
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
			
			# Cargar upgrades guardadas
			var loaded_ship = save_data.get("ship_upgrades", {})
			var loaded_clicker = save_data.get("clicker_upgrades", {})
			
			# Migrar: agregar mejoras nuevas que no existían antes
			_migrate_upgrades(ship_upgrades, loaded_ship)
			_migrate_upgrades(clicker_upgrades, loaded_clicker)

# Función auxiliar para migrar upgrades viejas a nuevas
func _migrate_upgrades(default_dict: Dictionary, loaded_dict: Dictionary) -> void:
	for key in default_dict.keys():
		if key in loaded_dict:
			# Mantener nivel guardado pero actualizar otros valores
			var loaded_level = loaded_dict[key].get("level", 0)
			var max_level = default_dict[key].get("max_level", 999)
			# Asegurarse de que el nivel cargado no exceda el máximo
			default_dict[key]["level"] = min(loaded_level, max_level)
		# Si no existe en loaded_dict, se queda con valores por defecto (level = 0)

func reset_all_data():
	clicker_points = 0
	game_points = 0
	for upgrade in ship_upgrades.values():
		upgrade["level"] = 0
	for upgrade in clicker_upgrades.values():
		upgrade["level"] = 0
	save_data()
