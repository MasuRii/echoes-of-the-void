extends CanvasLayer
## In-game HUD for Echoes of the Void.
## Displays shard counter and crystal indicators.
## Positioned in corners with minimal intrusion, fades on inactivity.

# Constants
const FADE_DELAY: float = 3.0
const FADE_DURATION: float = 0.5
const IDLE_ALPHA: float = 0.4
const ACTIVE_ALPHA: float = 1.0

# Node references
@onready var hud_container: MarginContainer = $MarginContainer
@onready var shard_container: HBoxContainer = $MarginContainer/VBoxContainer/ShardContainer
@onready var shard_icon: TextureRect = $MarginContainer/VBoxContainer/ShardContainer/ShardIcon
@onready var shard_label: Label = $MarginContainer/VBoxContainer/ShardContainer/ShardLabel
@onready var crystal_container: HBoxContainer = $MarginContainer/VBoxContainer/CrystalContainer
@onready var crystal_slots: Array[TextureRect] = []

# State tracking
var _fade_timer: float = 0.0
var _is_fading: bool = false
var _current_shards: int = 0
var _total_shards: int = 0
var _collected_crystals: int = 0
var _total_crystals: int = 3

# Cached autoload references
var _events: Node = null
var _game_manager: Node = null


func _ready() -> void:
	# Get autoload references
	_events = get_node_or_null("/root/Events")
	_game_manager = get_node_or_null("/root/GameManager")
	
	# Connect to Events signals
	_connect_events()
	
	# Initialize crystal slots array
	_setup_crystal_slots()
	
	# Initialize display
	_update_shard_display()
	_update_crystal_display()
	
	# Start fully visible
	if hud_container:
		hud_container.modulate.a = ACTIVE_ALPHA
	_fade_timer = FADE_DELAY


func _process(delta: float) -> void:
	# Handle fade to idle state
	if _fade_timer > 0:
		_fade_timer -= delta
		if _fade_timer <= 0 and not _is_fading:
			_start_fade_out()


func _connect_events() -> void:
	"""Connect to global Events signals."""
	if _events == null:
		push_warning("HUD: Events autoload not found")
		return
	
	_events.shard_collected.connect(_on_shard_collected)
	_events.crystal_collected.connect(_on_crystal_collected)
	_events.player_respawned.connect(_on_player_respawned)


func _setup_crystal_slots() -> void:
	"""Initialize the crystal slots array from child nodes."""
	crystal_slots.clear()
	for i in range(1, 4):  # Crystal1, Crystal2, Crystal3
		var slot := crystal_container.get_node_or_null("Crystal%d" % i) as TextureRect
		if slot:
			crystal_slots.append(slot)


func _on_shard_collected(count: int, total: int) -> void:
	"""Handle shard collection event."""
	_current_shards = count
	_total_shards = total
	_update_shard_display()
	_show_hud()


func _on_crystal_collected(_crystal_id: String) -> void:
	"""Handle crystal collection event."""
	_collected_crystals += 1
	_update_crystal_display()
	_show_hud()


func _on_player_respawned() -> void:
	"""Show HUD when player respawns."""
	_show_hud()


func _update_shard_display() -> void:
	"""Update the shard counter text."""
	if shard_label:
		shard_label.text = "%d / %d" % [_current_shards, _total_shards]


func _update_crystal_display() -> void:
	"""Update the crystal indicator slots."""
	for i in range(crystal_slots.size()):
		var slot := crystal_slots[i]
		if slot:
			if i < _collected_crystals:
				# Collected - full brightness cyan
				slot.modulate = Color(0.0, 1.0, 1.0, 1.0)
			else:
				# Not collected - dim gray
				slot.modulate = Color(0.3, 0.3, 0.3, 0.5)


func _show_hud() -> void:
	"""Make HUD fully visible and reset fade timer."""
	_fade_timer = FADE_DELAY
	_is_fading = false
	
	# Cancel any existing fade and show immediately
	if hud_container:
		var tween := create_tween()
		tween.tween_property(hud_container, "modulate:a", ACTIVE_ALPHA, 0.1)


func _start_fade_out() -> void:
	"""Begin fading HUD to idle transparency."""
	_is_fading = true
	if hud_container:
		var tween := create_tween()
		tween.tween_property(hud_container, "modulate:a", IDLE_ALPHA, FADE_DURATION)
		tween.tween_callback(func(): _is_fading = false)


## Set the total number of crystals for this level.
func set_crystal_count(count: int) -> void:
	_total_crystals = count
	# Could be used to show/hide crystal slots based on level


## Reset the HUD for a new level.
func reset() -> void:
	_current_shards = 0
	_total_shards = 0
	_collected_crystals = 0
	_update_shard_display()
	_update_crystal_display()
	_show_hud()


## Manually set shard counts (for level initialization).
func set_shard_counts(current: int, total: int) -> void:
	_current_shards = current
	_total_shards = total
	_update_shard_display()
