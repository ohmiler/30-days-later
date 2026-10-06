extends Node3D
## ฉากหลักของเกม: เริ่มเกมใหม่ หรือเล่นต่อจากเซฟ, บันทึกอัตโนมัติ, และลบเซฟเมื่อตาย (แบบ Project Zomboid)

## บันทึกอัตโนมัติทุกกี่วินาที (เวลาจริง)
const AUTOSAVE_INTERVAL := 60.0

var _autosave_left := AUTOSAVE_INTERVAL

@onready var player: Player = $Player
@onready var iso_camera: IsoCamera = $IsoCamera


func _ready() -> void:
	# GameClock เป็น Autoload จึงไม่ถูกรีเซ็ตเองตอนโหลดฉากใหม่ ต้องสั่งเอง
	GameClock.start_new_game()
	# _ready ของ Main ทำงานหลังลูกทุกตัวพร้อมแล้ว (ตู้สุ่มของเสร็จ ซอมบี้วางเสร็จ) จึงโหลดเซฟทับได้เลย
	if SaveSystem.load_on_start:
		SaveSystem.load_on_start = false
		SaveSystem.load_game(self)
		iso_camera.snap_to_target()
	# ตายแล้วตายเลย: ลบเซฟทิ้ง ครั้งหน้าต้องเริ่มใหม่
	player.health.died.connect(SaveSystem.delete_save)


func _process(delta: float) -> void:
	_autosave_left -= delta
	if _autosave_left <= 0.0:
		_autosave_left = AUTOSAVE_INTERVAL
		save()


func save() -> bool:
	if player.is_dead:
		return false
	return SaveSystem.save_game(self)


func _notification(what: int) -> void:
	# ผู้เล่นกดปิดหน้าต่างเกม (ปุ่ม X หรือ Alt+F4): บันทึกก่อนออก
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save()
