(() => {
  const panel = document.querySelector('.navigation-panel');
  if (!panel) return;
  if (matchMedia('(max-width: 760px)').matches) panel.open = false;
  const orbit = document.querySelector('.orbit');
  const nodes = [...orbit.querySelectorAll('.orbit-node')];
  const reduced = matchMedia('(prefers-reduced-motion: reduce)');
  const mobile = matchMedia('(max-width: 760px)');
  let yaw = 0.2, pitch = -0.15, drag = null, moved = false, frame = 0;
  const points = nodes.map((_, i) => {
    const y = 1 - 2 * (i + 0.5) / nodes.length;
    const radius = Math.sqrt(1 - y * y), theta = i * Math.PI * (3 - Math.sqrt(5));
    return [Math.cos(theta) * radius, y, Math.sin(theta) * radius];
  });
  function render() {
    frame = 0;
    if (reduced.matches || mobile.matches || !panel.open) return;
    const radius = Math.min(orbit.clientWidth * 0.34, 95);
    points.forEach(([x, y, z], i) => {
      const rx = x * Math.cos(yaw) + z * Math.sin(yaw);
      const rz = z * Math.cos(yaw) - x * Math.sin(yaw);
      const ry = y * Math.cos(pitch) - rz * Math.sin(pitch);
      const depth = y * Math.sin(pitch) + rz * Math.cos(pitch);
      const scale = 0.7 + (depth + 1) * 0.2;
      nodes[i].style.transform = `translate(-50%, -50%) translate(${rx * radius}px, ${ry * radius}px) scale(${scale})`;
      nodes[i].style.opacity = String(0.3 + (depth + 1) * 0.35);
      nodes[i].style.zIndex = String(Math.round((depth + 1) * 100));
    });
  }
  function schedule() { if (!frame) frame = requestAnimationFrame(render); }
  orbit.addEventListener('wheel', event => {
    if (event.ctrlKey || reduced.matches || mobile.matches) return;
    event.preventDefault();
    yaw += Math.max(-100, Math.min(100, event.deltaY + event.deltaX)) * 0.006;
    schedule();
  }, { passive: false });
  orbit.addEventListener('pointerdown', event => {
    if (event.button !== 0) return;
    drag = { id: event.pointerId, x: event.clientX, y: event.clientY, startX: event.clientX, startY: event.clientY };
    moved = false;
  });
  orbit.addEventListener('pointermove', event => {
    if (!drag || event.pointerId !== drag.id) return;
    if (Math.hypot(event.clientX - drag.startX, event.clientY - drag.startY) > 5) {
      moved = true;
      orbit.setPointerCapture(event.pointerId);
      orbit.classList.add('dragging');
    }
    if (moved) {
      yaw += (event.clientX - drag.x) * 0.012;
      pitch += (event.clientY - drag.y) * 0.01;
      schedule();
    }
    drag.x = event.clientX; drag.y = event.clientY;
  });
  function end(event) {
    if (!drag || event.pointerId !== drag.id) return;
    if (orbit.hasPointerCapture(event.pointerId)) orbit.releasePointerCapture(event.pointerId);
    drag = null; orbit.classList.remove('dragging');
  }
  window.addEventListener('pointerup', end);
  window.addEventListener('pointercancel', end);
  orbit.addEventListener('click', event => { if (moved) { event.preventDefault(); event.stopPropagation(); moved = false; } }, true);
  orbit.addEventListener('dragstart', event => event.preventDefault());
  document.querySelectorAll('[data-turn]').forEach(button => button.addEventListener('click', () => { yaw += Number(button.dataset.turn) * 0.6; schedule(); }));
  panel.addEventListener('toggle', schedule);
  window.addEventListener('resize', schedule);
  reduced.addEventListener('change', schedule);
  render();
})();
