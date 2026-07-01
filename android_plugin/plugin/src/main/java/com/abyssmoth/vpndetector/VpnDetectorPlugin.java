package com.abyssmoth.vpndetector;

import android.app.Activity;
import android.util.Log;
import android.view.View;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import com.abyssmoth.vpndetector.core.VpnDetectorCore;

import java.util.Collections;
import java.util.Set;

/**
 * VpnDetectorPlugin - тонкая Godot-обёртка над движко-независимым ядром
 * {@link VpnDetectorCore}. Вся логика определения VPN/интернета живёт в ядре
 * (репозиторий android-vpn-detector-core, подключён submodule'ом), а эта обёртка
 * только регистрирует синглтон и ретранслирует состояние в GDScript сигналом.
 *
 * Singleton name: "VpnDetector"
 * Сигнал: vpn_status_changed(is_vpn_active: bool, has_internet: bool)
 */
public class VpnDetectorPlugin extends GodotPlugin {

    private static final String TAG = "VpnDetectorPlugin";
    private static final String SINGLETON_NAME = "VpnDetector";
    private static final String SIGNAL_STATUS_CHANGED = "vpn_status_changed";

    private VpnDetectorCore core;

    public VpnDetectorPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return SINGLETON_NAME;
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(
            new SignalInfo(SIGNAL_STATUS_CHANGED, Boolean.class, Boolean.class)
        );
    }

    @Override
    public View onMainCreate(Activity activity) {
        try {
            core = new VpnDetectorCore(activity.getApplicationContext());
        } catch (Throwable t) {
            Log.e(TAG, "onMainCreate error: " + t.getMessage(), t);
        }
        return null;
    }

    @Override
    public void onMainDestroy() {
        try {
            if (core != null) {
                core.stopMonitoring();
            }
        } catch (Throwable t) {
            Log.e(TAG, "onMainDestroy error: " + t.getMessage(), t);
        }
    }

    // ─── Public API (вызывается из GDScript) ──────────────────────────────────

    @UsedByGodot
    public void startMonitoring() {
        try {
            if (core == null) {
                return;
            }
            core.startMonitoring(new VpnDetectorCore.Listener() {
                @Override
                public void onStatusChanged(boolean isVpnActive, boolean hasInternet) {
                    try {
                        emitSignal(SIGNAL_STATUS_CHANGED, isVpnActive, hasInternet);
                    } catch (Throwable t) {
                        Log.e(TAG, "emitSignal error: " + t.getMessage(), t);
                    }
                }
            });
        } catch (Throwable t) {
            Log.e(TAG, "startMonitoring error: " + t.getMessage(), t);
        }
    }

    @UsedByGodot
    public void stopMonitoring() {
        try {
            if (core != null) {
                core.stopMonitoring();
            }
        } catch (Throwable t) {
            Log.e(TAG, "stopMonitoring error: " + t.getMessage(), t);
        }
    }

    @UsedByGodot
    public boolean isVpnActive() {
        return core != null && core.isVpnActive();
    }

    @UsedByGodot
    public boolean hasInternetConnection() {
        return core != null && core.hasInternetConnection();
    }

    @UsedByGodot
    public boolean getCachedVpnStatus() {
        return core != null && core.getCachedVpnStatus();
    }

    @UsedByGodot
    public boolean getCachedInternetStatus() {
        return core != null && core.getCachedInternetStatus();
    }

    @UsedByGodot
    public boolean openVpnSettings() {
        return core != null && core.openVpnSettings(getActivity());
    }
}
