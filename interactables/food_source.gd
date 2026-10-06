extends Interactable
## ที่ที่มีอาหาร (ตู้เย็น ชั้นวางของ): กินได้ตามจำนวนที่มี หมดแล้วหมดเลย ต้องออกไปหาที่อื่น

@export var food_name := "อาหาร"
@export var servings := 4
@export var hunger_relief := 35.0


func get_prompt() -> String:
	if servings <= 0:
		return display_name + " (ว่างเปล่า)"
	return "กิน%sจาก%s (เหลือ %d)" % [food_name, display_name, servings]


func interact(player: Player) -> void:
	if servings <= 0:
		player.say("ไม่มีอะไรเหลือแล้ว")
		return
	servings -= 1
	player.needs.eat(hunger_relief)
	player.say("กิน%sแล้ว" % food_name)
