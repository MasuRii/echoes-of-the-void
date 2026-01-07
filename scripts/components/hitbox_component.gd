class_name HitboxComponent
extends Area2D

## Damage-dealing hitbox component.
## Detects collisions with HurtboxComponent and triggers damage.
## Attach as a child of any entity that should deal damage on contact.

# Signals
signal hit_landed(hurtbox: Area2D)

# Exported properties
@export var damage: int = 1

# Owner entity reference (set in _ready if not assigned)
var owner_entity: Node


func _ready() -> void:
	# Default owner to parent if not explicitly set
	if owner_entity == null:
		owner_entity = get_parent()
	
	# Connect to area_entered signal
	area_entered.connect(_on_area_entered)


## Called when this hitbox overlaps with another area.
## Checks if the area is a HurtboxComponent and triggers damage.
func _on_area_entered(area: Area2D) -> void:
	# Check if the area is a HurtboxComponent
	if area is HurtboxComponent:
		var hurtbox := area as HurtboxComponent
		
		# Don't damage self (entities shouldn't hurt themselves)
		if hurtbox.owner_entity != owner_entity:
			hurtbox.receive_hit(self)
			hit_landed.emit(hurtbox)
