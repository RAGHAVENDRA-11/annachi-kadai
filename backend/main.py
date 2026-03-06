from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routes import products, customers, orders, ai_routes, auth

app = FastAPI(title="Annachi Kadai API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"]
)

app.include_router(products.router, prefix="/api/products", tags=["Products"])
app.include_router(customers.router, prefix="/api/customers", tags=["Customers"])
app.include_router(orders.router, prefix="/api/orders", tags=["Orders"])
app.include_router(ai_routes.router, prefix="/api/ai", tags=["AI"])
app.include_router(auth.router, prefix="/api/auth", tags=["Auth"])

@app.get("/")
def root():
    return {"message": "Annachi Kadai API is Running!"}