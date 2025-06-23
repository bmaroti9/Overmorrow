import androidx.annotation.FontRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.LocalContext
import androidx.glance.unit.ColorProvider

@Composable
fun GlanceText(
    text: String,
    @FontRes font: Int,
    fontSize: TextUnit,
    modifier: GlanceModifier = GlanceModifier,
    color: ColorProvider,
    letterSpacing: TextUnit = 0.1.sp,
) {

    val context = LocalContext.current

    val resolvedColor = color.getColor(context)

    Image(
        modifier = modifier,
        provider = ImageProvider(
            LocalContext.current.textAsBitmap(
                text = text,
                fontSize = fontSize,
                color = resolvedColor,
                font = font,
                letterSpacing = letterSpacing.value
            )
        ),
        contentDescription = null,
    )
}