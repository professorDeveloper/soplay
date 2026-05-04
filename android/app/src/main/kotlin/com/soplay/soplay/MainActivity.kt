package com.soplay.soplay

import android.app.PendingIntent
import android.app.PictureInPictureParams
import android.app.RemoteAction
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.graphics.drawable.Icon
import android.os.Build
import android.os.Bundle
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val channelName = "soplay/pip"
    private val actionBroadcastName = "com.soplay.soplay.PIP_ACTION"
    private val actionExtraId = "action_id"

    private var methodChannel: MethodChannel? = null
    private var pipReceiver: BroadcastReceiver? = null

    companion object {
        const val ACTION_PLAY_PAUSE = "play_pause"
        const val ACTION_REWIND = "rewind"
        const val ACTION_FORWARD = "forward"
        const val ACTION_PREV = "prev"
        const val ACTION_NEXT = "next"

        const val REQ_PLAY_PAUSE = 1
        const val REQ_REWIND = 2
        const val REQ_FORWARD = 3
        const val REQ_PREV = 4
        const val REQ_NEXT = 5
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        )
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePiPActions" -> {
                    val isPlaying = call.argument<Boolean>("isPlaying") ?: true
                    val hasPrev = call.argument<Boolean>("hasPrev") ?: false
                    val hasNext = call.argument<Boolean>("hasNext") ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        applyPipActions(isPlaying, hasPrev, hasNext)
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun applyPipActions(
        isPlaying: Boolean,
        hasPrev: Boolean,
        hasNext: Boolean
    ) {
        val actions = mutableListOf<RemoteAction>()

        if (hasPrev) {
            actions.add(
                makeAction(
                    android.R.drawable.ic_media_previous,
                    "Previous",
                    "Previous episode",
                    ACTION_PREV,
                    REQ_PREV
                )
            )
        }
        actions.add(
            makeAction(
                android.R.drawable.ic_media_rew,
                "Rewind 10",
                "Rewind 10 seconds",
                ACTION_REWIND,
                REQ_REWIND
            )
        )
        actions.add(
            makeAction(
                if (isPlaying)
                    android.R.drawable.ic_media_pause
                else
                    android.R.drawable.ic_media_play,
                if (isPlaying) "Pause" else "Play",
                if (isPlaying) "Pause" else "Play",
                ACTION_PLAY_PAUSE,
                REQ_PLAY_PAUSE
            )
        )
        actions.add(
            makeAction(
                android.R.drawable.ic_media_ff,
                "Forward 10",
                "Forward 10 seconds",
                ACTION_FORWARD,
                REQ_FORWARD
            )
        )
        if (hasNext) {
            actions.add(
                makeAction(
                    android.R.drawable.ic_media_next,
                    "Next",
                    "Next episode",
                    ACTION_NEXT,
                    REQ_NEXT
                )
            )
        }

        val params = PictureInPictureParams.Builder()
            .setActions(actions)
            .build()

        try {
            setPictureInPictureParams(params)
        } catch (_: Exception) {
            // Activity may not be in a state to receive PiP params yet
        }
    }

    @RequiresApi(Build.VERSION_CODES.O)
    private fun makeAction(
        iconRes: Int,
        title: String,
        contentDesc: String,
        actionId: String,
        requestCode: Int
    ): RemoteAction {
        val intent = Intent(actionBroadcastName)
            .setPackage(packageName)
            .putExtra(actionExtraId, actionId)
        val flags =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            else
                PendingIntent.FLAG_UPDATE_CURRENT
        val pending = PendingIntent.getBroadcast(this, requestCode, intent, flags)
        val icon = Icon.createWithResource(this, iconRes)
        return RemoteAction(icon, title, contentDesc, pending)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        registerPipReceiver()
    }

    private fun registerPipReceiver() {
        if (pipReceiver != null) return
        pipReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                if (intent.action != actionBroadcastName) return
                val actionId = intent.getStringExtra(actionExtraId) ?: return
                methodChannel?.invokeMethod("onPipAction", actionId)
            }
        }
        val filter = IntentFilter(actionBroadcastName)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipReceiver, filter, RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            registerReceiver(pipReceiver, filter)
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        pipReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (_: Exception) {
            }
            pipReceiver = null
        }
    }
}
