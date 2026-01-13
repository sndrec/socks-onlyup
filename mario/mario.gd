extends LibSM64Mario

@onready var audio_stream_player := $AudioStreamPlayer
@onready var mario_collision := $MarioCollision as Area3D
@onready var collision_cylinder := $MarioCollision/CollisionCylinder.shape as CylinderShape3D

@onready var level_timer := $LevelTimer as Label
@onready var coin_counter := $CoinCounter
@onready var elevation_counter := $ElevationCounter
@onready var power_disp := $PowerDisp
@onready var health_wedges_disp := $PowerDisp/HealthWedges
@onready var respawn_timer := $RespawnTimer

const HOLD_DURATION_TO_RESPAWN := 5.0

var _cam_rotation := 0.0
var _cam_rotation_target := 0.0
var _cam_zoom := 1
var _cam_tilt := 0.0
var _cam_height := 0.0
var _cam_target_height := 0.0
var _cam_dist := 0.0
var _cam_target := Vector3(0, 0, 0)
var _cam_dir := Vector3(0, 0, 1)
var _cam_target_dist := 0.0

var _paused : bool = false

var finish_time : float = -1.0
var current_coin_count : int = 0

var start_time := 0.0

var checkpoint_pos : Vector3 = Vector3.ZERO
var checkpoint_facing : float = 0
var checkpoint_flag : Node3D

var needs_respawning : bool = false
var num_checkpoints_used : int = 0

var hide_hud : bool = false
var hide_hud_old : bool = false
var gravity_add : float = 0.0
var gravity_set_time : int = 0

var respawn_button_hold_time : float = 0.0

func _ready() -> void:
	SOGlobal.current_mario = self
	_default_material.vertex_color_is_srgb = true
	_vanish_material.vertex_color_is_srgb = true
	_metal_material.vertex_color_is_srgb = true
	_wing_material.vertex_color_is_srgb = true
	_update_power_disp_color()
	super()

