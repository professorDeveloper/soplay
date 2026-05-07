package com.soplay.soplay

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.abs

class DownloadForegroundService : Service() {

    private val notificationManager by lazy {
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> startTask(intent)
            ACTION_CANCEL -> cancelTask(intent.getStringExtra(EXTRA_ID).orEmpty())
            ACTION_CANCEL_ALL -> cancelAllTasks()
        }
        return START_STICKY
    }

    private fun startTask(intent: Intent) {
        val id = intent.getStringExtra(EXTRA_ID).orEmpty()
        val url = intent.getStringExtra(EXTRA_URL).orEmpty()
        val localPath = intent.getStringExtra(EXTRA_LOCAL_PATH).orEmpty()
        if (id.isEmpty() || url.isEmpty() || localPath.isEmpty()) return
        if (activeTasks.containsKey(id)) return

        val title = intent.getStringExtra(EXTRA_TITLE).takeUnless { it.isNullOrBlank() } ?: "Downloading"
        val headers = parseHeaders(intent.getStringExtra(EXTRA_HEADERS_JSON).orEmpty())
        val token = AtomicBoolean(false)
        activeTasks[id] = token

        updateState(id, title, url, localPath, "downloading", 0, 0, null)
        startForeground(
            SUMMARY_NOTIFICATION_ID,
            buildSummaryNotification("Preparing download")
        )
        updateProgressNotification(title, 0, 0)

        executor.execute {
            try {
                if (isHls(url)) {
                    downloadHls(id, title, url, localPath, headers, token)
                } else {
                    downloadDirect(id, title, url, localPath, headers, token)
                }
                if (token.get()) {
                    updateState(id, title, url, localPath, "cancelled", 0, 0, null)
                    notificationManager.cancel(notificationId(id))
                } else {
                    val existingState = JSONObject(readStates(this)).optJSONObject(id)
                    val fallbackTotal = File(localPath).takeIf { it.exists() }?.length() ?: 0L
                    val total = existingState?.optLong("totalBytes", fallbackTotal) ?: fallbackTotal
                    val downloaded = existingState?.optLong("downloadedBytes", total) ?: total
                    updateState(id, title, url, localPath, "completed", downloaded, total, null)
                    notificationManager.cancel(notificationId(id))
                }
            } catch (e: Exception) {
                if (token.get()) {
                    updateState(id, title, url, localPath, "cancelled", 0, 0, null)
                    notificationManager.cancel(notificationId(id))
                } else {
                    updateState(id, title, url, localPath, "failed", 0, 0, e.message)
                    notificationManager.cancel(notificationId(id))
                }
            } finally {
                activeTasks.remove(id)
                if (activeTasks.isEmpty()) {
                    notificationManager.notify(
                        SUMMARY_NOTIFICATION_ID,
                        buildDoneNotification(title, "Downloads finished")
                    )
                    stopForegroundCompat()
                    stopSelf()
                } else {
                    notificationManager.notify(
                        SUMMARY_NOTIFICATION_ID,
                        buildSummaryNotification("${activeTasks.size} downloads running")
                    )
                }
            }
        }
    }

    private fun downloadDirect(
        id: String,
        title: String,
        url: String,
        localPath: String,
        headers: Map<String, String>,
        token: AtomicBoolean
    ) {
        val file = File(localPath)
        file.parentFile?.mkdirs()

        var existing = if (file.exists()) file.length() else 0L
        val connection = openConnection(url, headers, existing)
        val responseCode = connection.responseCode
        val append = existing > 0 && responseCode == HttpURLConnection.HTTP_PARTIAL
        if (!append && file.exists()) {
            file.delete()
            existing = 0L
        }

        val contentLength = connection.getHeaderFieldLong("Content-Length", -1L)
        val total = if (contentLength > 0) existing + contentLength else 0L
        var downloaded = existing
        updateState(id, title, url, localPath, "downloading", downloaded, total, null)
        updateProgressNotification(title, downloaded, total)

        connection.inputStream.use { input ->
            FileOutputStream(file, append).use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    if (token.get()) return
                    val read = input.read(buffer)
                    if (read == -1) break
                    output.write(buffer, 0, read)
                    downloaded += read
                    updateState(id, title, url, localPath, "downloading", downloaded, total, null)
                    updateProgressNotification(title, downloaded, total)
                }
            }
        }
    }

    private fun downloadHls(
        id: String,
        title: String,
        url: String,
        localPath: String,
        headers: Map<String, String>,
        token: AtomicBoolean
    ) {
        val target = File(localPath)
        target.parentFile?.mkdirs()

        var playlistUrl = url
        var playlist = readText(url, headers, token)
        if (playlist.contains("#EXT-X-STREAM-INF")) {
            val variantUrl = pickVariantUrl(playlist, baseUrlOf(url))
                ?: throw IllegalStateException("No HLS variant found")
            playlistUrl = variantUrl
            playlist = readText(variantUrl, headers, token)
        }

        val baseUrl = baseUrlOf(playlistUrl)
        val segments = parseSegments(playlist, baseUrl)
        if (segments.isEmpty()) throw IllegalStateException("No HLS segments found")

        var totalBytes = 0L
        for (i in segments.indices) {
            if (token.get()) return
            val segmentFile = File(target.parentFile, "seg_$i.ts")
            if (!segmentFile.exists() || segmentFile.length() == 0L) {
                downloadDirectFile(segments[i], segmentFile, headers, token)
            }
            totalBytes += segmentFile.length()
            updateState(
                id,
                title,
                url,
                localPath,
                "downloading",
                i + 1L,
                segments.size.toLong(),
                null
            )
            updateProgressNotification(title, i + 1L, segments.size.toLong())
        }

        target.writeText(buildLocalPlaylist(playlist))
        updateState(id, title, url, localPath, "completed", totalBytes, totalBytes, null)
    }

    private fun downloadDirectFile(
        url: String,
        file: File,
        headers: Map<String, String>,
        token: AtomicBoolean
    ) {
        file.parentFile?.mkdirs()
        val connection = openConnection(url, headers, 0L)
        connection.inputStream.use { input ->
            FileOutputStream(file, false).use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                while (true) {
                    if (token.get()) return
                    val read = input.read(buffer)
                    if (read == -1) break
                    output.write(buffer, 0, read)
                }
            }
        }
    }

    private fun readText(
        url: String,
        headers: Map<String, String>,
        token: AtomicBoolean
    ): String {
        if (token.get()) return ""
        val connection = openConnection(url, headers, 0L)
        return connection.inputStream.bufferedReader().use { it.readText() }
    }

    private fun openConnection(
        url: String,
        headers: Map<String, String>,
        rangeStart: Long
    ): HttpURLConnection {
        val connection = URL(url).openConnection() as HttpURLConnection
        connection.connectTimeout = 15000
        connection.readTimeout = 30000
        connection.instanceFollowRedirects = true
        headers.forEach { (key, value) ->
            if (key.isNotBlank() && value.isNotBlank()) {
                connection.setRequestProperty(key, value)
            }
        }
        if (rangeStart > 0L) {
            connection.setRequestProperty("Range", "bytes=$rangeStart-")
        }
        return connection
    }

    private fun parseHeaders(raw: String): Map<String, String> {
        if (raw.isBlank()) return emptyMap()
        val json = JSONObject(raw)
        return json.keys().asSequence().associateWith { key ->
            json.optString(key)
        }
    }

    private fun isHls(url: String): Boolean = url.lowercase().contains(".m3u8")

    private fun pickVariantUrl(playlist: String, baseUrl: String): String? {
        val lines = playlist.lines()
        for (i in lines.indices) {
            if (!lines[i].startsWith("#EXT-X-STREAM-INF")) continue
            for (j in i + 1 until lines.size) {
                val line = lines[j].trim()
                if (line.isEmpty() || line.startsWith("#")) continue
                return resolveUrl(line, baseUrl)
            }
        }
        return null
    }

    private fun parseSegments(playlist: String, baseUrl: String): List<String> =
        playlist.lines()
            .map { it.trim() }
            .filter { it.isNotEmpty() && !it.startsWith("#") }
            .map { resolveUrl(it, baseUrl) }

    private fun buildLocalPlaylist(playlist: String): String {
        var index = 0
        return playlist.lines().joinToString("\n") { line ->
            val trimmed = line.trim()
            if (trimmed.isEmpty() || trimmed.startsWith("#")) {
                trimmed
            } else {
                "seg_${index++}.ts"
            }
        }
    }

    private fun baseUrlOf(url: String): String =
        url.substringBeforeLast("/", missingDelimiterValue = url) + "/"

    private fun resolveUrl(path: String, baseUrl: String): String {
        if (path.startsWith("http://") || path.startsWith("https://")) return path
        return URI(baseUrl).resolve(path).toString()
    }

    private fun cancelTask(id: String) {
        if (id.isBlank()) return
        activeTasks[id]?.set(true)
    }

    private fun cancelAllTasks() {
        activeTasks.values.forEach { it.set(true) }
    }

    private fun updateState(
        id: String,
        title: String,
        url: String,
        localPath: String,
        status: String,
        downloadedBytes: Long,
        totalBytes: Long,
        error: String?
    ) {
        synchronized(stateLock) {
            val json = JSONObject(readStates(this))
            val item = JSONObject()
                .put("id", id)
                .put("title", title)
                .put("url", url)
                .put("localPath", localPath)
                .put("status", status)
                .put("downloadedBytes", downloadedBytes)
                .put("totalBytes", totalBytes)
            if (error != null) item.put("error", error)
            json.put(id, item)
            prefs(this).edit().putString(PREF_STATES, json.toString()).apply()
        }
    }

    private fun updateProgressNotification(
        title: String,
        downloaded: Long,
        total: Long
    ) {
        notificationManager.notify(
            SUMMARY_NOTIFICATION_ID,
            buildProgressNotification(title, downloaded, total)
        )
    }

    private fun buildSummaryNotification(text: String): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle("Sozo downloads")
            .setContentText(text)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openAppIntent())
            .build()

    private fun buildProgressNotification(title: String, downloaded: Long, total: Long): Notification {
        val percent = if (total > 0L) ((downloaded * 100L) / total).toInt().coerceIn(0, 100) else 0
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentTitle(title)
            .setContentText(if (total > 0L) "$percent%" else "Downloading")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setProgress(100, percent, total <= 0L)
            .setContentIntent(openAppIntent())
            .build()
    }

    private fun buildDoneNotification(title: String, text: String): Notification =
        NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title)
            .setContentText(text)
            .setOnlyAlertOnce(true)
            .setAutoCancel(true)
            .setContentIntent(openAppIntent())
            .build()

    private fun openAppIntent(): PendingIntent {
        val intent = Intent(this, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        return PendingIntent.getActivity(this, 0, intent, flags)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "Downloads",
            NotificationManager.IMPORTANCE_LOW
        )
        notificationManager.createNotificationChannel(channel)
    }

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }
    }

    companion object {
        const val ACTION_START = "com.soplay.soplay.download.START"
        const val ACTION_CANCEL = "com.soplay.soplay.download.CANCEL"
        const val ACTION_CANCEL_ALL = "com.soplay.soplay.download.CANCEL_ALL"

        const val EXTRA_ID = "id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_URL = "url"
        const val EXTRA_LOCAL_PATH = "local_path"
        const val EXTRA_HEADERS_JSON = "headers_json"

        private const val CHANNEL_ID = "soplay_downloads"
        private const val SUMMARY_NOTIFICATION_ID = 2100
        private const val PREF_NAME = "soplay_downloads"
        private const val PREF_STATES = "download_states"

        private val executor = Executors.newCachedThreadPool()
        private val activeTasks = ConcurrentHashMap<String, AtomicBoolean>()
        private val stateLock = Any()

        fun readStates(context: Context): String =
            prefs(context).getString(PREF_STATES, "{}") ?: "{}"

        fun removeState(context: Context, id: String) {
            if (id.isBlank()) return
            synchronized(stateLock) {
                val json = JSONObject(readStates(context))
                json.remove(id)
                prefs(context).edit().putString(PREF_STATES, json.toString()).apply()
            }
        }

        private fun prefs(context: Context) =
            context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)

        private fun notificationId(id: String): Int =
            3000 + abs(id.hashCode() % 100000)
    }
}
