class_name Enemy
extends CharacterBody2D
## Enemy AI: idle / wander around its home, chase the player when close,
## melee attack (with a short wind-up) or keep distance and cast projectiles.

signal killed(enemy: Enemy)

const PROJECTILE := preload("res://scenes/projectile.tscn")

enum State { IDLE, WANDER, CHASE, ATTACK, RETURN, DEAD }

@export var display_name := "Enemy"
@export var max_hp := 3
@export var speed := 32.0
@export var damage := 1
@export var weapon_id := "bone_dagger"
@export var ranged := false
@export var projectile_texture: Texture2D
@export var detect_range := 90.0
@export var lose_range := 170.0
@export var preferred_distance := 70.0
@export var attack_cooldown := 1.2
@export var windup := 0.35
## true = always hunts the player (used for spawned waves / after being hit)
@export var aggressive := false

var state := State.IDLE
var hp := 3
var home := Vector2.ZERO
var player: Player
var _timer := 0.0
var _cooldown := 0.0
var _wander_target := Vector2.ZERO
var _knock := Vector2.ZERO
var _strafe := 1.0
var _last_nav_target := Vector2.INF

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var weapon: WeaponHolder = $Weapon
@onready var agent: NavigationAgent2D = $NavigationAgent2D


func _ready() -> void:
	add_to_group("enemy")
	hp = max_hp
	home = global_position
	weapon.set_weapon(weapon_id)
	_timer = randf_range(0.5, 2.5)
	_strafe = 1.0 if randf() < 0.5 else -1.0
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 4.0
	agent.radius = 6.0


func is_alive() -> bool:
	return state != State.DEAD


func _attack_range() -> float:
	return maxf(12.0, weapon.data.reach * 0.85)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_cooldown -= delta
	_timer -= delta
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player

	var player_ok := player != null and player.is_alive()
	var dist := INF
	var to_player := Vector2.ZERO
	if player_ok:
		to_player = player.global_position - global_position
		dist = to_player.length()

	var move := Vector2.ZERO
	match state:
		State.IDLE:
			if _timer <= 0.0:
				_wander_target = home + Vector2(randf_range(-40, 40), randf_range(-30, 30))
				state = State.WANDER
				_timer = 3.0
		State.WANDER:
			move = _steer_to(_wander_target) * 0.5
			if global_position.distance_to(_wander_target) < 5.0 or _timer <= 0.0:
				state = State.IDLE
				_timer = randf_range(1.0, 3.0)
		State.RETURN:
			move = _steer_to(home) * 0.7
			if global_position.distance_to(home) < 6.0:
				state = State.IDLE
		State.CHASE:
			if not player_ok or (dist > lose_range and not aggressive):
				state = State.RETURN
			elif ranged:
				move = _ranged_move(to_player, dist)
				if _cooldown <= 0.0 and dist < preferred_distance + 50.0:
					_cast()
			elif dist <= _attack_range():
				if _cooldown <= 0.0:
					_melee()
			else:
				move = _steer_to(player.global_position)
		State.ATTACK:
			pass

	if state in [State.IDLE, State.WANDER, State.RETURN] and player_ok and (dist < detect_range or aggressive):
		state = State.CHASE

	velocity = move * speed + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 350.0 * delta)
	move_and_slide()

	var look_x := velocity.x
	if player_ok and state in [State.CHASE, State.ATTACK]:
		look_x = to_player.x
	if absf(look_x) > 0.5:
		anim.flip_h = look_x < 0.0
		weapon.face(-1.0 if anim.flip_h else 1.0)
	anim.play("run" if velocity.length() > 4.0 else "idle")
	queue_redraw()


func _steer_to(target: Vector2) -> Vector2:
	if _last_nav_target.distance_to(target) > 6.0:
		agent.target_position = target
		_last_nav_target = target
	var next := agent.get_next_path_position()
	var d := next - global_position
	if agent.is_navigation_finished() or d.length() < 0.5:
		d = target - global_position
	return d.normalized() if d.length() > 1.0 else Vector2.ZERO


func _ranged_move(to_player: Vector2, dist: float) -> Vector2:
	if dist < preferred_distance - 18.0:
		return -to_player.normalized()
	if dist > preferred_distance + 18.0:
		return _steer_to(player.global_position)
	if get_slide_collision_count() > 0:
		_strafe = -_strafe
	return to_player.normalized().orthogonal() * _strafe * 0.5


func _melee() -> void:
	state = State.ATTACK
	_cooldown = attack_cooldown
	var dir := (player.global_position - global_position).normalized()
	anim.modulate = Color(1.8, 1.5, 1.5)  # wind-up telegraph
	await get_tree().create_timer(windup).timeout
	if state == State.DEAD:
		return
	anim.modulate = Color.WHITE
	weapon.strike(dir)
	var d := weapon.data
	if player and player.is_alive() and Weapons.hits(global_position + Vector2(0, -8), dir, player.global_position + Vector2(0, -8), d.reach + 2.0, d.arc):
		player.take_damage(damage, dir)
	await get_tree().create_timer(0.25).timeout
	if state != State.DEAD:
		state = State.CHASE


func _cast() -> void:
	state = State.ATTACK
	_cooldown = attack_cooldown
	anim.modulate = Color(1.5, 1.5, 1.9)
	await get_tree().create_timer(windup).timeout
	if state == State.DEAD:
		return
	anim.modulate = Color.WHITE
	if player and player.is_alive():
		var origin := global_position + Vector2(0, -10)
		var dir := (player.global_position + Vector2(0, -8) - origin).normalized()
		weapon.strike(dir)
		var p: Projectile = PROJECTILE.instantiate()
		p.setup(origin + dir * 8.0, dir, damage, "player", projectile_texture, 90.0)
		get_parent().add_child(p)
	await get_tree().create_timer(0.2).timeout
	if state != State.DEAD:
		state = State.CHASE


func take_damage(amount: int, from_dir: Vector2) -> void:
	if state == State.DEAD:
		return
	hp -= amount
	_knock = from_dir.normalized() * 150.0
	aggressive = true
	if state != State.ATTACK:
		state = State.CHASE
	anim.modulate = Color(1, 0.3, 0.3)
	create_tween().tween_property(anim, "modulate", Color.WHITE, 0.2)
	if hp <= 0:
		_die()


func _die() -> void:
	state = State.DEAD
	remove_from_group("enemy")
	velocity = Vector2.ZERO
	weapon.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	anim.modulate = Color.WHITE
	anim.play("death")
	queue_redraw()
	killed.emit(self)
	await anim.animation_finished
	var t := create_tween()
	t.tween_interval(1.5)
	t.tween_property(self, "modulate:a", 0.0, 0.6)
	t.tween_callback(queue_free)


func _draw() -> void:
	if state == State.DEAD or hp >= max_hp:
		return
	var w := 14.0
	var y := -32.0
	draw_rect(Rect2(-w * 0.5 - 1.0, y - 1.0, w + 2.0, 4.0), Color(0.1, 0.08, 0.12))
	draw_rect(Rect2(-w * 0.5, y, w * float(hp) / float(max_hp), 2.0), Color(0.9, 0.25, 0.3))
