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
//Then add your own api key from weatherapi.com below:

//IMPORTANT: Overmorrow has two weather providers (open-meteo and weatherapi)
//but only weatherapi requires an api key. You don't need an api key for open-meteo.

const String wapi_key = "YourWeatherApiKey"; //your api key from weatherapi.com
//the app works without this if you only use the open-meteo provider

const String access_key = "YourUnsplashApiKey"; //your api key from unsplash.com
//the app works without this if you set the image source to asset