class_name Projectile
extends Area2D
## Magic orb. Flies straight, damages the first target in `target_group`,
## disappears when it hits a wall/tree (any physics body on its mask) or after `life` seconds.

var velocity := Vector2.ZERO
var damage := 1
var target_group := "player"
var life := 2.5
var _texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D


func setup(pos: Vector2, dir: Vector2, dmg: int, group: String, tex: Texture2D, speed := 110.0) -> void:
	position = pos
	velocity = dir.normalized() * speed
	damage = dmg
	target_group = group
	_texture = tex


func _ready() -> void:
	if _texture:
		sprite.texture = _texture
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	sprite.rotation += 12.0 * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	for t in get_tree().get_nodes_in_group(target_group):
		if t.has_method("is_alive") and not t.is_alive():
			continue
		if global_position.distance_to(t.global_position + Vector2(0, -8)) < 8.0:
			t.take_damage(damage, velocity)
			queue_free()
			return


func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		queue_free()
