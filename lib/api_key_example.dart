/*
Copyright (C) <2025>  <Balint Maroti>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

//USAGE:
//To test this project with your own api key, first rename this file to api_key.dart.
//Then add your own api keys below:

//IMPORTANT: Overmorrow has 3 weather providers (open-meteo and weatherapi and met-norway)
//but only weatherapi requires an api key. You don't need an api key for open-meteo or met-norway.

const String wapi_key = "YourWeatherApiKey"; //your api key from weatherapi.com
//the app works without this if you only use the open-meteo or met-norway providers

const String access_key = "YourUnsplashApiKey"; //your api key from unsplash.com
//the app works without this if you set the image source to asset

const String timezonedbKey = "YourTimezonedbKey"; //your api key from timezonedb.com
//the app works without this is you use open-meteo as weather provider
//both the others don't return local times so they need this instead