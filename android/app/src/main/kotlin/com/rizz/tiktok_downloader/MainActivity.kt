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
                        // Return source filePath on error so app never breaks
                        result.success(filePath)
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
        if (!sourceFile.exists()) return sourcePath

        val fileName = sourceFile.name
        val mimeType = if (isVideo) "video/mp4" else "audio/mpeg"

        // On Android 10+ (API 29+), use MediaStore to save directly to Movies/TikTok or Music/TikTok
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val relativeDir = if (isVideo) "${Environment.DIRECTORY_MOVIES}/TikTok" else "${Environment.DIRECTORY_MUSIC}/TikTok"
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
        } else {
            // Android 9 and below
            try {
                val publicDir = if (isVideo) {
                    File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "TikTok")
                } else {
                    File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "TikTok")
                }
                if (!publicDir.exists()) publicDir.mkdirs()
                val destFile = File(publicDir, fileName)
                sourceFile.copyTo(destFile, overwrite = true)
                MediaScannerConnection.scanFile(context, arrayOf(destFile.absolutePath), arrayOf(mimeType), null)
                return destFile.absolutePath
            } catch (_: Exception) {}
        }

        MediaScannerConnection.scanFile(context, arrayOf(sourcePath), arrayOf(mimeType), null)
        return sourcePath
    }
}
