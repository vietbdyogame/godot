class_name Weapons
extends RefCounted
## Weapon database shared by the player and enemies.
## style: "swing" (arc slash), "thrust" (stab forward), "cast" (shoots a projectile).

const DIR := "res://Pixel Crawler - Free Pack/Weapons/extracted/"

const LIST := {
	"wood_sword":    {"name": "Kiếm gỗ",      "damage": 1, "reach": 20.0, "arc": 110.0, "cooldown": 0.35, "style": "swing"},
	"wood_dagger":   {"name": "Dao gỗ",       "damage": 1, "reach": 15.0, "arc": 80.0,  "cooldown": 0.25, "style": "thrust"},
	"wood_mallet":   {"name": "Búa gỗ",       "damage": 2, "reach": 17.0, "arc": 120.0, "cooldown": 0.55, "style": "swing"},
	"wood_hammer":   {"name": "Búa chiến gỗ", "damage": 3, "reach": 21.0, "arc": 120.0, "cooldown": 0.75, "style": "swing"},
	"wood_spear":    {"name": "Giáo gỗ",      "damage": 1, "reach": 28.0, "arc": 40.0,  "cooldown": 0.45, "style": "thrust"},
	"wood_staff":    {"name": "Gậy phép gỗ",  "damage": 1, "reach": 0.0,  "arc": 0.0,   "cooldown": 0.6,  "style": "cast"},
	"bone_scimitar": {"name": "Mã tấu xương", "damage": 2, "reach": 21.0, "arc": 120.0, "cooldown": 0.4,  "style": "swing"},
	"bone_club":     {"name": "Chùy xương",   "damage": 3, "reach": 17.0, "arc": 110.0, "cooldown": 0.7,  "style": "swing"},
	"bone_dagger":   {"name": "Dao xương",    "damage": 1, "reach": 15.0, "arc": 80.0,  "cooldown": 0.25, "style": "thrust"},
	"bone_axe":      {"name": "Rìu xương",    "damage": 2, "reach": 18.0, "arc": 120.0, "cooldown": 0.55, "style": "swing"},
	"bone_spear":    {"name": "Giáo xương",   "damage": 2, "reach": 28.0, "arc": 40.0,  "cooldown": 0.5,  "style": "thrust"},
	"bone_staff":    {"name": "Gậy phép xương", "damage": 2, "reach": 0.0, "arc": 0.0,  "cooldown": 0.6,  "style": "cast"},
}


static func texture(id: String) -> Texture2D:
	return load(DIR + id + ".png")


## True if a target at target_pos is inside the attack arc that starts at origin and points along dir.
static func hits(origin: Vector2, dir: Vector2, target_pos: Vector2, reach: float, arc_deg: float, target_radius := 6.0) -> bool:
	var to := target_pos - origin
	var dist := to.length()
	if dist > reach + target_radius:
		return false
	if dist < target_radius:
		return true
	return absf(dir.angle_to(to)) <= deg_to_rad(arc_deg) * 0.5 + 0.25
