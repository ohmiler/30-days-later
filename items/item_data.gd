class_name ItemData
extends Resource
## ข้อมูลของไอเทม 1 ชนิด เก็บเป็นไฟล์ .tres ในโฟลเดอร์ items/
## สร้างไอเทมใหม่ได้โดยไม่ต้องเขียนโค้ด: คลิกขวาในแถบ FileSystem > Create New > Resource > ItemData
## แล้วกรอกค่าใน Inspector (หรือ Duplicate ไฟล์ .tres ที่มีอยู่แล้วแก้ค่า)

enum Category { FOOD, DRINK, MEDICAL, WEAPON, MISC }

@export var display_name := "ไอเทม"
@export_multiline var description := ""
@export var category := Category.MISC
## น้ำหนัก (กก.) กระเป๋าใส่ได้จำกัด
@export var weight := 0.5
## สีที่ใช้แสดงในรายการ และเป็นสีของอาวุธตอนถือ
@export var color := Color.WHITE

@export_group("กิน / ดื่ม / รักษา")
## ลดความหิวเท่าไหร่
@export var hunger_relief := 0.0
## ลดความกระหายเท่าไหร่ (ติดลบ = กินแล้วคอแห้ง เช่นขนมเค็ม)
@export var thirst_relief := 0.0
@export var heal := 0.0

@export_group("อาวุธ")
@export var damage := 0.0
@export var attack_cooldown := 0.6
## ความยาวของอาวุธ (เมตร) ใช้แสดงผล
@export var weapon_length := 0.9


func is_weapon() -> bool:
	return category == Category.WEAPON


## คำกริยาที่ใช้กับไอเทมนี้ (ใช้บนปุ่มและข้อความ)
func get_use_verb() -> String:
	match category:
		Category.FOOD:
			return "กิน"
		Category.DRINK:
			return "ดื่ม"
		Category.WEAPON:
			return "ถือ"
	return "ใช้"


## สรุปผลของไอเทม เช่น "อาหาร +30  น้ำ -5"
func get_effect_text() -> String:
	var parts: Array[String] = []
	if hunger_relief != 0.0:
		parts.append("อาหาร %+d" % hunger_relief)
	if thirst_relief != 0.0:
		parts.append("น้ำ %+d" % thirst_relief)
	if heal != 0.0:
		parts.append("เลือด %+d" % heal)
	if is_weapon():
		parts.append("ความแรง %d  ความเร็ว %.2f วิ/ครั้ง" % [damage, attack_cooldown])
	parts.append("หนัก %.1f กก." % weight)
	return "   ".join(parts)
