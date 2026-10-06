class_name LootContainer
extends Interactable
## ที่เก็บของที่ค้นได้ (ตู้ ลิ้นชัก ลัง ท้ายรถ): กด E เพื่อเปิดดูแล้วหยิบของใส่กระเป๋า
## ของข้างในสุ่มใหม่ทุกเกม จาก possible_items (ใส่ชิ้นเดียวกันซ้ำหลายครั้ง = มีโอกาสออกบ่อยขึ้น)

## ของที่อาจสุ่มได้
@export var possible_items: Array[ItemData] = []
@export var min_items := 0
@export var max_items := 3
## ของที่ต้องมีแน่ๆ ทุกเกม
@export var guaranteed_items: Array[ItemData] = []
@export var capacity := 20.0

var inventory: Inventory
var _searched := false


func _ready() -> void:
	super()  # ให้ Interactable._ready() เพิ่มตัวเองเข้ากลุ่ม "interactables" ด้วย
	inventory = Inventory.new()
	inventory.name = "Inventory"
	inventory.capacity = capacity
	add_child(inventory)
	for item in guaranteed_items:
		inventory.add(item)
	if not possible_items.is_empty():
		for i in randi_range(min_items, max_items):
			inventory.add(possible_items.pick_random())


func get_prompt() -> String:
	if not _searched:
		return "ค้น" + display_name
	if inventory.items.is_empty():
		return display_name + " (ว่างเปล่า)"
	return "เปิด%s (%d ชิ้น)" % [display_name, inventory.items.size()]


func interact(player: Player) -> void:
	_searched = true
	player.open_loot(self)
