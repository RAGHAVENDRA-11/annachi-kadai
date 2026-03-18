from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os

# Load .env file FIRST before any routes import
try:
    from dotenv import load_dotenv
    load_dotenv(override=True)
except Exception:
    pass
from routes import products, customers, orders, ai_routes, auth, delivery_partners

app = FastAPI(title="Annachi Kadai API")

@app.on_event("startup")
async def startup_event():
    key = os.getenv("GEMINI_API_KEY", "")
    if key:
        print(f"✅ GEMINI_API_KEY loaded: {key[:8]}...")
    else:
        print("❌ GEMINI_API_KEY NOT found — check your .env file!")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(products.router,           prefix="/api/products",  tags=["Products"])
app.include_router(customers.router,          prefix="/api/customers", tags=["Customers"])
app.include_router(orders.router,             prefix="/api/orders",    tags=["Orders"])
app.include_router(ai_routes.router,          prefix="/api/ai",        tags=["AI"])
app.include_router(auth.router,               prefix="/api/auth",      tags=["Auth"])
app.include_router(delivery_partners.router,  prefix="/api/delivery-partners", tags=["Delivery"])

@app.get("/")
def root():
    return {"message": "Annachi Kadai API is running!", "status": "ok"}