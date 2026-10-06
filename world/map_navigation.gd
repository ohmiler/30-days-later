extends NavigationRegion3D
## สร้าง Navigation Mesh (แผนที่ "พื้นที่ที่เดินได้" ของซอมบี้) ใหม่ทุกครั้งที่เริ่มเกม
## โดยใช้รูปทรง collision ของชิ้น CSG ทุกชิ้นในแมพ (กำแพง เฟอร์นิเจอร์ รถ ต้นไม้)
## ข้อดี: แก้แมพแล้วไม่ต้องกดปุ่ม Bake NavigationMesh ใหม่เอง

## เอาเฉพาะของที่อยู่ใน physics layer 1 ("world")
const WORLD_LAYER := 1


func _ready() -> void:
	# CSG สร้างรูปทรงของตัวเองตอนท้ายเฟรม (ช้ากว่า _ready) จึงต้องรอ 1 เฟรมก่อน
	await get_tree().process_frame
	var source := NavigationMeshSourceGeometryData3D.new()
	_collect_geometry(get_parent(), source)
	# bake ลงสำเนา (ใช้ค่าตั้งเดิม เช่น agent_radius) แล้วค่อยใส่กลับ region จะได้รู้ว่ามีของใหม่
	var baked := navigation_mesh.duplicate() as NavigationMesh
	NavigationServer3D.bake_from_source_geometry_data(baked, source)
	# ต้องรอให้ navigation map ซิงค์รอบแรกเสร็จก่อน ถ้าใส่เร็วกว่านั้นข้อมูลจะหาย
	while NavigationServer3D.map_get_iteration_id(get_navigation_map()) == 0:
		await get_tree().physics_frame
	navigation_mesh = baked


## ไล่หาชิ้น CSG ทุกชิ้นในแมพ แล้วเก็บหน้าผิวของ collision มาให้ระบบนำทางคำนวณ
func _collect_geometry(node: Node, source: NavigationMeshSourceGeometryData3D) -> void:
	if node is CSGShape3D:
		var csg := node as CSGShape3D
		if csg.is_root_shape() and csg.use_collision and csg.collision_layer & WORLD_LAYER:
			var faces := csg.bake_collision_shape().get_faces()
			if not faces.is_empty():
				source.add_faces(faces, csg.global_transform)
		return  # ชิ้น CSG ลูกๆ ถูกรวมอยู่ในชิ้นแม่แล้ว ไม่ต้องไล่ต่อ
	for child in node.get_children():
		_collect_geometry(child, source)
