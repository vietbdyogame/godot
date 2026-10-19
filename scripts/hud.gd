extends CanvasLayer
## HUD: hearts, current weapon, kill/wave counter and center messages.
## All nodes live in scenes/hud.tscn — move / restyle them freely in the editor.
## The script only finds them by their unique names (%Name), so keep those names.

const HEART_FULL := preload("res://art/ui/heart_full.png")
const HEART_HALF := preload("res://art/ui/heart_half.png")
const HEART_EMPTY := preload("res://art/ui/heart_empty.png")

@onready var hearts: HBoxContainer = %Hearts
@onready var weapon_label: Label = %WeaponLabel
@onready var info_label: Label = %InfoLabel
@onready var center_label: Label = %CenterLabel

var _heart_template: TextureRect


func _ready() -> void:
	center_label.text = ""
	if hearts.get_child_count() > 0:
		_heart_template = hearts.get_child(0) as TextureRect
	await get_tree().process_frame
	var p := get_tree().get_first_node_in_group("player") as Player
	if p:
		p.health_changed.connect(set_health)
		p.weapon_changed.connect(set_weapon)
		set_health(p.hp, p.max_hp)
		set_weapon(p.weapon.data.name)


func set_health(hp: int, max_hp: int) -> void:
	var count := ceili(max_hp / 2.0)
	# add/remove heart nodes so there is one per 2 HP (copies the first heart's look)
	while hearts.get_child_count() < count:
		var h: TextureRect = _heart_template.duplicate() if _heart_template else TextureRect.new()
		hearts.add_child(h)
	for i in range(hearts.get_child_count()):
		var t := hearts.get_child(i) as TextureRect
		t.visible = i < count
		var v := hp - i * 2
		t.texture = HEART_FULL if v >= 2 else (HEART_HALF if v == 1 else HEART_EMPTY)


func set_weapon(weapon_name: String) -> void:
	weapon_label.text = "Vũ khí: " + weapon_name


func set_info(text: String) -> void:
	info_label.text = text


func show_message(text: String, seconds := 0.0) -> void:
	center_label.text = text
	center_label.modulate.a = 1.0
	if seconds > 0.0:
		var t := create_tween()
		t.tween_interval(seconds)
		t.tween_property(center_label, "modulate:a", 0.0, 0.5)
