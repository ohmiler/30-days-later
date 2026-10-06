extends Node3D
## ฉากหลักของเกม: ทุกครั้งที่ฉากนี้เริ่ม (รวมถึงกด R เริ่มใหม่) คือการเริ่มเกมใหม่


func _ready() -> void:
	# GameClock เป็น Autoload จึงไม่ถูกรีเซ็ตเองตอนโหลดฉากใหม่ ต้องสั่งเอง
	GameClock.start_new_game()
