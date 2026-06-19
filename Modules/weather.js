(function() {
    // 1. Inject Styles
    const css = `
        @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Outfit:wght@300;400;700&display=swap');
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: #000000;
            color: #ffffff;
            font-family: 'Share Tech Mono', monospace;
            overflow: hidden;
            margin: 0;
            padding: 10px;
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        /* Scanline scan cyber-effect */
        body::before {
            content: " ";
            display: block;
            position: fixed;
            top: 0; left: 0; bottom: 0; right: 0;
            background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.25) 50%), 
                        linear-gradient(90deg, rgba(255, 0, 0, 0.05), rgba(0, 255, 0, 0.02), rgba(0, 0, 255, 0.05));
            background-size: 100% 4px, 3px 100%;
            z-index: 9999;
            pointer-events: none;
        }

        .darkos-weather-container {
            width: 100%;
            height: 100%;
            max-width: 100%;
            background: rgba(15, 10, 10, 0.85);
            border: 1px solid #ff0055;
            box-shadow: 0 0 15px rgba(255, 0, 85, 0.35), inset 0 0 10px rgba(255, 0, 85, 0.1);
            border-radius: 8px;
            padding: 15px;
            position: relative;
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .terminal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(255, 0, 85, 0.3);
            padding-bottom: 6px;
            margin-bottom: 10px;
            font-size: 10px;
            letter-spacing: 1px;
            color: #ff0055;
            text-shadow: 0 0 3px rgba(255, 0, 85, 0.5);
            flex-shrink: 0;
        }

        .terminal-header .dot {
            width: 6px;
            height: 6px;
            background-color: #ff0055;
            border-radius: 50%;
            display: inline-block;
            margin-right: 6px;
            box-shadow: 0 0 8px #ff0055;
            animation: pulse-dot 1.5s infinite alternate;
        }

        @keyframes pulse-dot {
            0% { opacity: 0.4; }
            100% { opacity: 1; }
        }

        .search-row {
            display: flex;
            gap: 6px;
            margin-bottom: 10px;
            flex-shrink: 0;
        }

        .search-input {
            flex: 1;
            background: rgba(0, 0, 0, 0.6);
            border: 1px solid rgba(255, 0, 85, 0.4);
            color: #ffffff;
            font-family: 'Share Tech Mono', monospace;
            padding: 6px 10px;
            font-size: 12px;
            border-radius: 4px;
            outline: none;
            transition: all 0.3s;
        }

        .search-input:focus {
            border-color: #ff0055;
            box-shadow: 0 0 6px rgba(255, 0, 85, 0.4);
        }

        .search-btn {
            background: rgba(255, 0, 85, 0.15);
            border: 1px solid #ff0055;
            color: #ff0055;
            font-family: 'Share Tech Mono', monospace;
            padding: 6px 12px;
            font-size: 11px;
            font-weight: bold;
            cursor: pointer;
            border-radius: 4px;
            transition: all 0.3s;
            text-transform: uppercase;
        }

        .search-btn:hover {
            background: #ff0055;
            color: #ffffff;
            box-shadow: 0 0 8px rgba(255, 0, 85, 0.5);
        }

        .main-weather-display {
            text-align: center;
            position: relative;
            flex: 1;
            overflow-y: auto;
            display: flex;
            flex-direction: column;
            justify-content: flex-start;
            padding: 5px 0;
        }

        /* Customize scrollbar */
        .main-weather-display::-webkit-scrollbar {
            width: 4px;
        }
        .main-weather-display::-webkit-scrollbar-track {
            background: rgba(0,0,0,0.3);
        }
        .main-weather-display::-webkit-scrollbar-thumb {
            background: #ff0055;
            border-radius: 2px;
        }

        .location-title {
            font-family: 'Outfit', sans-serif;
            font-size: 22px;
            font-weight: 700;
            letter-spacing: 1px;
            margin-bottom: 2px;
            text-transform: uppercase;
            text-shadow: 0 0 5px rgba(255, 255, 255, 0.2);
            flex-shrink: 0;
        }

        .gps-coords {
            font-size: 9px;
            color: rgba(255, 0, 85, 0.7);
            margin-bottom: 8px;
            flex-shrink: 0;
        }

        .weather-icon-container {
            font-size: 52px;
            line-height: 1;
            margin: 6px 0;
            filter: drop-shadow(0 0 8px rgba(255, 255, 255, 0.2));
            animation: float-icon 3s ease-in-out infinite;
            flex-shrink: 0;
        }

        @keyframes float-icon {
            0% { transform: translateY(0px); }
            50% { transform: translateY(-6px); }
            100% { transform: translateY(0px); }
        }

        .temp-row {
            display: flex;
            justify-content: center;
            align-items: baseline;
            margin-bottom: 4px;
            flex-shrink: 0;
        }

        .temp-val {
            font-family: 'Outfit', sans-serif;
            font-size: 46px;
            font-weight: 300;
            line-height: 1;
            cursor: pointer;
        }

        .temp-unit {
            font-size: 20px;
            color: #ff0055;
            margin-left: 2px;
            cursor: pointer;
        }

        .weather-desc {
            font-size: 14px;
            color: rgba(255, 255, 255, 0.95);
            text-transform: uppercase;
            letter-spacing: 1px;
            margin-bottom: 12px;
            flex-shrink: 0;
        }

        .weather-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 8px;
            border-top: 1px solid rgba(255, 0, 85, 0.2);
            border-bottom: 1px solid rgba(255, 0, 85, 0.2);
            padding: 10px 0;
            margin-bottom: 12px;
            flex-shrink: 0;
        }

        .grid-item {
            display: flex;
            flex-direction: column;
            align-items: center;
            padding: 6px;
            background: rgba(255, 255, 255, 0.02);
            border: 1px solid rgba(255, 0, 85, 0.1);
            border-radius: 4px;
        }

        .grid-label {
            font-size: 8px;
            color: rgba(255, 0, 85, 0.75);
            margin-bottom: 2px;
            text-transform: uppercase;
        }

        .grid-value {
            font-size: 13px;
            font-weight: bold;
        }

        .forecast-title {
            font-size: 10px;
            color: #ff0055;
            text-transform: uppercase;
            margin-bottom: 8px;
            letter-spacing: 1px;
            display: flex;
            align-items: center;
            gap: 6px;
            flex-shrink: 0;
            text-align: left;
        }

        .forecast-row {
            display: flex;
            justify-content: space-between;
            gap: 6px;
            flex-shrink: 0;
        }

        .forecast-card {
            flex: 1;
            background: rgba(20, 10, 10, 0.5);
            border: 1px solid rgba(255, 0, 85, 0.15);
            border-radius: 4px;
            padding: 8px 4px;
            text-align: center;
            transition: all 0.3s;
        }

        .forecast-card:hover {
            border-color: #ff0055;
            background: rgba(255, 0, 85, 0.05);
            box-shadow: 0 0 6px rgba(255, 0, 85, 0.25);
        }

        .forecast-day {
            font-size: 9px;
            color: rgba(255, 255, 255, 0.7);
            margin-bottom: 2px;
            text-transform: uppercase;
        }

        .forecast-icon {
            font-size: 18px;
            margin: 4px 0;
        }

        .forecast-temp {
            font-size: 10px;
            font-weight: bold;
        }

        .forecast-temp-min {
            font-size: 8px;
            color: rgba(255, 255, 255, 0.4);
            margin-left: 2px;
        }

        .loading-overlay {
            position: absolute;
            top: 0; left: 0; right: 0; bottom: 0;
            background: rgba(0, 0, 0, 0.95);
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            gap: 15px;
            z-index: 10;
            border-radius: 8px;
        }

        .loader-ring {
            width: 32px;
            height: 32px;
            border: 2px solid rgba(255, 0, 85, 0.1);
            border-radius: 50%;
            border-top-color: #ff0055;
            animation: spin 1s linear infinite;
            box-shadow: 0 0 8px rgba(255, 0, 85, 0.3);
        }

        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }

        .loader-text {
            font-size: 10px;
            color: #ff0055;
            letter-spacing: 2px;
            animation: blink 1s infinite alternate;
        }

        @keyframes blink {
            0% { opacity: 0.3; }
            100% { opacity: 1; }
        }

        .error-message {
            color: #ff3333;
            text-shadow: 0 0 5px rgba(255, 51, 51, 0.4);
            font-size: 10px;
            text-align: center;
            margin-top: 8px;
            flex-shrink: 0;
        }
    `;

    // Inject Styles into Document Head
    const styleEl = document.createElement('style');
    styleEl.innerHTML = css;
    document.head.appendChild(styleEl);

    // Weather code mapping
    const weatherCodes = {
        0: { icon: '☀️', desc: 'Clear Sky' },
        1: { icon: '🌤️', desc: 'Mainly Clear' },
        2: { icon: '⛅', desc: 'Partly Cloudy' },
        3: { icon: '☁️', desc: 'Overcast' },
        45: { icon: '🌫️', desc: 'Foggy' },
        48: { icon: '🌫️', desc: 'Depositing Rime Fog' },
        51: { icon: '🌧️', desc: 'Light Drizzle' },
        53: { icon: '🌧️', desc: 'Moderate Drizzle' },
        55: { icon: '🌧️', desc: 'Dense Drizzle' },
        56: { icon: '🌧️', desc: 'Light Freezing Drizzle' },
        57: { icon: '🌧️', desc: 'Dense Freezing Drizzle' },
        61: { icon: '🌧️', desc: 'Slight Rain' },
        63: { icon: '🌧️', desc: 'Moderate Rain' },
        65: { icon: '🌧️', desc: 'Heavy Rain' },
        66: { icon: '🌧️', desc: 'Light Freezing Rain' },
        67: { icon: '🌧️', desc: 'Heavy Freezing Rain' },
        71: { icon: '❄️', desc: 'Slight Snow' },
        73: { icon: '❄️', desc: 'Moderate Snow' },
        75: { icon: '❄️', desc: 'Heavy Snow' },
        77: { icon: '❄️', desc: 'Snow Grains' },
        80: { icon: '🌧️', desc: 'Slight Rain Showers' },
        81: { icon: '🌧️', desc: 'Moderate Rain Showers' },
        82: { icon: '🌧️', desc: 'Heavy Rain Showers' },
        85: { icon: '❄️', desc: 'Slight Snow Showers' },
        86: { icon: '❄️', desc: 'Heavy Snow Showers' },
        95: { icon: '⛈️', desc: 'Thunderstorm' },
        96: { icon: '⛈️', desc: 'Thunderstorm with Hail' },
        99: { icon: '⛈️', desc: 'Heavy Thunderstorm' }
    };

    // State Variables
    let isCelsius = true;
    let weatherData = null;
    let currentCoords = { lat: 37.7749, lon: -122.4194 }; // SF default
    let currentCity = "SAN FRANCISCO, USA";

    // Create Main UI elements
    const appContainer = document.createElement('div');
    appContainer.className = 'darkos-weather-container';
    document.body.appendChild(appContainer);

    function buildUI() {
        appContainer.innerHTML = `
            <div class="terminal-header">
                <div><span class="dot"></span>DARKOS WEATHER SERVICE</div>
                <div id="clock">00:00:00</div>
            </div>
            
            <div class="search-row">
                <input type="text" class="search-input" id="city-search" placeholder="SEARCH SATELLITE CITY..." autocomplete="off">
                <button class="search-btn" id="search-btn">LOCATE</button>
            </div>

            <div class="main-weather-display">
                <div class="loading-overlay" id="loading-spinner">
                    <div class="loader-ring"></div>
                    <div class="loader-text">ESTABLISHING CONNECTION...</div>
                </div>
                
                <div class="location-title" id="loc-name">--</div>
                <div class="gps-coords" id="loc-coords">LAT: -- | LON: --</div>
                
                <div class="weather-icon-container" id="weather-icon">--</div>
                
                <div class="temp-row">
                    <span class="temp-val" id="temp-value">--</span>
                    <span class="temp-unit" id="temp-unit">°C</span>
                </div>
                
                <div class="weather-desc" id="weather-desc">--</div>
                
                <div class="weather-grid">
                    <div class="grid-item">
                        <span class="grid-label">FEELS LIKE</span>
                        <span class="grid-value" id="feels-like">--</span>
                    </div>
                    <div class="grid-item">
                        <span class="grid-label">HUMIDITY</span>
                        <span class="grid-value" id="humidity">--</span>
                    </div>
                    <div class="grid-item">
                        <span class="grid-label">WIND VECTOR</span>
                        <span class="grid-value" id="wind-speed">--</span>
                    </div>
                    <div class="grid-item">
                        <span class="grid-label">PRECIPITATION</span>
                        <span class="grid-value" id="precip">--</span>
                    </div>
                </div>

                <div class="forecast-title">
                    <span>📡</span> 3-DAY WEATHER PROJECTIONS
                </div>
                <div class="forecast-row" id="forecast-container">
                    <div class="forecast-card">
                        <div class="forecast-day">--</div>
                        <div class="forecast-icon">--</div>
                        <div class="forecast-temp">--</div>
                    </div>
                    <div class="forecast-card">
                        <div class="forecast-day">--</div>
                        <div class="forecast-icon">--</div>
                        <div class="forecast-temp">--</div>
                    </div>
                    <div class="forecast-card">
                        <div class="forecast-day">--</div>
                        <div class="forecast-icon">--</div>
                        <div class="forecast-temp">--</div>
                    </div>
                </div>
                <div class="error-message" id="error-box" style="display: none;"></div>
            </div>
        `;

        // Add event listeners
        document.getElementById('search-btn').addEventListener('click', handleSearch);
        document.getElementById('city-search').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') handleSearch();
        });
        
        // Temperature unit toggle
        document.getElementById('temp-value').addEventListener('click', toggleTempUnit);
        document.getElementById('temp-unit').addEventListener('click', toggleTempUnit);

        // Start clock
        updateClock();
        setInterval(updateClock, 1000);
    }

    // Digital clock in terminal header
    function updateClock() {
        const d = new Date();
        const h = String(d.getHours()).padStart(2, '0');
        const m = String(d.getMinutes()).padStart(2, '0');
        const s = String(d.getSeconds()).padStart(2, '0');
        const clockEl = document.getElementById('clock');
        if (clockEl) clockEl.innerText = `${h}:${m}:${s}`;
    }

    // Toggle units between Celsius and Fahrenheit
    function toggleTempUnit() {
        if (!weatherData) return;
        isCelsius = !isCelsius;
        renderWeather();
    }

    // Show/hide spinner
    function setLoader(show, text = "ESTABLISHING CONNECTION...") {
        const loader = document.getElementById('loading-spinner');
        if (loader) {
            loader.style.display = show ? 'flex' : 'none';
            const textEl = loader.querySelector('.loader-text');
            if (textEl) textEl.innerText = text;
        }
    }

    // Set Error Text
    function funcShowError(msg) {
        const errorBox = document.getElementById('error-box');
        if (errorBox) {
            if (msg) {
                errorBox.innerText = `ERROR: ${msg.toUpperCase()}`;
                errorBox.style.display = 'block';
            } else {
                errorBox.style.display = 'none';
            }
        }
    }

    // Convert Celsius to Fahrenheit
    function toFahrenheit(c) {
        return Math.round((c * 9) / 5 + 32);
    }

    // Format temperature string
    function formatTemp(c) {
        return isCelsius ? `${Math.round(c)}` : `${toFahrenheit(c)}`;
    }

    // Render weather data to UI
    function renderWeather() {
        if (!weatherData) return;
        
        funcShowError(null);

        // Current weather elements
        const current = weatherData.current;
        const currentCode = current.weather_code;
        const mappedCode = weatherCodes[currentCode] || { icon: '❓', desc: 'Unknown' };

        document.getElementById('loc-name').innerText = currentCity;
        document.getElementById('loc-coords').innerText = `LAT: ${currentCoords.lat.toFixed(4)} | LON: ${currentCoords.lon.toFixed(4)}`;
        document.getElementById('weather-icon').innerText = mappedCode.icon;
        document.getElementById('temp-value').innerText = formatTemp(current.temperature_2m);
        document.getElementById('temp-unit').innerText = isCelsius ? '°C' : '°F';
        document.getElementById('weather-desc').innerText = mappedCode.desc;

        document.getElementById('feels-like').innerText = `${formatTemp(current.apparent_temperature)}°${isCelsius ? 'C' : 'F'}`;
        document.getElementById('humidity').innerText = `${current.relative_humidity_2m}%`;
        document.getElementById('wind-speed').innerText = `${current.wind_speed_10m} KM/H`;
        document.getElementById('precip').innerText = `${current.precipitation} MM`;

        // Forecast elements
        const daily = weatherData.daily;
        const forecastContainer = document.getElementById('forecast-container');
        forecastContainer.innerHTML = '';

        // Render next 3 days
        const daysOfWeek = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
        for (let i = 1; i <= 3; i++) {
            if (!daily.time[i]) break;
            
            const date = new Date(daily.time[i] + 'T00:00:00');
            const dayLabel = daysOfWeek[date.getDay()];
            const code = daily.weather_code[i];
            const mappedDailyCode = weatherCodes[code] || { icon: '❓', desc: 'Unknown' };
            const maxTemp = formatTemp(daily.temperature_2m_max[i]);
            const minTemp = formatTemp(daily.temperature_2m_min[i]);

            const card = document.createElement('div');
            card.className = 'forecast-card';
            card.innerHTML = `
                <div class="forecast-day">${dayLabel}</div>
                <div class="forecast-icon">${mappedDailyCode.icon}</div>
                <div class="forecast-temp">${maxTemp}°<span class="forecast-temp-min">${minTemp}°</span></div>
            `;
            forecastContainer.appendChild(card);
        }
    }

    // Fetch Weather from Open-Meteo
    async function fetchWeather(lat, lon) {
        setLoader(true, "PINGING METEOROLOGY NET...");
        try {
            const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto`;
            const response = await fetch(url);
            if (!response.ok) throw new Error("Weather terminal link failed.");
            weatherData = await response.json();
            renderWeather();
        } catch (err) {
            funcShowError(err.message);
        } finally {
            setLoader(false);
        }
    }

    // Locate City via geocoding
    async function handleSearch() {
        const query = document.getElementById('city-search').value.trim();
        if (!query) return;

        setLoader(true, `SEARCHING SECTOR [${query.toUpperCase()}]...`);
        try {
            const geoUrl = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(query)}&count=1&language=en&format=json`;
            const response = await fetch(geoUrl);
            if (!response.ok) throw new Error("Search uplink failed.");
            const data = await response.json();
            
            if (!data.results || data.results.length === 0) {
                throw new Error("Location coordinates not mapped.");
            }

            const result = data.results[0];
            currentCoords.lat = result.latitude;
            currentCoords.lon = result.longitude;
            
            const countryStr = result.country ? `, ${result.country}` : '';
            currentCity = `${result.name}${countryStr}`.toUpperCase();

            // Clear search field focus
            document.getElementById('city-search').blur();
            
            // Load weather for coordinates
            fetchWeather(currentCoords.lat, currentCoords.lon);
        } catch (err) {
            funcShowError(err.message);
            setLoader(false);
        }
    }

    // Try Geo-location
    function autoLocate() {
        setLoader(true, "ACQUIRING POSITION SYSTEM GPS...");
        
        // Browser Geolocation
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                async (position) => {
                    currentCoords.lat = position.coords.latitude;
                    currentCoords.lon = position.coords.longitude;
                    currentCity = "ACQUIRED COORDINATES";
                    
                    // Attempt reverse geocoding via free osm API for better city label
                    try {
                        const revUrl = `https://nominatim.openstreetmap.org/reverse?lat=${currentCoords.lat}&lon=${currentCoords.lon}&format=json&zoom=10`;
                        const res = await fetch(revUrl, {
                            headers: { 'User-Agent': 'DarkOS-Weather-Agent' }
                        });
                        if (res.ok) {
                            const details = await res.json();
                            const city = details.address.city || details.address.town || details.address.village || details.address.county || "LOCAL CLUSTER";
                            const country = details.address.country || "";
                            currentCity = `${city}${country ? ', ' + country : ''}`.toUpperCase();
                        }
                    } catch(e) {
                        // ignore reverse geocoding fail, fallback is fine
                    }

                    fetchWeather(currentCoords.lat, currentCoords.lon);
                },
                () => {
                    // Fallback to IP geolocation
                    fallbackToIPGeo();
                },
                { timeout: 5000 }
            );
        } else {
            fallbackToIPGeo();
        }
    }

    // Fallback Geolocation using free API
    async function fallbackToIPGeo() {
        setLoader(true, "GPS FAILURE. QUERYING NET ROUTE IP...");
        try {
            const ipUrl = 'https://ipapi.co/json/';
            const response = await fetch(ipUrl);
            if (!response.ok) throw new Error("IP Geolocation endpoint refused.");
            const data = await response.json();
            
            currentCoords.lat = data.latitude || 37.7749;
            currentCoords.lon = data.longitude || -122.4194;
            
            const city = data.city || "SAN FRANCISCO";
            const country = data.country_name || "USA";
            currentCity = `${city}, ${country}`.toUpperCase();
            
            fetchWeather(currentCoords.lat, currentCoords.lon);
        } catch (err) {
            // Ultimate fallback to default SF
            currentCoords = { lat: 37.7749, lon: -122.4194 };
            currentCity = "SAN FRANCISCO, USA";
            funcShowError("Network geolocation unavailable. Loading defaults.");
            fetchWeather(currentCoords.lat, currentCoords.lon);
        }
    }

    // Initialization
    buildUI();
    autoLocate();
})();
