# godot-vpn-detector

Godot-аддон: определение **VPN** и **наличия интернета** на Android, плюс открытие
системного экрана настроек VPN. Тонкая обвязка над движко-независимым ядром
[`android-vpn-detector-core`](https://github.com/AbyssMoth/android-vpn-detector-core),
подключённым git submodule'ом. Ставится в `addons/vpn_detector/`.

Студийный аддон Abyss Moth. Лицензия MIT.

## Архитектура

- **Ядро** (`android-vpn-detector-core`, submodule в `android_plugin/core/`) - чистый
  Android-класс `VpnDetectorCore` без зависимостей от движка. То же ядро можно тянуть в
  Unity через C#-мост.
- **Обёртка** (`VpnDetectorPlugin extends GodotPlugin`) - регистрирует синглтон
  `VpnDetector`, делегирует в ядро и ретранслирует состояние сигналом в GDScript.
  Ядро компилируется прямо в AAR обёртки через `sourceSet`, поэтому итоговый `.aar`
  самодостаточен.

## Клонирование (для разработки/пересборки)

Нужны submodule'ы:

```bash
git clone --recurse-submodules https://github.com/AbyssMoth/godot-vpn-detector
# или после обычного clone:
git submodule update --init --recursive
```

При установке аддона как готового (копированием папки или через менеджер) submodule с
исходниками ядра не нужен - хватает предсобранного `bin/vpn-detector-release.aar`.

## Установка

1. Скопировать `addons/vpn_detector/` в проект (или поставить через менеджер аддонов).
2. Включить плагин `VPN Detector` в `Project > Project Settings > Plugins`.
3. На Android-экспорте подключится `bin/vpn-detector-release.aar`.

## API

Низкоуровнево - синглтон `VpnDetector` (только на Android). Удобнее - переносимый
`VpnDetectorService` (`vpn_detector_service.gd`), который вне Android работает no-op:

```gdscript
var vpn := VpnDetectorService.new()
add_child(vpn)                       # можно и автолоадом

vpn.vpn_status_changed.connect(_on_changed)
vpn.start_monitoring()

if vpn.is_vpn_active():
    vpn.open_vpn_settings()

func _on_changed(is_vpn: bool, has_internet: bool) -> void:
    pass
```

Вне Android: `is_available()` -> false, `is_vpn_active()` -> false,
`has_internet_connection()` -> true, `open_vpn_settings()` -> false.

### Сигнал

```text
vpn_status_changed(is_vpn_active: bool, has_internet: bool)
```

Шлётся только при реальном изменении состояния (rising/falling edge).

## Пересборка AAR

AAR предсобран и лежит в `bin/`. Пересобрать (после правок ядра или обёртки):

```bash
./build_aar.sh
```

Требует Android SDK, JDK 17-22 (Gradle 8.14.x не поддерживает JDK 25; на macOS рабочий
вариант JDK 22), AGP 8.13.0, compileSdk 36, minSdk 23. Скрипт сам подтянет submodule
ядра, если он не инициализирован.

## Ограничение платформы

Отключить чужой VPN программно нельзя - Android этого не разрешает. `open_vpn_settings`
лишь открывает игроку системный экран, где он выключит VPN вручную. Это ограничение
платформы, а не недоработка.
