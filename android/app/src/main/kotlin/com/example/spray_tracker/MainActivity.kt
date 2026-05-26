package com.example.spray_tracker

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBackupContent: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backupChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveBackupFile" -> {
                    val fileName =
                        call.argument<String>("fileName") ?: "spray-tracker-backup.spraygarden"
                    val content = call.argument<String>("content")
                    if (content == null) {
                        result.error("bad_args", "Backup content is missing.", null)
                        return@setMethodCallHandler
                    }
                    startBackupSave(fileName, content, result)
                }

                "loadBackupFile" -> startBackupLoad(result)
                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android API")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            requestCreateBackup -> finishBackupSave(resultCode, data?.data)
            requestOpenBackup -> finishBackupLoad(resultCode, data?.data)
        }
    }

    private fun startBackupSave(
        fileName: String,
        content: String,
        result: MethodChannel.Result,
    ) {
        if (!setPending(result)) return
        pendingBackupContent = content
        try {
            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "application/octet-stream"
                putExtra(Intent.EXTRA_TITLE, fileName)
            }
            startActivityForResult(intent, requestCreateBackup)
        } catch (exception: Exception) {
            finishWithError(
                "save_unavailable",
                exception.message ?: "No document provider is available.",
            )
        }
    }

    private fun startBackupLoad(result: MethodChannel.Result) {
        if (!setPending(result)) return
        try {
            val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                addCategory(Intent.CATEGORY_OPENABLE)
                type = "*/*"
            }
            startActivityForResult(intent, requestOpenBackup)
        } catch (exception: Exception) {
            finishWithError(
                "load_unavailable",
                exception.message ?: "No document provider is available.",
            )
        }
    }

    private fun finishBackupSave(resultCode: Int, uri: Uri?) {
        if (resultCode != Activity.RESULT_OK || uri == null) {
            finishWithSuccess(false)
            return
        }

        try {
            val content = pendingBackupContent ?: throw IOException("Backup content is missing.")
            val output = contentResolver.openOutputStream(uri)
                ?: throw IOException("Could not open backup file.")
            output.use { stream ->
                stream.write(content.toByteArray(Charsets.UTF_8))
                stream.flush()
            }
            finishWithSuccess(true)
        } catch (exception: Exception) {
            finishWithError(
                "save_failed",
                exception.message ?: "Backup file could not be written.",
            )
        }
    }

    private fun finishBackupLoad(resultCode: Int, uri: Uri?) {
        if (resultCode != Activity.RESULT_OK || uri == null) {
            finishWithSuccess(null)
            return
        }

        try {
            val input = contentResolver.openInputStream(uri)
                ?: throw IOException("Could not open backup file.")
            val content = input.bufferedReader(Charsets.UTF_8).use { reader ->
                reader.readText()
            }
            finishWithSuccess(content)
        } catch (exception: Exception) {
            finishWithError(
                "load_failed",
                exception.message ?: "Backup file could not be read.",
            )
        }
    }

    private fun setPending(result: MethodChannel.Result): Boolean {
        if (pendingResult != null) {
            result.error("busy", "A backup file operation is already running.", null)
            return false
        }
        pendingResult = result
        return true
    }

    private fun finishWithSuccess(value: Any?) {
        val result = pendingResult ?: return
        clearPending()
        result.success(value)
    }

    private fun finishWithError(code: String, message: String) {
        val result = pendingResult ?: return
        clearPending()
        result.error(code, message, null)
    }

    private fun clearPending() {
        pendingResult = null
        pendingBackupContent = null
    }

    companion object {
        private const val backupChannel = "spray_tracker/backup_files"
        private const val requestCreateBackup = 4101
        private const val requestOpenBackup = 4102
    }
}
