@tool
extends MeshInstance3D

@export var radius : float = 1 : set=set_radius
@export var thickness : float = 0.1 : set=set_thickness
@export var resolution : float = 0.25 : set=set_resolution

func set_radius(new_value : float):
	radius = new_value
	generate_mesh()

func set_thickness(new_value : float):
	thickness = new_value
	generate_mesh()
	
func set_resolution(new_value : float):
	resolution = new_value
	generate_mesh()

func _ready():
	generate_mesh()

func generate_mesh():
	if mesh == null:
		mesh = ArrayMesh.new()
		mesh.resource_name = "OrbitMesh"
	mesh.clear_surfaces()
	
	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	var verts : PackedVector3Array = PackedVector3Array()
	var uvs : PackedVector2Array = PackedVector2Array()
	var normals : PackedVector3Array = PackedVector3Array()
	var indices : PackedInt32Array = PackedInt32Array()

	var circumference : float = 2 * PI * radius
	var segments : float = ceil(circumference / resolution)
	var interval : float = 2 * PI / segments

	for i in range(segments):
		var normalized_position = Vector3(cos(i * interval), 0, sin(i * interval))
		var inside = normalized_position * (radius - thickness * 0.5)
		var outside = normalized_position * (radius + thickness * 0.5)
		verts.append(inside)
		uvs.append(Vector2(0, 0))
		normals.append(Vector3(0, 1, 0))
		verts.append(outside)
		uvs.append(Vector2(0, 1))
		normals.append(Vector3(0, 1, 0))
		if i < segments - 1:
			indices.append(verts.size() - 2) #this inside
			indices.append(verts.size() - 1) #this outside
			indices.append(verts.size())     #next inside
			
			indices.append(verts.size())     #next inside
			indices.append(verts.size() - 1) #this outside
			indices.append(verts.size() + 1) #next outside
		else:
			indices.append(verts.size() - 2) #this inside
			indices.append(verts.size() - 1) #this outside
			indices.append(0)                #next inside
			
			indices.append(0)                #next inside
			indices.append(verts.size() - 1) #this outside
			indices.append(1)                #next outside

	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	
	

