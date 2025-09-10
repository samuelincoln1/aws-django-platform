const apiBase = '';

function setStatus(message, type = 'info') {
  const el = document.getElementById('status');
  el.textContent = message || '';
  el.className = `status ${type}`;
}

function formatDateTime(iso) {
  try {
    return new Date(iso).toLocaleString();
  } catch {
    return iso;
  }
}

function rowHtml(item) {
  return `
    <tr data-id="${item.id}">
      <td class="item-name">${item.name}</td>
      <td>${formatDateTime(item.created_at)}</td>
      <td>${formatDateTime(item.updated_at)}</td>
      <td>
        <button class="btn btn-secondary btn-edit">Edit</button>
        <button class="btn btn-danger btn-delete">Delete</button>
      </td>
    </tr>
  `;
}

async function fetchItems() {
  setStatus('Loading items...');
  const res = await fetch(`${apiBase}/api/items/`);
  if (!res.ok) {
    setStatus('Failed to load items', 'error');
    return;
  }
  const data = await res.json();
  const tbody = document.getElementById('items-body');
  tbody.innerHTML = data.map(rowHtml).join('');
  setStatus('');
}

async function createItem(name) {
  const res = await fetch(`${apiBase}/api/items/`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name })
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Failed to create item');
  }
  return res.json();
}

async function updateItem(id, name) {
  const res = await fetch(`${apiBase}/api/items/${id}/`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name })
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.error || 'Failed to update item');
  }
  return res.json();
}

async function deleteItem(id) {
  const res = await fetch(`${apiBase}/api/items/${id}/`, { method: 'DELETE' });
  if (!res.ok && res.status !== 204) {
    throw new Error('Failed to delete item');
  }
}

function onTableClick(e) {
  const editBtn = e.target.closest('.btn-edit');
  const deleteBtn = e.target.closest('.btn-delete');
  if (!editBtn && !deleteBtn) return;

  const tr = e.target.closest('tr');
  const id = tr.getAttribute('data-id');
  const nameCell = tr.querySelector('.item-name');

  if (editBtn) {
    const current = nameCell.textContent.trim();
    const next = prompt('New item name:', current);
    if (next && next !== current) {
      setStatus('Updating item...');
      updateItem(id, next)
        .then(() => fetchItems())
        .then(() => setStatus('Item updated', 'success'))
        .catch(err => setStatus(err.message, 'error'));
    }
  }

  if (deleteBtn) {
    if (confirm('Are you sure you want to delete this item?')) {
      setStatus('Deleting item...');
      deleteItem(id)
        .then(() => fetchItems())
        .then(() => setStatus('Item deleted', 'success'))
        .catch(err => setStatus(err.message, 'error'));
    }
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