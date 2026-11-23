class_name HowToPlay
extends RefCounted
## "How to play": short pages with Next and Skip. Pages belong to a group:
## "intro" (2 pages) opens by itself the first time Start Night is pressed;
## "village" opens on the first return home (see Onboarding); "night" (bosses)
## is covered live by the in-run boss warnings. Settings shows every page.

const PAGE_WIDTH: float = 820.0
const ICON_SIZE: float = 220.0


static func seen() -> bool:
	return bool(GameState.p.get("how_to_play_seen", false))


static func mark_seen() -> void:
	GameState.p["how_to_play_seen"] = true
	GameState.save()


## [{"icon", "title", "text", "group"}], filled from game data so times and counts
## stay true. `group` "" = every page (the full guide in Settings).
static func pages(group: String = "") -> Array[Dictionary]:
	var first: WaveData = NightLogic.nights()[0]
	var first_boss: Dictionary = NightLogic.bosses(first)[0]
	var all: Array[Dictionary] = [
		{"group": "intro", "icon": "res://assets/sprites/hero_muthu.svg", "title": "Guard the village",
			"text": "Every night, creatures come out of the dark. Survive until dawn (%s on the timer) to win the night." % NightLogic.clock(first.duration)},
		{"group": "intro", "icon": "res://assets/sprites/joy_knob.svg", "title": "Move and level up",
			"text": "Drag anywhere on the lower screen to move; your weapons attack on their own. Walk over glowing embers to level up, then pick 1 of 3 upgrades."},
		{"group": "night", "icon": GameData.boss(str(first_boss["id"])).texture, "title": "Beat the bosses",
			"text": "Three bosses come each night. In %s: %s. Each one drops a chest with a big upgrade." % [first.display_name, NightLogic.boss_schedule(first)]},
		{"group": "village", "icon": UiKit.ICON_DIR + "coin.svg", "title": "Grow stronger",
			"text": "Every night pays coins and more, win or lose. Tap a building to build or upgrade it: each one makes your hero stronger. Reach dawn to unlock the next night; there are %d nights, each with new bosses." % NightLogic.nights().size()},
		{"group": "village", "icon": UiKit.ICON_DIR + "food.svg", "title": "Grow through the ages",
			"text": "Gather food, stone and more to lead the village from the %s to the %s, %d ages in all. Buy land below the village for farms and quarries that work while you are away. Each age also upgrades your hero's weapon. Tap the age bar to see what the next age needs." % [AgeLogic.ages()[0].display_name, AgeLogic.ages()[-1].display_name, AgeLogic.ages().size()]},
	]
	if group.is_empty():
		return all
	var out: Array[Dictionary] = []
	out.assign(all.filter(func(page: Dictionary) -> bool: return str(page["group"]) == group))
	return out


## Opens the pages of `group` ("" = all). `on_done` runs after the last page or Skip.
## Finishing the intro (or the full guide) marks How to play as seen.
static func open(parent: Node, on_done: Callable = Callable(), group: String = "") -> void:
	var content: VBoxContainer = UiKit.modal(parent, "Your village" if group == "village" else "How to play")
	var list: Array[Dictionary] = pages(group)
	var page: Array[int] = [0]
	var art: TextureRect = UiKit.icon(str(list[0]["icon"]), ICON_SIZE)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	content.add_child(art)
	var title: Label = UiKit.label("", UiKit.FONT_BIG, UiKit.AMBER)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	var body: Label = UiKit.label("", UiKit.FONT, UiKit.TEXT, true)
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.custom_minimum_size = Vector2(PAGE_WIDTH, 300.0)
	content.add_child(body)
	var counter: Label = UiKit.label("", UiKit.FONT_SMALL, UiKit.MUTED)
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(counter)
	var buttons: HBoxContainer = UiKit.hbox()
	content.add_child(buttons)
	var finish: Callable = func() -> void:
		if group != "village" and group != "night":
			mark_seen()
		UiKit.close_modal(content)
		if on_done.is_valid():
			on_done.call()
	var skip: Button = UiKit.button("Skip", finish, "secondary")
	skip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(skip)
	var next: Button = UiKit.button("Next", Callable())
	next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(next)
	var show_page: Callable = func() -> void:
		var entry: Dictionary = list[page[0]]
		art.texture = load(str(entry["icon"])) as Texture2D
		title.text = str(entry["title"])
		body.text = str(entry["text"])
		counter.text = "%d / %d" % [page[0] + 1, list.size()]
		var last: bool = page[0] == list.size() - 1
		next.text = "Let's go!" if last else "Next"
		skip.visible = not last
	next.pressed.connect(func() -> void:
		if page[0] >= list.size() - 1:
			finish.call()
		else:
			page[0] += 1
			show_page.call())
	show_page.call()
