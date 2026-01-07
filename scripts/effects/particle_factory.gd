class_name ParticleFactory
extends RefCounted

## Factory for creating particle effects programmatically.
## Provides methods to generate particle systems at runtime with fallbacks
## when .tscn scene files are missing or unavailable.


## Creates a burst particle effect (explosion-style).
## Returns a configured GPUParticles2D ready to add to the scene tree.
static func create_burst_particles(color: Color, count: int = 16) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.emitting = false
	particles.amount = count
	particles.lifetime = 0.6
	particles.one_shot = true
	particles.explosiveness = 1.0
	
	# Create process material for burst effect
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	material.emission_sphere_radius = 4.0
	material.direction = Vector3.ZERO
	material.spread = 180.0
	material.initial_velocity_min = 80.0
	material.initial_velocity_max = 160.0
	material.gravity = Vector3(0, 100, 0)
	material.scale_min = 2.0
	material.scale_max = 4.0
	material.color = color
	
	particles.process_material = material
	
	return particles


## Creates a trail particle effect (continuous emission).
## Returns a configured GPUParticles2D for trailing behind a moving object.
static func create_trail_particles(color: Color) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.emitting = false
	particles.amount = 12
	particles.lifetime = 0.4
	particles.one_shot = false
	particles.explosiveness = 0.0
	
	# Create process material for trail effect
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_POINT
	material.direction = Vector3(0, -1, 0)
	material.spread = 30.0
	material.initial_velocity_min = 20.0
	material.initial_velocity_max = 40.0
	material.gravity = Vector3(0, -20, 0)
	material.scale_min = 1.0
	material.scale_max = 2.0
	material.color = color
	
	# Add fade over lifetime
	var alpha_curve := Curve.new()
	alpha_curve.add_point(Vector2(0.0, 1.0))
	alpha_curve.add_point(Vector2(1.0, 0.0))
	
	var curve_texture := CurveTexture.new()
	curve_texture.curve = alpha_curve
	material.alpha_curve = curve_texture
	
	particles.process_material = material
	
	return particles


## Creates ambient floating particles for atmospheric effects.
## Returns a configured GPUParticles2D for background ambience.
static func create_ambient_particles() -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.emitting = false
	particles.amount = 32
	particles.lifetime = 4.0
	particles.one_shot = false
	particles.explosiveness = 0.0
	
	# Create process material for ambient floating effect
	var material := ParticleProcessMaterial.new()
	material.particle_flag_disable_z = true
	material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	material.emission_box_extents = Vector3(400, 300, 0)
	material.direction = Vector3(0, -1, 0)
	material.spread = 10.0
	material.initial_velocity_min = 5.0
	material.initial_velocity_max = 15.0
	material.gravity = Vector3.ZERO
	material.scale_min = 1.0
	material.scale_max = 2.0
	material.color = Color(1.0, 1.0, 1.0, 0.3)
	
	# Slow drift with fade
	var alpha_curve := Curve.new()
	alpha_curve.add_point(Vector2(0.0, 0.0))
	alpha_curve.add_point(Vector2(0.2, 0.8))
	alpha_curve.add_point(Vector2(0.8, 0.8))
	alpha_curve.add_point(Vector2(1.0, 0.0))
	
	var curve_texture := CurveTexture.new()
	curve_texture.curve = alpha_curve
	material.alpha_curve = curve_texture
	
	particles.process_material = material
	
	return particles


## Spawns a burst particle effect at the given position with auto-cleanup.
## Convenience method that handles adding to scene tree and starting emission.
static func spawn_burst_at(scene_tree: SceneTree, position: Vector2, color: Color, count: int = 16) -> GPUParticles2D:
	var particles := create_burst_particles(color, count)
	scene_tree.current_scene.add_child(particles)
	particles.global_position = position
	particles.emitting = true
	
	# Auto-cleanup after lifetime
	var timer := scene_tree.create_timer(particles.lifetime + 0.2)
	timer.timeout.connect(particles.queue_free)
	
	return particles


## Spawns trail particles attached to a parent node.
## The particles will follow the parent and can be stopped manually.
static func spawn_trail_on(parent: Node2D, color: Color) -> GPUParticles2D:
	var particles := create_trail_particles(color)
	parent.add_child(particles)
	particles.position = Vector2.ZERO
	particles.emitting = true
	
	return particles


## Spawns ambient particles covering a specified area.
## Useful for level background atmosphere.
static func spawn_ambient_in_area(parent: Node, area_size: Vector2) -> GPUParticles2D:
	var particles := create_ambient_particles()
	parent.add_child(particles)
	
	# Adjust emission box to cover the area
	var material: ParticleProcessMaterial = particles.process_material
	material.emission_box_extents = Vector3(area_size.x / 2.0, area_size.y / 2.0, 0)
	
	particles.emitting = true
	
	return particles


## Attempts to load a particle scene, falling back to programmatic generation if missing.
## Use this when you want to prefer .tscn files but have a fallback.
static func load_or_create_burst(scene_path: String, fallback_color: Color, fallback_count: int = 16) -> GPUParticles2D:
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			return scene.instantiate() as GPUParticles2D
	
	# Fallback to programmatic creation
	push_warning("ParticleFactory: Scene not found at '%s', using programmatic fallback" % scene_path)
	return create_burst_particles(fallback_color, fallback_count)


## Attempts to load a trail particle scene, falling back to programmatic generation if missing.
static func load_or_create_trail(scene_path: String, fallback_color: Color) -> GPUParticles2D:
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			return scene.instantiate() as GPUParticles2D
	
	push_warning("ParticleFactory: Scene not found at '%s', using programmatic fallback" % scene_path)
	return create_trail_particles(fallback_color)


## Attempts to load an ambient particle scene, falling back to programmatic generation if missing.
static func load_or_create_ambient(scene_path: String) -> GPUParticles2D:
	if ResourceLoader.exists(scene_path):
		var scene: PackedScene = load(scene_path)
		if scene:
			return scene.instantiate() as GPUParticles2D
	
	push_warning("ParticleFactory: Scene not found at '%s', using programmatic fallback" % scene_path)
	return create_ambient_particles()


## Predefined color constants for common particle effects.
const COLOR_DEATH := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_SHARD := Color(0.0, 1.0, 1.0, 1.0)  # Cyan
const COLOR_CRYSTAL := Color(0.5, 1.0, 1.0, 1.0)  # Light cyan
const COLOR_ENEMY := Color(0.5, 0.0, 0.5, 1.0)  # Purple
const COLOR_DUST := Color(0.7, 0.7, 0.7, 0.5)  # Gray
const COLOR_SPARK := Color(1.0, 0.9, 0.7, 1.0)  # Warm white
