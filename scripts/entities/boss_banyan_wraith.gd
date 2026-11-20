extends Boss
## Banyan Wraith: roots erupt under the hero after a 1 s warning; summons wisps.

var _root_timer: float = 0.0
var _summon_timer: float = 0.0


func attack(delta: float, mgr: EnemyManager) -> void:
	_root_timer += delta
	if _root_timer >= param("root_interval"):
		_root_timer = 0.0
		mgr.run.hazards.add_circle(mgr.target, param("root_radius"), param("root_delay"), param("root_damage"))
	_summon_timer += delta
	if _summon_timer >= param("summon_interval"):
		_summon_timer = 0.0
		mgr.spawn_around(GameData.enemy(str(data.params["summon_id"])), position, int(param("summon_count")), radius + 80.0)
