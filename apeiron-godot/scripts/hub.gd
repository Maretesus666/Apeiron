extends Control

@onready var scroller: ScrollContainer = $ContenedorBotones/ScrollContainer
@onready var animation_tree: AnimationTree = $AnimationTree

# Ya no necesitás tab_container ni clicker_tab
# El clicker script va directo en la página 1

var is_scrolling: bool = false
var is_manual_scrolling: bool = false
var scroll_to: float = 0.0
var scroll_to_index: int = 0

func _ready():
	await get_tree().process_frame
	@warning_ignore("narrowing_conversion")
	scroller.scroll_horizontal = 0

	# El script del clicker ahora está en la página del scroll, no en un tab
	# Si usás clicker.gd en la página 1, asegurate de que el nodo tenga el script asignado
func get_page_width() -> float:
	var hbox = scroller.get_child(0)
	if hbox and hbox.get_child_count() > 0:
		return hbox.get_child(0).size.x
	return scroller.size.x
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_scroll_container_scroll_started() -> void:
	is_scrolling = true
	set_process(true)

func _on_scroll_container_scroll_ended() -> void:
	is_scrolling = false

func _process(delta: float) -> void:
	var page_width := get_page_width() 

	if is_manual_scrolling:
		var current_scroll: float = scroller.scroll_horizontal
		scroller.scroll_horizontal = int(lerp(float(current_scroll), scroll_to, 1.0 - pow(0.001, delta)))
		var blend := scroller.scroll_horizontal / page_width
		animation_tree["parameters/blend_position"] = blend

		if abs(scroller.scroll_horizontal - scroll_to) < 1.0:
			@warning_ignore("narrowing_conversion")
			scroller.scroll_horizontal = scroll_to
			animation_tree["parameters/blend_position"] = float(scroll_to_index)
			is_manual_scrolling = false
			set_process(false)
	else:
		var scroll: float = scroller.scroll_horizontal / page_width
		var target: float = float(round(scroll))

		if is_scrolling:
			animation_tree["parameters/blend_position"] = scroll
		elif abs(target - scroll) > 0.01:
			animation_tree["parameters/blend_position"] = lerp(float(animation_tree["parameters/blend_position"]), target, 0.1)
			scroller.scroll_horizontal = int(lerp(float(scroller.scroll_horizontal), page_width * target, 0.2))
		else:
			animation_tree["parameters/blend_position"] = target
			@warning_ignore("narrowing_conversion")
			scroller.scroll_horizontal = page_width * target
			set_process(false)
func _on_button_pressed(extra_arg_0: int) -> void:
	await get_tree().process_frame
	scroll_to_index = extra_arg_0
	scroll_to = get_page_width() * extra_arg_0
	is_manual_scrolling = true
	set_process(true)
