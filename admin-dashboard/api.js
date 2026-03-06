var API = 'http://127.0.0.1:8000/api';

async function getProducts() {
    const res = await fetch('http://127.0.0.1:8000/api/products/');
    return await res.json();
}

async function addProduct(data) {
    const res = await fetch('http://127.0.0.1:8000/api/products/add', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    });
    return await res.json();
}

async function updateStock(productId, qty) {
    const res = await fetch(`http://127.0.0.1:8000/api/products/${productId}/stock`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ stock_quantity: qty })
    });
    return await res.json();
}

async function getOrders() {
    const res = await fetch('http://127.0.0.1:8000/api/orders/');
    return await res.json();
}

async function updateOrderStatus(orderId, status) {
    const res = await fetch(`http://127.0.0.1:8000/api/orders/${orderId}/status`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: status })
    });
    return await res.json();
}