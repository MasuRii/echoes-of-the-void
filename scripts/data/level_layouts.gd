class_name LevelLayouts
extends RefCounted

## Level layout data definitions for procedural geometry generation.
## Each level defines platforms, walls, and one-way platforms that will be
## generated at runtime by the PlatformGenerator system.
##
## Coordinate System:
## - Positive X = right, Positive Y = down
## - Player spawn is near origin, levels progress right and/or upward (negative Y)
## - Platform positions are top-left corner of the platform
## - Wall positions are top of the wall

# =============================================================================
# LEVEL 01: AWAKENING (Tutorial)
# =============================================================================
# Design Goals:
# - Teach basic movement (run, jump)
# - Introduce Light Shards (5 easy ones)
# - First checkpoint
# - Simple gap jumps, no enemies
# - One hidden Echo Crystal (requires wall jump exploration)
# - Estimated length: 30-60 seconds
#
# Key Positions:
# - PlayerSpawn: (96, 192)
# - Exit: (2432, 192)
# - Shards: Y=144-176
# - Crystal: (768, -64) - requires wall jump
# - Checkpoint: (1152, 224)
# =============================================================================

const LEVEL_01_LAYOUT := {
	"platforms": [
		# Main ground - full width for tutorial simplicity
		{"pos": Vector2(0, 224), "size": Vector2(2560, 64)},
		
		# Elevated platform for Shard 3 (at position 896, 144)
		{"pos": Vector2(832, 112), "size": Vector2(128, 32)},
		
		# Crystal access platform at top of wall section
		{"pos": Vector2(704, -96), "size": Vector2(160, 32)},
		
		# Exit platform area (already part of main ground)
	],
	"walls": [
		# Wall jump section for crystal access - left wall
		{"pos": Vector2(672, -96), "height": 320, "side": "left"},
		# Wall jump section for crystal access - right wall
		{"pos": Vector2(864, -96), "height": 320, "side": "right"},
	],
	"one_way_platforms": [
		# Optional one-way platforms for variety
		{"pos": Vector2(480, 160), "width": 96},
		{"pos": Vector2(1600, 160), "width": 96},
	],
	"metadata": {
		"ground_y": 224,
		"spawn_check": true,
		"description": "Tutorial level - basic movement and jumping"
	}
}

# =============================================================================
# LEVEL 02: FRACTURED PATHS
# =============================================================================
# Design Goals:
# - Introduce wall jump
# - First enemy: Shadow Crawlers (3)
# - Crumbling platforms introduction
# - 6 Light Shards
# - Two Checkpoints
# - One Echo Crystal (wall jump challenge)
#
# Key Positions:
# - PlayerSpawn: (96, 320)
# - Exit: (3072, -192)
# - Shards distributed along vertical ascent
# - Crystal: (1408, -384) - difficult wall jump area
# - Checkpoints: (768, 352), (1984, -96)
# - ShadowCrawlers: (512, 320), (1856, -128), (2432, -256)
# =============================================================================

