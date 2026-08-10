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

});