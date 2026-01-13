extends Node3D

@onready var sm_64_mario := $Mario
@onready var sm_64_static_surface_handler: LibSM64StaticSurfacesHandler = $SM64StaticSurfaceHandler
@onready var sm_64_surface_objects_handler: LibSM64SurfaceObjectsHandler = $SM64SurfaceObjectsHandler
@onready var world_environment := $WorldEnvironment as WorldEnvironment

func _process(delta):
	SOGlobal.block_material.set_shader_parameter("outer_time", float(Time.get_ticks_msec()) * 0.001)

var _is_libsm64_init := false

func _create_mario_world(useSeed = str(randi())) -> void:

	SOGlobal.current_seed = useSeed

	LibSM64.scale_factor = 110.0

	SOGlobal.total_coins = 0

	if _is_libsm64_init:
		LibSM64Global.terminate()

	_is_libsm64_init = LibSM64Global.init()
	
	sm_64_static_surface_handler.load_static_surfaces()
	sm_64_surface_objects_handler.load_all_surface_objects()
	
	sm_64_mario.create()
	SOGlobal.level_start_time = Time.get_ticks_msec()
	
	if ProjectSettings.get_setting("display/window/size/transparent") == true:
		world_environment.environment.sky.sky_material = null
		return

func _ready() -> void:
	LibSM64Global.load_rom_file(OS.get_executable_path().get_base_dir() + "/SM64.z64")
	_create_mario_world()
	SOGlobal.current_level_manager = self


func _on_tree_exiting() -> void:
	sm_64_mario.delete()
	LibSM64Global.terminate()
