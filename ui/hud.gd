extends CanvasLayer
## HUD: นาฬิกา, แถบสถานะ, สภาพร่างกาย (หิว/กระหาย/ง่วง), ข้อความ "[E] ...", หน้าจอตอนนอนและตอนตาย
## เลือดใช้ signal จาก Health ส่วนค่าอื่นที่เปลี่ยนต่อเนื่องทุกเฟรม (หิว น้ำ แรง) อ่านค่ามาแสดงใน _process

@export var player: Player

var _toast_tween: Tween

@onready var health_bar: ProgressBar = $Stats/Health/Bar
@onready var endurance_bar: ProgressBar = $Stats/Endurance/Bar
@onready var hunger_bar: ProgressBar = $Stats/Hunger/Bar
@onready var thirst_bar: ProgressBar = $Stats/Thirst/Bar
@onready var rest_bar: ProgressBar = $Stats/Rest/Bar
@onready var clock_label: Label = $Clock
@onready var moodles_label: Label = $Moodles
@onready var prompt_label: Label = $Prompt
@onready var toast_label: Label = $Toast
@onready var damage_flash: ColorRect = $DamageFlash
@onready var sleep_overlay: Control = $SleepOverlay
@onready var zombie_count: Label = $ZombieCount
@onready var equipped_label: Label = $Equipped
@onready var inventory_screen: Control = $InventoryScreen
@onready var death_screen: Control = $DeathScreen


func _ready() -> void:
	damage_flash.modulate.a = 0.0
	toast_label.modulate.a = 0.0
	death_screen.visible = false
	sleep_overlay.visible = false
	health_bar.max_value = player.health.max_health
	health_bar.value = player.health.current
	player.health.changed.connect(_on_player_health_changed)
	player.health.died.connect(_on_player_died)
	player.message.connect(_show_toast)
	player.sleep_changed.connect(_on_sleep_changed)
	inventory_screen.setup(player)


func _process(_delta: float) -> void:
	var needs := player.needs
	# แถบเต็ม = ดี: อาหาร/น้ำ/พักผ่อน จึงกลับค่าจาก hunger/thirst/fatigue (100 = แย่สุด)
	endurance_bar.value = needs.endurance
	hunger_bar.value = 100.0 - needs.hunger
	thirst_bar.value = 100.0 - needs.thirst
	rest_bar.value = 100.0 - needs.fatigue

	clock_label.text = "วันที่ %d   %s" % [GameClock.day, GameClock.get_time_text()]
	moodles_label.text = "\n".join(_moodles())
	zombie_count.text = "ซอมบี้: %d" % get_tree().get_nodes_in_group("zombies").size()

	var item := player.current_interactable
	prompt_label.text = "[E] " + item.get_prompt() if item else ""
	var weapon := player.equipped_weapon
	equipped_label.text = "ถือ: " + (weapon.display_name if weapon else "มือเปล่า (ผลัก)")


func _unhandled_input(event: InputEvent) -> void:
	if death_screen.visible and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


## สภาพร่างกายที่ควรรู้ (เหมือน "moodle" ใน Project Zomboid)
func _moodles() -> Array[String]:
	var needs := player.needs
	var list: Array[String] = []
	if needs.hunger >= 80.0:
		list.append("หิวมาก! (เสียเลือด)" if needs.hunger >= 90.0 else "หิวมาก")
	elif needs.hunger >= 50.0:
		list.append("หิว")
	if needs.thirst >= 80.0:
		list.append("คอแห้งมาก! (เสียเลือด)" if needs.thirst >= 90.0 else "คอแห้งมาก")
	elif needs.thirst >= 50.0:
		list.append("กระหายน้ำ")
	if needs.fatigue >= Needs.TOO_TIRED_TO_RUN:
		list.append("ง่วงมาก (วิ่งไม่ไหว)")
	elif needs.fatigue >= 60.0:
		list.append("ง่วง")
	if needs.is_winded():
		list.append("เหนื่อยหอบ (วิ่งไม่ได้)")
	if player.health.current < 30.0 and not player.is_dead:
		list.append("บาดเจ็บสาหัส")
	return list


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 1.0
	if _toast_tween:
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.5)
	_toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.5)


func _on_player_health_changed(current: float, _maximum: float) -> void:
	# กระพริบแดงเฉพาะตอนโดนแรงๆ (ไม่ใช่เลือดค่อยๆ ลดจากความหิว)
	if current < health_bar.value - 1.0:
		damage_flash.modulate.a = 1.0
		create_tween().tween_property(damage_flash, "modulate:a", 0.0, 0.4)
	health_bar.value = current


func _on_sleep_changed(sleeping: bool) -> void:
	sleep_overlay.visible = sleeping


func _on_player_died() -> void:
	death_screen.visible = true
