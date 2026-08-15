package com.rizz.tiktok_downloader

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.rizz.tiktok_downloader/media"
    private var methodChannel: MethodChannel? = null
    private var initialSharedText: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleSendIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleSendIntent(intent)
        initialSharedText?.let { text ->
            methodChannel?.invokeMethod("onSharedTextReceived", text)
        }
    }

    private fun handleSendIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_SEND && intent.type == "text/plain") {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT) 
                ?: intent.clipData?.getItemAt(0)?.text?.toString()
            if (!text.isNullOrEmpty()) {
                initialSharedText = text
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialSharedText" -> {
                    val text = initialSharedText
                    initialSharedText = null
                    result.success(text)
                }
                "saveToGallery" -> {
                    val filePath = call.argument<String>("filePath")
                    val mediaType = call.argument<String>("mediaType") ?: "video"
                    val title = call.argument<String>("title") ?: "MyDownloader_Media"
                    if (filePath == null) {
                        result.error("INVALID_PATH", "File path is null", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val savedPath = saveMediaToGallery(context, filePath, mediaType, title)
                        result.success(savedPath)
                    } catch (e: Exception) {
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
                "shareFile" -> {
                    val filePath = call.argument<String>("filePath")
                    val title = call.argument<String>("title") ?: "MyDownloader Media"
                    val mimeType = call.argument<String>("mimeType") ?: "video/mp4"
                    if (filePath != null) {
                        val success = shareFileNative(context, filePath, title, mimeType)
                        result.success(success)
                    } else {
                        result.success(false)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareFileNative(context: Context, filePath: String, title: String, mimeType: String): Boolean {
        return try {
            val file = File(filePath)
            if (!file.exists()) return false

            val uri: Uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            val shareIntent = Intent(Intent.ACTION_SEND).apply {
                type = mimeType
                putExtra(Intent.EXTRA_STREAM, uri)
                putExtra(Intent.EXTRA_TEXT, "Dibagikan via MyDownloader: $title")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(shareIntent, "Bagikan $title")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun saveMediaToGallery(context: Context, sourcePath: String, mediaType: String, title: String): String {
        val sourceFile = File(sourcePath)
        if (!sourceFile.exists()) return sourcePath

        val fileName = sourceFile.name
        val mimeType = when (mediaType) {
            "image", "photo", "photos" -> "image/jpeg"
            "audio" -> "audio/mpeg"
            else -> "video/mp4"
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            try {
                val relativeDir = when (mediaType) {
                    "image", "photo", "photos" -> "${Environment.DIRECTORY_PICTURES}/MyDownloader"
                    "audio" -> "${Environment.DIRECTORY_MUSIC}/MyDownloader"
                    else -> "${Environment.DIRECTORY_MOVIES}/MyDownloader"
                }

                val contentValues = ContentValues().apply {
                    put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                    put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                    put(MediaStore.MediaColumns.RELATIVE_PATH, relativeDir)
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val collection = when (mediaType) {
                    "image", "photo", "photos" -> MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                    "audio" -> MediaStore.Audio.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
                    else -> MediaStore.Video.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
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
            try {
                val publicDir = when (mediaType) {
                    "image", "photo", "photos" -> File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES), "MyDownloader")
                    "audio" -> File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MUSIC), "MyDownloader")
                    else -> File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES), "MyDownloader")
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
