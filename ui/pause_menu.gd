extends Control
## เมนูหยุดเกม (กด Esc): เล่นต่อ / บันทึกเกม / บันทึกแล้วกลับเมนูหลัก
## process_mode ของ node นี้ตั้งเป็น Always ใน scene เพื่อให้ยังกดปุ่มได้ตอนเกมหยุด (get_tree().paused)

const MENU_SCENE := "res://ui/main_menu.tscn"

var player: Player

@onready var resume_button: Button = %ResumeButton
@onready var save_button: Button = %SaveButton
@onready var menu_button: Button = %MenuButton
@onready var status: Label = %Status


func _ready() -> void:
	hide()
	resume_button.pressed.connect(close)
	save_button.pressed.connect(_on_save_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func setup(target: Player) -> void:
	player = target


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel") or player == null:
		return
	if visible:
		close()
	elif not player.is_dead:
		open()
	get_viewport().set_input_as_handled()


func open() -> void:
	status.text = ""
	show()
	get_tree().paused = true
	resume_button.grab_focus()


func close() -> void:
	hide()
	get_tree().paused = false


func _on_save_pressed() -> void:
	status.text = "บันทึกแล้ว" if _save() else "บันทึกไม่สำเร็จ"


func _on_menu_pressed() -> void:
	_save()
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


## ให้ฉากเกม (main.gd) เป็นคนบันทึก เพราะรู้ว่าตอนนี้ควรบันทึกได้ไหม (เช่นตายแล้วห้ามบันทึก)
func _save() -> bool:
	return get_tree().current_scene.save()