const LEVEL_02_LAYOUT := {
	"platforms": [
		# Starting ground section
		{"pos": Vector2(0, 352), "size": Vector2(640, 64)},
		
		# First climbing section platforms
		{"pos": Vector2(320, 288), "size": Vector2(160, 32)},
		{"pos": Vector2(560, 224), "size": Vector2(128, 32)},
		
		# Platform for Shard 2 and crawler 1 patrol
		{"pos": Vector2(384, 320), "size": Vector2(320, 32)},
		
		# Mid-level platforms ascending
		{"pos": Vector2(800, 160), "size": Vector2(192, 32)},
		{"pos": Vector2(960, 96), "size": Vector2(160, 32)},
		
		# Upper section platforms
		{"pos": Vector2(1200, 0), "size": Vector2(192, 32)},
		{"pos": Vector2(1440, -64), "size": Vector2(224, 32)},
		
		# Crystal challenge area platform
		{"pos": Vector2(1280, -416), "size": Vector2(256, 32)},
		
		# Continue upward section
		{"pos": Vector2(1696, -128), "size": Vector2(256, 32)},
		{"pos": Vector2(1920, -160), "size": Vector2(192, 32)},
		
		# Upper enemy patrol areas
		{"pos": Vector2(1760, -160), "size": Vector2(288, 32)},
		{"pos": Vector2(2112, -192), "size": Vector2(192, 32)},
		{"pos": Vector2(2336, -256), "size": Vector2(288, 32)},
		
		# Exit approach
		{"pos": Vector2(2688, -224), "size": Vector2(192, 32)},
		{"pos": Vector2(2944, -224), "size": Vector2(256, 64)},
	],
	"walls": [
		# Main wall jump shaft - left wall
		{"pos": Vector2(640, -64), "height": 448, "side": "left"},
		# Main wall jump shaft - right wall
		{"pos": Vector2(768, -64), "height": 448, "side": "right"},
		
		# Crystal challenge walls (narrower shaft)
		{"pos": Vector2(1248, -416), "height": 320, "side": "left"},
		{"pos": Vector2(1536, -416), "height": 320, "side": "right"},
		
		# Secondary wall jump section
		{"pos": Vector2(1984, -320), "height": 256, "side": "left"},
		{"pos": Vector2(2080, -320), "height": 256, "side": "right"},
	],
	"one_way_platforms": [
		# Various one-way platforms for vertical navigation
		{"pos": Vector2(688, 64), "width": 96},
		{"pos": Vector2(1120, -32), "width": 80},
		{"pos": Vector2(2016, -64), "width": 64},
	],
	"metadata": {
		"ground_y": 352,
		"spawn_check": true,
		"description": "Wall jumping introduction with vertical progression"
	}
}

# =============================================================================
# LEVEL 03: MIRROR'S EDGE
# =============================================================================
# Design Goals:
# - Introduce double jump
# - Mirror Guard enemy (2)
# - Moving platforms
# - Disappearing platforms (phase platforms)
# - 8 Light Shards
# - Two Echo Crystals
#
# Key Positions:
# - PlayerSpawn: (96, 320)
# - Exit: (3712, -480)
# - Wide gaps (160-256px) requiring double jump
# - Crystals: (1216, -320), (2880, -576)
# - MirrorGuards: (1024, 64), (2240, -256)
# =============================================================================

const LEVEL_03_LAYOUT := {
	"platforms": [
		# Starting ground section
		{"pos": Vector2(0, 352), "size": Vector2(512, 64)},
		
		# First section platforms - introducing gaps
		{"pos": Vector2(224, 288), "size": Vector2(160, 32)},
		{"pos": Vector2(480, 224), "size": Vector2(128, 32)},
		
		# Wide gap section (requires double jump)
		{"pos": Vector2(704, 160), "size": Vector2(160, 32)},
		{"pos": Vector2(960, 96), "size": Vector2(192, 32)}, # MirrorGuard 1 area
		
		# First crystal approach platforms
		{"pos": Vector2(1088, 32), "size": Vector2(160, 32)},
		{"pos": Vector2(1152, -352), "size": Vector2(192, 32)}, # Crystal 1 platform
		
		# Mid-level progression
		{"pos": Vector2(1408, -32), "size": Vector2(160, 32)},
		{"pos": Vector2(1600, -96), "size": Vector2(192, 32)},
		
		# Wider platform for moving platform anchor area
		{"pos": Vector2(1856, -160), "size": Vector2(256, 32)},
		
		# MirrorGuard 2 section
		{"pos": Vector2(2112, -224), "size": Vector2(256, 32)},
		{"pos": Vector2(2432, -288), "size": Vector2(192, 32)},
		
		# Second crystal area
		{"pos": Vector2(2816, -608), "size": Vector2(192, 32)}, # Crystal 2 platform
		
		# Final approach with phase platform gaps
		{"pos": Vector2(2752, -352), "size": Vector2(160, 32)},
		{"pos": Vector2(2944, -384), "size": Vector2(160, 32)},
		{"pos": Vector2(3136, -416), "size": Vector2(192, 32)},
		
		# Exit platform area
		{"pos": Vector2(3392, -448), "size": Vector2(192, 32)},
		{"pos": Vector2(3616, -512), "size": Vector2(256, 64)},
	],
	"walls": [
		# Crystal 1 access walls
		{"pos": Vector2(1120, -352), "height": 384, "side": "left"},
		{"pos": Vector2(1344, -352), "height": 384, "side": "right"},
		
		# Crystal 2 access walls
		{"pos": Vector2(2784, -608), "height": 320, "side": "left"},
		{"pos": Vector2(3008, -608), "height": 320, "side": "right"},
	],
	"one_way_platforms": [
		# Scattered one-way platforms for variety
		{"pos": Vector2(864, 128), "width": 96},
		{"pos": Vector2(1504, -64), "width": 80},
		{"pos": Vector2(2176, -256), "width": 96},
		{"pos": Vector2(3040, -416), "width": 96},
	],
	"metadata": {
		"ground_y": 352,
		"spawn_check": true,
		"description": "Double jump introduction with wide gaps and mirror enemies"
	}
}

