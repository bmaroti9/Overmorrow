import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.text.TextPaint
import android.util.TypedValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.unit.TextUnit
import androidx.core.content.res.ResourcesCompat

import androidx.core.graphics.createBitmap


fun Context.textAsBitmap(
    text: String,
    fontSize: TextUnit,
    color: Color = Color.Black,
    letterSpacing: Float = 0.1f,
    font: Int
): Bitmap {
    val paint = TextPaint(Paint.ANTI_ALIAS_FLAG)

    paint.textSize = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_SP,
        fontSize.value, // Get the float value from TextUnit
        this.resources.displayMetrics // Pass the DisplayMetrics
    )
    paint.color = color.toArgb()
    paint.letterSpacing = letterSpacing
    paint.typeface = ResourcesCompat.getFont(this, font)

    val baseline = -paint.ascent()
    val width = (paint.measureText(text)).toInt()
    val height = (baseline + paint.descent()).toInt()
    val image = createBitmap(width, height)
    val canvas = Canvas(image)
    canvas.drawText(text, 0f, baseline, paint)
    return image
}