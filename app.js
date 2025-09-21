// -----------------------------
// Initialize Leaflet Map
// -----------------------------
const map = L.map("map").setView([20.5937, 78.9629], 5); // Center on India

// Define tile layers for Dark and Light modes
const darkTiles = L.tileLayer(
  "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png",
  {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a>, &copy; <a href="https://carto.com/">CARTO</a>',
    subdomains: "abcd",
    maxZoom: 19,
  }
);

const lightTiles = L.tileLayer(
  "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
  {
    attribution:
      '&copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a>, &copy; <a href="https://carto.com/">CARTO</a>',
    subdomains: "abcd",
    maxZoom: 19,
  }
);

// Start in Dark mode
darkTiles.addTo(map);

// -----------------------------
// Define Color Zones
// -----------------------------
const safeZone = L.circle([28.7041, 77.1025], {
  // Delhi
  color: "green",
  fillColor: "lightgreen",
  fillOpacity: 0.4,
  radius: 20000,
})
  .addTo(map)
  .bindPopup("✅ Safe Zone");

const dangerZone = L.circle([19.076, 72.8777], {
  // Mumbai
  color: "orange",
  fillColor: "orange",
  fillOpacity: 0.5,
  radius: 30000,
})
  .addTo(map)
  .bindPopup("⚠️ Danger Zone");

const redAlertZone = L.circle([13.0827, 80.2707], {
  // Chennai
  color: "red",
  fillColor: "red",
  fillOpacity: 0.6,
  radius: 40000,
})
  .addTo(map)
  .bindPopup("🚨 Red Alert Zone");

// -----------------------------
// Fetch Live Weather Data (OpenWeatherMap)
// -----------------------------
const apiKey = "YOUR_OPENWEATHERMAP_API_KEY"; // replace with your key
const city = "Mumbai"; // example city

async function fetchWeather() {
  try {
    const response = await fetch(
      `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiKey}&units=metric`
    );
    const data = await response.json();

    // Show popup with weather info
    L.marker([19.076, 72.8777])
      .addTo(map)
      .bindPopup(
        `🌤 Weather in ${city}: ${data.weather[0].description}, 🌡 ${data.main.temp}°C`
      )
      .openPopup();
  } catch (error) {
    console.error("Error fetching weather:", error);
  }
}

fetchWeather();

// -----------------------------
// Legend (Color Explanation)
// -----------------------------
const legend = L.control({ position: "bottomright" });
legend.onAdd = function () {
  const div = L.DomUtil.create("div", "legend");
  div.innerHTML += "<h4>Zone Status</h4>";
  div.innerHTML += '<i style="background: green"></i> Safe Zone<br>';
  div.innerHTML += '<i style="background: orange"></i> Danger Zone<br>';
  div.innerHTML += '<i style="background: red"></i> Red Alert Zone<br>';
  return div;
};
legend.addTo(map);

// -----------------------------
// Theme Toggle (Dark / Light basemap + CSS)
// -----------------------------
document.addEventListener("DOMContentLoaded", () => {
  const toggleBtn = document.getElementById("theme-toggle");

  toggleBtn.addEventListener("click", () => {
    document.body.classList.toggle("light");

    if (document.body.classList.contains("light")) {
      // Switch to light map
      map.removeLayer(darkTiles);
      lightTiles.addTo(map);
      toggleBtn.textContent = "🌞 Light";
    } else {
      // Switch back to dark map
      map.removeLayer(lightTiles);
      darkTiles.addTo(map);
      toggleBtn.textContent = "🌙 Dark";
    }
  });
});
