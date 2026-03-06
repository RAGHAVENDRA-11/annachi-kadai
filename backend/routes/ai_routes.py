from fastapi import APIRouter
from ai_features import get_demand_forecast, get_low_stock_alerts, get_smart_recommendations

router = APIRouter()

@router.get("/demand/{product_id}")
def demand_forecast(product_id: int):
    return get_demand_forecast(product_id)

@router.get("/low-stock")
def low_stock_alerts():
    return get_low_stock_alerts()

@router.get("/recommendations/{customer_id}")
def recommendations(customer_id: int):
    return get_smart_recommendations(customer_id)