func _process(delta: float) -> void:
	if _id < 0:
		return
	if SOGlobal.unfocused:
		return
	if _paused:
		return
	
	if position.y <= -32:
		if checkpoint_flag and is_instance_valid(checkpoint_flag):
			_restore_mario_to_checkpoint()
		elif !needs_respawning:
			needs_respawning = true
			_respawn_mario()

	level_timer.visible = true
	var timer_seconds : float = float(finish_time - start_time) * 0.001
	if finish_time < 0:
		timer_seconds = float(Time.get_ticks_msec() - start_time) * 0.001
	if timer_seconds < 3600:
		level_timer.text = "%02d:%02d.%03d" % [timer_seconds/60.0, fmod(timer_seconds, 60.0), fmod(timer_seconds * 1000, 1000.0)]
	else:
		level_timer.text = "%d:%02d:%02d.%03d" % [timer_seconds/3600.0, fmod(timer_seconds/60.0, 60.0), fmod(timer_seconds, 60.0), fmod(timer_seconds * 1000, 1000.0)]
	visible = true
	
	elevation_counter.text = "%dm" % [position.y]

	#DebugDraw2D.set_text("ACTION", LibSM64.ACT_to_action_name(_action))

	time_since_start += delta

	if Input.is_action_just_pressed("start_button"):
		var pause_menu = preload("res://mario/mario_pause_menu.tscn").instantiate()
		SOGlobal.add_child(pause_menu)
		_paused = true
		return

	var camera_input : Vector2 = Input.get_vector("cam_stick_left", "cam_stick_right", "cam_stick_up", "cam_stick_down")
	if SOGlobal.flip_x:
		camera_input.x *= -1

	var time_minus_start = Time.get_ticks_msec() - SOGlobal.level_start_time

	mario_collision.position.y = 0.25
	collision_cylinder.radius = 0.5
	collision_cylinder.height = 1.75

	#print(action & LibSM64.ACT_FLAG_STATIONARY > 0)

	if action & LibSM64.ACT_FLAG_STATIONARY > 0:
		if Input.is_action_just_pressed("dpad_up"):
			_create_checkpoint()

	match action:
		LibSM64.ACT_SPAWN_SPIN_AIRBORNE:
			global_position = snapped(global_position, Vector3(0.5, 0, 0.5))
			#teleport(global_position)
			_velocity = _velocity * Vector3(0, 1, 0)
		LibSM64.ACT_GROUND_POUND:
			mario_collision.position.y = -0.5
			collision_cylinder.height = 2.0
			collision_cylinder.radius = 1.25

	if Input.is_action_just_pressed("dpad_down") and checkpoint_flag and is_instance_valid(checkpoint_flag):
		_restore_mario_to_checkpoint()

	if Time.get_ticks_msec() > gravity_set_time + 10000:
		gravity_add = 0

	if gravity_add != 0:
		velocity += Vector3(0, gravity_add * delta, 0)
		
	super(delta)

	_calculate_gameplay_camera(delta)
	var gameplay_camera_transform : Transform3D = camera.global_transform
	if false and time_since_start <= 1.0:
		var ratio : float = 1.0 - time_since_start
		ratio = ease(ratio, -2)
		camera.global_transform = camera.global_transform.interpolate_with(view_stage_transform, ratio)

	RenderingServer.global_shader_parameter_set("aspect_ratio", get_window().size.x / get_window().size.y)
	#DebugDraw2D.set_text("COIN COUNT", current_coin_count)
	coin_counter.text = "$*" + str(current_coin_count)
	health_wedges_disp.material.set_shader_parameter("wedges", health_wedges)
	if hide_hud and !hide_hud_old:
		level_timer.visible = false
		coin_counter.visible = false
		power_disp.visible = false

	if !hide_hud and hide_hud_old:
		level_timer.visible = true
		coin_counter.visible = true
		power_disp.visible = true

	hide_hud_old = hide_hud
	#DebugDraw3D.draw_sphere(position, 0.1, Color(1, 1, 1), delta)
	
	var mario_inputs := _make_mario_inputs()
	
	if Input.is_action_pressed("debug_restart"):
		if Input.is_action_pressed(mario_inputs_stick_left) or Input.is_action_pressed(mario_inputs_stick_right) or Input.is_action_pressed(mario_inputs_stick_up) or Input.is_action_pressed(mario_inputs_stick_down) or Input.is_action_pressed(mario_inputs_button_a) or Input.is_action_pressed(mario_inputs_button_b) or Input.is_action_pressed(mario_inputs_button_z):
			respawn_button_hold_time = 0.0
			respawn_timer.text = ""
		elif not (action & (LibSM64.ACT_FLAG_AIR)):
			respawn_button_hold_time += delta
			respawn_timer.text = "Keep holding to respawn... %.1f" % [HOLD_DURATION_TO_RESPAWN - respawn_button_hold_time]
			if respawn_button_hold_time > HOLD_DURATION_TO_RESPAWN:
				_restore_mario_to_checkpoint()
				respawn_button_hold_time = 0.0
	elif Input.is_action_just_released("debug_restart"):
		respawn_button_hold_time = 0.0
		respawn_timer.text = ""
		
func _get_power_star(in_star_id : String) -> void:
	finish_time = Time.get_ticks_msec()
	var time_in_seconds : float = float(finish_time - start_time) * 0.001
	action = LibSM64.ACT_FALL_AFTER_STAR_GRAB
	audio_stream_player.play()
	var saysound_playback : AudioStreamPlaybackPolyphonic = audio_stream_player.get_stream_playback()
	saysound_playback.play_stream(preload("res://mario/enter_painting.WAV"), 0, -8, 1.0)
	await get_tree().create_timer(0.5).timeout
	saysound_playback.play_stream(preload("res://mario/star_get_socks.ogg"), 0, 0, 1.0)
	#action = LibSM64.ACT_FALL_AFTER_STAR_GRAB
	set_angle(Quaternion.from_euler(camera.position - position).normalized())
	await get_tree().create_timer(1.2).timeout
	saysound_playback.play_stream(preload("res://mario/here_we_go.wav"), 0, 10, 1.0)

