extends Node
## Global signal bus for decoupled communication across the game.
## Register as autoload "Events" in Project Settings > Autoload.

# Player events
signal player_died
signal player_respawned

# Collectible events
signal shard_collected(count: int, total: int)
signal crystal_collected(crystal_id: String)

# Level events
signal level_completed(level_name: String)
signal checkpoint_reached(position: Vector2)

# Game state events
signal game_paused(is_paused: bool)

# Screen shake events - used by objects to request camera shake
signal screen_shake_requested(intensity: float, duration: float)
