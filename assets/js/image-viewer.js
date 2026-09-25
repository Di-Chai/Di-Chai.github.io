/* Keep ordinary image links as a fallback when modal dialogs are unavailable. */
(() => {
  const viewer = document.querySelector('#image-viewer');
  if (!viewer || typeof viewer.showModal !== 'function') return;

  const image = viewer.querySelector('.image-viewer-image');
  const closeButton = viewer.querySelector('.image-viewer-close');
  let opener = null;

  document.querySelectorAll('.update-image-link, .award-image-link').forEach(link => {
    link.setAttribute('aria-haspopup', 'dialog');
    link.setAttribute('aria-controls', viewer.id);
    link.addEventListener('click', event => {
      if (event.button !== 0 || event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return;
      const thumbnail = link.querySelector('img');
      const description = link.dataset.imageAlt || (thumbnail && thumbnail.alt);
      if (!description || viewer.open) return;

      opener = link;
      image.src = link.href;
      image.alt = description;
      const name = link.closest('article').querySelector('h3').textContent;
      viewer.setAttribute('aria-label', `${name} image preview`);
      viewer.showModal();
      document.documentElement.classList.add('image-viewer-open');
      event.preventDefault();
    });
  });

  closeButton.addEventListener('click', () => viewer.close());
  viewer.addEventListener('click', event => {
    if (event.target === viewer || event.target === image) viewer.close();
  });
  // Native dialog behavior also supports Escape and keeps focus inside the modal.
  viewer.addEventListener('close', () => {
    document.documentElement.classList.remove('image-viewer-open');
    image.removeAttribute('src');
    image.alt = '';
    if (opener && opener.isConnected) opener.focus({ preventScroll: true });
    opener = null;
  });
})();
