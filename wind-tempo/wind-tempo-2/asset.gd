# AssetLoader.gd
extends Node

# Dictionary to cache resources that are often re-used
var cached_tracks: Dictionary = {}

# --- Configurable Track Paths ---
const TRACK_PATHS: Dictionary = {
	"easy": "res://audio/track_easy.ogg",
	"normal": "res://audio/track_normal.ogg",
	"hard": "res://audio/track_hard.ogg"
}

# --- Loading Function ---
func get_track_stream(difficulty: String) -> AudioStream:
	var path = TRACK_PATHS.get(difficulty)
	if not path:
		push_error("Track path not defined for: " + difficulty)
		return null

	# Use caching: if resource is loaded, return it immediately
	if cached_tracks.has(path):
		return cached_tracks[path]

	# Load and cache the resource
	var stream = load(path)
	if stream:
		cached_tracks[path] = stream
		return stream
	else:
		push_error("Failed to load audio stream at path: " + path)
		return null
