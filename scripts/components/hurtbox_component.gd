class_name HurtboxComponent
extends Area2D

## Damage-receiving hurtbox component.
## Emits a signal when hit by a HitboxComponent.
## Attach as a child of any entity that can receive damage.

# Signals
signal hurt(hitbox: Area2D)

# Owner entity reference (set in _ready if not assigned)
var owner_entity: Node


func _ready() -> void:
	# Default owner to parent if not explicitly set
	if owner_entity == null:
		owner_entity = get_parent()


## Called by HitboxComponent when a hit is detected.
## Emits the hurt signal for the owning entity to handle.
func receive_hit(hitbox: Area2D) -> void:
	hurt.emit(hitbox)
