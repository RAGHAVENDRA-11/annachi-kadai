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