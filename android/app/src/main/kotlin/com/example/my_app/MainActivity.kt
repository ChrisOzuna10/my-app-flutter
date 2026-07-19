package com.example.my_app

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager
import android.util.Log
import android.provider.Settings
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val SECURITY_CHANNEL = "security_channel"
	private val FAKE_GPS_CHANNEL = "fake_gps_channel"
	private var securityMethodChannel: MethodChannel? = null
	private var devModeObserver: android.database.ContentObserver? = null

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		securityMethodChannel = MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
		securityMethodChannel?.setMethodCallHandler { call, result ->
				if (call.method == "secureScreen") {
					val secure = call.argument<Boolean>("secure") ?: false
					if (secure) {
						window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
					} else {
						window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
					}
					result.success(null)
				} else if (call.method == "isAdbEnabled") {
					// Comprueba Settings.Global.ADB_ENABLED; devuelve false ante cualquier excepción
					try {
						val adb = try {
							Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED)
						} catch (e: Exception) {
							Log.w("MainActivity", "Error leyendo ADB_ENABLED: ${e.message}")
							0
						}
						Log.d("MainActivity", "isAdbEnabled -> $adb")
						result.success(adb == 1)
					} catch (e: Exception) {
						Log.w("MainActivity", "Excepción en isAdbEnabled: ${e.message}")
						result.success(false)
					}
				} else if (call.method == "isDeviceInDevMode") {
					// Comprueba tanto DEVELOPMENT_SETTINGS_ENABLED como ADB_ENABLED; devuelve true si cualquiera está activado
					try {
						val adb = try {
							Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED)
						} catch (e: Exception) { 0 }
						val dev = try {
							Settings.Global.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED)
						} catch (e: Exception) { 0 }
						Log.d("MainActivity", "isDeviceInDevMode -> ADB=$adb DEV=$dev")
						result.success(adb == 1 || dev == 1)
					} catch (e: Exception) {
						Log.w("MainActivity", "Excepción en isDeviceInDevMode: ${e.message}")
						result.success(false)
					}
				} else {
					result.notImplemented()
				}
			}
		// Registrar ContentObserver para detectar cambios en Settings.Global (ADB y Developer Options)
		try {
			val resolver = contentResolver
			val handler = android.os.Handler(mainLooper)
			devModeObserver = object : android.database.ContentObserver(handler) {
				override fun onChange(selfChange: Boolean) {
					super.onChange(selfChange)
					notifyDevModeChanged()
				}
			}
			resolver.registerContentObserver(Settings.Global.getUriFor(Settings.Global.ADB_ENABLED), false, devModeObserver!!)
			resolver.registerContentObserver(Settings.Global.getUriFor(Settings.Global.DEVELOPMENT_SETTINGS_ENABLED), false, devModeObserver!!)
		} catch (e: Exception) {
			Log.w("MainActivity", "No se pudo registrar ContentObserver: ${e.message}")
		}
		MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, FAKE_GPS_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method == "isLocationMocked") {
					var isMocked = false
					try {
						val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
						val providers = locationManager.getProviders(true)
						for (provider in providers) {
							val location = locationManager.getLastKnownLocation(provider)
							if (location != null) {
								isMocked = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) {
									location.isFromMockProvider
								} else {
									location.provider != LocationManager.GPS_PROVIDER
								}
								if (isMocked) break
							}
						}
					} catch (e: Exception) {
						isMocked = false
					}
					result.success(isMocked)
				} else {
					result.notImplemented()
				}
			}
	}

	override fun onDestroy() {
		super.onDestroy()
		try {
			devModeObserver?.let { contentResolver.unregisterContentObserver(it) }
		} catch (e: Exception) {
			Log.w("MainActivity", "Error unregistering observer: ${e.message}")
		}
	}

	private fun notifyDevModeChanged() {
		try {
			val adb = try { Settings.Global.getInt(contentResolver, Settings.Global.ADB_ENABLED) } catch (e: Exception) { 0 }
			val dev = try { Settings.Global.getInt(contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED) } catch (e: Exception) { 0 }
			val isDev = (adb == 1 || dev == 1)
			Log.d("MainActivity", "notifyDevModeChanged -> ADB=$adb DEV=$dev")
			// Invocar método en Dart para notificar cambio
			securityMethodChannel?.invokeMethod("onDevModeChanged", mapOf("devMode" to isDev))
		} catch (e: Exception) {
			Log.w("MainActivity", "Error notifying dev mode change: ${e.message}")
		}
	}
}
