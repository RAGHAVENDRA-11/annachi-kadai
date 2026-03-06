from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db

router = APIRouter()

@router.post("/place")
def place_order(data: dict, db: Session = Depends(get_db)):
    result = db.execute(text("""
        INSERT INTO orders (customer_id, total_amount, delivery_address)
        VALUES (:customer_id, :total_amount, :delivery_address)
    """), data)
    db.commit()
    order_id = result.lastrowid
    for item in data["items"]:
        item["order_id"] = order_id
        db.execute(text("""
            INSERT INTO order_items (order_id, product_id, quantity, unit_price)
            VALUES (:order_id, :product_id, :quantity, :unit_price)
        """), item)
    db.commit()
    return {"message": "Order placed", "order_id": order_id}

@router.get("/")
def get_orders(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM orders ORDER BY created_at DESC"))
    return result.mappings().all()

@router.put("/{order_id}/status")
def update_status(order_id: int, data: dict, db: Session = Depends(get_db)):
    db.execute(text("UPDATE orders SET status = :status WHERE id = :id"),
               {"status": data["status"], "id": order_id})
    db.commit()
    return {"message": "Status updated"}