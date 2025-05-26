console.log("✅ Visitor count script running...");

const apiUrl = "https://api.joshvvcv.com/visit";

fetch(apiUrl, {
  method: "POST"
})
  .then((response) => {
    console.log("✅ Received response:", response);
    return response.json();
  })
  .then((data) => {
    console.log("✅ Visitor data received:", data);
    document.getElementById("visitor-count").textContent = data.visits;
  })
  .catch((error) => {
    console.error("❌ Error fetching visitor count:", error);
  });

