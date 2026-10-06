shader_type spatial;

// วัสดุสำหรับของสูงที่อาจบังตัวละคร (กำแพง พุ่มไม้)
// ส่วนที่อยู่ "ระหว่างกล้องกับผู้เล่น" และใกล้แนวสายตา จะถูกเจาะเป็นวงกลม ทำให้ยังเห็นตัวละคร
// player_position กับ camera_forward ถูกตั้งจากสคริปต์ (ดู Project Settings > Shader Globals)

global uniform vec3 player_position;
global uniform vec3 camera_forward;

uniform vec4 albedo : source_color = vec4(0.78, 0.74, 0.66, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.9;
uniform float cutout_radius = 2.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 to_frag = world_pos - player_position;
	// ระยะตามแนวที่กล้องมอง: ติดลบแปลว่าจุดนี้อยู่ใกล้กล้องมากกว่าผู้เล่น
	float depth = dot(to_frag, camera_forward);
	// ระยะห่างจากเส้นสายตาที่มองไปยังผู้เล่น (เทียบได้กับระยะบนจอ)
	float off_axis = length(to_frag - depth * camera_forward);

	// เจาะเฉพาะภาพจากกล้องหลัก ไม่เจาะตอนวาดเงา (ตอนวาดเงา "กล้อง" คือดวงอาทิตย์) เงากำแพงจึงยังครบ
	float main_camera = step(0.999, abs(dot(CAMERA_DIRECTION_WORLD, camera_forward)));

	// ขอบรูค่อยๆ จางด้วยการทิ้งพิกเซลแบบสุ่ม (dither) ดูนุ่มกว่าตัดขาด
	float hole = (1.0 - smoothstep(cutout_radius * 0.7, cutout_radius, off_axis)) * step(depth, -0.3) * main_camera;
	float dither = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
	if (hole > dither) {
		discard;
	}

	ALBEDO = albedo.rgb;
	ROUGHNESS = roughness;
}