func _respawn_mario() -> void:
	for block:LevelBlock in SOGlobal.level_meshes:
		block._reset_block()
	await get_tree().create_timer(0.05).timeout
	needs_respawning = false
	position = Vector3(0, 6, 0)
	current_coin_count = 0
	var cant_spawn = true
	var iter : int = 0
	var spawn_random := RandomNumberGenerator.new()
	spawn_random.seed = hash("le spawn seed")
	var dist = 1.0
	teleport(position)
	time_since_start = 0
	num_checkpoints_used = 0
	_cam_target_height = position.y
	health_wedges = 8
	_velocity = Vector3.ZERO
	_cam_rotation_target = deg_to_rad(SOGlobal.start_angle)
	_cam_zoom = 1
	action = LibSM64.ACT_SPAWN_SPIN_AIRBORNE
	start_time = Time.get_ticks_msec()
	finish_time = -1.0
	if checkpoint_flag and is_instance_valid(checkpoint_flag):
		checkpoint_flag.queue_free()
	checkpoint_pos = position
	checkpoint_facing = face_angle
	SOGlobal.play_sound(preload("res://mario/enter_painting.WAV"))
	for child in SOGlobal.get_children():
		if child is PowerStar:
			child._respawn()
		if child is Coin:
			child._respawn()
		if child is CorkBox:
			child._reset()

func smin(a : float, b : float, k : float) -> float:
	var h : float = clampf(0.5 + 0.5*(a-b)/k, 0.0, 1.0);
	return lerp(a, b, h) - k*h*(1.0-h);

func _make_mario_inputs() -> LibSM64MarioInputs:
	var mario_inputs := super()

	var pl_input := PlayerInput.from_input()

	mario_inputs.stick = Vector2(pl_input.JoyXAxis, pl_input.JoyYAxis)
	if mario_inputs.stick.length() > 1.0:
		mario_inputs.stick = mario_inputs.stick.normalized()
	#DebugDraw2D.set_text("INPUT", mario_inputs.stick)

	if action == LibSM64.ACT_STAR_DANCE_NO_EXIT or action == LibSM64.ACT_FALL_AFTER_STAR_GRAB or action == LibSM64.ACT_STAR_DANCE_EXIT:
		mario_inputs.cam_look *= -1

	return mario_inputs

func _create_checkpoint() -> void:
	checkpoint_pos = global_position
	checkpoint_facing = face_angle
	if checkpoint_flag and is_instance_valid(checkpoint_flag):
		checkpoint_flag.queue_free()
	checkpoint_flag = preload("res://mario/checkpoint_flag.tscn").instantiate()
	checkpoint_flag.position = checkpoint_pos
	SOGlobal.add_child(checkpoint_flag)
	checkpoint_flag.get_node("AnimationPlayer").play("flag_spawn")
	SOGlobal.play_sound(preload("res://mario/sfx/sm64_drop_into_course.wav"))

func _restore_mario_to_checkpoint() -> void:
	num_checkpoints_used += 1
	teleport(checkpoint_pos)
	_cam_target_height = position.y
	set_angle(Quaternion.from_euler(Vector3.FORWARD.rotated(Vector3.UP, checkpoint_facing)))
	velocity = Vector3.ZERO
	_velocity = Vector3.ZERO
	forward_velocity = 0.0
	velocity = Vector3.ZERO
	face_angle = checkpoint_facing
	forward_velocity = 0.0
	SOGlobal.play_sound(preload("res://mario/sfx/sm64_spinning_heart.wav"))
	action = LibSM64.ACT_IDLE

var time_since_start : float = 0
var view_stage_transform : Transform3D

