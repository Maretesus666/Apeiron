extends CanvasLayer

@onready var pause_panel    := $Panel
@onready var title_label    := $Panel/VBoxContainer/TitleLabel
@onready var score_label    := $Panel/VBoxContainer/ScoreLabel
@onready var resume_button  := $Panel/VBoxContainer/ResumeButton
@onready var restart_button := $Panel/VBoxContainer/RestartButton
@onready var menu_button    := $Panel/VBoxContainer/MenuButton

var is_paused:    bool = false
var is_game_over: bool = false
var _mobile: Node = null

func _ready() -> void:
	add_to_group("pause_menu")
	hide_menu()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.player_died.connect(_on_player_died)
	await get_tree().process_frame
	_mobile = get_tree().get_first_node_in_group("mobile_controls")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not is_game_over:
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	if is_paused:
		_show_pause()
	else:
		_hide()

func _show_pause() -> void:
	pause_panel.visible   = true
	title_label.text      = "PAUSA"
	resume_button.visible = true
	score_label.visible   = false
	get_tree().paused     = true
	if _mobile:
		_mobile.enabled = false
	
	# Panel normal para pausa
	_set_panel_style(false)

func show_mission_complete(reward: int) -> void:
	is_game_over        = true
	pause_panel.visible = true
	title_label.text    = "MISION COMPLETADA"
	score_label.text    = "Ganaste: %d puntos\nScore: %d" % [reward, ScoreManager.score if ScoreManager else 0]
	score_label.visible   = true
	resume_button.visible = false
	get_tree().paused     = true
	if _mobile:
		_mobile.enabled = false
	
	# Panel transparente para victoria
	_set_panel_style(true)

func show_game_over_menu(score: int = 0) -> void:
	is_game_over         = true
	pause_panel.visible  = true
	title_label.text     = "GAME OVER"
	
	if UpgradeManager.is_mission_active:
		score_label.text = "Perdiste: %d puntos\nScore: %d" % [UpgradeManager.bet_points, score]
		UpgradeManager.fail_mission()
	else:
		score_label.text = "Score: %d" % score
	
	score_label.visible   = true
	resume_button.visible = false
	get_tree().paused     = true
	if _mobile:
		_mobile.enabled = false
	
	# Panel transparente para game over
	_set_panel_style(true)

func _set_panel_style(transparent: bool) -> void:
	# Si es transparente (game over/victoria), hacer el panel invisible
	# pero mantener los botones y texto visibles
	if transparent:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)  # Transparente
		pause_panel.add_theme_stylebox_override("panel", style)
	else:
		# Estilo normal para pausa
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.3, 0.3, 0.3, 0.8)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		pause_panel.add_theme_stylebox_override("panel", style)

func hide_menu() -> void:
	pause_panel.visible = false
	get_tree().paused   = false
	if _mobile:
		_mobile.enabled = true

func _hide() -> void:
	hide_menu()

func _on_player_died() -> void:
	await get_tree().create_timer(1.0).timeout
	show_game_over_menu(ScoreManager.score if ScoreManager else 0)

func _on_resume_button_pressed() -> void:
	toggle_pause()

func _on_restart_button_pressed() -> void:
	if UpgradeManager.is_mission_active:
		UpgradeManager.cancel_mission()
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	if UpgradeManager.is_mission_active:
		UpgradeManager.cancel_mission()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")
