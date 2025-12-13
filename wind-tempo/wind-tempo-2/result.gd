# ResultsData.gd
extends Node

# Final Game Stats
var final_score: int = 0
var max_combo: int = 0
var perfects: int = 0
var greats: int = 0
var oks: int = 0
var misses: int = 0

# Static function to create and populate the results object
# Returns the instantiated ResultsData object
static func compile_results() -> Node:
	# 1. Create a new instance of this Node
	var results_data = ResultsData.new() 
	
	# 2. Populate stats from the global Point Autoload
	if has_node("/root/Point"):
		# ASSUMPTION: Point.gd has been updated with these public variables
		results_data.final_score = Point.current_score
		results_data.max_combo = Point.max_combo_achieved 
		results_data.perfects = Point.perfects_count
		results_data.greats = Point.greats_count
		results_data.oks = Point.oks_count
		results_data.misses = Point.misses_count
		
	return results_data

# The GameStateManager will call this and then load the Results scene.