# =============================================================================
# LEVEL 04: COLLAPSE
# =============================================================================
# Design Goals:
# - Challenge level - all mechanics combined
# - Pulse Orbs (4 with varied patterns)
# - Laser beam hazards (5)
# - Complex crumbling platform chains (7)
# - 12 Light Shards
# - Two Echo Crystals (difficult placement)
#
# Key Positions:
# - PlayerSpawn: (96, 320)
# - Exit: (4352, -896)
# - Crystals: (1920, -544), (3584, -1024)
# =============================================================================

const LEVEL_04_LAYOUT := {
	"platforms": [
		# Starting ground section
		{"pos": Vector2(0, 352), "size": Vector2(384, 64)},
		
		# First section - crumbling platform chain area
		{"pos": Vector2(224, 288), "size": Vector2(128, 32)},
		
		# Post-crumble landing platforms
		{"pos": Vector2(608, 192), "size": Vector2(160, 32)},
		{"pos": Vector2(768, 128), "size": Vector2(192, 32)},
		
		# Mid-ascent platforms with laser gauntlet zones
		{"pos": Vector2(896, 64), "size": Vector2(160, 32)},
		{"pos": Vector2(1056, 32), "size": Vector2(224, 32)}, # ShadowCrawler 1 area
		
		# Branching path section
		{"pos": Vector2(1200, -32), "size": Vector2(160, 32)},
		{"pos": Vector2(1408, -96), "size": Vector2(192, 32)},
		
		# Pulse Orb navigation corridors
		{"pos": Vector2(1568, -160), "size": Vector2(192, 32)},
		{"pos": Vector2(1728, -224), "size": Vector2(256, 32)},
		
		# First crystal challenge area
		{"pos": Vector2(1856, -576), "size": Vector2(192, 32)}, # Crystal 1 platform
		
		# Continue main path
		{"pos": Vector2(1984, -288), "size": Vector2(192, 32)},
		{"pos": Vector2(2176, -352), "size": Vector2(192, 32)},
		
		# Upper section with more hazards
		{"pos": Vector2(2400, -416), "size": Vector2(192, 32)},
		{"pos": Vector2(2624, -480), "size": Vector2(256, 32)}, # ShadowCrawler 2 area
		{"pos": Vector2(2912, -544), "size": Vector2(192, 32)},
		
		# Final ascent section
		{"pos": Vector2(3136, -608), "size": Vector2(192, 32)},
		{"pos": Vector2(3360, -672), "size": Vector2(224, 32)},
		
		# Second crystal challenge area
		{"pos": Vector2(3520, -1056), "size": Vector2(192, 32)}, # Crystal 2 platform
		
		# Crumble chain to exit
		{"pos": Vector2(3648, -736), "size": Vector2(192, 32)},
		{"pos": Vector2(3904, -800), "size": Vector2(192, 32)},
		
		# Exit platform area
		{"pos": Vector2(4128, -864), "size": Vector2(192, 32)},
		{"pos": Vector2(4256, -928), "size": Vector2(256, 64)},
	],
	"walls": [
		# Crystal 1 access walls
		{"pos": Vector2(1824, -576), "height": 352, "side": "left"},
		{"pos": Vector2(2048, -576), "height": 352, "side": "right"},
		
		# Crystal 2 access walls (extra challenging)
		{"pos": Vector2(3488, -1056), "height": 384, "side": "left"},
		{"pos": Vector2(3712, -1056), "height": 384, "side": "right"},
		
		# Additional wall jump sections
		{"pos": Vector2(2336, -544), "height": 256, "side": "left"},
		{"pos": Vector2(2464, -544), "height": 256, "side": "right"},
	],
	"one_way_platforms": [
		{"pos": Vector2(704, 160), "width": 96},
		{"pos": Vector2(1264, -64), "width": 80},
		{"pos": Vector2(1888, -256), "width": 96},
		{"pos": Vector2(2544, -448), "width": 80},
		{"pos": Vector2(3200, -640), "width": 96},
		{"pos": Vector2(3808, -768), "width": 96},
	],
	"metadata": {
		"ground_y": 352,
		"spawn_check": true,
		"description": "Challenge level with all mechanics combined"
	}
}

