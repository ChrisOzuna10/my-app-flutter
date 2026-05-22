package com.example.my_app

import android.content.Context
import android.location.Location
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val SECURITY_CHANNEL = "security_channel"
	private val FAKE_GPS_CHANNEL = "fake_gps_channel"

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, SECURITY_CHANNEL)
			.setMethodCallHandler { call, result ->
				if (call.method == "secureScreen") {
					val secure = call.argument<Boolean>("secure") ?: false
					if (secure) {
						window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
					} else {
						window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
					}
					result.success(null)
				} else {
					result.notImplemented()
				}
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
}
