class_name VpnDetectorService
extends Node

## Переносимая обвязка над нативным синглтоном "VpnDetector".
## На Android делегирует в плагин и ретранслирует его сигнал; вне Android работает
## как no-op (VPN не активен, интернет считается доступным), чтобы игровой код был
## единым на всех платформах и не падал в редакторе/на десктопе.
##
## Можно повесить автолоадом или создать как обычный узел.

signal vpn_status_changed(is_vpn_active: bool, has_internet: bool)

var _singleton: Object = null

func _ready() -> void:
	_singleton = _get_singleton()
	if _singleton != null and _singleton.has_signal("vpn_status_changed"):
		_singleton.connect("vpn_status_changed", _on_native_status_changed)

## Доступен ли нативный детектор (только Android-сборка).
func is_available() -> bool:
	return _get_singleton() != null

func start_monitoring() -> void:
	var s := _get_singleton()
	if s != null:
		s.startMonitoring()

func stop_monitoring() -> void:
	var s := _get_singleton()
	if s != null:
		s.stopMonitoring()

func is_vpn_active() -> bool:
	var s := _get_singleton()
	return bool(s.isVpnActive()) if s != null else false

func has_internet_connection() -> bool:
	var s := _get_singleton()
	return bool(s.hasInternetConnection()) if s != null else true

func get_cached_vpn_status() -> bool:
	var s := _get_singleton()
	return bool(s.getCachedVpnStatus()) if s != null else false

func get_cached_internet_status() -> bool:
	var s := _get_singleton()
	return bool(s.getCachedInternetStatus()) if s != null else true

## Открыть системный экран настроек VPN. true, если удалось запустить (только Android).
func open_vpn_settings() -> bool:
	var s := _get_singleton()
	return bool(s.openVpnSettings()) if s != null else false

func _get_singleton() -> Object:
	if Engine.has_singleton("VpnDetector"):
		return Engine.get_singleton("VpnDetector")
	return null

func _on_native_status_changed(is_vpn_active: bool, has_internet: bool) -> void:
	vpn_status_changed.emit(is_vpn_active, has_internet)
