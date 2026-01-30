@tool
class_name LevelBlock extends MeshInstance3D

enum move_type {
	NONE,
	LINEAR_PINGPONG,
	ROTATE_CONTINUOUS,
	CHILD,
	KEYFRAMED
}

var block_material := preload("res://mario/block_material.tres") as ShaderMaterial

@export var is_block : bool = true:
	set(in_bool):
		is_block = in_bool
		block_changed.emit()
@export var block_size : Vector3 = Vector3.ZERO:
	set(in_size):
		block_size = in_size
		block_changed.emit()
@export var north_slope : float = 0.0:
	set(in_size):
		north_slope = in_size
		block_changed.emit()
@export var south_slope : float = 0.0:
	set(in_size):
		south_slope = in_size
		block_changed.emit()
@export var east_slope : float = 0.0:
	set(in_size):
		east_slope = in_size
		block_changed.emit()
@export var west_slope : float = 0.0:
	set(in_size):
		west_slope = in_size
		block_changed.emit()

@export var current_move_type : move_type = move_type.NONE
@export var movement_keyframes : Array[AnimKeyframe]
@export var start_position : Vector3 = Vector3.ZERO
@export var start_rotation_euler : Vector3 = Vector3.ZERO
var start_rotation : Basis = Basis.IDENTITY
@export var target_delta_position : Vector3 = Vector3.ZERO
@export var end_rotation_euler : Vector3 = Vector3.ZERO
var target_delta_rotation : Basis = Basis.IDENTITY
var temp_basis : Basis = Basis.IDENTITY
@export var continuous_rotation : Vector3 = Vector3.ZERO
@export var move_time : float = 3
@export var pause_time : float = 3
var forward_or_backward : int = 1
var cur_time : float = 0
var cur_frame : int = 0
var movement_parent : Node3D
var base_transform : Transform3D = Transform3D.IDENTITY
var additive_transform : Transform3D = Transform3D.IDENTITY

signal block_changed

func generate_block() -> void:
	if is_block == false:
		return
	var new_mesh : BoxMesh = BoxMesh.new()
	new_mesh.size = block_size
	var mesh_faces : PackedVector3Array = new_mesh.get_faces()
	var mesh_normals : PackedVector3Array = []
	mesh_normals.resize(mesh_faces.size())
	for i in range(mesh_faces.size()):
		if mesh_faces[i].y < 0:
			if mesh_faces[i].x > 0:
				mesh_faces[i] += Vector3(east_slope, 0, 0)
			else:
				mesh_faces[i] -= Vector3(west_slope, 0, 0)
			if mesh_faces[i].z > 0:
				mesh_faces[i] += Vector3(0, 0, north_slope)
			else:
				mesh_faces[i] -= Vector3(0, 0, south_slope)
	for i in range(mesh_faces.size()):
		match i % 3:
			0:
				var dir_one : Vector3 = (mesh_faces[i + 1] - mesh_faces[i])
				var dir_two : Vector3 = (mesh_faces[i + 2] - mesh_faces[i])
				mesh_normals[i] = -dir_one.cross(dir_two).normalized()
			1:
				var dir_one : Vector3 = (mesh_faces[i - 1] - mesh_faces[i])
				var dir_two : Vector3 = (mesh_faces[i + 1] - mesh_faces[i])
				mesh_normals[i] = dir_one.cross(dir_two).normalized()
			2:
				var dir_one : Vector3 = (mesh_faces[i - 1] - mesh_faces[i])
				var dir_two : Vector3 = (mesh_faces[i - 2] - mesh_faces[i])
				mesh_normals[i] = dir_one.cross(dir_two).normalized()
		#DebugDraw3D.draw_arrow_line(mesh_faces[i] + new_block.position, mesh_faces[i] + mesh_normals[i] + new_block.position, Color(1, 0, 0), 0.25, true, 10)
	var arr_mesh : ArrayMesh = ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = mesh_faces
	arrays[Mesh.ARRAY_NORMAL] = mesh_normals
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = arr_mesh
	material_override = block_material
	#if in_parent != SOGlobal:
		#new_block.movement_parent = in_parent
	#new_block.current_move_type = move_mode
	#add_child(new_block)
	var surface_properties := LibSM64SurfacePropertiesComponent.new()
	surface_properties.surface_properties = LibSM64SurfaceProperties.new()
	surface_properties.surface_properties.surface_type = LibSM64.SURFACE_DEFAULT
	add_child(surface_properties)
	var calced_start_pos := Vector3(wrapf(block_size.x * 0.5, 0, 1), wrapf(block_size.y * 0.5, 0, 1), wrapf(block_size.z * 0.5, 0, 1))
	print(calced_start_pos)
	set_instance_shader_parameter("spawn_pos", calced_start_pos)
	#var new_collider := StaticBody3D.new()
	#var new_collider_shape := CollisionShape3D.new()
	#var new_box_shape := arr_mesh.create_convex_shape(true, false)
	#new_collider_shape.shape = new_box_shape
	#new_collider.set_collision_layer_value(1, true)
	#new_collider.set_collision_mask_value(1, true)
	#
	#new_block.add_child(new_collider)
	#new_collider.add_child(new_collider_shape)
	#return new_block

