document.addEventListener('DOMContentLoaded', () => {

  // ---- HAMBURGER ----
  const hamburger = document.getElementById('hamburger');
  const navMenu   = document.querySelector('.nav-links');
  if (hamburger && navMenu) {
    hamburger.addEventListener('click', () => {
      hamburger.classList.toggle('open');
      navMenu.classList.toggle('open');
    });
    navMenu.querySelectorAll('a').forEach(a => {
      a.addEventListener('click', () => {
        hamburger.classList.remove('open');
        navMenu.classList.remove('open');
      });
    });
  }

  // ---- THEME TOGGLE ----
  const themeBtn = document.getElementById('theme-toggle');
  const preferLight = window.matchMedia('(prefers-color-scheme: light)').matches;
  if (preferLight) document.body.classList.add('light');
  if (themeBtn) {
    themeBtn.textContent = preferLight ? '☀' : '☾';
    themeBtn.addEventListener('click', () => {
      document.body.classList.toggle('light');
      const isLight = document.body.classList.contains('light');
      themeBtn.textContent = isLight ? '☀' : '☾';
    });
  }

  // ---- SMOOTH SCROLL ----
  document.querySelectorAll('a[href^="#"]').forEach(a => {
    a.addEventListener('click', e => {
      const target = document.querySelector(a.getAttribute('href'));
      if (target) { e.preventDefault(); target.scrollIntoView({ behavior: 'smooth' }); }
    });
  });

  const visitorCount = document.getElementById("visitor-count");

  async function getVisitorCount() {
    try {
        visitorCount.textContent = "Visitors: …";

        const response = await fetch("https://9sokrohzx1.execute-api.us-east-1.amazonaws.com/count");

        if (!response.ok) {
            throw new Error("Failed to fetch visitor count");
        }

        const data = await response.json();
        visitorCount.textContent = `Visitors: ${data.count}`;
    } catch (error) {
        console.error("Visitor counter error:", error);
        visitorCount.textContent = "Visitors: —";
    }
}

getVisitorCount();

});