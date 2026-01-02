class_name SM64StaticSurfaceHandler
extends Node

## Node that handles adding MeshInstance3D nodes as Static Surfaces for libsm64.

## Group name that contains the MeshInstance3D that are part of the scene's static surfaces
@export var static_surfaces_group := &"libsm64_static_surfaces"

var _default_surface_properties := SM64SurfaceProperties.new()


## Load all MeshInstance3D in static_surfaces_group into SM64
func load_static_surfaces() -> void:
	var faces := PackedVector3Array()
	var surface_properties_array: Array[SM64SurfaceProperties] = []

	for node in get_tree().get_nodes_in_group(static_surfaces_group):
		var mesh_instance := node as MeshInstance3D
		if not mesh_instance:
			push_warning("Non MeshInstance3D in %s group" % static_surfaces_group)
			continue

		var mesh_faces := mesh_instance.get_mesh().get_faces()
		for i in range(mesh_faces.size()):
			mesh_faces[i] = mesh_instance.global_transform * mesh_faces[i]
		faces.append_array(mesh_faces)

		var surface_properties := _find_surface_properties(mesh_instance)
		var array: Array[SM64SurfaceProperties] = []
		array.resize(mesh_faces.size() / 3)
		
		# TODO: fix this properly in libsm64-godot instead of using this awful workaround
		const shitty_hacky_surface_type_lut: Array[int] = [0, 1, 4, 5, 9, 10, 11, 13, 14, 18, 19, 20, 21, 22, 26, 27, 28, 29, 30, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46, 47, 48, 50, 51, 52, 53, 54, 55, 56, 101, 102, 104, 105, 110, 111, 112, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 255]
		surface_properties.surface_type = min(shitty_hacky_surface_type_lut[surface_properties.surface_type], shitty_hacky_surface_type_lut.size() - 1)
		
		array.fill(surface_properties)
		surface_properties_array.append_array(array)

	SM64Surfaces.static_surfaces_load(faces, surface_properties_array)


func _find_surface_properties(node: Node) -> SM64SurfaceProperties:
	for child in node.get_children():
		if child is SM64SurfacePropertiesComponent:
			return child.surface_properties

	return _default_surface_properties
