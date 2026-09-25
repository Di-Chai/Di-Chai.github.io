/* Apply the theme before styles load to avoid a flash of the wrong background. */
(() => {
  const key = 'homepage-theme';
  const system = window.matchMedia('(prefers-color-scheme: dark)');
  const valid = value => ['system', 'light', 'dark'].includes(value);
  let preference = 'system';
  let button = null;
  try {
    const saved = localStorage.getItem(key);
    if (valid(saved)) preference = saved;
  } catch (_) { /* Storage may be unavailable for local files or private browsing. */ }

  const apply = () => {
    const dark = preference === 'dark' || (preference === 'system' && system.matches);
    document.documentElement.dataset.theme = dark ? 'dark' : 'light';
    document.querySelector('meta[name="theme-color"]').content = dark ? '#101722' : '#ffffff';
    if (button) {
      const action = dark ? 'Switch to light mode' : 'Switch to dark mode';
      button.setAttribute('aria-label', action);
      button.title = action;
    }
  };
  apply();
  system.addEventListener('change', apply);

  document.addEventListener('DOMContentLoaded', () => {
    button = document.querySelector('#theme-toggle');
    apply();
    button.hidden = false;
    button.addEventListener('click', () => {
      preference = document.documentElement.dataset.theme === 'dark' ? 'light' : 'dark';
      apply();
      try { localStorage.setItem(key, preference); } catch (_) { /* Still switch this page. */ }
    });
    window.addEventListener('storage', event => {
      if (event.key !== key && event.key !== null) return;
      preference = valid(event.newValue) ? event.newValue : 'system';
      apply();
    });
  });
})();
