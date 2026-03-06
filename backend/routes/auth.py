from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from database import get_db
from otp_service import send_otp_email, verify_otp

router = APIRouter()

@router.post("/send-otp")
def send_otp(data: dict):
    email = data.get("email")
    if not email:
        return {"success": False, "message": "Email is required"}
    return send_otp_email(email)

@router.post("/verify-otp")
def verify(data: dict, db: Session = Depends(get_db)):
    email = data.get("email")
    otp = data.get("otp")

    result = verify_otp(email, otp)

    if result["success"]:
        # Find existing customer by email
        customer = db.execute(
            text("SELECT * FROM customers WHERE email = :email"),
            {"email": email}
        ).mappings().first()

        if not customer:
            return {
                "success": False,
                "message": "No account found for this email. Please register first."
            }

        return {
            "success": True,
            "message": "Login successful!",
            "customer": dict(customer)
        }

    return result