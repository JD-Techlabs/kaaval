extends Boss
## Thorn Queen: charges in a line every few seconds; calls crawlers at half HP.

var _timer: float = 0.0
var _summoned: bool = false


func attack(delta: float, mgr: EnemyManager) -> void:
	if charge_state == Charge.NONE:
		_timer += delta
		if _timer >= param("charge_interval"):
			_timer = 0.0
			begin_charge(mgr)
	if not _summoned and hp <= max_hp * param("summon_hp_pct"):
		_summoned = true
		mgr.spawn_around(GameData.enemy(str(data.params["summon_id"])), position, int(param("summon_count")), radius + 60.0)
