extends Control
## เมนูหลัก: เล่นต่อจากเซฟ / เริ่มเกมใหม่ / ออกจากเกม

const GAME_SCENE := "res://game/main.tscn"

@onready var continue_button: Button = %ContinueButton
@onready var save_info: Label = %SaveInfo
@onready var new_game_button: Button = %NewGameButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	var has_save := SaveSystem.has_save()
	continue_button.disabled = not has_save
	if has_save:
		save_info.text = SaveSystem.get_save_summary() + "\n(เริ่มเกมใหม่จะเขียนทับเซฟนี้)"
	else:
		save_info.text = "ยังไม่มีเกมที่บันทึกไว้"
	continue_button.pressed.connect(_start.bind(true))
	new_game_button.pressed.connect(_start.bind(false))
	quit_button.pressed.connect(get_tree().quit)
	(continue_button if has_save else new_game_button).grab_focus()


func _start(load_save: bool) -> void:
	SaveSystem.load_on_start = load_save
	get_tree().change_scene_to_file(GAME_SCENE)
