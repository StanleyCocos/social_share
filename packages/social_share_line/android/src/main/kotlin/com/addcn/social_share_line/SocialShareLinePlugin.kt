package com.addcn.social_share_line

import android.app.Activity
import android.content.ComponentName
import android.content.ContentUris
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Point
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import android.webkit.*
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.*
import java.lang.ref.WeakReference
import java.net.URL
import android.widget.FrameLayout

import android.view.Display
import java.net.URLEncoder


const val TAG: String = "FlutterSharePlugin"

/** FlutterSharePlugin */
public class SocialShareLinePlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private var channel: MethodChannel? = null
    private var activityRef: WeakReference<Activity>? = null
    private var contextRef: WeakReference<Context>? = null
    private var resultOutput: Result? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        onAttachedToEngine(flutterPluginBinding.applicationContext, flutterPluginBinding.binaryMessenger)
    }

    private fun setActivity(flutterActivity: Activity?) {
        activityRef = WeakReference<Activity>(flutterActivity)
    }

    private fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?) {
        if (intent == null) return
    }

    private fun onAttachedToEngine(context: Context, binaryMessenger: BinaryMessenger) {
        contextRef = WeakReference<Context>(context)
        channel = MethodChannel(binaryMessenger, "social_share_line")
        channel?.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        resultOutput = result
        if (call.method == "share") {
            val platform = call.argument<String>("platform")
            val text = call.argument<String>("text")
            val image = call.argument<String>("image")

            Log.d("platform", "$platform")
            if (platform == "SharePlatform.Line") {
                shareToLine(text, image)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
    }

    override fun onDetachedFromActivity() {
        contextRef?.clear()
        activityRef?.clear()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        updateActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
    }

    private fun updateActivity(binding: ActivityPluginBinding) {
        binding.addActivityResultListener { requestCode, resultCode, intent ->
                false
        }
        activityRef = WeakReference(binding.activity)
    }





    private fun shareToLine(text: String?, image: String?) {
        Log.d(TAG, "shareToLine =>  text: $text == image: $image")
        val map = HashMap<String, Any>()
        map["state"] = 0
        map["msg"] = "success"
        resultOutput?.success(map)

        if (!text.isNullOrEmpty()) {
            shareTextLine(activityRef?.get(), text)
            return
        }
        if (image?.startsWith("http") == true) {
            val uri = getUriFromUrl(activityRef?.get(), image)
            shareImageLine(activityRef?.get(), uri)
            return
        }

        val uri = getUriForFile(activityRef?.get(), File(image))
        shareImageLine(activityRef?.get(), uri)
    }



    /************************ Line 分享 ************************/

    private val linePackageName: String = "jp.naver.line.android"
    private val lineOldClass: String = "jp.naver.line.android.activity.selectchat.SelectChatActivity"
    private val lineOldClass2: String = "jp.naver.line.android.activity.selectchat.SelectChatActivityLaunchActivity"
    private val lineNewClass: String = "com.linecorp.line.share.common.view.FullPickerLaunchActivity"
    private val lineClassList: List<String> = listOf(lineNewClass, lineOldClass2, lineOldClass)

    private fun shareTextLine(activity: Activity?, text: String?) {
        if (activity == null) return
        if (!checkPackageExist(activity, "jp.naver.line.android")) {
            val intent = Intent()
            intent.setClass(activity, WebViewActivity::class.java)
            intent.putExtra("text", "https://line.me/R/share?text=$text")
            activity.startActivity(intent)
            return
        }

        val intent = Intent()
        intent.action = Intent.ACTION_SEND
        intent.type = "text/plain"
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        intent.putExtra(Intent.EXTRA_TEXT, text)
        for (lineClass in lineClassList) {
            intent.component = ComponentName(linePackageName, lineClass)
            if (activity.packageManager.resolveActivity(intent, 0) != null) {
                activity.startActivity(intent)
                return
            }
        }
    }

    private fun shareImageLine(activity: Activity?, uri: Uri?) {
        if (activity == null) return
        if (!checkPackageExist(activity, "jp.naver.line.android")) {
            val intent = Intent()
            intent.setClass(activity, WebViewActivity::class.java)
            intent.putExtra("text", "https://line.me/R/share?text=$uri")
            activity.startActivity(intent)
            return
        }

        val intent = Intent()
        intent.action = Intent.ACTION_SEND
        intent.type = "image/*"
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        intent.putExtra(Intent.EXTRA_STREAM, uri)
        for (lineClass in lineClassList) {
            intent.component = ComponentName(linePackageName, lineClass)
            if (activity.packageManager.resolveActivity(intent, 0) != null) {
                activity.startActivity(intent)
                return
            }
        }
    }

    /************************ Facebook 分享 ************************/




    /************************ 获取图片相关方法 ************************/

    // 图片 url 转 Uri
    private fun getUriFromUrl(activity: Activity?, url: String): Uri {
        val file = File.createTempFile("temp_", ".png", activity?.cacheDir)
        val runnable = Runnable {
            run {
                try {
                    val imageUrl = URL(url)
                    val conn = imageUrl.openConnection()
                    conn.connectTimeout = 5000
                    conn.doInput = true
                    conn.connect()
                    val inputStream = conn.getInputStream()
                    val fos = FileOutputStream(file)
                    val buffer = ByteArray(1024)
                    var len = 0
                    while (inputStream.read(buffer).also { len = it } != -1) {
                        fos.write(buffer, 0, len)
                    }
                    inputStream.close()
                    fos.close()
                } catch (e: IOException) {
                }
            }
        }
        Thread(runnable).start()
        Log.e("==", "$file")
        return getUriForFile(activity, file)
    }

    // 图片 File 转 Uri
    private fun getUriForFile(activity: Activity?, file: File?): Uri {
        if (activity == null || file == null) return Uri.EMPTY
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                FileProvider.getUriForFile(
                    activity.applicationContext,
                    "${activity.packageName}.social_share_line.fileprovider",
                    file
                )
            } else {
                Uri.fromFile(file)
            }
        } catch (e: Exception) {
            Uri.EMPTY
        }
    }

    // 图片 url 转 Bitmap


    // 图片 url 转 图片路径
    private fun getPathFromUrl(activity: Activity?, url: String): String {
        val file = File.createTempFile("temp_", ".png", activity?.cacheDir)
        val runnable = Runnable {
            run {
                try {
                    val imageUrl = URL(url)
                    val conn = imageUrl.openConnection()
                    conn.connectTimeout = 5000
                    conn.doInput = true
                    conn.connect()
                    val inputStream = conn.getInputStream()
                    val fos = FileOutputStream(file)
                    val buffer = ByteArray(1024)
                    var len = 0
                    while (inputStream.read(buffer).also { len = it } != -1) {
                        fos.write(buffer, 0, len)
                    }
                    inputStream.close()
                    fos.close()
                } catch (e: IOException) {
                }
            }
        }
        Thread(runnable).start()
        Log.e("==", "$file")
        return file.absolutePath
    }

    // 图片 路径 转 Uri
    private fun getMediaUriFromPath(activity: Activity?, path: String?): Uri {
        if (path.isNullOrEmpty()) return Uri.EMPTY
        val mediaUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        val cursor = activity?.contentResolver?.query(
            mediaUri, null,
            MediaStore.Images.Media.DISPLAY_NAME + "= ?",
            arrayOf(path.substring(path.lastIndexOf("/") + 1)), null
        )
        var uri: Uri = Uri.EMPTY
        if (cursor?.moveToFirst() == true) {
            val columnId = cursor.getColumnIndex(MediaStore.Images.Media._ID);
            uri = ContentUris.withAppendedId(
                mediaUri,
                cursor.getLong(if (columnId >= 0) columnId else 0)
            )
        }
        cursor?.close()
        return uri
    }

    // 图片 Uri 转 Bitmap
    private fun getBitmapFromUri(activity: Activity?, uri: Uri): Bitmap? {
        if (activity == null) return null
        val bitmap: Bitmap?
        try {
            // 解析并获取图片配置项
            var input: InputStream? = activity.contentResolver.openInputStream(uri)
            val onlyBoundsOptions = BitmapFactory.Options()
            onlyBoundsOptions.inJustDecodeBounds = true
            onlyBoundsOptions.inDither = true // optional
            onlyBoundsOptions.inPreferredConfig = Bitmap.Config.ARGB_8888 // optional
            BitmapFactory.decodeStream(input, null, onlyBoundsOptions)
            input?.close()

            // 根据图片的宽高对图片的缩放比率进行设置（防止图片过大造成OOM）
            val originalWidth = onlyBoundsOptions.outWidth
            val originalHeight = onlyBoundsOptions.outHeight
            if (originalWidth == -1 || originalHeight == -1) return null
            // Image resolution is based on 720x1280
            val maxHeight = 1280f // The height is set as 800f here
            val maxWidth = 720f // Set the width here to 480f
            // Zoom ratio. Because it is a fixed scale, only one data of height or width is used for calculation
            var ratio = 1 // ratio 为 1 表示不缩放
            if (originalWidth > originalHeight && originalWidth > maxWidth) { // If the width is large, scale according to the fixed size of the width
                ratio = (originalWidth / maxWidth).toInt()
            } else if (originalWidth < originalHeight && originalHeight > maxHeight) { // If the height is large, scale according to the fixed size of the width
                ratio = (originalHeight / maxHeight).toInt()
            }
            if (ratio <= 0) ratio = 1

            // 对图片进行缩放并转为Bitmap
            val bitmapOptions = BitmapFactory.Options()
            bitmapOptions.inSampleSize = ratio // Set scaling
            bitmapOptions.inDither = true // optional
            bitmapOptions.inPreferredConfig = Bitmap.Config.ARGB_8888 // optional
            input = activity.contentResolver.openInputStream(uri)
            bitmap = BitmapFactory.decodeStream(input, null, bitmapOptions)
            input?.close()
        } catch (e: Exception) {
            return null
        }

        return compressImage(bitmap) // Mass compression again
    }

    // 对图片进行压缩，防止OOM
    private fun compressImage(image: Bitmap?): Bitmap? {
        val bios = ByteArrayOutputStream()
        // 图片质量压缩，这里的100表示不压缩，最终将压缩的数据存储到 BIOS
        image?.compress(Bitmap.CompressFormat.JPEG, 100, bios)
        var options = 100
        // 对图片进行循环压缩：压缩后的图片如果大于300kb，则再次进行压缩
        while (bios.toByteArray().size / 1024 > 300) {
            bios.reset() //Reset the BIOS to clear it
            // First parameter: picture format, second parameter: picture quality, 100 is the highest, 0 is the worst, third parameter: save the compressed data stream
            // Here, the compression options are used to store the compressed data in the BIOS
            image?.compress(Bitmap.CompressFormat.JPEG, options, bios)
            options -= 10 // 10 less each time
        }
        // Store the compressed data in ByteArrayInputStream
        val bitmapInputStream = ByteArrayInputStream(bios.toByteArray())
        return BitmapFactory.decodeStream(bitmapInputStream, null, null)
    }

    private fun checkPackageExist(context: Context?, packageName: String): Boolean {
        if (packageName.isEmpty() || context == null) return false
        return try {
            val packageInfo = context.packageManager.getPackageInfo(packageName, 0)
            packageInfo != null
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }
}
