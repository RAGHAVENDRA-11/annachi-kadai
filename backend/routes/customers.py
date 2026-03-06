from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db

router = APIRouter()

@router.post("/register")
def register_customer(data: dict, db: Session = Depends(get_db)):
    # Check if phone already exists
    existing_phone = db.execute(
        text("SELECT id FROM customers WHERE phone = :phone"),
        {"phone": data['phone']}
    ).mappings().first()
    if existing_phone:
        raise HTTPException(status_code=400,
            detail="Phone number already registered")

    # Check if email already exists
    existing_email = db.execute(
        text("SELECT id FROM customers WHERE email = :email"),
        {"email": data.get('email', '')}
    ).mappings().first()
    if existing_email:
        raise HTTPException(status_code=400,
            detail="Email already registered. Please login.")

    db.execute(text("""
        INSERT INTO customers (name, phone, address, email, latitude, longitude)
        VALUES (:name, :phone, :address, :email, :latitude, :longitude)
    """), {
        "name": data['name'],
        "phone": data['phone'],
        "address": data.get('address', ''),
        "email": data.get('email', ''),
        "latitude": data.get('latitude', 0.0),
        "longitude": data.get('longitude', 0.0),
    })
    db.commit()
    return {"message": "Registered successfully"}

@router.get("/{phone}")
def get_customer(phone: str, db: Session = Depends(get_db)):
    result = db.execute(
        text("SELECT * FROM customers WHERE phone = :phone"),
        {"phone": phone})
    return result.mappings().first()

@router.get("/all")
def get_all_customers(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM customers ORDER BY id DESC"))
    return [dict(r) for r in result.mappings().all()]