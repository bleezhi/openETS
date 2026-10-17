extends Node3D

const ROAD_LENGTH := 600.0
const ROAD_WIDTH := 12.0
const MAX_SPEED := 38.0
const ACCELERATION := 10.0
const BRAKING := 20.0
const ROLLING_RESISTANCE := 1.5
const STEERING_RATE := 1.15

var speed := 0.0
var steering := 0.0
var truck_position := Vector3(0.0, 0.0, 0.0)
var heading := 0.0
var third_person := false
var paused := false

var truck_root: Node3D
var camera: Camera3D
var hud: CanvasLayer
var speed_label: Label
var gear_label: Label
var view_label: Label
var help_label: Label
var road_material: StandardMaterial3D
var truck_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var wheel_material: StandardMaterial3D

func _ready() -> void:
	_make_materials()
	_make_world()
	_make_road()
	_make_truck()
	_make_camera()
	_make_hud()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _make_materials() -> void:
	road_material = _mat(Color(0.12, 0.13, 0.15), 0.95)
	truck_material = _mat(Color(0.78, 0.08, 0.055), 0.45)
	glass_material = _mat(Color(0.12, 0.25, 0.31, 0.82), 0.25)
	wheel_material = _mat(Color(0.035, 0.04, 0.045), 0.95)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _make_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	add_child(sun)

	var ground := _box("Ground", Vector3(0, -0.6, -ROAD_LENGTH * 0.45), Vector3(300, 1, ROAD_LENGTH * 1.4), _mat(Color(0.22, 0.36, 0.20), 1.0))
	add_child(ground)

func _make_road() -> void:
	var road := _box("Road", Vector3(0, -0.02, -ROAD_LENGTH * 0.45), Vector3(ROAD_WIDTH, 0.12, ROAD_LENGTH), road_material)
	add_child(road)
	for side in [-1.0, 1.0]:
		var shoulder := _box("Shoulder", Vector3(side * (ROAD_WIDTH / 2.0 + 1.0), 0.0, -ROAD_LENGTH * 0.45), Vector3(2.0, 0.13, ROAD_LENGTH), _mat(Color(0.42, 0.40, 0.33), 1.0))
		add_child(shoulder)
		var line := _box("EdgeLine", Vector3(side * (ROAD_WIDTH / 2.0 - 0.22), 0.055, -ROAD_LENGTH * 0.45), Vector3(0.12, 0.025, ROAD_LENGTH), _mat(Color(0.92, 0.9, 0.78), 0.8))
		add_child(line)
	for z in range(-int(ROAD_LENGTH), 0, 12):
		var dash := _box("CenterDash", Vector3(0, 0.06, float(z)), Vector3(0.14, 0.025, 5.5), _mat(Color(0.95, 0.84, 0.42), 0.8))
		add_child(dash)
	_make_roadside()

func _make_roadside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41277
	for i in range(100):
		var z := -float(i) * 6.0 - 8.0
		for side in [-1.0, 1.0]:
			var x := side * rng.randf_range(10.0, 34.0)
			var height := rng.randf_range(2.5, 7.0)
			var trunk := _box("TreeTrunk", Vector3(x, height * 0.32, z + rng.randf_range(-2.0, 2.0)), Vector3(0.45, height * 0.65, 0.45), _mat(Color(0.28, 0.17, 0.09), 1.0))
			add_child(trunk)
			var crown := _box("TreeCrown", Vector3(x, height, z), Vector3(rng.randf_range(2.2, 4.0), height * 0.8, rng.randf_range(2.2, 4.0)), _mat(Color(0.12, rng.randf_range(0.27, 0.43), 0.14), 1.0))
			add_child(crown)

func _make_truck() -> void:
	truck_root = Node3D.new()
	truck_root.name = "Truck"
	add_child(truck_root)

	_add_box_to(truck_root, "Chassis", Vector3(0, 0.82, 0.0), Vector3(2.15, 0.48, 5.4), _mat(Color(0.13, 0.14, 0.15), 0.7))
	_add_box_to(truck_root, "Cab", Vector3(0, 1.85, -1.35), Vector3(2.25, 1.95, 2.0), truck_material)
	_add_box_to(truck_root, "Windshield", Vector3(0, 2.18, -2.365), Vector3(1.72, 0.82, 0.035), glass_material)
	_add_box_to(truck_root, "LeftWindow", Vector3(-1.135, 2.0, -1.35), Vector3(0.035, 0.78, 0.88), glass_material)
	_add_box_to(truck_root, "RightWindow", Vector3(1.135, 2.0, -1.35), Vector3(0.035, 0.78, 0.88), glass_material)
	_add_box_to(truck_root, "Bumper", Vector3(0, 0.78, -2.48), Vector3(2.3, 0.28, 0.22), _mat(Color(0.72, 0.73, 0.72), 0.4))
	_add_box_to(truck_root, "Grille", Vector3(0, 1.05, -2.49), Vector3(0.8, 0.42, 0.035), wheel_material)
	_add_box_to(truck_root, "Trailer", Vector3(0, 2.05, 3.65), Vector3(2.45, 2.65, 5.6), _mat(Color(0.77, 0.78, 0.74), 0.8))
	_add_box_to(truck_root, "TrailerFront", Vector3(0, 2.05, 0.85), Vector3(2.25, 2.5, 0.12), _mat(Color(0.65, 0.66, 0.64), 0.8))

	for x in [-1.12, 1.12]:
		for z in [-1.8, 0.0, 3.1, 4.1, 5.0]:
			var wheel := _cylinder("Wheel", Vector3(x, 0.55, z), 0.42, 0.28, wheel_material)
			wheel.rotation_degrees.z = 90
			truck_root.add_child(wheel)

