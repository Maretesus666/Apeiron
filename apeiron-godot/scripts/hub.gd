extends Control

@onready var scroller: ScrollContainer = $ContenedorBotones/ScrollContainer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var panel_mejoras := $PanelMejoras

var is_scrolling: bool = false
var page_width: float = 0.0
var scroll_pos: float = 0.0
var was_scrolling: bool = false
var button_tween: Tween = null

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	page_width = scroller.get_child(0).get_child(0).size.x
	scroller.scroll_horizontal = 0
	
	var nucleo := $ContenedorBotones/ScrollContainer/HBoxContainer/nucleo
	if nucleo.has_signal("mejoras_solicitadas"):
		nucleo.mejoras_solicitadas.connect(panel_mejoras.abrir)
	
	_actualizar_stats_nave()
	_actualizar_stats_nucleo()
	
	UpgradeManager.upgrade_purchased.connect(func(_t,_i): 
		_actualizar_stats_nave()
		_actualizar_stats_nucleo()
	)

func _actualizar_stats_nave() -> void:
	var lbl = $ContenedorBotones/ScrollContainer/HBoxContainer/Nave/VBoxContainer/InfoLabel
	
	var vel_base := 5000
	var vel_bonus := int(UpgradeManager.get_ship_stat("max_speed"))
	var vel_total := vel_base + vel_bonus
	
	var vida_base := 5
	var vida_bonus := int(UpgradeManager.get_ship_stat("max_health"))
	var vida_total := vida_base + vida_bonus
	
	var cadencia_base := 0.2
	var cadencia_bonus := UpgradeManager.get_ship_stat("fire_rate")
	var cadencia_total := maxf(0.05, cadencia_base - cadencia_bonus)
	
	var dano_base := 1
	var dano_bonus := int(UpgradeManager.get_ship_stat("bullet_damage"))
	var dano_total := dano_base + dano_bonus
	
	lbl.text = "🚀 NAVE\n"
	lbl.text += "━━━━━━━━━━━━━━━━━\n"
	lbl.text += "Velocidad: %d (+%d)\n" % [vel_total, vel_bonus]
	lbl.text += "Vida: %d (+%d)\n" % [vida_total, vida_bonus]
	lbl.text += "Daño: %d (+%d)\n" % [dano_total, dano_bonus]
	lbl.text += "Cadencia: %.2fs\n" % cadencia_total
	lbl.text += "━━━━━━━━━━━━━━━━━\n"
	lbl.text += "💰 Puntos: %d" % UpgradeManager.clicker_points

func _actualizar_stats_nucleo() -> void:
	# Esto podría mostrar stats del clicker en algún lugar si quieres
	pass

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_scroll_container_scroll_started() -> void:
	is_scrolling = true
	 
func _on_scroll_container_scroll_ended() -> void:
	is_scrolling = false
	was_scrolling = true
	
func _process(delta: float) -> void:
	var max_scroll := scroller.get_h_scroll_bar().max_value
	if max_scroll == 0:
		return
		
	elif was_scrolling:
		var progress := float(scroller.scroll_horizontal) / max_scroll
		var target: float = round(progress)
		scroll_pos = lerp(scroll_pos, max_scroll * target, 1.0 - pow(0.001, delta))
		scroller.scroll_horizontal = int(scroll_pos)
		var cb: float = animation_tree["parameters/blend_position"]
		animation_tree["parameters/blend_position"] = lerp(cb, target, 1.0 - pow(0.001, delta))
		if abs(scroll_pos - max_scroll * target) < 0.5:
			scroll_pos = max_scroll * target
			scroller.scroll_horizontal = int(scroll_pos)
			animation_tree["parameters/blend_position"] = target
			was_scrolling = false

	elif is_scrolling:
		scroll_pos = float(scroller.scroll_horizontal)
		animation_tree["parameters/blend_position"] = scroll_pos / max_scroll

func _on_button_pressed(extra_arg_0: int) -> void:
	var max_scroll := scroller.get_h_scroll_bar().max_value
	var target_scroll: float = max_scroll * float(extra_arg_0)
	var duration: float = 0.4

	if button_tween:
		button_tween.kill()
	button_tween = create_tween()
	button_tween.set_parallel(true)
	button_tween.set_trans(Tween.TRANS_SINE)
	button_tween.set_ease(Tween.EASE_IN_OUT)
	button_tween.tween_method(func(v: float): scroller.scroll_horizontal = int(v), float(scroller.scroll_horizontal), target_scroll, duration)
	button_tween.tween_property(animation_tree, "parameters/blend_position", float(extra_arg_0), duration)

func _on_mejoras_nave_btn_pressed() -> void:
	panel_mejoras.abrir("nave")
