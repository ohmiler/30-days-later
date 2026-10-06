class_name Interactable
extends Node3D
## ของที่ผู้เล่นเดินเข้าไปใกล้แล้วกด E ใช้ได้ (อ่างน้ำ ตู้เย็น เตียง ...)
## นี่คือ "คลาสแม่": สคริปต์ลูก (sink.gd, food_source.gd, bed.gd) จะ extends Interactable
## แล้วเขียนทับ get_prompt() กับ interact() เป็นพฤติกรรมของตัวเอง

## ชื่อที่แสดงบนจอ
@export var display_name := "ของ"
## ความสูงของจุดที่ผู้เล่นต้องมองเห็น (ใช้เช็กว่าไม่มีกำแพงขวางระหว่างผู้เล่นกับของ)
@export var focus_height := 1.0


func _ready() -> void:
	add_to_group("interactables")


func get_focus_point() -> Vector3:
	return global_position + Vector3.UP * focus_height


## ข้อความที่ขึ้นบนจอ เช่น "[E] ดื่มน้ำจากอ่างล้างจาน"
func get_prompt() -> String:
	return "ใช้" + display_name


func interact(_player: Player) -> void:
	pass