#func add_keyframe(in_pos : Vector3, in_rot : Quaternion, in_time : float) -> void:
	#var new_keyframe : AnimKeyframe = AnimKeyframe.new()
	#new_keyframe.position = in_pos
	#new_keyframe.rotation = in_rot
	#new_keyframe.time = in_time
	#movement_keyframes.append(new_keyframe)
	#movement_keyframes.sort_custom(func(a, b): return a.time < b.time)
#
#func add_keyframe_euler(in_pos : Vector3, in_rot : Vector3, in_time : float) -> void:
	#var new_keyframe : AnimKeyframe = AnimKeyframe.new()
	#new_keyframe.position = in_pos
	#new_keyframe.rotation_euler = in_rot
	#new_keyframe.time = in_time
	#movement_keyframes.append(new_keyframe)
	#movement_keyframes.sort_custom(func(a, b): return a.time < b.time)

func _update_transform():
	base_transform = Transform3D(basis.orthonormalized(), position)
	if movement_parent:
		base_transform = movement_parent.global_transform.inverse() * base_transform
		additive_transform = movement_parent.global_transform
	temp_basis = base_transform.basis
	_change_block_move_mode(current_move_type)

func _ready():
	_update_transform()
	calculate_transforms()
	cur_time = 0
	forward_or_backward = 1
	block_changed.connect(generate_block)

func _reset_block() -> void:
	transform = Transform3D(start_rotation, start_position)
	_ready()

func _change_block_move_mode(in_type : move_type) -> void:
	current_move_type = in_type
	remove_from_group("libsm64_static_surfaces")
	remove_from_group("libsm64_surface_objects")
	match in_type:
		move_type.NONE:
			add_to_group("libsm64_static_surfaces")
		move_type.LINEAR_PINGPONG:
			add_to_group("libsm64_surface_objects")
		move_type.ROTATE_CONTINUOUS:
			add_to_group("libsm64_surface_objects")
		move_type.KEYFRAMED:
			add_to_group("libsm64_surface_objects")
		move_type.CHILD:
			add_to_group("libsm64_surface_objects")
	

func calculate_transforms() -> void:
	start_rotation = Basis.from_euler(start_rotation_euler * deg_to_rad(1.0))
	var desired_end_rotation := Basis.from_euler(end_rotation_euler * deg_to_rad(1.0))
	target_delta_rotation = desired_end_rotation * start_rotation.inverse()

func _physics_process(delta : float):
	if Engine.is_editor_hint() == false and SOGlobal.current_mario._paused:
		return
	if Engine.is_editor_hint():
		calculate_transforms()
	if movement_parent:
		additive_transform = movement_parent.global_transform
	var move_duration : float = move_time + pause_time
	cur_time += delta * forward_or_backward
	if cur_time >= move_duration:
		match current_move_type:
			move_type.ROTATE_CONTINUOUS:
				cur_time = cur_time - move_duration
				temp_basis = base_transform.basis
			move_type.KEYFRAMED:
				cur_time = fmod(cur_time, movement_keyframes[movement_keyframes.size()].time)
	if cur_time >= move_duration or cur_time <= 0:
		match current_move_type:
			move_type.LINEAR_PINGPONG:
				forward_or_backward *= -1
				cur_time = clampf(cur_time, 0, move_duration)
	
	match current_move_type:
		move_type.NONE:
			return
		move_type.LINEAR_PINGPONG:
			var ratio : float
			ratio = minf(1.0, cur_time / move_time) if forward_or_backward == 1 else maxf(0.0, (cur_time - pause_time) / move_time)
			base_transform.origin = start_position.lerp(start_position + target_delta_position, ratio)
			base_transform.basis = start_rotation.slerp(target_delta_rotation * start_rotation, ratio)
		move_type.ROTATE_CONTINUOUS:
			base_transform.basis = base_transform.basis.rotated(continuous_rotation.normalized(), deg_to_rad(continuous_rotation.length()) * delta)
			base_transform.basis = base_transform.basis.orthonormalized()
			base_transform.origin = start_position
		move_type.KEYFRAMED:
			if cur_time > movement_keyframes[cur_frame].time:
				cur_frame = (cur_frame + 1) % movement_keyframes.size() - 1
			var current_keyframe : AnimKeyframe = movement_keyframes[cur_frame]
			var next_keyframe : AnimKeyframe
			if cur_frame + 1 < movement_keyframes.size():
				next_keyframe = movement_keyframes[cur_frame + 1]
			else:
				next_keyframe = movement_keyframes[0]
			var keyframe_ratio = (cur_time - current_keyframe.time) / (next_keyframe.time - current_keyframe.time)
			base_transform.origin = current_keyframe.position.lerp(next_keyframe.position, keyframe_ratio)
			base_transform.basis = current_keyframe.rotation.slerp(next_keyframe.rotation, keyframe_ratio)
	base_transform.basis = base_transform.basis.orthonormalized()
	#print(cur_time)
	#print(move_duration)
	global_transform = additive_transform * base_transform
