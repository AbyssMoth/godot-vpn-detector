##EXCLUDE_FILE
@tool
extends EditorPlugin

# Подключает .aar VPN-детектора к Android-экспорту.
#
# Сборка AAR:
#   - готовый .aar лежит в bin/ и используется по умолчанию;
#   - one-click: build_aar.command (macOS), build_aar.bat (Windows), build_aar.sh (Linux/macOS);
#   - авто: при экспорте, ЕСЛИ рядом есть исходники ядра (submodule android_plugin/core) и они
#     новее .aar, плагин сам пересоберёт его. При установке через zip-менеджер (submodule нет)
#     авто-пересборка не срабатывает и берётся готовый .aar - это безопасно.

var _export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	_export_plugin = VpnDetectorAndroidExport.new()
	add_export_plugin(_export_plugin)

func _exit_tree() -> void:
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
		_export_plugin = null


class VpnDetectorAndroidExport extends EditorExportPlugin:
	const PLUGIN_NAME := "VpnDetector"
	# Путь к .aar относительно res://addons/
	const AAR_PATH := "vpn_detector/bin/vpn-detector-release.aar"

	func _get_name() -> String:
		return PLUGIN_NAME

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_libraries(platform: EditorExportPlatform, debug: bool) -> PackedStringArray:
		_maybe_rebuild()
		return PackedStringArray([AAR_PATH])

	# res://addons/vpn_detector
	func _addon_dir() -> String:
		return "res://addons/" + AAR_PATH.get_base_dir().get_base_dir()

	func _maybe_rebuild() -> void:
		var addon := _addon_dir()
		var core_src := addon + "/android_plugin/core/vpndetectorcore/src/main/java/com/abyssmoth/vpndetector/core/VpnDetectorCore.java"
		if not FileAccess.file_exists(core_src):
			return  # submodule ядра отсутствует (zip-установка) -> используем готовый AAR
		var aar := "res://addons/" + AAR_PATH
		if FileAccess.file_exists(aar) and not _source_newer_than_aar(addon, aar):
			return
		_run_build_script(addon)

	func _source_newer_than_aar(addon: String, aar: String) -> bool:
		var aar_time := FileAccess.get_modified_time(ProjectSettings.globalize_path(aar))
		var newest := _newest_time(ProjectSettings.globalize_path(addon + "/android_plugin"))
		return newest > aar_time

	func _newest_time(path: String) -> int:
		var dir := DirAccess.open(path)
		if dir == null:
			return 0
		var newest := 0
		dir.list_dir_begin()
		while true:
			var name := dir.get_next()
			if name.is_empty():
				break
			if name.begins_with("."):
				continue
			var child := path.path_join(name)
			if dir.current_is_dir():
				if name == "build" or name == ".gradle":
					continue
				newest = maxi(newest, _newest_time(child))
			elif _is_source_file(name):
				newest = maxi(newest, FileAccess.get_modified_time(child))
		dir.list_dir_end()
		return newest

	func _is_source_file(name: String) -> bool:
		return name.ends_with(".java") or name.ends_with(".kt") \
			or name.ends_with(".xml") or name.ends_with(".gradle") or name.ends_with(".pro")

	func _run_build_script(addon: String) -> void:
		var output: Array = []
		var code := -1
		if OS.get_name() == "Windows":
			code = OS.execute("cmd", PackedStringArray(["/c", ProjectSettings.globalize_path(addon + "/build_aar.bat")]), output, true, false)
		else:
			code = OS.execute("/bin/sh", PackedStringArray([ProjectSettings.globalize_path(addon + "/build_aar.sh")]), output, true, false)
		for line in output:
			print("[VpnDetector] ", line)
		if code != 0:
			push_warning("VpnDetector: авто-пересборка AAR не удалась (код %d), используется предыдущий AAR из bin/." % code)
		else:
			print("[VpnDetector] AAR пересобран.")
