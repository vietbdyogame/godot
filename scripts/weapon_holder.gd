class_name WeaponHolder
extends Node2D
## Holds a weapon sprite in a character's hand and plays the attack motion.
## The sprite is drawn "blade up" from this node's origin (the grip).

@export var weapon_id := "wood_sword"
@export var weapon_scale := 0.5
@export var hand_offset := Vector2(5, -7)

var data: Dictionary = {}
var busy := false
var _side := 1.0
var _tween: Tween

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	set_weapon(weapon_id)


func set_weapon(id: String) -> void:
	weapon_id = id
	data = Weapons.LIST[id]
	sprite.texture = Weapons.texture(id)
	sprite.scale = Vector2.ONE * weapon_scale
	sprite.offset = Vector2(0, -sprite.texture.get_height() * 0.5 + 3)
	_rest()


## side = 1 facing right, -1 facing left
func face(side: float) -> void:
	_side = side
	if not busy:
		_rest()


func _rest() -> void:
	position = Vector2(hand_offset.x * _side, hand_offset.y)
	rotation = deg_to_rad(25.0) * _side
	sprite.position = Vector2.ZERO
	sprite.flip_h = _side < 0.0


## Plays the attack animation toward dir. Returns its duration.
func strike(dir: Vector2) -> float:
	if busy or data.is_empty():
		return 0.0
	busy = true
	if _tween:
		_tween.kill()
	var base := dir.angle() + PI * 0.5
	position = Vector2(0, -8)
	sprite.flip_h = false
	_tween = create_tween()
	var dur := 0.16
	match data.style:
		"thrust":
			rotation = base
			_tween.tween_property(sprite, "position", Vector2(0, -9), dur * 0.45).set_ease(Tween.EASE_OUT)
			_tween.tween_property(sprite, "position", Vector2.ZERO, dur * 0.8)
		"cast":
			rotation = base - 0.5
			_tween.tween_property(self, "rotation", base + 0.2, dur).set_trans(Tween.TRANS_BACK)
			_tween.tween_interval(0.12)
		_:
			var half := deg_to_rad(data.arc) * 0.5
			var s := -1.0 if _side < 0.0 else 1.0
			rotation = base - half * s
			_tween.tween_property(self, "rotation", base + half * s, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween.tween_interval(0.08)
	_tween.tween_callback(_finish)
	return dur


func _finish() -> void:
	busy = false
	_rest()
