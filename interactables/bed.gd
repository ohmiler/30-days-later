extends Interactable
## เตียง: นอนเพื่อหายง่วง (ระหว่างนอนเวลาในเกมเดินเร็วขึ้นมาก ซอมบี้อาจย่องมาหาได้!)

## ต้องง่วงอย่างน้อยเท่านี้ถึงจะนอนหลับ
@export var min_fatigue := 30.0


func get_prompt() -> String:
	return "นอนบน" + display_name


func interact(player: Player) -> void:
	if player.needs.fatigue < min_fatigue:
		player.say("ยังไม่ง่วง")
		return
	player.start_sleeping()
