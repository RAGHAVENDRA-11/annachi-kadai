import pandas as pd
import numpy as np
from sqlalchemy import text
from database import SessionLocal

def get_demand_forecast(product_id: int):
    db = SessionLocal()
    try:
        # Get order history for this product
        result = db.execute(text("""
            SELECT DATE(o.created_at) as date, SUM(oi.quantity) as total_qty
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            WHERE oi.product_id = :pid
            GROUP BY DATE(o.created_at)
            ORDER BY date DESC
            LIMIT 30
        """), {"pid": product_id})
        rows = result.mappings().all()

        if len(rows) < 2:
            return {
                "product_id": product_id,
                "predicted_daily_demand": 5,
                "restock_suggestion": 35,
                "confidence": "low - not enough data",
                "message": "Need more order history for accurate prediction"
            }

        quantities = [r['total_qty'] for r in rows]
        avg = round(float(np.mean(quantities)), 2)
        trend = round(float(quantities[0] - quantities[-1]) / len(quantities), 2)
        predicted = max(1, round(avg + trend))
        restock = predicted * 7  # 1 week stock

        return {
            "product_id": product_id,
            "predicted_daily_demand": predicted,
            "restock_suggestion": restock,
            "confidence": "high" if len(rows) >= 7 else "medium",
            "avg_daily_sales": avg,
            "trend": "increasing" if trend > 0 else "decreasing"
        }
    finally:
        db.close()


def get_low_stock_alerts():
    db = SessionLocal()
    try:
        result = db.execute(text("""
            SELECT p.id, p.name, p.stock_quantity, p.unit
            FROM products p
            WHERE p.stock_quantity < 10 AND p.is_available = 1
            ORDER BY p.stock_quantity ASC
        """))
        rows = result.mappings().all()
        alerts = []
        for r in rows:
            alerts.append({
                "product_id": r['id'],
                "name": r['name'],
                "current_stock": r['stock_quantity'],
                "unit": r['unit'],
                "urgency": "critical" if r['stock_quantity'] < 5 else "warning",
                "message": f"Only {r['stock_quantity']} {r['unit']} left!"
            })
        return alerts
    finally:
        db.close()


def get_smart_recommendations(customer_id: int):
    db = SessionLocal()
    try:
        # Get what this customer ordered before
        result = db.execute(text("""
            SELECT p.id, p.name, p.price, p.unit, COUNT(*) as order_count
            FROM order_items oi
            JOIN orders o ON oi.order_id = o.id
            JOIN products p ON oi.product_id = p.id
            WHERE o.customer_id = :cid AND p.is_available = 1
            GROUP BY p.id, p.name, p.price, p.unit
            ORDER BY order_count DESC
            LIMIT 5
        """), {"cid": customer_id})
        rows = result.mappings().all()

        if not rows:
            # Return popular products if no history
            popular = db.execute(text("""
                SELECT p.id, p.name, p.price, p.unit, COUNT(*) as order_count
                FROM order_items oi
                JOIN products p ON oi.product_id = p.id
                WHERE p.is_available = 1
                GROUP BY p.id, p.name, p.price, p.unit
                ORDER BY order_count DESC
                LIMIT 5
            """))
            rows = popular.mappings().all()

        return [dict(r) for r in rows]
    finally:
        db.close()