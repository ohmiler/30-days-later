class_name Health
extends Node
## พลังชีวิต: แปะเป็นลูกของตัวละครไหนก็ได้ (ผู้เล่น ซอมบี้ สัตว์ ฯลฯ)
## ตัวละครไม่ต้องเขียนระบบเลือดเอง แค่ฟัง signal "changed" กับ "died"

## ส่งออกไปทุกครั้งที่เลือดเปลี่ยน (เช่นให้ HUD อัปเดตแถบเลือด)
signal changed(current: float, maximum: float)
## ส่งออกไปครั้งเดียวตอนเลือดหมด
signal died

@export var max_health := 100.0

var current := 0.0
var is_dead := false


func _ready() -> void:
	current = max_health


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current = maxf(current - amount, 0.0)
	changed.emit(current, max_health)
	if current == 0.0:
		is_dead = true
		died.emit()


func heal(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current = minf(current + amount, max_health)
	changed.emit(current, max_health)
