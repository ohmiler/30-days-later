extends Interactable
## อ่างล้างจาน/ก๊อกน้ำ: ดื่มได้ไม่จำกัด (ใน PZ น้ำประปาจะถูกตัดหลังผ่านไปหลายวัน ไว้ทำทีหลัง)

@export var thirst_relief := 60.0


func get_prompt() -> String:
	return "ดื่มน้ำจาก" + display_name


func interact(player: Player) -> void:
	player.needs.drink(thirst_relief)
	player.say("ดื่มน้ำแล้ว สดชื่นขึ้น")
