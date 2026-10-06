class_name Inventory
extends Node
## กระเป๋า/ที่เก็บของ: เก็บรายการไอเทมและจำกัดน้ำหนักรวม
## ใช้ได้ทั้งกับผู้เล่น และกับตู้/ลัง/ท้ายรถ (LootContainer สร้าง Inventory ของตัวเองขึ้นมา)

## ส่งออกไปทุกครั้งที่ของข้างในเปลี่ยน (หน้าต่างกระเป๋าใช้ฟังเพื่ออัปเดตรายการ)
signal changed

## น้ำหนักรวมสูงสุด (กก.)
@export var capacity := 12.0
## ของที่มีอยู่ตั้งแต่เริ่ม
@export var starting_items: Array[ItemData] = []

## ไอเทมทุกชิ้น (ของชนิดเดียวกัน 2 ชิ้น = มี ItemData ตัวเดียวกันอยู่ 2 ครั้ง)
var items: Array[ItemData] = []


func _ready() -> void:
	items.append_array(starting_items)


func get_weight() -> float:
	var total := 0.0
	for item in items:
		total += item.weight
	return total


func can_add(item: ItemData) -> bool:
	return get_weight() + item.weight <= capacity + 0.001


func add(item: ItemData) -> bool:
	if not can_add(item):
		return false
	items.append(item)
	changed.emit()
	return true


func remove(item: ItemData) -> bool:
	var index := items.find(item)
	if index == -1:
		return false
	items.remove_at(index)
	changed.emit()
	return true


func has(item: ItemData) -> bool:
	return items.has(item)


## ย้ายไอเทม 1 ชิ้นไปอีกที่ (ถ้าปลายทางเต็มจะไม่ย้าย และคืนค่า false)
func transfer_to(item: ItemData, other: Inventory) -> bool:
	if not has(item) or not other.can_add(item):
		return false
	remove(item)
	other.add(item)
	return true


## รวมของชนิดเดียวกันเป็นกองเดียวไว้แสดงผล: [{"item": ItemData, "count": 2}, ...]
func get_stacks() -> Array[Dictionary]:
	var stacks: Array[Dictionary] = []
	for item in items:
		var found := false
		for stack in stacks:
			if stack.item == item:
				stack.count += 1
				found = true
				break
		if not found:
			stacks.append({"item": item, "count": 1})
	return stacks
