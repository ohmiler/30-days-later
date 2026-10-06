extends Control
## หน้าต่างกระเป๋า: กด Tab/I ดูของในกระเป๋า หรือกด E ที่ตู้/ลังเพื่อค้นของ
## ซ้าย = กระเป๋าของเรา, ขวา = ที่เก็บของที่กำลังเปิด (ซ่อนไว้ถ้าเปิดดูกระเป๋าอย่างเดียว)
## ชื่อที่ขึ้นต้นด้วย % เช่น %PlayerList คือ "Unique Name" ตั้งใน scene ทำให้อ้างถึงได้โดยไม่ต้องพิมพ์ path ยาว

## HUD ส่งผู้เล่นมาให้ผ่าน setup() (หน้าต่างนี้เป็นลูกของ HUD ซึ่งรู้จักผู้เล่นอยู่แล้ว)
var player: Player
## ที่เก็บของที่เปิดอยู่ (null = ดูกระเป๋าอย่างเดียว)
var _container: LootContainer
## ของในแต่ละแถวของรายการ [{"item": ItemData, "count": int}] — แถวที่ i ของ ItemList = _stacks[i]
var _player_stacks: Array[Dictionary] = []
var _loot_stacks: Array[Dictionary] = []
## ไอคอนสี่เหลี่ยมสีของไอเทมแต่ละชนิด (สร้างครั้งเดียวแล้วเก็บไว้ใช้ซ้ำ)
var _icons := {}

@onready var player_list: ItemList = %PlayerList
@onready var player_weight: Label = %PlayerWeight
@onready var use_button: Button = %UseButton
@onready var store_button: Button = %StoreButton
@onready var loot_side: Control = %LootSide
@onready var loot_title: Label = %LootTitle
@onready var loot_info: Label = %LootInfo
@onready var loot_list: ItemList = %LootList
@onready var take_button: Button = %TakeButton
@onready var take_all_button: Button = %TakeAllButton
@onready var description: Label = %Description


func _ready() -> void:
	hide()
	set_process_input(false)  # ยังไม่รับปุ่มจนกว่าจะรู้จักผู้เล่น
	player_list.item_selected.connect(_on_player_item_selected)
	player_list.item_activated.connect(func(_index: int) -> void: _use_selected())
	loot_list.item_selected.connect(_on_loot_item_selected)
	loot_list.item_activated.connect(func(_index: int) -> void: _take_selected())
	use_button.pressed.connect(_use_selected)
	store_button.pressed.connect(_store_selected)
	take_button.pressed.connect(_take_selected)
	take_all_button.pressed.connect(_take_all)


func setup(target: Player) -> void:
	player = target
	player.loot_requested.connect(open)
	player.attacked.connect(close)  # โดนกัดระหว่างค้นของ = ปิดหน้าต่างทันที
	player.health.died.connect(close)
	player.inventory.changed.connect(_refresh)
	set_process_input(true)


## ใช้ _input (ไม่ใช่ _unhandled_input) เพราะปุ่ม Tab ถูกระบบ UI ใช้เลื่อนโฟกัส ต้องดักก่อน
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if visible:
			close()
		elif not player.is_dead and not player.is_sleeping:
			open(null)
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func open(container: LootContainer) -> void:
	_set_container(container)
	player.is_busy = true
	description.text = "เลือกไอเทมเพื่อดูรายละเอียด"
	show()
	_refresh()


func close() -> void:
	if not visible:
		return
	_set_container(null)
	player.is_busy = false
	hide()


func _set_container(container: LootContainer) -> void:
	if _container:
		_container.inventory.changed.disconnect(_refresh)
	_container = container
	if _container:
		_container.inventory.changed.connect(_refresh)


func _refresh() -> void:
	if not visible:
		return
	var inventory := player.inventory
	_player_stacks = inventory.get_stacks()
	_fill_list(player_list, _player_stacks, true)
	player_weight.text = "น้ำหนัก %.1f / %.1f กก." % [inventory.get_weight(), inventory.capacity]

	loot_side.visible = _container != null
	store_button.visible = _container != null
	if _container:
		loot_title.text = _container.display_name
		_loot_stacks = _container.inventory.get_stacks()
		_fill_list(loot_list, _loot_stacks, false)
		loot_info.text = "ว่างเปล่า" if _loot_stacks.is_empty() else "%d ชิ้น" % _container.inventory.items.size()
	_update_buttons()


func _fill_list(list: ItemList, stacks: Array[Dictionary], is_player: bool) -> void:
	var selected := list.get_selected_items()
	list.clear()
	for stack in stacks:
		var item: ItemData = stack.item
		var text := item.display_name
		if stack.count > 1:
			text += "  x%d" % stack.count
		text += "   (%.1f กก.)" % (item.weight * stack.count)
		if is_player and item == player.equipped_weapon:
			text += "   [ถืออยู่]"
		list.add_item(text, _icon_for(item))
	# เลือกแถวเดิมไว้ (หรือแถวสุดท้ายถ้าแถวเดิมหายไปแล้ว)
	if not selected.is_empty() and list.item_count > 0:
		list.select(mini(selected[0], list.item_count - 1))


func _selected_item(list: ItemList, stacks: Array[Dictionary]) -> ItemData:
	var selected := list.get_selected_items()
	if selected.is_empty() or selected[0] >= stacks.size():
		return null
	return stacks[selected[0]].item


func _use_selected() -> void:
	var item := _selected_item(player_list, _player_stacks)
	if item:
		player.use_item(item)
		_refresh()


func _store_selected() -> void:
	var item := _selected_item(player_list, _player_stacks)
	if item and _container and not player.inventory.transfer_to(item, _container.inventory):
		player.say("%sเต็มแล้ว" % _container.display_name)


func _take_selected() -> void:
	var item := _selected_item(loot_list, _loot_stacks)
	if item and _container and not _container.inventory.transfer_to(item, player.inventory):
		player.say("กระเป๋าหนักเกินไป!")


func _take_all() -> void:
	if _container == null:
		return
	for item in _container.inventory.items.duplicate():
		if not _container.inventory.transfer_to(item, player.inventory):
			player.say("กระเป๋าหนักเกินไป!")
			return


func _on_player_item_selected(index: int) -> void:
	_describe(_player_stacks[index].item)
	_update_buttons()


func _on_loot_item_selected(index: int) -> void:
	_describe(_loot_stacks[index].item)
	_update_buttons()


func _describe(item: ItemData) -> void:
	description.text = "%s — %s\n%s" % [item.display_name, item.description, item.get_effect_text()]


## ปุ่มเปลี่ยนข้อความตามไอเทมที่เลือก: "กิน", "ดื่ม", "ถือ", "เลิกถือ"
func _update_buttons() -> void:
	var item := _selected_item(player_list, _player_stacks)
	use_button.disabled = item == null
	store_button.disabled = item == null
	if item == null:
		use_button.text = "ใช้"
	elif item == player.equipped_weapon:
		use_button.text = "เลิกถือ"
	else:
		use_button.text = item.get_use_verb()
	var loot_item := _selected_item(loot_list, _loot_stacks)
	take_button.disabled = loot_item == null
	take_all_button.disabled = _loot_stacks.is_empty()


func _icon_for(item: ItemData) -> Texture2D:
	if not _icons.has(item):
		var image := Image.create_empty(14, 14, false, Image.FORMAT_RGBA8)
		image.fill(item.color)
		_icons[item] = ImageTexture.create_from_image(image)
	return _icons[item]
