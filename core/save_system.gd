extends Node
## ระบบบันทึกเกม (Autoload: เรียกได้ทุกที่ด้วยชื่อ SaveSystem)
## บันทึกเป็นไฟล์ JSON ที่ user://savegame.json (เปิดอ่านด้วย text editor ได้)
##   Windows: %APPDATA%/Godot/app_userdata/30 Days Later/savegame.json
##
## node ไหนอยากถูกบันทึก ให้ทำ 2 อย่าง:
##   1) เข้ากลุ่ม "persist"   2) มีฟังก์ชัน save_data() -> Dictionary และ load_data(data: Dictionary)
## ระบบจะใช้ "path ของ node เทียบกับฉากเกม" (เช่น "Zombies/Zombie3") เป็นชื่อในไฟล์

signal saved

const SAVE_PATH := "user://savegame.json"
const PERSIST_GROUP := "persist"
## เพิ่มเลขนี้เมื่อเปลี่ยนรูปแบบไฟล์เซฟ เพื่อไม่โหลดเซฟเก่าที่อ่านไม่ออก
const VERSION := 1

## เมนูหลักตั้งเป็น true ก่อนเข้าฉากเกม เพื่อบอกว่า "เล่นต่อจากเซฟ" แทน "เริ่มเกมใหม่"
var load_on_start := false


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(game: Node) -> bool:
	var nodes := {}
	for node in get_tree().get_nodes_in_group(PERSIST_GROUP):
		if game.is_ancestor_of(node):
			nodes[str(game.get_path_to(node))] = node.save_data()
	var data := {
		"version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(false, true),
		"clock": GameClock.save_data(),
		"nodes": nodes,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("บันทึกเกมไม่ได้: %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	saved.emit()
	return true


func load_game(game: Node) -> bool:
	var data := _read()
	if data.is_empty():
		return false
	GameClock.load_data(data.clock)
	var nodes: Dictionary = data.nodes
	for path: String in nodes:
		var node := game.get_node_or_null(path)
		if node and node.has_method("load_data"):
			node.load_data(nodes[path])
		else:
			push_warning("เซฟมีข้อมูลของ '%s' แต่ไม่พบ node นี้ในฉาก (แมพเปลี่ยนไป?)" % path)
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## ข้อความสั้นๆ ไว้แสดงในเมนู เช่น "วันที่ 3  เวลา 14:20"
func get_save_summary() -> String:
	var data := _read()
	if data.is_empty():
		return ""
	var minutes := int(data.clock.minutes)
	return "วันที่ %d  เวลา %02d:%02d" % [int(data.clock.day), floori(minutes / 60.0), minutes % 60]


## อ่านไฟล์เซฟ (คืนค่า {} ถ้าไม่มีไฟล์ อ่านไม่ออก หรือเป็นเวอร์ชันเก่า)
func _read() -> Dictionary:
	if not has_save():
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or parsed.get("version") != VERSION:
		push_warning("ไฟล์เซฟเสียหายหรือเป็นเวอร์ชันเก่า จะไม่โหลด")
		return {}
	return parsed


## Vector3 <-> Array: JSON ไม่รู้จัก Vector3 จึงเก็บเป็น [x, y, z]
static func vec_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func array_to_vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