# =============================================================================
# LEVEL 05: THE LAST ECHO (Finale)
# =============================================================================
# Design Goals:
# - Final challenge - mastery test
# - All enemy types (4 ShadowCrawlers, 3 MirrorGuards, 6 PulseOrbs)
# - Complex platform combinations (10 Crumbling, 8 Moving, 9 Phase)
# - 15 Light Shards
# - 3 Echo Crystals at increasing difficulty
# - Climactic ending sequence
#
# Key Positions:
# - PlayerSpawn: (96, 320)
# - Exit: (4992, -1408) - Grand scale 5120x2400 play area
# - Crystals: (1344, -384), (3200, -1024), (4800, -1536)
# =============================================================================

const LEVEL_05_LAYOUT := {
	"platforms": [
		# Starting ground section
		{"pos": Vector2(0, 352), "size": Vector2(320, 64)},
		
		# First challenge section - callback to earlier levels
		{"pos": Vector2(192, 288), "size": Vector2(128, 32)},
		{"pos": Vector2(352, 256), "size": Vector2(128, 32)},
		
		# Early ascending platforms
		{"pos": Vector2(512, 224), "size": Vector2(192, 32)}, # ShadowCrawler 1 area
		{"pos": Vector2(736, 160), "size": Vector2(160, 32)},
		{"pos": Vector2(928, 96), "size": Vector2(192, 32)},
		
		# First major platform hub
		{"pos": Vector2(1056, 32), "size": Vector2(224, 32)},
		{"pos": Vector2(1248, -32), "size": Vector2(192, 32)}, # ShadowCrawler 2 area
		
		# Crystal 1 approach
		{"pos": Vector2(1280, -416), "size": Vector2(192, 32)}, # Crystal 1 platform
		
		# Mid-level platforms with MirrorGuard
		{"pos": Vector2(1440, -96), "size": Vector2(192, 32)},
		{"pos": Vector2(1632, -160), "size": Vector2(224, 32)},
		{"pos": Vector2(1792, -224), "size": Vector2(256, 32)}, # MirrorGuard 1 area
		
		# Continue vertical climb
		{"pos": Vector2(1984, -288), "size": Vector2(192, 32)},
		{"pos": Vector2(2176, -352), "size": Vector2(160, 32)},
		{"pos": Vector2(2336, -416), "size": Vector2(192, 32)},
		
		# Major mid-section hub
		{"pos": Vector2(2496, -480), "size": Vector2(256, 32)}, # ShadowCrawler 3 area
		{"pos": Vector2(2752, -544), "size": Vector2(192, 32)},
		
		# Upper section with hazard gauntlets
		{"pos": Vector2(2880, -608), "size": Vector2(192, 32)},
		{"pos": Vector2(3008, -672), "size": Vector2(192, 32)},
		
		# Crystal 2 area
		{"pos": Vector2(3136, -1056), "size": Vector2(192, 32)}, # Crystal 2 platform
		
		# MirrorGuard 2 section
		{"pos": Vector2(3136, -736), "size": Vector2(256, 32)}, # MirrorGuard 2 area
		{"pos": Vector2(3392, -800), "size": Vector2(192, 32)},
		
		# Final vertical climb begins
		{"pos": Vector2(3584, -864), "size": Vector2(224, 32)}, # ShadowCrawler 4 area
		{"pos": Vector2(3808, -928), "size": Vector2(192, 32)},
		{"pos": Vector2(4000, -992), "size": Vector2(192, 32)},
		
		# Final approach section
		{"pos": Vector2(4192, -1056), "size": Vector2(224, 32)},
		{"pos": Vector2(4416, -1120), "size": Vector2(256, 32)}, # MirrorGuard 3 area
		{"pos": Vector2(4640, -1184), "size": Vector2(192, 32)},
		
		# Crystal 3 (hardest) access area
		{"pos": Vector2(4736, -1568), "size": Vector2(192, 32)}, # Crystal 3 platform
		
		# Epic finale area - grand platform
		{"pos": Vector2(4832, -1280), "size": Vector2(192, 32)},
		
		# Final exit platform
		{"pos": Vector2(4896, -1440), "size": Vector2(256, 64)},
	],
	"walls": [
		# Crystal 1 access walls
		{"pos": Vector2(1248, -416), "height": 448, "side": "left"},
		{"pos": Vector2(1472, -416), "height": 448, "side": "right"},
		
		# Crystal 2 access walls (harder)
		{"pos": Vector2(3104, -1056), "height": 384, "side": "left"},
		{"pos": Vector2(3328, -1056), "height": 384, "side": "right"},
		
		# Crystal 3 access walls (hardest - true ending path)
		{"pos": Vector2(4704, -1568), "height": 384, "side": "left"},
		{"pos": Vector2(4928, -1568), "height": 384, "side": "right"},
		
		# Additional wall jump sections throughout
		{"pos": Vector2(1888, -384), "height": 256, "side": "left"},
		{"pos": Vector2(2016, -384), "height": 256, "side": "right"},
		
		{"pos": Vector2(2688, -672), "height": 288, "side": "left"},
		{"pos": Vector2(2816, -672), "height": 288, "side": "right"},
		
		{"pos": Vector2(3744, -1024), "height": 256, "side": "left"},
		{"pos": Vector2(3872, -1024), "height": 256, "side": "right"},
		
		{"pos": Vector2(4576, -1312), "height": 256, "side": "left"},
		{"pos": Vector2(4704, -1312), "height": 256, "side": "right"},
	],
	"one_way_platforms": [
		# Many one-way platforms for vertical navigation variety
		{"pos": Vector2(416, 192), "width": 96},
		{"pos": Vector2(848, 128), "width": 80},
		{"pos": Vector2(1184, 0), "width": 96},
		{"pos": Vector2(1536, -128), "width": 80},
		{"pos": Vector2(2048, -320), "width": 96},
		{"pos": Vector2(2432, -448), "width": 80},
		{"pos": Vector2(2816, -576), "width": 96},
		{"pos": Vector2(3264, -768), "width": 80},
		{"pos": Vector2(3520, -832), "width": 96},
		{"pos": Vector2(3936, -960), "width": 80},
		{"pos": Vector2(4320, -1088), "width": 96},
		{"pos": Vector2(4768, -1248), "width": 96},
	],
	"metadata": {
		"ground_y": 352,
		"spawn_check": true,
		"description": "Grand finale - mastery test with all mechanics and epic vertical climb"
	}
}

# =============================================================================
# LAYOUT REGISTRY
# =============================================================================
# Maps level layout keys to their data dictionaries for runtime lookup.

const LAYOUTS := {
	"LEVEL_01": LEVEL_01_LAYOUT,
	"LEVEL_02": LEVEL_02_LAYOUT,
	"LEVEL_03": LEVEL_03_LAYOUT,
	"LEVEL_04": LEVEL_04_LAYOUT,
	"LEVEL_05": LEVEL_05_LAYOUT,
}


## Gets the layout data for a given level key.
## Returns null if the key is not found.
static func get_layout(level_key: String) -> Variant:
	if level_key in LAYOUTS:
		return LAYOUTS[level_key]
	return null


## Gets all available level layout keys.
static func get_available_levels() -> Array[String]:
	return ["LEVEL_01", "LEVEL_02", "LEVEL_03", "LEVEL_04", "LEVEL_05"]


## Validates that a layout has all required fields.
static func validate_layout(layout: Dictionary) -> bool:
	var required_keys := ["platforms", "walls", "one_way_platforms", "metadata"]
	for key in required_keys:
		if key not in layout:
			push_warning("LevelLayouts: Missing required key '%s'" % key)
			return false
	return true
