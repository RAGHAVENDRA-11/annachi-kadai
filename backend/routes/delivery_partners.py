from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
import hashlib, os

router = APIRouter()

def hash_password(pw: str) -> str:
    return hashlib.sha256(pw.encode()).hexdigest()

def ensure_table(db):
    try:
        db.execute(text("""
            CREATE TABLE IF NOT EXISTS delivery_partners (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                phone VARCHAR(20) UNIQUE NOT NULL,
                email VARCHAR(100),
                password_hash VARCHAR(64) NOT NULL,
                vehicle_no VARCHAR(20),
                is_active TINYINT(1) DEFAULT 1,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """))
        db.commit()
    except Exception:
        pass

@router.post("/register")
def register_partner(data: dict, db: Session = Depends(get_db)):
    ensure_table(db)
    name       = data.get("name", "").strip()
    phone      = data.get("phone", "").strip()
    email      = data.get("email", "").strip()
    password   = data.get("password", "").strip()
    vehicle_no = data.get("vehicle_no", "").strip()

    if not all([name, phone, password]):
        raise HTTPException(status_code=400, detail="Name, phone and password are required")
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")

    existing = db.execute(text("SELECT id FROM delivery_partners WHERE phone = :p"),
                          {"p": phone}).fetchone()
    if existing:
        raise HTTPException(status_code=400, detail="Phone number already registered")

    db.execute(text("""
        INSERT INTO delivery_partners (name, phone, email, password_hash, vehicle_no)
        VALUES (:name, :phone, :email, :pw, :veh)
    """), {"name": name, "phone": phone, "email": email,
           "pw": hash_password(password), "veh": vehicle_no})
    db.commit()
    return {"success": True, "message": "Registered successfully"}

@router.post("/login")
def login_partner(data: dict, db: Session = Depends(get_db)):
    ensure_table(db)
    phone    = data.get("phone", "").strip()
    password = data.get("password", "").strip()
    if not phone or not password:
        raise HTTPException(status_code=400, detail="Phone and password required")

    row = db.execute(text("""
        SELECT id, name, phone, email, vehicle_no, password_hash
        FROM delivery_partners WHERE phone = :p AND is_active = 1
    """), {"p": phone}).mappings().first()

    if not row or row["password_hash"] != hash_password(password):
        raise HTTPException(status_code=401, detail="Invalid phone or password")

    return {
        "success": True,
        "partner": {
            "id": row["id"], "name": row["name"],
            "phone": row["phone"], "email": row["email"],
            "vehicle_no": row["vehicle_no"],
        }
    }

@router.put("/{partner_id}/password")
def change_password(partner_id: int, data: dict, db: Session = Depends(get_db)):
    ensure_table(db)
    old_pw = data.get("old_password", "")
    new_pw = data.get("new_password", "")
    if len(new_pw) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")

    row = db.execute(text("SELECT password_hash FROM delivery_partners WHERE id = :id"),
                     {"id": partner_id}).fetchone()
    if not row or row[0] != hash_password(old_pw):
        raise HTTPException(status_code=401, detail="Current password incorrect")

    db.execute(text("UPDATE delivery_partners SET password_hash = :pw WHERE id = :id"),
               {"pw": hash_password(new_pw), "id": partner_id})
    db.commit()
    return {"success": True}

@router.get("/{partner_id}")
def get_partner(partner_id: int, db: Session = Depends(get_db)):
    ensure_table(db)
    row = db.execute(text("""
        SELECT id, name, phone, email, vehicle_no, created_at
        FROM delivery_partners WHERE id = :id
    """), {"id": partner_id}).mappings().first()
    if not row:
        raise HTTPException(status_code=404, detail="Partner not found")
    r = dict(row)
    r["created_at"] = str(r["created_at"])
    return r