/* Progressive enhancement: section links still work without JavaScript. */
(() => {
  const nav = document.querySelector('.nav');
  if (!nav) return;
  const entries = Array.from(nav.querySelectorAll('a[href^="#"]'))
    .map(link => ({ link, target: document.getElementById(link.hash.slice(1)) }))
    .filter(entry => entry.target);
  if (!entries.length) return;

  let navHeight = 0;
  let scheduled = false;
  let requested = entries.find(entry => entry.link.hash === location.hash) || null;
  const markCurrent = current => {
    entries.forEach(entry => {
      if (entry === current) entry.link.setAttribute('aria-current', 'location');
      else entry.link.removeAttribute('aria-current');
    });
  };
  const update = () => {
    scheduled = false;
    if (requested) {
      markCurrent(requested);
      return;
    }
    let current = entries[0];
    const atBottom = window.scrollY > 0 && window.scrollY + window.innerHeight >= document.documentElement.scrollHeight - 3;
    // A short final section cannot reach the top; use the visible middle there.
    const boundary = atBottom ? Math.max(navHeight + 28, window.innerHeight / 2) : navHeight + 28;
    entries.forEach(entry => {
      if (entry.target.getBoundingClientRect().top <= boundary) current = entry;
    });
    markCurrent(current);
  };
  const schedule = () => {
    if (!scheduled) {
      scheduled = true;
      window.requestAnimationFrame(update);
    }
  };
  const measure = () => {
    navHeight = Math.ceil(nav.getBoundingClientRect().height);
    document.documentElement.style.setProperty('--nav-height', `${navHeight}px`);
    schedule();
  };

  entries.forEach(entry => {
    entry.link.addEventListener('click', event => {
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      requested = entry;
      markCurrent(entry);
      entry.target.focus({ preventScroll: true });
      // Native anchors handle the URL, history and scrolling, including file://.
    });
  });
  window.addEventListener('scroll', schedule, { passive: true });
  window.addEventListener('resize', measure);
  window.addEventListener('hashchange', () => {
    requested = entries.find(entry => entry.link.hash === location.hash) || null;
    schedule();
  });
  const followScroll = () => { requested = null; schedule(); };
  window.addEventListener('wheel', followScroll, { passive: true });
  window.addEventListener('touchstart', followScroll, { passive: true });
  window.addEventListener('keydown', event => {
    if (['ArrowUp', 'ArrowDown', 'PageUp', 'PageDown', 'Home', 'End', ' '].includes(event.key)) followScroll();
  });
  document.addEventListener('pointerdown', event => {
    if (!nav.contains(event.target)) followScroll();
  });
  window.addEventListener('pageshow', measure);
  document.addEventListener('toggle', schedule, true);
  if ('ResizeObserver' in window) new ResizeObserver(measure).observe(nav);
  measure();
})();
