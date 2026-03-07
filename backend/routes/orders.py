from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db

router = APIRouter()

@router.post("/place")
def place_order(data: dict, db: Session = Depends(get_db)):
    try:
        result = db.execute(text("""
            INSERT INTO orders (customer_id, total_amount, status)
            VALUES (:customer_id, :total_amount, 'pending')
        """), {
            "customer_id": data["customer_id"],
            "total_amount": data["total_amount"]
        })
        db.commit()
        order_id = result.lastrowid

        for item in data["items"]:
            db.execute(text("""
                INSERT INTO order_items (order_id, product_id, quantity, unit_price)
                VALUES (:order_id, :product_id, :quantity, :unit_price)
            """), {
                "order_id": order_id,
                "product_id": item["product_id"],
                "quantity": item["quantity"],
                "unit_price": item["unit_price"]
            })
        db.commit()
        return {"message": "Order placed", "order_id": order_id}
    except Exception as e:
        db.rollback()
        return {"error": str(e)}

@router.get("/")
def get_orders(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM orders ORDER BY created_at DESC"))
    return result.mappings().all()

@router.get("/customer/{customer_id}")
def get_customer_orders(customer_id: int, db: Session = Depends(get_db)):
    result = db.execute(text("""
        SELECT * FROM orders WHERE customer_id = :customer_id
        ORDER BY created_at DESC
    """), {"customer_id": customer_id})
    return result.mappings().all()

@router.put("/{order_id}/status")
def update_status(order_id: int, data: dict, db: Session = Depends(get_db)):
    db.execute(text("UPDATE orders SET status = :status WHERE id = :id"),
               {"status": data["status"], "id": order_id})
    db.commit()
    return {"message": "Status updated"}