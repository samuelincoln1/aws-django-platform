const apiBase = '';

function setStatus(message, type = 'info') {
  const el = document.getElementById('status');
  el.textContent = message || '';
  el.className = `status ${type}`;
  console.log('Status updated:', message, type);
}

function formatDateTime(iso) {
  try {
    return new Date(iso).toLocaleString();
  } catch (err) {
    console.error('Error formatting date:', iso, err);
    return iso;
  }
}

function rowHtml(item) {
  console.log('Rendering row for item:', item);
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
  console.log('Fetching items from API...');
  setStatus('Loading items...');
  try {
    const res = await fetch(`${apiBase}/api/items/`);
    console.log('Fetch response status:', res.status);
    if (!res.ok) {
      setStatus('Failed to load items', 'error');
      console.error('Failed to fetch items:', res.status);
      return;
    }
    const data = await res.json();
    console.log('Items fetched:', data);
    const tbody = document.getElementById('items-body');
    tbody.innerHTML = data.map(rowHtml).join('');
    setStatus('');
  } catch (err) {
    console.error('Error fetching items:', err);
    setStatus('Error fetching items', 'error');
  }
}

async function createItem(name) {
  console.log('Creating item with name:', name);
  try {
    const res = await fetch(`${apiBase}/api/items/`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name })
    });
    console.log('Create response status:', res.status);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Failed to create item');
    }
    const json = await res.json();
    console.log('Item created:', json);
    return json;
  } catch (err) {
    console.error('Error creating item:', err);
    throw err;
  }
}

async function updateItem(id, name) {
  console.log('Updating item id:', id, 'with name:', name);
  try {
    const res = await fetch(`${apiBase}/api/items/${id}/`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name })
    });
    console.log('Update response status:', res.status);
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Failed to update item');
    }
    const json = await res.json();
    console.log('Item updated:', json);
    return json;
  } catch (err) {
    console.error('Error updating item:', err);
    throw err;
  }
}

async function deleteItem(id) {
  console.log('Deleting item id:', id);
  try {
    const res = await fetch(`${apiBase}/api/items/${id}/`, { method: 'DELETE' });
    console.log('Delete response status:', res.status);
    if (!res.ok && res.status !== 204) {
      throw new Error('Failed to delete item');
    }
    console.log('Item deleted successfully:', id);
  } catch (err) {
    console.error('Error deleting item:', err);
    throw err;
  }
}

function onTableClick(e) {
  const editBtn = e.target.closest('.btn-edit');
  const deleteBtn = e.target.closest('.btn-delete');
  if (!editBtn && !deleteBtn) return;

  const tr = e.target.closest('tr');
  const id = tr.getAttribute('data-id');
  const nameCell = tr.querySelector('.item-name');
  console.log('Row clicked id:', id);

  if (editBtn) {
    const current = nameCell.textContent.trim();
    const next = prompt('New item name:', current);
    console.log('Edit button clicked. Current:', current, 'Next:', next);
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
      console.log('Delete confirmed for id:', id);
      setStatus('Deleting item...');
      deleteItem(id)
        .then(() => fetchItems())
        .then(() => setStatus('Item deleted', 'success'))
        .catch(err => setStatus(err.message, 'error'));
    } else {
      console.log('Delete cancelled for id:', id);
    }
  }
}

function onCreateSubmit(e) {
  e.preventDefault();
  const input = document.getElementById('name');
  const name = input.value.trim();
  console.log('Create form submitted with name:', name);
  if (!name) return;
  setStatus('Creating item...');
  createItem(name)
    .then(() => { input.value = ''; return fetchItems(); })
    .then(() => setStatus('Item created', 'success'))
    .catch(err => setStatus(err.message, 'error'));
}

// Init
window.addEventListener('DOMContentLoaded', () => {
  console.log('DOM loaded, initializing event listeners...');
  document.getElementById('create-form').addEventListener('submit', onCreateSubmit);
  document.getElementById('items-body').addEventListener('click', onTableClick);
  fetchItems();
});