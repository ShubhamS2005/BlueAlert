package com.example.bluealert

import io.flutter.embedding.android.FlutterActivity
// --- ADD THESE IMPORTS ---
import android.os.Build
import android.view.WindowManager
import android.os.Bundle

class MainActivity: FlutterActivity() {
    // --- ADD THIS ENTIRE OVERRIDE METHOD ---
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // This ensures the screen wakes up and shows over the lock screen
        // when launched from a full-screen intent.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            window.addFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
            window.addFlags(WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON)
        }
    }
}