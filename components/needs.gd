class_name Needs
extends Node
## ความต้องการของร่างกาย (แบบ Project Zomboid)
##   hunger / thirst / fatigue : 0 = สบายดี, 100 = แย่สุด — เพิ่มขึ้นตาม "เวลาในเกม"
##   endurance (แรง)          : 100 = เต็ม — ลดตอนวิ่ง/ฟัน ฟื้นตอนพัก — ใช้ "เวลาจริง"
## เจ้าของ (Player) เรียก tick() ทุกเฟรม แล้วบอกว่ากำลังวิ่ง/เดิน/นอนอยู่ไหม

## เลือดของเจ้าของ: หิว/กระหายมากจะเสียเลือด, อิ่มและไม่กระหายจะค่อยๆ ฟื้นเลือด
@export var health: Health

@export_group("ต่อ 1 ชั่วโมงในเกม")
@export var hunger_rate := 4.0
@export var thirst_rate := 6.0
@export var fatigue_rate := 4.0
## นอน 1 ชั่วโมงหายง่วงเท่าไหร่
@export var sleep_recovery := 15.0
@export var starving_damage := 3.0
@export var dehydration_damage := 6.0
@export var health_regen := 3.0

@export_group("แรง (ต่อ 1 วินาทีจริง)")
@export var run_drain := 12.0
@export var rest_regen := 15.0

## ถ้าแรงหมด ต้องพักจนแรงกลับมาถึงค่านี้ถึงจะวิ่งได้อีก
const WINDED_RECOVER := 30.0
## ง่วงเกินค่านี้จะวิ่งไม่ไหว
const TOO_TIRED_TO_RUN := 85.0

var hunger := 0.0
var thirst := 0.0
var fatigue := 0.0
var endurance := 100.0

var _winded := false


func tick(delta: float, is_running: bool, is_moving: bool, is_sleeping: bool) -> void:
	var hours := GameClock.hours_from(delta)
	hunger = minf(hunger + hunger_rate * hours, 100.0)
	thirst = minf(thirst + thirst_rate * hours, 100.0)
	if is_sleeping:
		fatigue = maxf(fatigue - sleep_recovery * hours, 0.0)
	else:
		fatigue = minf(fatigue + fatigue_rate * hours, 100.0)

	# แรง: วิ่งแล้วลด, เดินฟื้นช้า, ยืนนิ่งฟื้นเร็ว, ง่วงมากฟื้นช้าลงครึ่งหนึ่ง
	if is_running:
		endurance -= run_drain * delta
	else:
		var regen := rest_regen * (0.5 if is_moving else 1.0) * (0.5 if fatigue > 75.0 else 1.0)
		endurance += regen * delta
	endurance = clampf(endurance, 0.0, 100.0)
	if endurance <= 0.0:
		_winded = true
	elif _winded and endurance >= WINDED_RECOVER:
		_winded = false

	if hunger >= 90.0:
		health.take_damage(starving_damage * hours)
	if thirst >= 90.0:
		health.take_damage(dehydration_damage * hours)
	if hunger < 50.0 and thirst < 50.0:
		health.heal(health_regen * hours)


func can_run() -> bool:
	return not _winded and fatigue < TOO_TIRED_TO_RUN


func is_winded() -> bool:
	return _winded


## amount ติดลบได้ (เช่นขนมเค็มทำให้กระหายขึ้น)
func eat(amount: float) -> void:
	hunger = clampf(hunger - amount, 0.0, 100.0)


func drink(amount: float) -> void:
	thirst = clampf(thirst - amount, 0.0, 100.0)


func use_endurance(amount: float) -> void:
	endurance = maxf(endurance - amount, 0.0)
