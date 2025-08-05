import androidx.annotation.DrawableRes
import com.marotidev.overmorrow.R

val weatherConditionIcons: Map<String, Int> = mapOf(
    "Clear Night" to R.drawable.weather_clear_night,
    "Partly Cloudy" to R.drawable.weather_partly_cloudy,
    "Clear Sky" to R.drawable.weather_clear_sky,
    "Overcast" to R.drawable.weather_cloudy,
    "Haze" to R.drawable.weather_haze,
    "Rain" to R.drawable.weather_rain,
    "Sleet" to R.drawable.weather_sleet,
    "Drizzle" to R.drawable.weather_drizzle,
    "Thunderstorm" to R.drawable.weather_thunderstorm,
    "Heavy Snow" to R.drawable.weather_heavy_snow,
    "Fog" to R.drawable.weather_fog,
    "Snow" to R.drawable.weather_snow,
    "Heavy Rain" to R.drawable.weather_heavy_rain,
    "Cloudy Night" to R.drawable.weather_cloudy_night,
)

@DrawableRes // Annotation on the return type of the function
fun getIconForCondition(condition: String): Int {
    return weatherConditionIcons[condition] ?: R.drawable.weather_clear_sky
}
