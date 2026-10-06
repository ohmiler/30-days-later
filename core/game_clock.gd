extends Node
## นาฬิกาในเกม (Autoload: เรียกได้ทุกที่ด้วยชื่อ GameClock)
## เวลาในเกมเดินเร็วกว่าเวลาจริง: ค่าเริ่มต้น 1 วินาทีจริง = 1 นาทีในเกม (1 วัน = 24 นาทีจริง)

const START_HOUR := 8
const MINUTES_PER_DAY := 1440.0

## นาทีในเกมต่อ 1 วินาทีจริง (เพิ่มค่านี้ถ้าอยากให้วันผ่านไปเร็วขึ้น)
var minutes_per_second := 1.0
## ตัวคูณความเร็วเวลา เช่นตอนนอนจะเร่งเป็น 60 เท่า
var time_scale := 1.0
var day := 1
## เวลาของวันนี้ หน่วยเป็นนาที (0 = เที่ยงคืน, 720 = เที่ยงวัน)
var minutes := 0.0


func _ready() -> void:
	start_new_game()


func start_new_game() -> void:
	day = 1
	minutes = START_HOUR * 60.0
	time_scale = 1.0


func _process(delta: float) -> void:
	minutes += delta * minutes_per_second * time_scale
	while minutes >= MINUTES_PER_DAY:
		minutes -= MINUTES_PER_DAY
		day += 1


## แปลงเวลาจริง (delta วินาที) เป็นจำนวน "ชั่วโมงในเกม" ที่ผ่านไป ใช้คำนวณความหิว ฯลฯ
func hours_from(delta: float) -> float:
	return delta * minutes_per_second * time_scale / 60.0


func get_hour() -> int:
	return int(minutes / 60.0)


func get_time_text() -> String:
	return "%02d:%02d" % [get_hour(), int(minutes) % 60]


## ความสว่างของวัน: 0 = กลางคืน, 1 = กลางวัน
## รุ่งเช้า 05:00-07:00 ค่อยๆ สว่าง, พลบค่ำ 19:00-21:00 ค่อยๆ มืด
func get_daylight() -> float:
	var hour := minutes / 60.0
	if hour < 5.0 or hour >= 21.0:
		return 0.0
	if hour < 7.0:
		return smoothstep(5.0, 7.0, hour)
	if hour < 19.0:
		return 1.0
	return 1.0 - smoothstep(19.0, 21.0, hour)
