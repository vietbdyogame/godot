class_name Player
extends CharacterBody2D
## Top-down player.
## Move: arrows / WASD.  Attack: Space, J or left mouse (aims at the cursor).
## Switch weapon: Q / E, mouse wheel, or number keys 1-6.

signal health_changed(hp: int, max_hp: int)
signal weapon_changed(weapon_name: String)
signal died

const PROJECTILE := preload("res://scenes/projectile.tscn")
const ORB := preload("res://Pixel Crawler - Free Pack/Weapons/extracted/orb_purple.png")

@export var speed := 60.0
@export var max_hp := 10
@export var weapons: Array[String] = ["wood_sword", "wood_spear", "wood_mallet", "bone_scimitar", "bone_club", "bone_staff"]

var hp := 10
var dead := false
var facing := Vector2.RIGHT
var weapon_index := 0
var _cooldown := 0.0
var _invuln := 0.0
var _knock := Vector2.ZERO

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon: WeaponHolder = $Weapon


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	weapon.set_weapon(weapons[weapon_index])


func is_alive() -> bool:
	return not dead


func _physics_process(delta: float) -> void:
	_cooldown -= delta
	_invuln -= delta
	if dead:
		velocity = Vector2.ZERO
		return

	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		dir = Vector2(
			int(Input.is_physical_key_pressed(KEY_D)) - int(Input.is_physical_key_pressed(KEY_A)),
			int(Input.is_physical_key_pressed(KEY_S)) - int(Input.is_physical_key_pressed(KEY_W))
		).normalized()
	if dir != Vector2.ZERO:
		facing = dir

	velocity = dir * speed + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()

	if dir.x != 0.0:
		_set_side(dir.x)
	anim.play("run" if dir != Vector2.ZERO else "idle")
	# blink while invulnerable after a hit
	anim.visible = _invuln <= 0.0 or int(_invuln * 20.0) % 2 == 0


func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE, KEY_J:
				attack(facing)
			KEY_Q:
				select_weapon(weapon_index - 1)
			KEY_E:
				select_weapon(weapon_index + 1)
			_:
				var n: int = event.physical_keycode - KEY_1
				if n >= 0 and n < weapons.size():
					select_weapon(n)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				attack((get_global_mouse_position() - (global_position + Vector2(0, -8))).normalized())
			MOUSE_BUTTON_WHEEL_UP:
				select_weapon(weapon_index - 1)
			MOUSE_BUTTON_WHEEL_DOWN:
				select_weapon(weapon_index + 1)


func select_weapon(i: int) -> void:
	weapon_index = wrapi(i, 0, weapons.size())
	weapon.set_weapon(weapons[weapon_index])
	weapon.face(-1.0 if anim.flip_h else 1.0)
	weapon_changed.emit(weapon.data.name)


func attack(dir: Vector2) -> void:
	if _cooldown > 0.0 or weapon.busy or dir == Vector2.ZERO:
		return
	var d := weapon.data
	_cooldown = d.cooldown
	if absf(dir.x) > 0.1:
		_set_side(dir.x)
	weapon.strike(dir)
	var origin := global_position + Vector2(0, -8)
	if d.style == "cast":
		var p: Projectile = PROJECTILE.instantiate()
		p.setup(origin + dir * 8.0, dir, d.damage, "enemy", ORB, 130.0)
		get_parent().add_child(p)
		return
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.is_alive() and Weapons.hits(origin, dir, e.global_position + Vector2(0, -8), d.reach, d.arc):
			e.take_damage(d.damage, dir)


func take_damage(amount: int, from_dir: Vector2) -> void:
	if dead or _invuln > 0.0:
		return
	hp = maxi(hp - amount, 0)
	_invuln = 0.8
	_knock = from_dir.normalized() * 130.0
	health_changed.emit(hp, max_hp)
	if hp == 0:
		_die()


func heal(amount: int) -> void:
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


func _die() -> void:
	dead = true
	anim.visible = true
	weapon.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	anim.play("death")
	died.emit()


func _set_side(x: float) -> void:
	anim.flip_h = x < 0.0
	weapon.face(-1.0 if anim.flip_h else 1.0)
