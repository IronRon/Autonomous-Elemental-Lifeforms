extends CanvasLayer

@export var update_interval: float = 0.5

var _update_timer: float = 0.0
@onready var stats_label: Label = $StatsPanel/MarginContainer/StatsLabel


func _ready() -> void:
	_update_stats()


func _process(delta: float) -> void:
	_update_timer -= delta
	if _update_timer > 0.0:
		return
	_update_timer = update_interval
	_update_stats()


func _update_stats() -> void:
	if stats_label == null:
		return

	var element_counts = {
		"Fire": [0, 0, 0],
		"Wind": [0, 0, 0],
		"Water": [0, 0, 0],
		"Earth": [0, 0, 0],
		"Anti": [0, 0, 0]
	}
	var total_lifeforms = 0

	for lifeform in get_tree().get_nodes_in_group("lifeforms"):
		if lifeform == null or not is_instance_valid(lifeform):
			continue
		total_lifeforms += 1
		var element_type = lifeform.get("element_type")
		var lifeform_level = lifeform.get("level")
		var element_name = _element_name(int(element_type) if element_type != null else -1)
		var level_index = int(clamp((int(lifeform_level) if lifeform_level != null else 1) - 1, 0, 2))
		if element_counts.has(element_name):
			element_counts[element_name][level_index] += 1

	var manager = _get_simulation_manager()
	var deaths = int(manager.get("total_deaths")) if manager and manager.get("total_deaths") != null else 0
	var evolutions = int(manager.get("total_evolutions")) if manager and manager.get("total_evolutions") != null else 0
	var mana_orbs = get_tree().get_nodes_in_group("mana_orbs").size()

	var lines: Array[String] = []
	lines.append("SIMULATION")
	lines.append("Lifeforms: %d    Mana: %d" % [total_lifeforms, mana_orbs])
	lines.append("Deaths: %d       Evolutions: %d" % [deaths, evolutions])
	lines.append("")
	lines.append("          L1  L2  L3")
	for element_name in ["Fire", "Wind", "Water", "Earth", "Anti"]:
		var counts = element_counts[element_name]
		lines.append("%-6s   %2d  %2d  %2d" % [element_name, counts[0], counts[1], counts[2]])

	stats_label.text = "\n".join(lines)


func _get_simulation_manager() -> Node:
	var current_scene = get_tree().current_scene
	if current_scene:
		var manager = current_scene.get_node_or_null("SimulationManager")
		if manager:
			return manager
	return get_tree().get_first_node_in_group("simulation_manager")


func _element_name(element_type: int) -> String:
	match element_type:
		0:
			return "Fire"
		1:
			return "Wind"
		2:
			return "Water"
		3:
			return "Earth"
		4:
			return "Anti"
		_:
			return "Unknown"
