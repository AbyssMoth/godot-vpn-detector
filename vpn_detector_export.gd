##EXCLUDE_FILE
@tool
extends EditorPlugin

# Подключает предсобранный .aar VPN-детектора к Android-экспорту.
# AAR собирается отдельно скриптом build_aar.sh (нужен Android SDK + JDK 17-22),
# см. README. Здесь без авто-пересборки: так аддон безопасно ставится и через
# zip-менеджер (где submodule с исходниками ядра отсутствует).

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
		return PackedStringArray([AAR_PATH])
