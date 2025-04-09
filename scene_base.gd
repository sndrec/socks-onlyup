extends Node3D

@onready var sm_64_mario := $Mario as SM64Mario
@onready var sm_64_static_surface_handler: Node = $SM64StaticSurfaceHandler
@onready var sm_64_surface_objects_handler: Node = $SM64SurfaceObjectsHandler
@onready var world_environment := $WorldEnvironment as WorldEnvironment

func _process(delta):
	SOGlobal.block_material.set_shader_parameter("outer_time", float(Time.get_ticks_msec()) * 0.001)

func _create_mario_world() -> void:
	
	SM64Global.rom_filepath = OS.get_executable_path().get_base_dir() + "/SM64.z64"
	
	SM64Global.scale_factor = 110.0
	
	SOGlobal.total_coins = 0
	
	if SM64Global.is_init():
		SM64Global.terminate()
	
	SM64Global.init()
	
	sm_64_static_surface_handler.load_static_surfaces()
	sm_64_surface_objects_handler.load_all_surface_objects()
	
	sm_64_mario.create()
	SOGlobal.level_start_time = Time.get_ticks_msec()
	sm_64_mario.preview_cam_yaw = 45
	sm_64_mario.preview_cam_pitch = -20
	sm_64_mario.preview_cam_zoom = 1
	sm_64_mario.preview_cam_pan_pitch = 0
	sm_64_mario.preview_cam_pan_yaw = 0
	
	if ProjectSettings.get_setting("display/window/size/transparent") == true:
		world_environment.environment.sky.sky_material = null
		return

func _ready() -> void:
	_create_mario_world()
	SOGlobal.current_level_manager = self


func _on_tree_exiting() -> void:
	sm_64_mario.delete()
	SM64Global.terminate()