func _calculate_gameplay_camera(delta : float):
	if Input.is_action_just_pressed("cam_stick_left"):
		if SOGlobal.flip_x:
			_cam_rotation_target -= deg_to_rad(45)
		else:
			_cam_rotation_target += deg_to_rad(45)
	if Input.is_action_just_pressed("cam_stick_right"):
		if SOGlobal.flip_x:
			_cam_rotation_target += deg_to_rad(45)
		else:
			_cam_rotation_target -= deg_to_rad(45)

	if Input.is_action_just_pressed("cam_stick_down"):
		_cam_zoom += 1
	if Input.is_action_just_pressed("cam_stick_up"):
		_cam_zoom -= 1

	_cam_zoom = clampi(_cam_zoom, 0, 2)

	var target_height : float = 10
	var target_dist : float = 5
	var target_lookat : float = 1.4
	match _cam_zoom:
		0:
			target_height = 4
			target_dist = 10
			target_lookat = 1.6
		1:
			target_height = 6
			target_dist = 14
			target_lookat = 2.0
		2:
			target_height = 8
			target_dist = 18
			target_lookat = 2.6

	_cam_rotation = lerp(_cam_rotation, _cam_rotation_target, delta * 12)
	_cam_height = lerp(_cam_height, target_height, delta * 12)
	_cam_dist = lerp(_cam_dist, target_dist, delta * 12)
	camera.rotation = Vector3(0, _cam_rotation, 0)
	camera.fov = 45
	var height_diff : float = min(absf(_cam_target_height - position.y), 2)
	_cam_target_height = move_toward(_cam_target_height, position.y, delta * 6 * height_diff)
	var face_dir = Basis.IDENTITY.rotated(Vector3(0, 1, 0), _face_angle)
	var target_look = face_dir.x * -target_lookat + Vector3(0, 1, 0)
	var dist_to_target = (target_look - _cam_target).length() * 2
	_cam_target = _cam_target.move_toward(target_look, minf(dist_to_target, 0.5) * delta * 4)
	var look_to = Vector3(position.x, smin(_cam_target_height, position.y + 4, 1.5), position.z) + _cam_target

	#DebugDraw3D.draw_sphere(look_to, 0.1, Color(1, 0, 0), delta)
	#DebugDraw3D.draw_arrow_line(position + Vector3(0, 0.5, 0), position + Vector3(0, 0.5, 0) - face_dir.x, Color(0, 1, 0), 0.1, true, delta)

	var camera_basis = Basis.IDENTITY.rotated(Vector3(0, 1, 0), _cam_rotation)
	camera.position = Vector3(position.x, _cam_target_height, position.z) + camera_basis.z * _cam_dist + Vector3(0, _cam_height, 0)
	#camera.position = snapped(camera.position, Vector3(1.0 / 32.0, 1.0 / 32.0, 1.0 / 32.0))
	camera.look_at(look_to)
	var angle_snap : float = 360.0 / 65536.0
	camera.global_rotation_degrees = snapped(camera.global_rotation_degrees, Vector3(angle_snap, angle_snap, angle_snap))

func _update_power_disp_color() -> void:
	var hue : float = [0.0, 0.0, 0.05, 0.11, 0.18, 0.27, 0.37, 0.47, 0.57][clamp(health_wedges, 0, 8)]
	var base_saturation := 0.0 if health_wedges == 0 else 1.0
	var base_value := 0.4 if health_wedges == 0 else 1.0
	power_disp.material.set_shader_parameter("outlineColor",         Color.from_hsv(hue, base_saturation * 0.75, base_value))
	power_disp.material.set_shader_parameter("topGradientCheck1",    Color.from_hsv(hue, base_saturation * 0.8,  base_value * 0.75))
	power_disp.material.set_shader_parameter("bottomGradientCheck1", Color.from_hsv(hue, base_saturation * 0.8,  base_value * 0.5))
	power_disp.material.set_shader_parameter("topGradientCheck2",    Color.from_hsv(hue, base_saturation,        base_value * 0.5))
	power_disp.material.set_shader_parameter("bottomGradientCheck2", Color.from_hsv(hue, base_saturation,        base_value * 0.25))
