shader_type spatial;

// พื้นหญ้าที่มีเส้นตารางทุก 1 เมตร (1 ช่อง = 1 tile แบบ Project Zomboid)
// ช่วยให้กะระยะและรู้สึกถึงการเคลื่อนที่ได้ง่ายตอนยังไม่มีกราฟิกจริง

uniform vec4 base_color : source_color = vec4(0.30, 0.38, 0.22, 1.0);
uniform vec4 line_color : source_color = vec4(0.22, 0.29, 0.16, 1.0);
uniform float tile_size = 1.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 coord = world_pos.xz / tile_size;

	// สุ่มความสว่างแต่ละช่องเล็กน้อย ให้พื้นดูไม่เรียบเกินไป
	float tile_noise = fract(sin(dot(floor(coord), vec2(12.9898, 78.233))) * 43758.5453);

	// ระยะถึงเส้นตารางที่ใกล้ที่สุด (หารด้วย fwidth ให้เส้นคมเท่ากันทุกระดับซูม)
	vec2 grid = abs(fract(coord - 0.5) - 0.5) / fwidth(coord);
	float line = 1.0 - min(min(grid.x, grid.y), 1.0);

	vec3 color = base_color.rgb * (0.92 + 0.08 * tile_noise);
	ALBEDO = mix(color, line_color.rgb, line);
	ROUGHNESS = 1.0;
}
