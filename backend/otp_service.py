import random
import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv
from datetime import datetime, timedelta

load_dotenv()

# Store OTPs temporarily in memory
otp_store = {}

def generate_otp():
    return str(random.randint(100000, 999999))

def send_otp_email(email: str):
    otp = generate_otp()
    
    # Store OTP with expiry (5 minutes)
    otp_store[email] = {
        "otp": otp,
        "expires": datetime.now() + timedelta(minutes=5)
    }

    # Create email
    msg = MIMEMultipart()
    msg['From'] = os.getenv('EMAIL_ADDRESS')
    msg['To'] = email
    msg['Subject'] = "Annachi Kadai - Your OTP Code"

    body = f"""
    Hello!

    Your OTP for Annachi Kadai login is:

    🔐  {otp}

    This OTP is valid for 5 minutes.
    Do not share this with anyone.

    - Annachi Kadai Team 🛒
    """

    msg.attach(MIMEText(body, 'plain'))

    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(
            os.getenv('EMAIL_ADDRESS'),
            os.getenv('EMAIL_PASSWORD')
        )
        server.sendmail(
            os.getenv('EMAIL_ADDRESS'),
            email,
            msg.as_string()
        )
        server.quit()
        return {"success": True, "message": "OTP sent to your email"}
    except Exception as e:
        return {"success": False, "message": str(e)}


def verify_otp(email: str, otp: str):
    if email not in otp_store:
        return {"success": False, "message": "OTP not found. Please request again."}
    
    stored = otp_store[email]

    if datetime.now() > stored["expires"]:
        del otp_store[email]
        return {"success": False, "message": "OTP expired. Please request again."}

    if stored["otp"] != otp:
        return {"success": False, "message": "Invalid OTP. Try again."}

    # OTP verified — delete it
    del otp_store[email]
    return {"success": True, "message": "OTP verified successfully!"}