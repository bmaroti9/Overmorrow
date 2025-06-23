import androidx.annotation.DrawableRes
import com.marotidev.overmorrow.R

val weatherConditionIcons: Map<String, Int> = mapOf(
    "Clear Night" to R.drawable.clear_night,
    "Partly Cloudy" to R.drawable.partly_cloudy,
    "Clear Sky" to R.drawable.clear_sky,
    "Overcast" to R.drawable.cloudy,
    "Haze" to R.drawable.haze,
    "Rain" to R.drawable.rain,
    "Sleet" to R.drawable.sleet,
    "Drizzle" to R.drawable.drizzle,
    "Thunderstorm" to R.drawable.thunderstorm,
    "Heavy Snow" to R.drawable.heavy_snow,
    "Fog" to R.drawable.fog,
    "Snow" to R.drawable.snow,
    "Heavy Rain" to R.drawable.heavy_rain,
    "Cloudy Night" to R.drawable.cloudy_night,
)

@DrawableRes // Annotation on the return type of the function
fun getIconForCondition(condition: String): Int {
    return weatherConditionIcons[condition] ?: R.drawable.clear_sky
}