func _make_camera() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 78.0
	add_child(camera)
	_update_camera(0.0)

func _make_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)

	var panel := PanelContainer.new()
	panel.position = Vector2(22, 20)
	panel.custom_minimum_size = Vector2(300, 142)
	hud.add_child(panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	panel.add_child(column)

	var title := Label.new()
	title.text = "openETS  |  PROTOTYPE"
	title.add_theme_font_size_override("font_size", 19)
	column.add_child(title)

	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 30)
	column.add_child(speed_label)

	gear_label = Label.new()
	column.add_child(gear_label)
	view_label = Label.new()
	column.add_child(view_label)

	help_label = Label.new()
	help_label.anchor_left = 0.0
	help_label.anchor_top = 1.0
	help_label.anchor_right = 1.0
	help_label.anchor_bottom = 1.0
	help_label.offset_left = 24
	help_label.offset_top = -52
	help_label.offset_right = -24
	help_label.offset_bottom = -18
	help_label.text = "W / S drive   A / D steer   SPACE brake   C change camera   ESC release mouse"
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 16)
	hud.add_child(help_label)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_C:
				third_person = not third_person
				_update_camera(0.0)
				_update_hud()
			KEY_ESCAPE:
				var mode := Input.MOUSE_MODE_VISIBLE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
				Input.set_mouse_mode(mode)
			KEY_R:
				truck_position = Vector3.ZERO
				heading = 0.0
				speed = 0.0
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("ui_up")
	var reverse := Input.get_action_strength("ui_down")
	var steer_input := Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	# Support the familiar W/A/S/D controls without requiring a separate input map.
	throttle = maxf(throttle, float(Input.is_key_pressed(KEY_W)))
	reverse = maxf(reverse, float(Input.is_key_pressed(KEY_S)))
	steer_input = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))

	if Input.is_key_pressed(KEY_SPACE):
		speed = move_toward(speed, 0.0, BRAKING * delta)
	else:
		speed += throttle * ACCELERATION * delta
		speed -= reverse * BRAKING * delta
		if throttle < 0.01 and reverse < 0.01:
			speed = move_toward(speed, 0.0, ROLLING_RESISTANCE * delta)
	speed = clampf(speed, -8.0, MAX_SPEED)

	var steer_factor := clampf(absf(speed) / 8.0, 0.15, 1.0)
	steering = move_toward(steering, steer_input, 2.8 * delta)
	heading -= steering * STEERING_RATE * steer_factor * delta * signf(speed if absf(speed) > 0.1 else 1.0)
	truck_position.x -= sin(heading) * speed * delta
	truck_position.z -= cos(heading) * speed * delta

	if truck_position.x > ROAD_WIDTH * 0.42:
		truck_position.x = ROAD_WIDTH * 0.42
		speed *= 0.96
	elif truck_position.x < -ROAD_WIDTH * 0.42:
		truck_position.x = -ROAD_WIDTH * 0.42
		speed *= 0.96

	truck_root.position = truck_position
	truck_root.rotation.y = heading
	_update_camera(delta)
	_update_hud()

func _update_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	if third_person:
		var desired := truck_root.global_position + Vector3(0, 5.0, 10.5).rotated(Vector3.UP, heading)
		camera.global_position = camera.global_position.lerp(desired, 1.0 if delta == 0.0 else minf(delta * 4.0, 1.0))
		camera.look_at(truck_root.global_position + Vector3(0, 1.4, 0), Vector3.UP)
	else:
		var cockpit_pos := truck_root.global_position + Vector3(0.0, 2.45, -1.65).rotated(Vector3.UP, heading)
		camera.global_position = cockpit_pos
		camera.rotation = Vector3(0.0, heading, 0.0)

func _update_hud() -> void:
	if not is_instance_valid(speed_label):
		return
	speed_label.text = "%03d km/h" % int(round(absf(speed) * 3.6))
	gear_label.text = "gear: " + ("R" if speed < -0.1 else ("N" if absf(speed) < 0.1 else str(clampi(int(absf(speed) / 5.0) + 1, 1, 8))))
	view_label.text = "camera: " + ("chase" if third_person else "cockpit") + "   |   R reset"

func _box(label: String, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = label
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	mesh_instance.position = pos
	mesh_instance.material_override = material
	return mesh_instance

func _add_box_to(parent: Node3D, label: String, pos: Vector3, size: Vector3, material: Material) -> void:
	parent.add_child(_box(label, pos, size, material))

func _cylinder(label: String, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 16
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	return node
