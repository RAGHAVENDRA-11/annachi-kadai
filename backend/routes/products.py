from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db

router = APIRouter()

@router.get("/")
def get_products(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM products WHERE is_available = 1"))
    return [dict(r) for r in result.mappings().all()]

@router.post("/add")
def add_product(data: dict, db: Session = Depends(get_db)):
    db.execute(text("""
        INSERT INTO products (name, category_id, price, stock_quantity, unit, image)
        VALUES (:name, :category_id, :price, :stock_quantity, :unit, :image)
    """), {
        "name": data['name'],
        "category_id": data['category_id'],
        "price": data['price'],
        "stock_quantity": data['stock_quantity'],
        "unit": data['unit'],
        "image": data.get('image', None),
    })
    db.commit()
    return {"message": "Product added successfully"}

@router.put("/{product_id}/stock")
def update_stock(product_id: int, data: dict, db: Session = Depends(get_db)):
    db.execute(text("""
        UPDATE products SET stock_quantity = :qty WHERE id = :id
    """), {"qty": data['stock_quantity'], "id": product_id})
    db.commit()
    return {"message": "Stock updated"}

@router.put("/{product_id}")
def update_product(product_id: int, data: dict, db: Session = Depends(get_db)):
    db.execute(text("""
        UPDATE products SET name=:name, price=:price, stock_quantity=:stock_quantity,
        unit=:unit, image=:image WHERE id=:id
    """), {
        "name": data['name'],
        "price": data['price'],
        "stock_quantity": data['stock_quantity'],
        "unit": data['unit'],
        "image": data.get('image', None),
        "id": product_id
    })
    db.commit()
    return {"message": "Product updated"}

@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    db.execute(text("UPDATE products SET is_available=0 WHERE id=:id"),
               {"id": product_id})
    db.commit()
    return {"message": "Product deleted"}

# Add these endpoints to your existing backend/routes/products.py

@router.put("/{product_id}/stock")
def update_stock(product_id: int, data: dict, db: Session = Depends(get_db)):
    new_stock = data.get("stock_quantity")
    if new_stock is None or new_stock < 0:
        raise HTTPException(status_code=400, detail="Invalid stock quantity")
    db.execute(text(
        "UPDATE products SET stock_quantity = :stock WHERE id = :pid"
    ), {"stock": new_stock, "pid": product_id})
    db.commit()
    return {"message": "Stock updated", "product_id": product_id, "stock_quantity": new_stock}

@router.delete("/{product_id}")
def delete_product(product_id: int, db: Session = Depends(get_db)):
    db.execute(text("DELETE FROM products WHERE id = :pid"), {"pid": product_id})
    db.commit()
    return {"message": "Product deleted", "product_id": product_id}

@router.put("/{product_id}")
def update_product(product_id: int, data: dict, db: Session = Depends(get_db)):
    fields = []
    params = {"pid": product_id}
    if "name" in data:
        fields.append("name = :name"); params["name"] = data["name"]
    if "price" in data:
        fields.append("price = :price"); params["price"] = data["price"]
    if "stock_quantity" in data:
        fields.append("stock_quantity = :stock"); params["stock"] = data["stock_quantity"]
    if "unit" in data:
        fields.append("unit = :unit"); params["unit"] = data["unit"]
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    db.execute(text(f"UPDATE products SET {', '.join(fields)} WHERE id = :pid"), params)
    db.commit()
    return {"message": "Product updated"}