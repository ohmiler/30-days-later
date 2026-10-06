shader_type spatial;
render_mode unshaded, depth_test_disabled, depth_draw_never, cull_disabled, fog_disabled;

// แผ่นสี่เหลี่ยมที่ทับเต็มจอ (post-process): ทำให้บริเวณที่ผู้เล่น "มองไม่เห็น" มืดและซีดลง
// วิธีคิด: อ่านความลึก (depth) ของแต่ละพิกเซล → คำนวณกลับเป็นตำแหน่งในโลก 3D
//          → เช็กว่าจุดนั้นอยู่ในสายตาผู้เล่นไหม (ข้อมูลระยะมองเห็นแต่ละทิศมาจาก player_vision.gd)

const int RAY_COUNT = 240; // ต้องตรงกับ RAY_COUNT ใน player_vision.gd

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, filter_nearest;

// ระยะที่มองไปได้ก่อนชนกำแพง ในแต่ละทิศรอบตัว (ทิศที่ i = มุม i/RAY_COUNT ของวงกลม)
uniform float ray_distances[RAY_COUNT];
uniform vec3 eye_position;
uniform float facing_angle;
uniform float half_fov = 1.309;
uniform float near_radius = 2.0;
uniform float view_distance = 30.0;
uniform float hidden_brightness = 0.35;
// ของที่สูงกว่านี้ (หลังคา ยอดไม้) ไม่ต้องเช็กกำแพงบัง ขอแค่อยู่ในกรวยสายตา
uniform float roof_height = 2.8;

void vertex() {
	// วางแผ่นนี้ให้เต็มจอเสมอ ไม่สนตำแหน่งกล้อง
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec3 color = textureLod(screen_texture, SCREEN_UV, 0.0).rgb;

	// คำนวณตำแหน่งในโลกของพิกเซลนี้จาก depth
	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 world = (INV_VIEW_MATRIX * vec4(view.xyz / view.w, 1.0)).xyz;

	vec2 to_point = world.xz - eye_position.xz;
	float dist = length(to_point);
	float angle = atan(to_point.y, to_point.x);

	// 1) มีกำแพงบังไหม: เทียบระยะกับระยะที่ raycast ทิศนั้นไปได้ (เกลี่ยระหว่าง 2 เส้นข้างเคียง)
	float f = mod(angle, TAU) / TAU * float(RAY_COUNT);
	int i0 = int(floor(f)) % RAY_COUNT;
	int i1 = (i0 + 1) % RAY_COUNT;
	float clear_distance = mix(ray_distances[i0], ray_distances[i1], fract(f));
	float in_sight = 1.0 - smoothstep(clear_distance + 0.1, clear_distance + 0.6, dist);
	// หลังคาอยู่เหนือห้องที่เรามองไม่เห็นข้างใน แต่ตัวหลังคาเองมองเห็นได้จากข้างนอก
	in_sight = max(in_sight, smoothstep(roof_height - 0.3, roof_height + 0.2, world.y));

	// 2) อยู่ในกรวยสายตาด้านหน้าไหม (หรืออยู่ใกล้ตัวมากจนรู้สึกได้แม้อยู่ข้างหลัง)
	float angle_off = abs(mod(angle - facing_angle + PI, TAU) - PI);
	float in_cone = 1.0 - smoothstep(half_fov - 0.15, half_fov + 0.15, angle_off);
	float nearby = 1.0 - smoothstep(near_radius - 0.5, near_radius, dist);

	// 3) ไม่ไกลเกินระยะมองเห็น
	float in_range = 1.0 - smoothstep(view_distance - 4.0, view_distance, dist);

	float visible = in_sight * max(in_cone, nearby) * in_range;

	// ส่วนที่มองไม่เห็น: เกือบเป็นขาวดำ และมืดลง
	float gray = dot(color, vec3(0.299, 0.587, 0.114));
	vec3 hidden = mix(vec3(gray), color, 0.25) * hidden_brightness;
	ALBEDO = mix(hidden, color, visible);
}
