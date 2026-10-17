const apiBase = '';

function setStatus(message, type = 'info') {
  const el = document.getElementById('status');
  el.textContent = message || '';
  el.className = `status ${type}`;
}

function formatDateTime(iso) {
  try {
    return new Date(iso).toLocaleString();
  } catch (err) {
    console.error('Error formatting date:', iso, err);
    return iso;
  }
}

// Django sets the csrftoken cookie on the home page (ensure_csrf_cookie)
function csrfToken() {
  const match = document.cookie.match(/(?:^|;\s*)csrftoken=([^;]+)/);
  return match ? decodeURIComponent(match[1]) : '';
}

function jsonHeaders() {
  return { 'Content-Type': 'application/json', 'X-CSRFToken': csrfToken() };
}

function cell(text, className) {
  const td = document.createElement('td');
  if (className) td.className = className;
  td.textContent = text;
  return td;
}

function button(label, className) {
  const btn = document.createElement('button');
  btn.className = `btn ${className}`;
  btn.textContent = label;
  return btn;
}

// Built with textContent (not innerHTML) so item names can never inject markup
function buildRow(item) {
  const tr = document.createElement('tr');
  tr.dataset.id = item.id;
  const actions = document.createElement('td');
  actions.append(button('Edit', 'btn-secondary btn-edit'), button('Delete', 'btn-danger btn-delete'));
  tr.append(
    cell(item.name, 'item-name'),
    cell(formatDateTime(item.created_at)),
    cell(formatDateTime(item.updated_at)),
    actions
  );
  return tr;
}

async function errorMessage(res, fallback) {
  const body = await res.json().catch(() => ({}));
  return body.error || fallback;
}

async function fetchItems() {
  setStatus('Loading items...');
  try {
    const res = await fetch(`${apiBase}/api/items/`);
    if (!res.ok) {
      setStatus('Failed to load items', 'error');
      console.error('Failed to fetch items:', res.status);
      return;
    }
    const data = await res.json();
    document.getElementById('items-body').replaceChildren(...data.map(buildRow));
    setStatus('');
  } catch (err) {
    console.error('Error fetching items:', err);
    setStatus('Error fetching items', 'error');
  }
}

async function createItem(name) {
  const res = await fetch(`${apiBase}/api/items/`, {
    method: 'POST',
    headers: jsonHeaders(),
    body: JSON.stringify({ name })
  });
  if (!res.ok) {
    throw new Error(await errorMessage(res, 'Failed to create item'));
  }
  return res.json();
}

async function updateItem(id, name) {
  const res = await fetch(`${apiBase}/api/items/${id}/`, {
    method: 'PATCH',
    headers: jsonHeaders(),
    body: JSON.stringify({ name })
  });
  if (!res.ok) {
    throw new Error(await errorMessage(res, 'Failed to update item'));
  }
  return res.json();
}

async function deleteItem(id) {
  const res = await fetch(`${apiBase}/api/items/${id}/`, {
    method: 'DELETE',
    headers: { 'X-CSRFToken': csrfToken() }
  });
  if (!res.ok) {
    throw new Error('Failed to delete item');
  }
}

function onTableClick(e) {
  const editBtn = e.target.closest('.btn-edit');
  const deleteBtn = e.target.closest('.btn-delete');
  if (!editBtn && !deleteBtn) return;

  const tr = e.target.closest('tr');
  const id = tr.dataset.id;

  if (editBtn) {
    const current = tr.querySelector('.item-name').textContent.trim();
    const next = prompt('New item name:', current);
    if (next && next !== current) {
      setStatus('Updating item...');
      updateItem(id, next)
        .then(() => fetchItems())
        .then(() => setStatus('Item updated', 'success'))
        .catch(err => setStatus(err.message, 'error'));
    }
  }

  if (deleteBtn && confirm('Are you sure you want to delete this item?')) {
    setStatus('Deleting item...');
    deleteItem(id)
      .then(() => fetchItems())
      .then(() => setStatus('Item deleted', 'success'))
      .catch(err => setStatus(err.message, 'error'));
  }
}

function onCreateSubmit(e) {
  e.preventDefault();
  const input = document.getElementById('name');
  const name = input.value.trim();
  if (!name) return;
  setStatus('Creating item...');
  createItem(name)
    .then(() => { input.value = ''; return fetchItems(); })
    .then(() => setStatus('Item created', 'success'))
    .catch(err => setStatus(err.message, 'error'));
}

// Init
window.addEventListener('DOMContentLoaded', () => {
  document.getElementById('create-form').addEventListener('submit', onCreateSubmit);
  document.getElementById('items-body').addEventListener('click', onTableClick);
  fetchItems();
});
