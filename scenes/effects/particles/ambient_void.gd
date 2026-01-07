class_name AmbientVoid
extends GPUParticles2D

## Floating ambient particles for void background atmosphere.
## Creates a subtle, ethereal effect with slowly drifting particles.
## Place in ParallaxBackground or as a child of levels for ambiance.

## The area size for particle emission (width x height).
@export var emission_area: Vector2 = Vector2(1920, 1080)

## Whether particles should emit continuously.
@export var auto_start: bool = true


func _ready() -> void:
	# Update emission box to match desired area
	_configure_emission_area()
	
	if auto_start:
		emitting = true


## Configure the emission shape to cover the specified area.
func _configure_emission_area() -> void:
	var material := process_material as ParticleProcessMaterial
	if material:
		# Set emission box extents (half-size in each direction)
		material.emission_box_extents = Vector3(emission_area.x / 2.0, emission_area.y / 2.0, 0.0)


## Starts the ambient particle effect.
func start() -> void:
	emitting = true


## Stops the ambient particle effect.
func stop() -> void:
	emitting = false


## Sets the emission area and reconfigures the material.
func set_emission_area(new_area: Vector2) -> void:
	emission_area = new_area
	_configure_emission_area()
