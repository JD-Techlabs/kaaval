extends GutTest
## Shared setup: every test gets a fresh profile, a throwaway save file, a
## fixed clock and default remote config, and never touches the real save.

const TEST_SAVE: String = "user://test_save.json"
const NOW: float = 1_700_000_000.0


func before_each() -> void:
	SaveManager.path = TEST_SAVE
	SaveManager.delete_save()
	GameState.reset_profile()
	GameState.time_override = NOW
	GameState.date_override = "2026-01-10"
	RemoteConfig.reset_to_defaults()


func after_each() -> void:
	SaveManager.delete_save()
	for leftover: String in [TEST_SAVE + ".corrupt", TEST_SAVE + ".tmp"]:
		if FileAccess.file_exists(leftover):
			DirAccess.remove_absolute(leftover)
	SaveManager.path = SaveManager.DEFAULT_PATH
	GameState.time_override = -1.0
	GameState.date_override = ""
	GameState.load_profile()
