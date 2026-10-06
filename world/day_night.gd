extends Node
## เปลี่ยนแสงของโลกตามเวลาในเกม: กลางวันสว่างขาว, รุ่งเช้า/พลบค่ำสีส้ม, กลางคืนมืดสีน้ำเงิน

@export var sun: DirectionalLight3D
@export var world_environment: WorldEnvironment

@export_group("Sun")
@export var day_sun_energy := 1.1
## กลางคืนยังมีแสงจันทร์จางๆ
@export var night_sun_energy := 0.25
@export var day_sun_color := Color(1.0, 0.97, 0.9)
@export var dusk_sun_color := Color(1.0, 0.55, 0.3)
@export var night_sun_color := Color(0.5, 0.6, 1.0)

@export_group("Ambient")
@export var day_ambient_energy := 0.5
@export var night_ambient_energy := 0.35
@export var day_ambient_color := Color(0.6, 0.65, 0.75)
@export var night_ambient_color := Color(0.35, 0.45, 0.75)


func _process(_delta: float) -> void:
	var daylight := GameClock.get_daylight()
	sun.light_energy = lerpf(night_sun_energy, day_sun_energy, daylight)
	# 0 → 0.5 : กลางคืน → ส้ม,  0.5 → 1 : ส้ม → กลางวัน
	if daylight < 0.5:
		sun.light_color = night_sun_color.lerp(dusk_sun_color, daylight * 2.0)
	else:
		sun.light_color = dusk_sun_color.lerp(day_sun_color, (daylight - 0.5) * 2.0)

	var environment := world_environment.environment
	environment.ambient_light_energy = lerpf(night_ambient_energy, day_ambient_energy, daylight)
	environment.ambient_light_color = night_ambient_color.lerp(day_ambient_color, daylight)
