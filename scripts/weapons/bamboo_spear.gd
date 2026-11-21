extends BaseWeapon
## Bamboo Spear: thrown in the movement direction, pierces several creatures.


func fire() -> bool:
	var direction: Vector2 = run.player.facing
	run.projectiles.fire(sprite("spear"), run.player.position, direction * stat("speed"),
		damage(), int(stat("pierce")), stat("radius"), stat("life"))
	AudioManager.play("whoosh", 0.9)
	return true
