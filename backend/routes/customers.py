from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
from otp_service import send_otp_email, verify_otp

router = APIRouter()

# ── REGISTER: Step 1 - Send OTP ──
@router.post("/register/send-otp")
def register_send_otp(data: dict, db: Session = Depends(get_db)):
    email = data.get('email', '').strip()
    name  = data.get('name', '').strip()

    if not email or not name:
        raise HTTPException(status_code=400, detail="Name and email are required")

    existing = db.execute(
        text("SELECT id FROM customers WHERE email = :email"),
        {"email": email}
    ).mappings().first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered. Please login.")

    result = send_otp_email(email)
    if not result["success"]:
        raise HTTPException(status_code=500, detail=f"Failed to send OTP: {result['message']}")

    return {"message": "OTP sent to your email"}

# ── REGISTER: Step 2 - Verify OTP ──
@router.post("/register/verify-otp")
def register_verify_otp(data: dict, db: Session = Depends(get_db)):
    email = data.get('email', '').strip()
    otp   = data.get('otp', '').strip()
    name  = data.get('name', '').strip()
    phone = data.get('phone', '').strip()  # keep as empty string, not NULL

    result = verify_otp(email, otp)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])

    # Check if customer already exists
    existing = db.execute(text(
        "SELECT * FROM customers WHERE email = :email"
    ), {"email": email}).mappings().first()
    if existing:
        return dict(existing)

    res = db.execute(text("""
        INSERT INTO customers (name, phone, email)
        VALUES (:name, :phone, :email)
    """), {"name": name, "phone": phone, "email": email})
    db.commit()

    customer = db.execute(
        text("SELECT * FROM customers WHERE id = :id"),
        {"id": res.lastrowid}
    ).mappings().first()
    return dict(customer)

# ── LOGIN: Step 1 - Send OTP ──
@router.post("/login/send-otp")
def login_send_otp(data: dict, db: Session = Depends(get_db)):
    email = data.get('email', '').strip()
    if not email:
        raise HTTPException(status_code=400, detail="Email is required")

    customer = db.execute(
        text("SELECT * FROM customers WHERE email = :email"),
        {"email": email}
    ).mappings().first()
    if not customer:
        raise HTTPException(status_code=404, detail="No account found. Please register.")

    result = send_otp_email(email)
    if not result["success"]:
        raise HTTPException(status_code=500, detail=f"Failed to send OTP: {result['message']}")

    return {"message": "OTP sent to your email"}

# ── LOGIN: Step 2 - Verify OTP ──
@router.post("/login/verify-otp")
def login_verify_otp(data: dict, db: Session = Depends(get_db)):
    email = data.get('email', '').strip()
    otp   = data.get('otp', '').strip()

    result = verify_otp(email, otp)
    if not result["success"]:
        raise HTTPException(status_code=400, detail=result["message"])

    customer = db.execute(
        text("SELECT * FROM customers WHERE email = :email"),
        {"email": email}
    ).mappings().first()
    return dict(customer)

# ── OTHER ROUTES ──
@router.post("/register")
def register_customer(data: dict, db: Session = Depends(get_db)):
    existing = db.execute(
        text("SELECT id FROM customers WHERE email = :email"),
        {"email": data.get('email', '')}
    ).mappings().first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered.")

    res = db.execute(text("""
        INSERT INTO customers (name, phone, email)
        VALUES (:name, :phone, :email)
    """), {"name": data['name'], "phone": data.get('phone', ''), "email": data.get('email', '')})
    db.commit()
    customer = db.execute(
        text("SELECT * FROM customers WHERE id = :id"),
        {"id": res.lastrowid}
    ).mappings().first()
    return dict(customer)

@router.get("/all")
def get_all_customers(db: Session = Depends(get_db)):
    result = db.execute(text("SELECT * FROM customers ORDER BY id DESC"))
    return [dict(r) for r in result.mappings().all()]

@router.get("/{phone}")
def get_customer(phone: str, db: Session = Depends(get_db)):
    result = db.execute(
        text("SELECT * FROM customers WHERE phone = :phone"),
        {"phone": phone})
    return result.mappings().first()

@router.put("/{customer_id}")
def update_customer(customer_id: int, data: dict, db: Session = Depends(get_db)):
    fields = []
    params = {"cid": customer_id}
    if "name" in data:
        fields.append("name = :name"); params["name"] = data["name"]
    if "phone" in data:
        fields.append("phone = :phone"); params["phone"] = data["phone"]
    if "address" in data:
        fields.append("address = :address"); params["address"] = data["address"]
    if not fields:
        raise HTTPException(status_code=400, detail="No fields to update")
    db.execute(text(f"UPDATE customers SET {', '.join(fields)} WHERE id = :cid"), params)
    db.commit()
    return {"success": True, "message": "Profile updated"}

@router.post("/membership/purchase")
def purchase_membership(data: dict, db: Session = Depends(get_db)):
    customer_id  = data.get("customer_id")
    member_type  = data.get("type")
    card_number  = data.get("card_number")
    valid_until  = data.get("valid_until")

    if not all([customer_id, member_type, card_number]):
        raise HTTPException(status_code=400, detail="Missing fields")

    # Check if membership column exists, add if not
    try:
        db.execute(text("ALTER TABLE customers ADD COLUMN membership_type VARCHAR(20) DEFAULT ''"))
        db.execute(text("ALTER TABLE customers ADD COLUMN membership_card VARCHAR(30) DEFAULT ''"))
        db.execute(text("ALTER TABLE customers ADD COLUMN membership_valid_until VARCHAR(10) DEFAULT ''"))
        db.commit()
    except Exception:
        pass  # columns already exist

    db.execute(text("""
        UPDATE customers SET
            membership_type = :mtype,
            membership_card = :card,
            membership_valid_until = :valid
        WHERE id = :cid
    """), {"mtype": member_type, "card": card_number, "valid": valid_until, "cid": customer_id})
    db.commit()
    return {"success": True, "message": f"{member_type} membership activated"}

@router.get("/membership/{customer_id}")
def get_membership(customer_id: int, db: Session = Depends(get_db)):
    try:
        result = db.execute(text("""
            SELECT membership_type, membership_card, membership_valid_until
            FROM customers WHERE id = :cid
        """), {"cid": customer_id}).mappings().first()
        if result:
            return dict(result)
        return {"membership_type": "", "membership_card": "", "membership_valid_until": ""}
    except Exception:
        return {"membership_type": "", "membership_card": "", "membership_valid_until": ""}