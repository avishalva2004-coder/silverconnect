// ─── i18n ───
function __(key) {
  if (window.__translations && window.__translations[key]) return window.__translations[key];
  return key;
}

// ─── Theme ───
function toggleTheme() {
  document.body.classList.toggle('dark');
  localStorage.setItem('sc_theme', document.body.classList.contains('dark') ? 'dark' : 'light');
  const icon = document.querySelector('#themeToggle i');
  if (icon) {
    icon.className = document.body.classList.contains('dark') ? 'fas fa-sun' : 'fas fa-moon';
  }
}

(function() {
  const saved = localStorage.getItem('sc_theme');
  if (saved === 'dark' || (!saved && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.body.classList.add('dark');
  }
})();

// ─── Toast ───
function showToast(msg) {
  const t = document.createElement('div');
  t.className = 'toast';
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 3000);
}

// ─── Medicine Alarm ───
var medAlarmNotified = new Set();
var medAlarmInterval = null;

function playMedAlarm() {
  try {
    var ctx = new (window.AudioContext || window.webkitAudioContext)();
    var osc = ctx.createOscillator();
    var gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.frequency.value = 880;
    gain.gain.setValueAtTime(0.3, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
    osc.start(ctx.currentTime);
    osc.stop(ctx.currentTime + 0.5);
    setTimeout(function() {
      var osc2 = ctx.createOscillator();
      var gain2 = ctx.createGain();
      osc2.connect(gain2);
      gain2.connect(ctx.destination);
      osc2.frequency.value = 880;
      gain2.gain.setValueAtTime(0.3, ctx.currentTime);
      gain2.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.5);
      osc2.start(ctx.currentTime);
      osc2.stop(ctx.currentTime + 0.5);
    }, 600);
  } catch(e) {}
}

function checkMedicineAlarm() {
  fetch('/api/medicines/today')
    .then(function(r) { return r.json(); })
    .then(function(meds) {
      var now = new Date();
      var h = String(now.getHours()).padStart(2, '0');
      var m = String(now.getMinutes()).padStart(2, '0');
      var currentTime = h + ':' + m;
      meds.forEach(function(med) {
        var key = med.id + '-' + med.med_time;
        if (med.med_time === currentTime && !medAlarmNotified.has(key)) {
          medAlarmNotified.add(key);
          playMedAlarm();
          showToast(__("\u23F0 Time to take") + " " + med.name + "!");
        }
      });
    });
}

function startMedicineAlarm() {
  if (medAlarmInterval) return;
  checkMedicineAlarm();
  medAlarmInterval = setInterval(checkMedicineAlarm, 60000);
}

document.addEventListener('DOMContentLoaded', function() {
  if (document.body.querySelector('.page-content')) {
    startMedicineAlarm();
  }
});

// ─── GSAP Entrance ───
document.addEventListener('DOMContentLoaded', () => {
  gsap.set('.page-content', {opacity: 1, y: 0});
});
