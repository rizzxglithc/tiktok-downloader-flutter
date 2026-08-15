package com.rizz.tiktok_downloader

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.rizz.tiktok_downloader/media"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    val isVideo = call.argument<Boolean>("isVideo") ?: true
                    val title = call.argument<String>("title") ?: "TikTok_Download"
                    if (filePath == null) {
                        result.error("INVALID_PATH", "File path is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val savedPath = saveMediaToGallery(context, filePath, isVideo, title)
                        result.success(savedPath)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.localizedMessage, null)
                    }
                }
                "scanFile" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        MediaScannerConnection.scanFile(context, arrayOf(filePath), null, null)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveMediaToGallery(context: Context, sourcePath: String, isVideo: Boolean, title: String): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) throw Exception("Source file not found at: $sourcePath")

        val fileName = sourceFile.name
        val mimeType = if (isVideo) "video/mp4" else "audio/mpeg"

        // Preferred public directory: Download/TikTok or Movies/TikTok
        val publicDir = if (isVideo) {
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "TikTok")
        } else {
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "TikTok_Audio")
        }

        if (!publicDir.exists()) {
            publicDir.mkdirs()
        }

        val destinationFile = File(publicDir, fileName)
        
        // Copy file to public Download folder
        try {
            sourceFile.copyTo(destinationFile, overwrite = true)
        } catch (e: Exception) {
            // Fallback to original path if copy fails
        }

        val targetPath = if (destinationFile.exists()) destinationFile.absolutePath else sourceFile.absolutePath

        // 1. Insert into MediaStore for Android 10+ (API 29+) so Gallery indexes immediately
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val relativeDir = if (isVideo) "${Environment.DIRECTORY_DOWNLOADS}/TikTok" else "${Environment.DIRECTORY_DOWNLOADS}/TikTok_Audio"
                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDir)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val collection = if (isVideo) {
                    MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                } else {
                    MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                }

                val uri: Uri? = context.contentResolver.insert(collection, contentValues)
                if (uri != null) {
                    context.contentResolver.openOutputStream(uri)?.use { outStream ->
                        FileInputStream(sourceFile).use { inStream ->
                            inStream.copyTo(outStream)
                        }
                    }
                    contentValues.clear()
                    contentValues.put(MediaStore.MediaColumns.IS_PENDING, 0)
                    context.contentResolver.update(uri, contentValues, null, null)
                }
            } catch (_: Exception) {}
        }

        // 2. Also trigger MediaScannerConnection for all Android versions
        MediaScannerConnection.scanFile(
            context,
            arrayOf(targetPath),
            arrayOf(mimeType),
            null
        )

        // ALWAYS return the POSIX filesystem path so File(path) works everywhere in Flutter!
        return targetPath
    }
}
