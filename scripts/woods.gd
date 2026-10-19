extends Node2D
## Level controller: bakes navigation, tracks kills, spawns enemy waves, restart on death.

const ENEMY_SCENES := {
	"skeleton": preload("res://scenes/enemies/skeleton.tscn"),
	"skeleton_rogue": preload("res://scenes/enemies/skeleton_rogue.tscn"),
	"skeleton_warrior": preload("res://scenes/enemies/skeleton_warrior.tscn"),
	"skeleton_mage": preload("res://scenes/enemies/skeleton_mage.tscn"),
	"orc": preload("res://scenes/enemies/orc.tscn"),
	"orc_rogue": preload("res://scenes/enemies/orc_rogue.tscn"),
	"orc_warrior": preload("res://scenes/enemies/orc_warrior.tscn"),
	"orc_shaman": preload("res://scenes/enemies/orc_shaman.tscn"),
}
## Where new waves enter the map (ends of the dirt path).
const SPAWN_POINTS := [Vector2(14, 220), Vector2(626, 142), Vector2(316, 14)]
const MAP_SIZE := Vector2(640, 384)

var wave := 0
var kills := 0
var _game_over := false
var _spawning := false

@onready var objects: Node2D = $Objects
@onready var nav: NavigationRegion2D = $NavigationRegion2D
@onready var hud = $HUD


func _ready() -> void:
	_bake_navigation()
	for e in get_tree().get_nodes_in_group("enemy"):
		e.killed.connect(_on_enemy_killed)
	var p := get_tree().get_first_node_in_group("player") as Player
	p.died.connect(_on_player_died)
	_update_info()


func _bake_navigation() -> void:
	objects.add_to_group("nav_source")
	$WorldCollision.add_to_group("nav_source")
	var poly := NavigationPolygon.new()
	poly.add_outline(PackedVector2Array([Vector2(2, 2), Vector2(MAP_SIZE.x - 2, 2), MAP_SIZE - Vector2(2, 2), Vector2(2, MAP_SIZE.y - 2)]))
	poly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
	poly.source_geometry_group_name = &"nav_source"
	poly.agent_radius = 5.0
	poly.cell_size = 0.5
	NavigationServer2D.map_set_cell_size(get_world_2d().navigation_map, 0.5)
	nav.navigation_polygon = poly
	nav.bake_navigation_polygon(false)


func _on_enemy_killed(_e: Enemy) -> void:
	kills += 1
	_update_info()
	if get_tree().get_nodes_in_group("enemy").is_empty() and not _game_over and not _spawning:
		_next_wave()


func _next_wave() -> void:
	_spawning = true
	wave += 1
	hud.show_message("Đợt %d đang tới..." % wave, 2.5)
	await get_tree().create_timer(3.0).timeout
	if _game_over:
		return
	var keys := ENEMY_SCENES.keys()
	for i in range(2 + wave):
		var e: Enemy = ENEMY_SCENES[keys.pick_random()].instantiate()
		e.position = SPAWN_POINTS.pick_random() + Vector2(randf_range(-12, 12), randf_range(-10, 10))
		e.aggressive = true
		objects.add_child(e)
		e.killed.connect(_on_enemy_killed)
	_spawning = false
	_update_info()


func _on_player_died() -> void:
	_game_over = true
	hud.show_message("Bạn đã gục!\nNhấn R để chơi lại")


func _unhandled_input(event: InputEvent) -> void:
	if _game_over and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _update_info() -> void:
	hud.set_info("Hạ gục: %d    Đợt: %d    Còn lại: %d" % [kills, wave, get_tree().get_nodes_in_group("enemy").size()])
