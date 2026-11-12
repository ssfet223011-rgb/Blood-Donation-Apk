// BloodBond Bangladesh — Admin Command Center Controller

document.addEventListener("DOMContentLoaded", () => {
  initTabs();
  initCharts();
});

// Tab Switching
function initTabs() {
  const tabs = document.querySelectorAll(".nav-item");
  tabs.forEach((tab) => {
    tab.addEventListener("click", () => {
      tabs.forEach((t) => t.classList.remove("active"));
      tab.classList.add("active");

      const targetTab = tab.getAttribute("data-tab");
      document.querySelectorAll(".content-tab").forEach((content) => {
        content.classList.remove("active");
      });

      const activeContent = document.getElementById(`tab-${targetTab}`);
      if (activeContent) {
        activeContent.classList.add("active");
      }
    });
  });
}

// Chart Initializations
function initCharts() {
  // 1. Blood Group Inventory Chart
  const ctxBlood = document.getElementById("bloodGroupChart");
  if (ctxBlood) {
    new Chart(ctxBlood, {
      type: "doughnut",
      data: {
        labels: ["O+", "A+", "B+", "AB+", "O-", "A-", "B-", "AB-"],
        datasets: [
          {
            data: [31, 26, 25, 9, 4, 2, 2, 1],
            backgroundColor: [
              "#C62828",
              "#D32F2F",
              "#E53935",
              "#EF5350",
              "#991B1B",
              "#7F1D1D",
              "#581C87",
              "#475569",
            ],
          },
        ],
      },
      options: {
        responsive: true,
        plugins: {
          legend: { position: "right" },
        },
      },
    });
  }

  // 2. Division Donations Chart
  const ctxDiv = document.getElementById("divisionChart");
  if (ctxDiv) {
    new Chart(ctxDiv, {
      type: "bar",
      data: {
        labels: [
          "Dhaka",
          "Chattogram",
          "Rajshahi",
          "Khulna",
          "Sylhet",
          "Barishal",
          "Rangpur",
          "Mymensingh",
        ],
        datasets: [
          {
            label: "Verified Donations (2026)",
            data: [15420, 9280, 5410, 4390, 3120, 2410, 2180, 1680],
            backgroundColor: "#C62828",
            borderRadius: 6,
          },
        ],
      },
      options: {
        responsive: true,
        scales: {
          y: { beginAtZero: true },
        },
      },
    });
  }

  // 3. Monthly Trend Chart
  const ctxTrend = document.getElementById("monthlyTrendChart");
  if (ctxTrend) {
    new Chart(ctxTrend, {
      type: "line",
      data: {
        labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov"],
        datasets: [
          {
            label: "Fulfillment Rate (%)",
            data: [82, 85, 87, 86, 91, 89, 93, 94, 92, 95, 96],
            borderColor: "#16A34A",
            backgroundColor: "rgba(22, 163, 74, 0.1)",
            fill: true,
            tension: 0.3,
          },
        ],
      },
      options: {
        responsive: true,
        scales: {
          y: { min: 70, max: 100 },
        },
      },
    });
  }
}

// Verification Action
function verifyDonation(donationId) {
  if (confirm(`Approve and verify donation record ${donationId}? This will update the official verified count and set donor rest period.`)) {
    alert(`Donation ${donationId} successfully verified! Official donor history updated.`);
  }
}

function refreshDashboardStats() {
  console.log("Refreshed stats from Supabase Realtime");
}
