extends Node

"""
ObjectPool provides object pooling for efficient reuse of game objects.
Reduces garbage collection overhead by reusing instantiated objects.
"""

class PooledObject:
	var object: Node
	var is_active: bool = false
	
	func _init(obj: Node) -> void:
		object = obj

var pools: Dictionary = {}
var pool_sizes: Dictionary = {}

func _ready() -> void:
	pass

func create_pool(scene_path: String, pool_size: int = 20) -> void:
	"""Create an object pool for a scene."""
	if scene_path in pools:
		return
	
	var scene = load(scene_path)
	if not scene:
		push_error("Failed to load scene: %s" % scene_path)
		return
	
	var pool = []
	for i in range(pool_size):
		var obj = scene.instantiate()
		obj.visible = false
		add_child(obj)
		pool.append(PooledObject.new(obj))
	
	pools[scene_path] = pool
	pool_sizes[scene_path] = pool_size
	print("Created pool for %s with size %d" % [scene_path, pool_size])

func get_object(scene_path: String) -> Node:
	"""Get an object from the pool."""
	if scene_path not in pools:
		create_pool(scene_path)
	
	var pool = pools[scene_path]
	
	# Find inactive object
	for pooled in pool:
		if not pooled.is_active:
			pooled.is_active = true
			pooled.object.visible = true
			return pooled.object
	
	# If no inactive objects, create new one
	var scene = load(scene_path)
	var obj = scene.instantiate()
	add_child(obj)
	var pooled = PooledObject.new(obj)
	pooled.is_active = true
	pool.append(pooled)
	return obj

func return_object(scene_path: String, obj: Node) -> void:
	"""Return object to pool."""
	if scene_path not in pools:
		obj.queue_free()
		return
	
	var pool = pools[scene_path]
	for pooled in pool:
		if pooled.object == obj:
			pooled.is_active = false
			obj.visible = false
			break

func clear_pool(scene_path: String) -> void:
	"""Clear a pool."""
	if scene_path in pools:
		var pool = pools[scene_path]
		for pooled in pool:
			pooled.object.queue_free()
		pools.erase(scene_path)
		pool_sizes.erase(scene_path)

func clear_all_pools() -> void:
	"""Clear all pools."""
	for scene_path in pools.keys():
		clear_pool(scene_path)
