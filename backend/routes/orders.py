from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
from bill_service import generate_bill_pdf, send_bill_email
import math
import os
import urllib.parse
import urllib.request
import json

router = APIRouter()

SHOP_LAT = 11.085015
SHOP_LNG = 76.998475
MAX_DISTANCE_KM = 3.0


def haversine(lat1, lon1, lat2, lon2) -> float:
    R = 6371
    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)
    a = (math.sin(dlat/2)**2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon/2)**2)
    return R * 2 * math.asin(math.sqrt(a))


def geocode_address(address: str):
    query = urllib.parse.quote(address)
    url = f"https://nominatim.openstreetmap.org/search?q={query}&format=json&limit=1"
    req = urllib.request.Request(url, headers={'User-Agent': 'AnnachiKadai/1.0'})
    with urllib.request.urlopen(req, timeout=10) as resp:
        data = json.loads(resp.read())
    if data:
        return float(data[0]['lat']), float(data[0]['lon'])
    return None, None


# ── VALIDATE ADDRESS ──
@router.post("/validate-address")
def validate_address(data: dict):
    address = data.get('address', '').strip()
    if not address:
        raise HTTPException(status_code=400, detail="Address is required")
    try:
        lat, lng = geocode_address(address)
        if lat is None:
            raise HTTPException(status_code=400,
                detail="Could not find this address. Please be more specific.")
        distance = haversine(SHOP_LAT, SHOP_LNG, lat, lng)
        return {
            "within_range": distance <= MAX_DISTANCE_KM,
            "distance_km": round(distance, 2),
            "lat": lat,
            "lng": lng,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Address lookup failed: {str(e)}")



# ── VALIDATE BY COORDINATES (GPS) ──
@router.post("/validate-coordinates")
def validate_coordinates(data: dict):
    lat = data.get('lat')
    lng = data.get('lng')
    if lat is None or lng is None:
        raise HTTPException(status_code=400, detail="lat and lng are required")
    try:
        distance = haversine(SHOP_LAT, SHOP_LNG, float(lat), float(lng))
        return {
            "within_range": distance <= MAX_DISTANCE_KM,
            "distance_km": round(distance, 2),
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── PLACE ORDER WITH BILL ──
@router.post("/place-with-bill")
def place_order_with_bill(data: dict, db: Session = Depends(get_db)):
    customer_id      = data.get('customer_id')
    customer_name    = data.get('customer_name', '')
    customer_email   = data.get('customer_email', '')
    delivery_address = data.get('delivery_address', '')
    notes            = data.get('notes', '')
    payment_method   = data.get('payment_method', 'cod')
    items            = data.get('items', [])
    total_amount     = float(data.get('total_amount', 0))

    if not customer_id or not items:
        raise HTTPException(status_code=400, detail="customer_id and items are required")

    try:
        res = db.execute(text("""
            INSERT INTO orders (customer_id, total_amount, status, delivery_address)
            VALUES (:cid, :total, 'pending', :addr)
        """), {"cid": customer_id, "total": total_amount, "addr": delivery_address})
        db.commit()
        order_id = res.lastrowid

        # Ensure price column exists
        try:
            db.execute(text("ALTER TABLE order_items ADD COLUMN price DECIMAL(10,2) DEFAULT 0.00"))
            db.commit()
        except Exception:
            pass  # column already exists

        for item in items:
            product_id = item.get('product_id')
            quantity   = int(item.get('quantity', 1))
            price      = float(item.get('price', 0))

            db.execute(text("""
                INSERT INTO order_items (order_id, product_id, quantity, price)
                VALUES (:oid, :pid, :qty, :price)
            """), {"oid": order_id, "pid": product_id, "qty": quantity, "price": price})

            db.execute(text("""
                UPDATE products SET stock_quantity = GREATEST(stock_quantity - :qty, 0)
                WHERE id = :pid
            """), {"qty": quantity, "pid": product_id})

        db.commit()

        pdf_path = generate_bill_pdf(
            order_id=order_id,
            customer_name=customer_name,
            customer_email=customer_email,
            delivery_address=delivery_address,
            items=items,
            total_amount=total_amount,
            notes=notes,
            payment_method=payment_method,
        )

        email_sent = send_bill_email(
            customer_email=customer_email,
            customer_name=customer_name,
            order_id=order_id,
            pdf_path=pdf_path,
            total=total_amount,
        )

        return {
            "order_id": order_id,
            "status": "pending",
            "email_sent": email_sent,
            "bill_url": f"/api/orders/bill/{order_id}",
        }

    except HTTPException:
        raise
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


# ── SERVE PDF ──
@router.get("/bill/{order_id}")
def get_bill(order_id: int):
    path = f"bills/bill_order_{order_id}.pdf"
    if not os.path.exists(path):
        raise HTTPException(status_code=404, detail="Bill not found")
    return FileResponse(path, media_type="application/pdf",
                        filename=f"annachi_kadai_bill_{order_id}.pdf")


# ── GET ORDERS BY CUSTOMER ──
@router.get("/customer/{customer_id}")
def get_customer_orders(customer_id: int, db: Session = Depends(get_db)):
    result = db.execute(text("""
        SELECT * FROM orders WHERE customer_id = :cid ORDER BY id DESC
    """), {"cid": customer_id})
    return [dict(r) for r in result.mappings().all()]


# ── PLACE ORDER (legacy) ──
@router.post("/place")
def place_order(data: dict, db: Session = Depends(get_db)):
    try:
        res = db.execute(text("""
            INSERT INTO orders (customer_id, total_amount, status)
            VALUES (:cid, :total, 'pending')
        """), {"cid": data.get('customer_id'), "total": data.get('total_amount', 0)})
        db.commit()
        return {"order_id": res.lastrowid, "status": "pending"}
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=str(e))


# ── GET ALL ORDERS (admin) ──
@router.get("/all")
def get_all_orders(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM orders ORDER BY id DESC"))
    return [dict(r) for r in result.mappings().all()]


# ── UPDATE ORDER STATUS (admin) ──
@router.put("/{order_id}/status")
def update_order_status(order_id: int, data: dict, db: Session = Depends(get_db)):
    status = data.get("status")
    allowed = ["pending", "confirmed", "processing", "on_the_way", "delivered", "cancelled"]
    if status not in allowed:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of {allowed}")

    # Auto-migrate ENUM to VARCHAR to support new statuses
    try:
        db.execute(text("ALTER TABLE orders MODIFY COLUMN status VARCHAR(20) NOT NULL DEFAULT 'pending'"))
        db.commit()
    except Exception:
        pass  # already VARCHAR or migration already done

    db.execute(text("UPDATE orders SET status = :status WHERE id = :oid"),
               {"status": status, "oid": order_id})
    db.commit()
    return {"order_id": order_id, "status": status, "message": "Order status updated"}


# ── DELIVERY BOY ENDPOINTS ──

@router.get("/delivery/active")
def get_active_orders(db: Session = Depends(get_db)):
    """Get all active orders for delivery dashboard"""
    try:
        # Add delivery_address column if missing
        try:
            db.execute(text("ALTER TABLE orders ADD COLUMN delivery_address TEXT"))
            db.commit()
        except Exception:
            pass

        result = db.execute(text("""
            SELECT o.id, o.customer_id, o.total_amount, o.status,
                   o.delivery_address, o.created_at,
                   c.name as customer_name, c.phone as customer_phone
            FROM orders o
            LEFT JOIN customers c ON o.customer_id = c.id
            WHERE o.status NOT IN ('delivered', 'cancelled')
            ORDER BY o.created_at DESC
        """)).mappings().all()

        orders = []
        for row in result:
            o = dict(row)
            # Get items
            items = db.execute(text("""
                SELECT oi.quantity, oi.price, p.name, p.unit
                FROM order_items oi
                JOIN products p ON oi.product_id = p.id
                WHERE oi.order_id = :oid
            """), {"oid": o["id"]}).mappings().all()
            o["items"] = [dict(i) for i in items]
            o["created_at"] = str(o["created_at"])
            orders.append(o)
        return orders
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/delivery/history")
def get_delivery_history(db: Session = Depends(get_db)):
    """Get recently delivered orders"""
    try:
        result = db.execute(text("""
            SELECT o.id, o.customer_id, o.total_amount, o.status,
                   o.delivery_address, o.created_at,
                   c.name as customer_name, c.phone as customer_phone
            FROM orders o
            LEFT JOIN customers c ON o.customer_id = c.id
            WHERE o.status = 'delivered'
            ORDER BY o.created_at DESC LIMIT 20
        """)).mappings().all()
        orders = []
        for row in result:
            o = dict(row)
            items = db.execute(text("""
                SELECT oi.quantity, oi.price, p.name, p.unit
                FROM order_items oi JOIN products p ON oi.product_id = p.id
                WHERE oi.order_id = :oid
            """), {"oid": o["id"]}).mappings().all()
            o["items"] = [dict(i) for i in items]
            o["created_at"] = str(o["created_at"])
            orders.append(o)
        return orders
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))