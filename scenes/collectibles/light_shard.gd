class_name LightShard
extends Area2D

## Small glowing collectible that contributes to level completion.
## Emits shard_collected signal via Events autoload when collected.

# Signals
signal collected

# Animation constants
const BOB_AMPLITUDE: float = 4.0
const BOB_FREQUENCY: float = 2.0
const COLLECT_DURATION: float = 0.3
const SPARKLE_INTERVAL: float = 0.5

# Colors
const SHARD_COLOR: Color = Color("#FFFFFF")
const GLOW_COLOR: Color = Color("#00FFFF")

# State tracking
var _is_collected: bool = false
var _time_elapsed: float = 0.0
var _initial_y: float = 0.0
var _sparkle_timer: float = 0.0

# Node references
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var glow_particles: GPUParticles2D = $GlowParticles


func _ready() -> void:
	# Store initial position for bob animation
	_initial_y = position.y
	
	# Add to collectibles group
	add_to_group("collectibles")
	add_to_group("light_shards")
	
	# Connect body_entered signal
	body_entered.connect(_on_body_entered)
	
	# Start idle animation if it exists
	if animation_player.has_animation("idle"):
		animation_player.play("idle")


func _process(delta: float) -> void:
	if _is_collected:
		return
	
	_time_elapsed += delta
	
	# Bob up and down
	position.y = _initial_y + sin(_time_elapsed * BOB_FREQUENCY * TAU) * BOB_AMPLITUDE
	
	# Sparkle timer for particle bursts
	_sparkle_timer += delta
	if _sparkle_timer >= SPARKLE_INTERVAL:
		_sparkle_timer = 0.0
		_emit_sparkle()


## Called when a body enters the collection area.
func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	
	# Only collect if player touches it
	if body.is_in_group("player"):
		_collect()


## Handles the collection sequence.
func _collect() -> void:
	_is_collected = true
	
	# Disable further collisions
	collision_shape.set_deferred("disabled", true)
	
	# Emit local signal
	collected.emit()
	
	# Emit global event - get current counts from level
	_emit_shard_collected_event()
	
	# Play collect sound
	if audio_player and audio_player.stream:
		audio_player.play()
	
	# Stop ambient particles
	if glow_particles:
		glow_particles.emitting = false
	
	# Play collection animation (scale up and fade out)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), COLLECT_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, COLLECT_DURATION).set_ease(Tween.EASE_IN)
	
	# Wait for animation to complete before cleanup
	await tween.finished
	
	# Wait for audio to finish if playing
	if audio_player and audio_player.playing:
		await audio_player.finished
	
	queue_free()


## Emits the shard_collected event with updated counts.
func _emit_shard_collected_event() -> void:
	var events := get_node_or_null("/root/Events")
	if events == null:
		push_warning("LightShard: Events autoload not found")
		return
	
	# Count shards in current scene
	var all_shards := get_tree().get_nodes_in_group("light_shards")
	var collected_count: int = 0
	var total_count: int = all_shards.size()
	
	for shard in all_shards:
		if shard is LightShard and shard._is_collected:
			collected_count += 1
	
	events.shard_collected.emit(collected_count, total_count)


## Emits a sparkle particle effect.
func _emit_sparkle() -> void:
	if glow_particles and glow_particles.emitting:
		# Particles are continuous, just let them emit
		pass
